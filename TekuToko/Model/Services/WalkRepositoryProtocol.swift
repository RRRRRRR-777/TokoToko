//
//  WalkRepositoryProtocol.swift
//  TekuToko
//
//  Created by Claude Code on 2025/12/02.
//

import CoreLocation
import Foundation

/// 散歩データリポジトリのプロトコル定義
///
/// バックエンド実装（Firestore / Go API）を抽象化し、
/// 依存性注入（DI）によるテスタビリティと切り替え可能性を提供します。
///
/// ## 準拠クラス
/// - `FirestoreWalkRepository`: Firebase Firestore実装
/// - `GoBackendWalkRepository`: Go Backend API実装（将来）
/// - `MockWalkRepository`: テスト用モック実装
///
/// ## CRUD操作
/// - Create: `createWalk`, `saveWalk`
/// - Read: `fetchWalks`, `fetchWalk`
/// - Update: `updateWalk`
/// - Delete: `deleteWalk`
protocol WalkRepositoryProtocol {

  // MARK: - Read Operations

  /// 現在の認証済みユーザーの全散歩データを取得
  ///
  /// - Parameter completion: 取得結果のコールバック（Walk配列またはエラー）
  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void)

  /// 指定されたIDの散歩データを取得
  ///
  /// - Parameters:
  ///   - id: 取得したい散歩のUUID
  ///   - completion: 取得結果のコールバック（Walkオブジェクトまたはエラー）
  func fetchWalk(withID id: UUID, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void)

  // MARK: - Create Operations

  /// 新しい散歩を作成して保存
  ///
  /// - Parameters:
  ///   - title: 散歩のタイトル
  ///   - description: 散歩の説明
  ///   - location: 開始位置（オプション）
  ///   - completion: 作成結果のコールバック（作成されたWalkまたはエラー）
  func createWalk(
    title: String,
    description: String,
    location: CLLocationCoordinate2D?,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  )

  /// 完全なWalkオブジェクトを保存
  ///
  /// - Parameters:
  ///   - walk: 保存するWalkオブジェクト
  ///   - completion: 保存結果のコールバック（保存済みWalkまたはエラー）
  func saveWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  )

  // MARK: - Update Operations

  /// 既存の散歩データを更新
  ///
  /// - Parameters:
  ///   - walk: 更新するWalkオブジェクト
  ///   - completion: 更新結果のコールバック（更新済みWalkまたはエラー）
  func updateWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  )

  // MARK: - Delete Operations

  /// 指定されたIDの散歩を削除
  ///
  /// - Parameters:
  ///   - id: 削除する散歩のUUID
  ///   - completion: 削除結果のコールバック（成功フラグまたはエラー）
  func deleteWalk(
    withID id: UUID,
    completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  )
}
