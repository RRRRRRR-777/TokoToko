//
//  RouteSuggestionService.swift
//  TekuToko
//
//  Created by Claude Code on 2025/10/12.
//

import CoreLocation
import Foundation
#if canImport(FoundationModels)
  import FoundationModels
#endif


/// Geocoderのプロトコル定義（テスタビリティのため）
protocol GeocoderProtocol {
  func reverseGeocodeLocation(
    _ location: CLLocation,
    completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void
  )
  func cancelGeocode()
}

/// CLGeocoderをプロトコルに準拠させる
extension CLGeocoder: GeocoderProtocol {}

/// RouteSuggestionService が発生させるエラー
enum RouteSuggestionServiceError: Error {
  /// 利用可能な Foundation Model が存在しない場合
  case foundationModelUnavailable(String)

  /// モデルが有効な提案を生成できなかった場合
  case generationFailed(String)

  /// データベース接続エラー
  case databaseUnavailable(String)
}

/// 散歩ルート提案サービス
///
/// ユーザーの散歩履歴と気分をもとに、散歩ルート候補を提案します。
/// 現在はプロトタイプとして固定の提案を返しますが、
/// 将来的にはFoundation Modelsを使用して動的に生成します。
@available(iOS 26.0, *)
class RouteSuggestionService {

  // MARK: - Properties

  /// 散歩履歴を取得するリポジトリ
  internal let walkRepository: WalkRepositoryProtocol

  /// ジオコーダー（テスト時にモック可能）
  internal let geocoderFactory: () -> GeocoderProtocol

  #if canImport(FoundationModels)
    /// テスト用にLLM応答を差し替えるためのフック
    internal var llmResponseOverride: ((String, Int) async throws -> [RouteSuggestion])?
  #endif

  /// 生成するルート提案数
  private let targetSuggestionCount = 3

  /// 散歩履歴の取得件数（過去15件）
  private let walkHistoryLimit = 15

  /// デフォルトの訪問エリア（履歴が0件の場合）
  private let defaultArea = "東京周辺"

  /// デフォルトの散歩時間（2時間 = 120分）
  private let defaultDuration = 120

  /// Foundation Models に与える共通指示
  private let generationInstructions = """
  あなたは散歩ルート提案AIです。

  【重要】必ず指定された件数（通常3件）の提案を生成してください。

  提案する際のルール：
  1. ユーザーの気分を最優先し、その気分に合った散歩ルートを提案する
  2. 提案するエリアは、ユーザーの散歩履歴エリアまたはその近隣から選ぶ
  3. title・description・landmarkに記載する地名と、addressの市区町村は必ず一致させる
  4. 全ての必須フィールド（address, postalCode, landmark）を必ず埋める
  5. 郵便番号は7桁ハイフン付き（例：113-0033）で記載する
  """

  // MARK: - Initialization

  /// イニシャライザ
  ///
  /// - Parameters:
  ///   - walkRepository: 散歩履歴を取得するリポジトリ（デフォルトは共有インスタンス）
  ///   - geocoderFactory: ジオコーダーを生成するファクトリ（デフォルトはCLGeocoder）
  init(
    walkRepository: WalkRepositoryProtocol = WalkRepositoryFactory.shared.repository,
    geocoderFactory: @escaping () -> GeocoderProtocol = { CLGeocoder() }
  ) {
    self.walkRepository = walkRepository
    self.geocoderFactory = geocoderFactory
    #if DEBUG
      print("[RouteSuggestionService] 初期化されました")
    #endif
  }

  // MARK: - Public Methods

