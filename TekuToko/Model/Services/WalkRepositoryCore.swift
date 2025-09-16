//
//  WalkRepositoryCore.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/08/30.
//

import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit

/// WalkRepository操作で発生するエラータイプ
///
/// Firestoreとのデータ同期、認証、ネットワーク通信で発生する
/// 各種エラー状況を表現します。適切なエラーハンドリングとユーザー通知を可能にします。
///
/// ## Topics
///
/// ### Error Cases
/// - ``notFound``
/// - ``firestoreError(_:)``
/// - ``networkError``
/// - ``authenticationRequired``
/// - ``invalidData``
enum WalkRepositoryError: Error, Equatable {
  /// 指定されたWalkが見つからない
  ///
  /// リクエストされたWalkIDが存在しない、または現在のユーザーがアクセス権限を持たない場合に発生します。
  case notFound

  /// Firestoreでの操作エラー
  ///
  /// Firebase Firestoreとの通信やデータ操作で発生したエラーです。
  /// - Parameter Error: 発生した具体的なFirestoreエラー
  case firestoreError(Error)

  /// ネットワーク接続エラー
  ///
  /// インターネット接続の問題やタイムアウトで発生するエラーです。
  case networkError

  /// 認証が必要
  ///
  /// Firebase Authenticationでの認証が必要な操作でユーザーが未認証の場合に発生します。
  case authenticationRequired

  /// 無効なデータ
  ///
  /// データの変換やバリデーションに失敗した場合に発生するエラーです。
  case invalidData

  /// ストレージエラー
  ///
  /// Firebase Storageでの画像アップロードやダウンロードで発生するエラーです。
  case storageError(Error)

  /// Equatableプロトコルの実装
  ///
  /// エラータイプ同士の等価比較を行います。Errorプロトコルの制約により、
  /// firestoreErrorの場合はエラー内容ではなくタイプのみを比較します。
  static func == (lhs: WalkRepositoryError, rhs: WalkRepositoryError) -> Bool {
    switch (lhs, rhs) {
    case (.notFound, .notFound),
      (.networkError, .networkError),
      (.authenticationRequired, .authenticationRequired),
      (.invalidData, .invalidData):
      return true
    case (.firestoreError, .firestoreError),
      (.storageError, .storageError):
      // Errorは等価比較が困難なため、同じタイプであることのみチェック
      return true
    default:
      return false
    }
  }
}

/// 散歩データの永続化とFirestore連携を管理するリポジトリクラス
///
/// `WalkRepository`はWalkデータのCRUD操作、Firestoreとの同期、
/// オフライン対応、認証管理を統合的に提供するデータ層のコアクラスです。
///
/// ## Overview
///
/// 主要な責務：
/// - **データ永続化**: Firebase Firestoreへの散歩データ保存
/// - **オフライン対応**: ローカルキャッシュとオフライン永続化
/// - **認証連携**: Firebase Authenticationとの統合
/// - **エラーハンドリング**: 包括的なエラー管理と分類
/// - **パフォーマンス**: バッチ処理とタイムアウト制御
///
/// ## Architecture
///
/// WalkRepositoryは以下の専門的なモジュールに分割されています：
/// - ``WalkRepositoryCore``: 基本定義とコア機能
/// - ``WalkRepositoryFirestore``: Firestore統合機能
/// - ``WalkRepositoryStorage``: 画像ストレージ機能
/// - ``WalkRepositoryHelpers``: プライベートヘルパー機能
///
/// ## Topics
///
/// ### Singleton Instance
/// - ``shared``
///
/// ### Data Operations
/// - ``saveWalk(_:)``
/// - ``getWalks(limit:)``
/// - ``getWalk(id:)``
/// - ``deleteWalk(id:)``
///
/// ### Image Operations
/// - ``saveSharedImage(_:for:completion:)``
class WalkRepository {
  /// WalkRepositoryのシングルトンインスタンス
  ///
  /// アプリ全体で単一のリポジトリインスタンスを使用し、
  /// キャッシュとFirestore接続状態の一貫性を保証します。
  static let shared = WalkRepository()

  /// Firebase Firestoreのデータベース参照
  ///
  /// 散歩データの保存と取得に使用するFirestoreインスタンスです。
  internal var db: Firestore!

  /// 設定済みFirestoreインスタンスを他のサービスで共有するためのアクセサ
  ///
  /// アプリ全体で同一の設定を持つFirestoreインスタンスを使用するために提供されます。
  var sharedFirestore: Firestore { db }

  /// Firebase Storageの参照
  ///
  /// 共有画像の保存に使用するFirebase Storageインスタンスです。
  internal var storage: Storage!

  /// Firestoreコレクション名
  ///
  /// 散歩データを保存するFirestoreコレクションの名前です。
  internal let collectionName = "walks"

  /// 高度なログ機能を提供するロガーインスタンス
  ///
  /// WalkRepository内のすべての操作、エラー、デバッグ情報を記録します。
  internal let logger = EnhancedVibeLogger.shared

  /// メモリキャッシュされた散歩データ
  ///
  /// パフォーマンス向上のため、最近アクセスされた散歩データをメモリに保持します。
  /// アプリの再起動やメモリ不足時にクリアされます。
  internal var cachedWalks: [Walk] = []

  /// WalkRepositoryのプライベート初期化メソッド
  ///
  /// シングルトンパターンによりプライベート初期化子を定義します。
  /// 初期化時にFirestoreの設定とオフライン永続化の設定を行います。
  private init() {
    // UIテスト時はFirebaseに触れない
    if UITestingHelper.shared.isUITesting {
      self.db = nil
      self.storage = nil
      return
    }
    // Firestoreの設定
    self.db = Self.configureFirestore()
    // Storageの設定
    self.storage = Storage.storage()
    // 初期化完了後にネットワーク設定
    setupNetworkConfiguration()
  }

  /// 設定済みFirestoreインスタンスを取得（スタティックメソッド）
  ///
  /// AppDelegateで既に設定済みのFirestoreインスタンスを返します。
  /// 重複設定によるクラッシュを防ぐため、設定は行わずインスタンスの取得のみ行います。
  private static func configureFirestore() -> Firestore {
    // AppDelegateで既に設定済みのFirestoreインスタンスを取得
    let firestore = Firestore.firestore()
    return firestore
  }

  /// ネットワーク設定のセットアップ
  ///
  /// Firestoreのネットワーク接続設定とログ記録を行います。
  private func setupNetworkConfiguration() {
    logger.logMethodStart()
    guard let db else { return }
    // オフライン時の自動再試行設定
    db.enableNetwork { [weak self] error in
      if let error = error {
        self?.logger.warning(
          operation: "setupNetworkConfiguration",
          message: "ネットワーク有効化でエラー: \(error.localizedDescription)",
          humanNote: "Firestoreネットワーク接続に問題があります",
          aiTodo: "ネットワーク設定を確認してください"
        )
      } else {
        self?.logger.info(
          operation: "setupNetworkConfiguration",
          message: "Firestoreネットワーク設定完了"
        )
      }
    }

    logger.info(
      operation: "setupNetworkConfiguration",
      message: "WalkRepository初期化完了",
      context: [
        "offline_persistence": "enabled",
        "collection_name": collectionName,
      ]
    )
  }
}
