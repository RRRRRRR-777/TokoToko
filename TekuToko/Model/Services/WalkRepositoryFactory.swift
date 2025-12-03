//
//  WalkRepositoryFactory.swift
//  TekuToko
//
//  Created by Claude Code on 2025/12/02.
//

import Foundation

/// WalkRepositoryの実装タイプ
///
/// バックエンド切り替え機能で使用するリポジトリ実装の種類を定義します。
enum WalkRepositoryType {
  /// Firebase Firestore実装（既存）
  case firestore

  /// Go Backend API実装（将来）
  case goBackend
}

/// WalkRepositoryのファクトリクラス
///
/// 依存性注入（DI）パターンを実現し、環境設定に基づいて
/// 適切なWalkRepository実装を提供します。
///
/// ## 使用例
/// ```swift
/// // 現在のリポジトリを取得
/// let repository = WalkRepositoryFactory.shared.repository
///
/// // リポジトリタイプを切り替え
/// WalkRepositoryFactory.shared.setRepositoryType(.goBackend)
/// ```
///
/// ## Feature Flag連携
/// `EnvironmentConfig.shared.useGoBackend` フラグに基づいて
/// 自動的にリポジトリタイプを決定します。
final class WalkRepositoryFactory {

  // MARK: - Singleton

  /// 共有インスタンス
  static let shared = WalkRepositoryFactory()

  // MARK: - Properties

  /// 現在のリポジトリタイプ
  private(set) var currentType: WalkRepositoryType

  /// Firestoreリポジトリインスタンス（遅延初期化）
  private lazy var firestoreRepository: WalkRepositoryProtocol = WalkRepository.shared

  /// Go Backendリポジトリインスタンス（遅延初期化）
  private lazy var goBackendRepository: WalkRepositoryProtocol = GoBackendWalkRepository()

  // MARK: - Initialization

  private init() {
    // 環境設定に基づいて初期タイプを決定
    if AppConfig.useGoBackend {
      self.currentType = .goBackend
    } else {
      self.currentType = .firestore
    }
  }

  // MARK: - Public Methods

  /// 現在のリポジトリ実装を取得
  ///
  /// 現在のタイプに基づいて適切なリポジトリインスタンスを返します。
  var repository: WalkRepositoryProtocol {
    switch currentType {
    case .firestore:
      return firestoreRepository
    case .goBackend:
      return goBackendRepository
    }
  }

  /// リポジトリタイプを変更
  ///
  /// - Parameter type: 新しいリポジトリタイプ
  func setRepositoryType(_ type: WalkRepositoryType) {
    self.currentType = type
    #if DEBUG
      print("[WalkRepositoryFactory] リポジトリタイプを変更: \(type)")
    #endif
  }

  /// 環境設定に基づいてリポジトリタイプをリセット
  ///
  /// `AppConfig` の設定に基づいて、リポジトリタイプを再設定します。
  func resetToEnvironmentDefault() {
    if AppConfig.useGoBackend {
      setRepositoryType(.goBackend)
    } else {
      setRepositoryType(.firestore)
    }
  }

  // MARK: - Testing Support

  /// テスト用: カスタムリポジトリを注入
  ///
  /// ユニットテストでモックリポジトリを使用するために提供されます。
  ///
  /// - Parameter repository: テスト用のモックリポジトリ
  func injectRepository(_ repository: WalkRepositoryProtocol) {
    self.firestoreRepository = repository
    #if DEBUG
      print("[WalkRepositoryFactory] テスト用リポジトリを注入しました")
    #endif
  }
}

// MARK: - Type Alias for Backward Compatibility

/// FirestoreWalkRepository は WalkRepository のエイリアス
///
/// 将来的なGoBackendWalkRepositoryとの対比のために、
/// 既存のWalkRepositoryを明示的な名前で参照できるようにします。
typealias FirestoreWalkRepository = WalkRepository