  /// 散歩ルート提案を生成します
  ///
  /// ユーザーの散歩履歴と入力（気分、時間/距離、発見したいもの）をもとに
  /// Foundation Modelsを使用してルート提案を動的に生成します。
  ///
  /// - Parameter userInput: ユーザーからの入力（気分、時間/距離、発見したいもの）
  /// - Returns: ルート提案の配列（最大3件）
  /// - Throws: ルート生成に失敗した場合のエラー
  func generateRouteSuggestions(userInput: RouteSuggestionUserInput) async throws -> [RouteSuggestion] {
    #if DEBUG
      print("[RouteSuggestionService] ルート提案生成を開始")
    #endif

    #if !canImport(FoundationModels)
      throw RouteSuggestionServiceError.foundationModelUnavailable(
        "FoundationModelsフレームワークが利用できません"
      )
    #else
      guard SystemLanguageModel.default.isAvailable else {
        throw RouteSuggestionServiceError.foundationModelUnavailable(
          "SystemLanguageModel.defaultがこのデバイスで利用できません"
        )
      }

      // Phase 1: 散歩履歴を取得
      let walks = try await fetchWalkHistory()

      // Phase 2: 訪問エリアを抽出
      let visitedAreas = await extractVisitedAreas(from: walks)

      // Phase 3: プロンプトを生成
      let prompt = makePrompt(visitedAreas: visitedAreas, userInput: userInput)

      if let override = llmResponseOverride {
        let suggestions = try await override(prompt, targetSuggestionCount)
        logGeneratedSuggestions(suggestions, source: "LLMOverride")
        return suggestions
      }

      let session = LanguageModelSession(instructions: generationInstructions)
      var lastError: Error?

      for attempt in 1 ... 3 {
        do {
          let response = try await session.respond(
            to: prompt,
            generating: [GeneratedRouteSuggestion].self
          )

          let suggestions = mapToRouteSuggestions(from: response.content)

          // 目標件数に満たない場合の処理
          if suggestions.count < targetSuggestionCount {
            #if DEBUG
              print(
                "[RouteSuggestionService] FoundationModelsが\(suggestions.count)件を返しました(目標\(targetSuggestionCount)件)"
              )
            #endif

            // 3回目のリトライでも目標件数に達しない場合
            if attempt == 3 {
              // 0件の場合はエラー
              if suggestions.isEmpty {
                throw RouteSuggestionServiceError.generationFailed(
                  "Foundation Modelsが提案を生成できませんでした"
                )
              }
              // 1件以上あればその結果を返す
              #if DEBUG
                print(
                  "[RouteSuggestionService] リトライ上限に達しました。\(suggestions.count)件の提案を返します"
                )
              #endif
              logGeneratedSuggestions(
                suggestions,
                source: "FoundationModels(試行\(attempt)回目、目標未達)"
              )
              return suggestions
            }

            // まだリトライ可能な場合は続行
            #if DEBUG
              print("[RouteSuggestionService] リトライします (\(attempt)/3)")
            #endif
            continue
          }

          // 目標件数に達した場合
          logGeneratedSuggestions(
            suggestions,
            source: "FoundationModels(試行\(attempt)回目)"
          )
          return suggestions
        } catch {
          lastError = error
          #if DEBUG
            print(
              "[RouteSuggestionService] FoundationModels呼び出しに失敗しました (\(attempt)/3): \(error.localizedDescription)"
            )
          #endif
          if attempt == 3 {
            throw RouteSuggestionServiceError.generationFailed(
              "Foundation Modelsの応答生成に失敗: \(error.localizedDescription)"
            )
          }
        }
      }

      throw RouteSuggestionServiceError.generationFailed(
        "Foundation Modelsの応答生成に失敗しました: \(lastError?.localizedDescription ?? "Unknown error")"
      )
    #endif
  }

  // MARK: - Private Helpers

  /// Foundation Models に渡すプロンプトを生成します。
  ///
  /// - Parameters:
  ///   - visitedAreas: 訪問エリアの配列
  ///   - userInput: ユーザーからの入力（気分、時間/距離、発見したいもの）
  /// - Returns: Foundation Modelsに送信するプロンプト文字列
  private func makePrompt(visitedAreas: [String], userInput: RouteSuggestionUserInput) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    let dateString = formatter.string(from: Date())

    // 訪問エリアを整形
    let areasText = visitedAreas.isEmpty ? defaultArea : visitedAreas.joined(separator: "、")

    // ユーザーの気分（空の場合はデフォルト）
    let mood = userInput.mood.isEmpty ? "散歩を楽しみたい" : userInput.mood

    // 散歩オプション（時間 or 距離）を整形
    let optionText: String
    let distanceSpec: String
    let durationSpec: String

