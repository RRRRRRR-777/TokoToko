//
//  TestHelpers.swift
//  TekuTokoTests
//
//  Created by Test on 2025/05/23.
//

import FirebaseAuth
import XCTest

@testable import TekuToko

/// テスト用のヘルパー関数やモックを提供するクラス
///
/// XcodeCloud環境でのFirebase設定エラーを回避し、
/// テスト実行時にはモック機能を提供します。
class TestHelpers {

  /// XcodeCloud対応: Firebase初期化なしでテストを実行
  ///
  /// Firebase設定ファイル（GoogleService-Info.plist）が
  /// XcodeCloud環境で見つからない問題を回避します。
  static func configureFirebaseForTesting() {
    // XcodeCloudでは実際のFirebase設定を行わず、
    // モック化されたサービスのみを使用
    print("テスト環境ではFirebase設定をスキップします")
  }

  /// Firebase接続が不要なテスト環境かどうかを判定
  static var isTestEnvironmentWithoutFirebase: Bool {
    // XcodeCloudやCI環境でのテスト実行を検出
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
           ProcessInfo.processInfo.environment["CI"] == "true"
  }

  /// FirebaseAuthのモックを作成するヘルパーメソッド
  static func createMockAuth() -> Auth {
    // 実際の環境では、FirebaseAuthのモックを作成するコードが必要です
    // このサンプルでは基本的な構造のみを示しています
    return Auth.auth()
  }

  /// テスト用のAuthManagerを作成
  static func createTestAuthManager(isLoggedIn: Bool = false) -> AuthManager {
    let authManager = AuthManager()
    // 実際の環境では、isLoggedInプロパティを設定するコードが必要です
    return authManager
  }

  /// テスト用のGoogleAuthServiceを作成
  static func createMockGoogleAuthService(resultToReturn: GoogleAuthService.AuthResult = .success)
    -> MockGoogleAuthService
  {
    let service = MockGoogleAuthService()
    service.resultToReturn = resultToReturn
    return service
  }
}

/// GoogleAuthServiceのモッククラス
class MockGoogleAuthService: GoogleAuthService {
  var signInCalled = false
  var resultToReturn: AuthResult = .success

  override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
    signInCalled = true
    completion(resultToReturn)
  }
}
