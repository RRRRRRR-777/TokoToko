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

/// WalkRepositoryのプロトコル定義（テスタビリティのため）
protocol WalkRepositoryProtocol {
  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void)
}

/// WalkRepositoryをプロトコルに準拠させる
extension WalkRepository: WalkRepositoryProtocol {}

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
    walkRepository: WalkRepositoryProtocol = WalkRepository.shared,
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
                "[RouteSuggestionService] FoundationModelsが\(suggestions.count)件を返しました（目標\(targetSuggestionCount)件）"
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
                source: "FoundationModels（試行\(attempt)回目、目標未達）"
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
            source: "FoundationModels（試行\(attempt)回目）"
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
    print("入力プロンプト: \(inputPrompt)")
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
      print("[RouteSuggestionService] 訪問エリアの抽出を開始（\(walks.count)件の散歩履歴）")
    #endif

    var areas: [String] = []

    for walk in walks {
      let samplingPoints = extractSamplingPoints(from: walk)

      for location in samplingPoints {
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