    switch userInput.walkOption {
    case .time(let hours):
      optionText = "希望時間: \(hours)時間"
      durationSpec = "\(hours)時間に近い値"
      distanceSpec = "適切な距離"
    case .distance(let kilometers):
      optionText = "希望距離: \(kilometers)km"
      distanceSpec = "\(kilometers)kmに近い値"
      durationSpec = "適切な時間"
    }

    // 発見したいものを整形
    let discoveriesText = userInput.discoveries.isEmpty
      ? ""
      : "\n- 発見したいもの: \(userInput.discoveries.joined(separator: "、"))"

    let inputPrompt = """
    【必須】必ず\(targetSuggestionCount)件の散歩ルート提案を生成してください

    ■ ユーザー情報
    - 気分: 「\(mood)」
    - \(optionText) ← **この値に近い提案を必ず生成すること**\(discoveriesText)
    - よく歩くエリア: \(areasText)

    ■ 出力条件（優先順位順）
    1. 【最重要】件数: 必ず\(targetSuggestionCount)件（\(targetSuggestionCount)件未満は不可）
    2. 【最重要】\(optionText)に近い値で提案すること（大幅に外れた値は不可）
    3. エリア: ユーザーのよく歩くエリアまたはその近隣から選ぶ
    4. 必須項目: address（都道府県+市区町村+町名）、postalCode（7桁ハイフン付き）、landmark（具体的な場所名）
    5. 整合性: title・description・landmarkの地名とaddressの市区町村を一致させる

    ■ 出力フォーマット（JSON配列）
    以下の形式で\(targetSuggestionCount)件を生成：
    - title: エリア名を含む短いルート名
    - description: ルートの特徴（1〜2文）
    - estimatedDistance: \(distanceSpec)（km）
    - estimatedDuration: \(durationSpec)（時間）
    - recommendationReason: 気分に基づいた推奨理由
    - address: 「都道府県+市区町村+町名」形式の住所
    - postalCode: 7桁ハイフン付き郵便番号
    - landmark: 具体的な場所名

    JSON配列として出力してください。
    """
    #if DEBUG
      print("入力プロンプト: \(inputPrompt)")
    #endif
    return inputPrompt
  }
  /// 生成したルート提案をデバッグ出力します。
  ///
  /// - Parameters:
  ///   - suggestions: 出力する提案。
  ///   - source: 生成元（FoundationModelsまたはFallbackなど）。
  private func logGeneratedSuggestions(_ suggestions: [RouteSuggestion], source: String) {
    #if DEBUG
      print("[RouteSuggestionService] \(source)から\(suggestions.count)件の提案を取得しました")
      for (index, suggestion) in suggestions.enumerated() {
        print("  [\(index + 1)] \(suggestion.title) - \(suggestion.estimatedDistance)km, \(suggestion.estimatedDuration)時間")
        print("       住所: \(suggestion.address)")
        print("       郵便番号: \(suggestion.postalCode)")
        print("       ランドマーク: \(suggestion.landmark)")
        print("       理由: \(suggestion.recommendationReason)")
      }
    #endif
  }

  // MARK: - Phase 1: Walk History Fetching

  /// Firestoreから過去15件の散歩履歴を取得します。
  ///
  /// - Returns: 散歩履歴の配列（最大15件）
  /// - Throws: データベース接続エラー
  private func fetchWalkHistory() async throws -> [Walk] {
    #if DEBUG
      print("[RouteSuggestionService] 散歩履歴の取得を開始（最大\(walkHistoryLimit)件）")
    #endif

    return try await withCheckedThrowingContinuation { continuation in
      self.walkRepository.fetchWalks { result in
        switch result {
        case .success(let walks):
          // 最新15件を取得（作成日時の降順）
          let recentWalks = Array(walks.sorted { $0.createdAt > $1.createdAt }.prefix(self.walkHistoryLimit))
          #if DEBUG
            print("[RouteSuggestionService] 散歩履歴を\(recentWalks.count)件取得しました")
          #endif
          continuation.resume(returning: recentWalks)

        case .failure(let error):
          #if DEBUG
            print("[RouteSuggestionService] 散歩履歴の取得に失敗: \(error)")
          #endif
          continuation.resume(throwing: RouteSuggestionServiceError.databaseUnavailable(
            "散歩履歴の取得に失敗しました: \(error.localizedDescription)"
          ))
        }
      }
    }
  }

  // MARK: - Phase 2: Visited Areas Extraction

  /// 散歩履歴から訪問エリアを抽出します。
  ///
  /// - Parameter walks: 散歩履歴の配列
  /// - Returns: 訪問エリアの配列（重複除去済み）
  private func extractVisitedAreas(from walks: [Walk]) async -> [String] {
    #if DEBUG
      print("[RouteSuggestionService] 訪問エリアの抽出を開始(\(walks.count)件の散歩履歴)")
    #endif

    // Phase 1: 全散歩からサンプリング地点を収集
    var allSamplingPoints: [CLLocation] = []
    for walk in walks {
      let samplingPoints = extractSamplingPoints(from: walk)
      allSamplingPoints.append(contentsOf: samplingPoints)
    }

    #if DEBUG
      print("[RouteSuggestionService] サンプリング地点を\(allSamplingPoints.count)件収集")
    #endif

    // Phase 2: クラスタリングで代表地点を抽出
    let clusteredLocations = clusterLocations(allSamplingPoints)

    // Phase 3: 代表地点のみをジオコーディング
    var areas: [String] = []
    for location in clusteredLocations {
      do {
        if let areaName = try await reverseGeocode(location: location) {
          areas.append(areaName)
        }
      } catch {
        #if DEBUG
          print("[RouteSuggestionService] ジオコーディング失敗: \(error.localizedDescription)")
        #endif
      }

      // レート制限対策：0.1秒待機
      try? await Task.sleep(nanoseconds: 100_000_000)
    }

    // 重複除去
    let uniqueAreas = Array(Set(areas))

    #if DEBUG
      print("[RouteSuggestionService] 訪問エリアを\(uniqueAreas.count)件抽出しました: \(uniqueAreas.joined(separator: "、"))")
    #endif

    return uniqueAreas
  }

  /// 散歩から3地点（開始+中間+終了）を抽出します。
  ///
  /// - Parameter walk: 散歩データ
  /// - Returns: サンプリングポイントの配列（最大3地点）
  private func extractSamplingPoints(from walk: Walk) -> [CLLocation] {
    guard !walk.locations.isEmpty else { return [] }

    var points: [CLLocation] = []

    // 開始地点
    if let start = walk.locations.first {
      points.append(start)
    }

    // 中間地点（位置配列の中央）
    if walk.locations.count > 2 {
      let middleIndex = walk.locations.count / 2
      points.append(walk.locations[middleIndex])
    }

    // 終了地点
    if let end = walk.locations.last, walk.locations.count > 1 {
      points.append(end)
    }

    return points
  }

  /// 座標をグリッドキーに変換します（クラスタリング用）。
  ///
  /// 緯度経度を一定精度で丸めることで、近接する地点を同じグループにまとめます。
  /// 精度: 約0.01度 ≈ 1km
  ///
  /// - Parameter location: 位置情報
  /// - Returns: グリッドキー（"緯度_経度"形式）
  private func gridKey(for location: CLLocation) -> String {
    let precision = 100.0  // 0.01度単位（約1km）
    let roundedLat = round(location.coordinate.latitude * precision) / precision
    let roundedLon = round(location.coordinate.longitude * precision) / precision
    return "\(roundedLat)_\(roundedLon)"
  }

  /// サンプリング地点をクラスタリングして代表地点を抽出します。
  ///
  /// 近接する地点を1つの代表地点にまとめることで、ジオコーディングの呼び出し回数を削減します。
  ///
  /// - Parameter locations: サンプリング地点の配列
  /// - Returns: クラスタリング後の代表地点配列
  func clusterLocations(_ locations: [CLLocation]) -> [CLLocation] {
    var clusters: [String: CLLocation] = [:]

    for location in locations {
      let key = gridKey(for: location)
      // 同じグリッド内に既存の地点がない場合のみ追加
      if clusters[key] == nil {
        clusters[key] = location
      }
    }

    let clusteredLocations = Array(clusters.values)

    #if DEBUG
      print("[RouteSuggestionService] クラスタリング: \(locations.count)地点 → \(clusteredLocations.count)地点に削減")
    #endif

    return clusteredLocations
  }

  /// リバースジオコーディングで位置から地名を取得します。
  ///
  /// - Parameter location: 位置情報
  /// - Returns: 市区町村レベルの地名（取得できない場合はnil）
  /// - Throws: ジオコーディングエラー
  private func reverseGeocode(location: CLLocation) async throws -> String? {
    let geocoder = geocoderFactory()

    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
      var isResumed = false
      let lock = NSLock()

      // タイムアウト設定（2秒）
      let timeoutTask = Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        lock.lock()
        defer { lock.unlock() }

        if !isResumed {
          isResumed = true
          geocoder.cancelGeocode()
          continuation.resume(throwing: NSError(
            domain: "RouteSuggestionService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "ジオコーディングタイムアウト"]
          ))
        }
      }

      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        lock.lock()
        defer { lock.unlock() }

        guard !isResumed else { return }
        isResumed = true
        timeoutTask.cancel()

        if let error = error {
          continuation.resume(throwing: error)
          return
        }

        // 市区町村レベルの地名を優先
        let areaName = placemarks?.first?.locality
          ?? placemarks?.first?.subLocality
          ?? placemarks?.first?.administrativeArea
        continuation.resume(returning: areaName)
      }
    }
  }

