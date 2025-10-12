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
  あなたは散歩コーチAIです。ユーザーの散歩履歴や気分の文脈を踏まえ、安全で多様性のある散歩ルートを日本語で提案してください。各候補のタイトルには、入力で与えられる散歩エリアや頻繁に訪れるスポット名（または同じ特徴を持つ近隣エリア）を含め、公道や公園など一般的にアクセス可能な場所のみを案内します。説明はポジティブで具体的にしつつ、誇張や現実離れした描写は避けてください。
  """

  // MARK: - Initialization

  /// イニシャライザ
  ///
  /// - Parameter walkRepository: 散歩履歴を取得するリポジトリ（デフォルトは共有インスタンス）
  init(walkRepository: WalkRepositoryProtocol = WalkRepository.shared) {
    self.walkRepository = walkRepository
    #if DEBUG
      print("[RouteSuggestionService] 初期化されました")
    #endif
  }

  // MARK: - Public Methods

  /// 散歩ルート提案を生成します
  ///
  /// 現在はプロトタイプとして固定の3つの提案を返します。
  /// 将来的には、ユーザーの散歩履歴と気分入力をもとに
  /// Foundation Modelsを使用して動的に生成します。
  ///
  /// - Returns: ルート提案の配列（最大3件）
  /// - Throws: ルート生成に失敗した場合のエラー
  func generateRouteSuggestions() async throws -> [RouteSuggestion] {
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

      // Phase 2: 訪問エリアを抽出（プレースホルダー）
      let visitedAreas = await extractVisitedAreas(from: walks)

      let prompt = makePrompt(visitedAreas: visitedAreas)
      let session = LanguageModelSession(instructions: generationInstructions)
      var lastError: Error?

      for attempt in 1 ... 3 {
        do {
          let response = try await session.respond(
            to: prompt,
            generating: [GeneratedRouteSuggestion].self
          )

          let suggestions = mapToRouteSuggestions(from: response.content)

          if suggestions.isEmpty {
            #if DEBUG
              print(
                "[RouteSuggestionService] FoundationModelsが0件を返したためリトライします (\(attempt)/3)"
              )
            #endif
            if attempt == 3 {
              throw RouteSuggestionServiceError.generationFailed(
                "Foundation Modelsが提案を生成できませんでした"
              )
            }
            continue
          }

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
  /// - Parameter visitedAreas: 訪問エリアの配列
  /// - Returns: Foundation Modelsに送信するプロンプト文字列
  private func makePrompt(visitedAreas: [String]) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    let dateString = formatter.string(from: Date())

    // 訪問エリアを整形
    let areasText = visitedAreas.isEmpty ? defaultArea : visitedAreas.joined(separator: "、")

    // 固定の気分（将来的にはユーザー入力に置き換え）
    let mood = "自然を感じながらリラックスしたい"

    return """
    今日の日付: \(dateString)
    散歩履歴サマリー:
    - 希望時間: \(defaultDuration)分
    - いつも散歩している場所: \(areasText)
    ※ 上記と類似するエリア名を提案に使っても構いません
    ユーザーの気分: 「\(mood)」

    上記の文脈を踏まえ、\(targetSuggestionCount)件の散歩ルート候補を提案してください。
    各候補には以下のフィールドを含めます:
    - title: 文脈から適切な具体的エリア名を含む3〜6語の短いルート名
    - description: 1〜2文でルートの特徴を説明
    - estimatedDistance: 1.5〜5.0の範囲の距離 (km)
    - estimatedDuration: 20〜60の範囲の時間 (分)
    - recommendationReason: 気分やメリットに言及した推奨理由

    出力は構造化されたデータとして生成してください。
    """
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
        print("  [\(index + 1)] \(suggestion.title) - \(suggestion.estimatedDistance)km, \(suggestion.estimatedDuration)分")
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
    let geocoder = CLGeocoder()

    return try await withCheckedThrowingContinuation { continuation in
      // タイムアウト設定（2秒）
      let timeoutTask = Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        geocoder.cancelGeocode()
        continuation.resume(throwing: NSError(
          domain: "RouteSuggestionService",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "ジオコーディングタイムアウト"]
        ))
      }

      geocoder.reverseGeocodeLocation(location) { placemarks, error in
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
    let normalized = generated.prefix(targetSuggestionCount).map { item -> RouteSuggestion in
      // モデルの出力を UI で扱いやすい値幅に丸める
      let roundedDistance = max((item.estimatedDistance * 10).rounded() / 10, 0.1)
      let duration = max(item.estimatedDuration, 5)

      return RouteSuggestion(
        title: item.title.trimmingCharacters(in: .whitespacesAndNewlines),
        description: item.description.trimmingCharacters(in: .whitespacesAndNewlines),
        estimatedDistance: roundedDistance,
        estimatedDuration: duration,
        recommendationReason: item.recommendationReason
          .trimmingCharacters(in: .whitespacesAndNewlines)
      )
    }

    return normalized
  }
#endif
}

// MARK: - Data Models

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

  /// 推定所要時間（分）
  let estimatedDuration: Int

  /// 推奨理由
  let recommendationReason: String
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

    /// 推定時間（分）
    let estimatedDuration: Int

    /// 推奨理由
    let recommendationReason: String
  }
#endif
