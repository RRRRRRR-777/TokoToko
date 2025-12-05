//
//  WalkRepositoryErrorMessages.swift
//  TekuToko
//
//  Created by Claude Code on 2025/12/05.
//

import Foundation

/// WalkRepositoryErrorのローカライズされたエラーメッセージを提供
///
/// アプリ全体で統一されたエラーメッセージを表示するためのヘルパーです。
/// 各ViewやViewModelからこの拡張を使用することで、一貫したユーザー体験を提供します。
extension WalkRepositoryError {

  /// 操作コンテキスト付きのエラーメッセージ
  ///
  /// - Parameter context: 操作の種類（例: "取得", "保存", "削除"）
  /// - Returns: コンテキストを含むエラーメッセージ
  func localizedMessage(for context: OperationContext) -> String {
    switch self { 
    case .authenticationRequired:
      return "ログインが必要です。\n再度ログインしてください。"
    case .notFound:
      return "散歩記録が見つかりません。"
    case .networkError:
      return "\(context.displayName)に失敗しました。\nネットワーク接続をご確認ください。"
    case .invalidData:
      return "データが破損しています。"
    case .firestoreError:
      return "\(context.displayName)に失敗しました。\nしばらくしてから再度お試しください。"
    case .storageError:
      return "画像の\(context.displayName)に失敗しました。\nしばらくしてから再度お試しください。"
    }
  }

  /// 操作コンテキストの種類
  enum OperationContext {
    case fetch       // 取得
    case save        // 保存
    case delete      // 削除
    case update      // 更新

    var displayName: String {
      switch self {
      case .fetch:
        return "取得"
      case .save:
        return "保存"
      case .delete:
        return "削除"
      case .update:
        return "更新"
      }
    }
  }
}