#if canImport(FoundationModels)
  /// 生成結果を`RouteSuggestion`に変換します。
  ///
  /// - Parameter generated: Foundation Models が生成したルート提案。
  /// - Returns: アプリで扱える`RouteSuggestion`配列。
  private func mapToRouteSuggestions(from generated: [GeneratedRouteSuggestion]) -> [RouteSuggestion] {
    let normalized = generated.prefix(targetSuggestionCount).compactMap { item -> RouteSuggestion? in
      // モデルの出力を UI で扱いやすい値幅に丸める
      let roundedDistance = max((item.estimatedDistance * 10).rounded() / 10, 0.1)
      let roundedDuration = max((item.estimatedDuration * 10).rounded() / 10, 0.1)

      // 必須フィールドのバリデーション
      let address = item.address.trimmingCharacters(in: .whitespacesAndNewlines)
      let postalCode = item.postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
      let landmark = item.landmark.trimmingCharacters(in: .whitespacesAndNewlines)

      // 空文字列チェック: いずれかが空の場合は候補から除外
      guard !address.isEmpty, !postalCode.isEmpty, !landmark.isEmpty else {
        #if DEBUG
          print("[RouteSuggestionService] 必須フィールドが空のため候補を除外: \(item.title)")
        #endif
        return nil
      }

      return RouteSuggestion(
        title: item.title.trimmingCharacters(in: .whitespacesAndNewlines),
        description: item.description.trimmingCharacters(in: .whitespacesAndNewlines),
        estimatedDistance: roundedDistance,
        estimatedDuration: roundedDuration,
        recommendationReason: item.recommendationReason
          .trimmingCharacters(in: .whitespacesAndNewlines),
        address: address,
        postalCode: postalCode,
        landmark: landmark
      )
    }

    return normalized
  }
