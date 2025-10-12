//
//  RouteSuggestionService.swift
//  TekuToko
//
//  Created by Claude Code on 2025/10/12.
//

import Foundation
#if canImport(FoundationModels)
  import FoundationModels
#endif

/// RouteSuggestionService が発生させるエラー
enum RouteSuggestionServiceError: Error {
  /// 利用可能な Foundation Model が存在しない場合
  case foundationModelUnavailable(String)

  /// モデルが有効な提案を生成できなかった場合
  case generationFailed(String)
}

/// 散歩ルート提案サービス
///
/// ユーザーの散歩履歴と気分をもとに、散歩ルート候補を提案します。
/// 現在はプロトタイプとして固定の提案を返しますが、
/// 将来的にはFoundation Modelsを使用して動的に生成します。
@available(iOS 26.0, *)
class RouteSuggestionService {

  // MARK: - Properties

  /// 生成するルート提案数
  private let targetSuggestionCount = 3

  /// Foundation Models に与える共通指示
  private let generationInstructions = """
  あなたは散歩コーチAIです。ユーザーの散歩履歴や気分の文脈を踏まえ、安全で多様性のある散歩ルートを日本語で提案してください。各候補のタイトルには、入力で与えられる散歩エリアや頻繁に訪れるスポット名（または同じ特徴を持つ近隣エリア）を含め、公道や公園など一般的にアクセス可能な場所のみを案内します。説明はポジティブで具体的にしつつ、誇張や現実離れした描写は避けてください。
  """

  // MARK: - Initialization

  init() {
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

      let prompt = makePrompt()
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
  private func makePrompt() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja_JP")
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    let dateString = formatter.string(from: Date())

    // TODO: 散歩履歴・気分・常連エリアの実データを流し込む際はここを置き換える
    return """
    今日の日付: \(dateString)
    散歩履歴サマリー:
    - 平均距離: 3.2km
    - 平均時間: 38分
    - いつも散歩している場所（固定入力例）: 皇居周辺、渋谷、青山
    ※ 上記と類似するエリア名を提案に使っても構いません
    ユーザーの気分: 「自然を感じながらリラックスしたい」

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

#if canImport(FoundationModels)
  /// 生成結果を`RouteSuggestion`に変換します。
  ///
  /// - Parameter generated: Foundation Models が生成したルート提案。
  /// - Returns: アプリで扱える`RouteSuggestion`配列。
  private func mapToRouteSuggestions(from generated: [GeneratedRouteSuggestion]) -> [RouteSuggestion] {
    var normalized = generated.prefix(targetSuggestionCount).map { item -> RouteSuggestion in
      // モデルの出力を UI で扱いやすい値幅に丸める
      let roundedDistance = max((item.estimatedDistance * 10).rounded() / 10, 0.1)
      let duration = max(item.estimatedDuration, 5)

      return RouteSuggestion(
        id: UUID().uuidString,
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
struct RouteSuggestion: Identifiable, Codable {
  /// 一意識別子
  let id: String

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