#endif
}

// MARK: - Data Models

/// ユーザー入力データ
///
/// ルート提案を生成するために必要なユーザーからの入力を表します。
struct RouteSuggestionUserInput {
  /// 気分や希望（任意、空文字列可）
  let mood: String

  /// 散歩のオプション（時間 or 距離）
  let walkOption: WalkOption

  /// 発見したいもの（複数選択可）
  let discoveries: [String]

  /// 散歩のオプション（時間 or 距離）
  enum WalkOption {
    /// 時間指定（時間単位）
    case time(hours: Double)

    /// 距離指定（km単位）
    case distance(kilometers: Double)
  }
}

/// 散歩ルート提案
///
/// LLMによって生成される散歩ルートの提案内容を表します。
struct RouteSuggestion: Codable {
  /// ルートのタイトル
  let title: String

  /// ルートの説明
  let description: String

  /// 推定距離（km）
  let estimatedDistance: Double

  /// 推定所要時間（時間）
  let estimatedDuration: Double

  /// 推奨理由
  let recommendationReason: String

  /// ルート中心の住所（都道府県＋市区町村＋丁目レベル、例: "東京都文京区本郷3丁目"）
  let address: String

  /// 郵便番号（7桁ハイフン付き、例: "113-0033"）
  let postalCode: String

  /// ランドマーク（駅、公園、商店街、寺社、大学など、例: "東京大学本郷キャンパス"）
  let landmark: String
}

#if canImport(FoundationModels)
  @available(iOS 26.0, *)
  @Generable
  private struct GeneratedRouteSuggestion: Sendable {
    /// ルート名
    let title: String

    /// ルートの説明
    let description: String

    /// 推定距離（km）
    let estimatedDistance: Double

    /// 推定時間（時間）
    let estimatedDuration: Double

    /// 推奨理由
    let recommendationReason: String

    /// ルート中心の住所（都道府県＋市区町村＋丁目レベル）
    let address: String

    /// 郵便番号（7桁ハイフン付き）
    let postalCode: String

    /// ランドマーク（駅、公園、商店街、寺社、大学など）
    let landmark: String
  }

#endif

// MARK: - Verification Models

/// 検証結果を保持する構造体（検証1用）
struct VerificationResult: Codable, Identifiable {
  let id = UUID()
  let title: String
  let prompt: String
  let response: String
  let latencySeconds: Double
  let timestamp: Date
  let observations: [String]

  var formattedLatency: String {
    String(format: "%.2f秒", latencySeconds)
  }
}

/// 検証7: 理解・要約能力の結果
struct SummarizationVerificationResult: Codable, Identifiable {
  let id = UUID()
  let title: String
  let prompt: String
  let response: String
  let latencySeconds: Double
  let timestamp: Date
  let observations: [String]

  var formattedLatency: String {
    String(format: "%.2f秒", latencySeconds)
  }
}

// MARK: - Verification Methods

#if canImport(FoundationModels)
@available(iOS 26.0, *)
extension RouteSuggestionService {

  /// 検証1: 最小利用検証
  ///
  /// 目的: Foundation Modelsが基本的に動作するか確認する
  /// - 最もシンプルなプロンプトを送信
  /// - レスポンスが返ってくるか確認
  /// - 初期化のレイテンシを計測
  func verifyBasicUsage() async throws -> VerificationResult {
    // 既存実装と同じくavailabilityチェック
    guard SystemLanguageModel.default.isAvailable else {
      throw RouteSuggestionServiceError.foundationModelUnavailable(
        "SystemLanguageModel.defaultがこのデバイスで利用できません"
      )
    }

    let startTime = Date()
    let prompt = "散歩に良い場所を1つ教えてください。場所の名前だけを答えてください。"

    // 既存実装と同じくinstructionsを渡す
    let instructions = "あなたは散歩ルート提案AIです。簡潔に答えてください。"
    let session = LanguageModelSession(instructions: instructions)
    let response = try await session.respond(to: prompt)

    let endTime = Date()
    let latency = endTime.timeIntervalSince(startTime)

    let observations = [
      "✅ レスポンス取得成功",
      "📏 応答長: \(response.content.count)文字",
      latency < 5.0 ? "⚡ レイテンシ良好（5秒以内）" : "⚠️ レイテンシやや遅い（5秒超）"
    ]

    return VerificationResult(
      title: "最小利用検証",
      prompt: prompt,
      response: response.content,
      latencySeconds: latency,
      timestamp: startTime,
      observations: observations
    )
  }

  /// 検証1: 指示追従性能 - 制約を守るか
  ///
  /// 目的: 「必ず3件」「距離5km以内」などの条件を付けて、守られるか確認する
  /// - 件数制約: 必ず3件生成すること
  /// - 距離制約: 5km以内のルート
  /// - 時間制約: 1時間以内
  func verifyInstructionFollowing() async throws -> VerificationResult {
    guard SystemLanguageModel.default.isAvailable else {
      throw RouteSuggestionServiceError.foundationModelUnavailable(
        "SystemLanguageModel.defaultがこのデバイスで利用できません"
      )
    }

    let startTime = Date()

    // 制約付きプロンプト
    let prompt = """
    【必須制約】以下の条件を全て守って散歩ルートを提案してください:
    1. 件数: 必ず3件（3件未満・3件超過は不可）
    2. 距離: 5km以内のルート（5.0km以下）
    3. 時間: 1時間以内のルート（60分以内）
    4. エリア: 東京周辺

    以下のJSON配列形式で出力してください:
    [
      {
        "title": "ルート名",
        "description": "説明",
        "estimatedDistance": 距離(km),
        "estimatedDuration": 時間(時間),
        "recommendationReason": "推奨理由",
        "address": "住所",
        "postalCode": "郵便番号",
        "landmark": "ランドマーク"
      }
    ]
    """

    let instructions = """
    あなたは散歩ルート提案AIです。
    ユーザーが指定した制約条件を必ず守ってください。
    制約を1つでも破った場合は失格となります。
    """

    let session = LanguageModelSession(instructions: instructions)
    let response = try await session.respond(
      to: prompt,
      generating: [GeneratedRouteSuggestion].self
    )

    let endTime = Date()
    let latency = endTime.timeIntervalSince(startTime)

    // 制約チェック
    let suggestions = response.content

    #if DEBUG
      print("[verifyInstructionFollowing] LLMから\(suggestions.count)件の提案を受信")
      if suggestions.isEmpty {
        print("[verifyInstructionFollowing] 警告: 提案が0件です。LLMが空配列を返した可能性があります")
      }
      for (index, suggestion) in suggestions.enumerated() {
        print("[verifyInstructionFollowing] [\(index + 1)] \(suggestion.title)")
        print("  - distance: \(suggestion.estimatedDistance)km, duration: \(suggestion.estimatedDuration)h")
        print("  - address: '\(suggestion.address)', postalCode: '\(suggestion.postalCode)', landmark: '\(suggestion.landmark)'")
      }
    #endif

    var observations: [String] = []

    // 件数チェック
    if suggestions.count == 3 {
      observations.append("✅ 件数制約: 3件生成（正しい）")
    } else {
      observations.append("❌ 件数制約: \(suggestions.count)件生成（期待: 3件）")
    }

    // 距離制約チェック
    let distanceViolations = suggestions.filter { $0.estimatedDistance > 5.0 }
    if distanceViolations.isEmpty {
      observations.append("✅ 距離制約: 全て5km以内（正しい）")
    } else {
      observations.append("❌ 距離制約: \(distanceViolations.count)件が5km超過")
      distanceViolations.forEach {
        observations.append("  - \($0.title): \($0.estimatedDistance)km")
      }
    }

    // 時間制約チェック
    let durationViolations = suggestions.filter { $0.estimatedDuration > 1.0 }
    if durationViolations.isEmpty {
      observations.append("✅ 時間制約: 全て1時間以内（正しい）")
    } else {
      observations.append("❌ 時間制約: \(durationViolations.count)件が1時間超過")
      durationViolations.forEach {
        observations.append("  - \($0.title): \($0.estimatedDuration)時間")
      }
    }

    // 必須フィールドチェック
    let missingFieldCount = suggestions.filter {
      $0.address.isEmpty || $0.postalCode.isEmpty || $0.landmark.isEmpty
    }.count
    if missingFieldCount == 0 {
      observations.append("✅ 必須フィールド: 全て入力あり")
    } else {
      observations.append("❌ 必須フィールド: \(missingFieldCount)件に欠損")
    }

    // レイテンシ
    observations.append(
      latency < 5.0 ? "⚡ レイテンシ良好（5秒以内）" : "⚠️ レイテンシやや遅い（5秒超）"
    )

    // 結果の整形
    let responseText = suggestions.enumerated().map { index, suggestion in
      """
      【\(index + 1)】\(suggestion.title)
      - 距離: \(suggestion.estimatedDistance)km
      - 時間: \(suggestion.estimatedDuration)時間
      - 住所: \(suggestion.address)
      - 郵便番号: \(suggestion.postalCode)
      - ランドマーク: \(suggestion.landmark)
      - 理由: \(suggestion.recommendationReason)
      """
    }.joined(separator: "\n\n")

    return VerificationResult(
      title: "検証1: 指示追従性能",
      prompt: prompt,
      response: responseText,
      latencySeconds: latency,
      timestamp: startTime,
      observations: observations
    )
  }

  /// 検証7: 理解・要約能力
  ///
  /// 目的: 構造理解・要約能力とハルシネーション耐性を確認する
  /// - 文章を提示し、複数の制約を設けたうえ要約させて出力を確認する
  func verifySummarization() async throws -> SummarizationVerificationResult {
    guard SystemLanguageModel.default.isAvailable else {
      throw RouteSuggestionServiceError.foundationModelUnavailable(
        "SystemLanguageModel.defaultがこのデバイスで利用できません"
      )
    }

    let startTime = Date()

    // 要約対象の文章（散歩関連）
    let sourceText = """
    散歩は心身の健康に多くの利益をもたらす活動である。
    定期的な散歩は、心肺機能を向上させ、筋力を維持し、骨密度を高める効果がある。
    また、自然の中を歩くことでストレスが軽減され、気分が改善されることが研究で示されている。
    さらに、散歩中に季節の変化や地域の景色を観察することで、
    観察力や創造性が高まるという報告もある。
    近年では、スマートフォンアプリで散歩ルートや歩数を記録し、
    健康管理に活用する人が増えている。
    """

    // 制約付きプロンプト
    let prompt = """
    以下の文章を要約してください。

    制約：
    - 見出し＋本文の2部構成
    - 見出しは15文字以内
    - 本文は4行以内
    - 原文にない情報は追加しない

    文章：
    \(sourceText)
    """

    let instructions = "あなたは散歩ルート提案AIです。ユーザーが指定した制約条件を必ず守ってください。"

    let session = LanguageModelSession(instructions: instructions)
    let response = try await session.respond(to: prompt)

    let endTime = Date()
    let latency = endTime.timeIntervalSince(startTime)

    #if DEBUG
      print("[verifySummarization] 実行完了")
      print("[verifySummarization] レスポンス: \(response.content)")
      print("[verifySummarization] レイテンシ: \(String(format: "%.2f", latency))秒")
    #endif

    // 制約チェック
    let lines = response.content.split(separator: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.map { String($0) }
    var observations: [String] = []

    // 構成チェック（見出し＋本文）
    if lines.count >= 2 {
      observations.append("✅ 構成: 見出し＋本文の2部構成")
    } else {
      observations.append("❌ 構成: \(lines.count)部構成（期待: 2部構成）")
    }

    // 見出し文字数チェック（1行目を見出しと仮定）
    if !lines.isEmpty {
      let headingLength = lines[0].count
      if headingLength <= 15 {
        observations.append("✅ 見出し文字数: \(headingLength)文字（15文字以内）")
      } else {
        observations.append("❌ 見出し文字数: \(headingLength)文字（期待: 15文字以内）")
      }
    }

    // 本文行数チェック（2行目以降を本文と仮定）
    let bodyLines = lines.dropFirst()
    if bodyLines.count <= 4 {
      observations.append("✅ 本文行数: \(bodyLines.count)行（4行以内）")
    } else {
      observations.append("❌ 本文行数: \(bodyLines.count)行（期待: 4行以内）")
    }

    // ハルシネーションチェック（原文に存在するキーワード）
    let sourceKeywords = ["散歩", "健康", "心肺機能", "ストレス", "自然", "観察", "スマートフォン", "アプリ", "記録"]
    let responseText = response.content
    var foundKeywords: [String] = []
    for keyword in sourceKeywords {
      if responseText.contains(keyword) {
        foundKeywords.append(keyword)
      }
    }
    observations.append("✅ 原文キーワード: \(foundKeywords.count)/\(sourceKeywords.count)個含む（\(foundKeywords.joined(separator: "、"))）")

    // 明らかな追加情報のチェック（ネガティブチェック）
    let hallucinations = ["AI", "ロボット", "未来", "宇宙", "量子"]
    var foundHallucinations: [String] = []
    for word in hallucinations {
      if responseText.contains(word) {
        foundHallucinations.append(word)
      }
    }
    if foundHallucinations.isEmpty {
      observations.append("✅ ハルシネーション: 検出なし")
    } else {
      observations.append("❌ ハルシネーション: \(foundHallucinations.joined(separator: "、"))")
    }

    // レイテンシ
    observations.append(
      latency < 5.0 ? "⚡ レイテンシ良好（5秒以内）" : "⚠️ レイテンシやや遅い（5秒超）"
    )

    return SummarizationVerificationResult(
      title: "検証7: 理解・要約能力",
      prompt: prompt,
      response: response.content,
      latencySeconds: latency,
      timestamp: startTime,
      observations: observations
    )
  }
}
#endif
