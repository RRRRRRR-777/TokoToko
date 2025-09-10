//
//  TestHelpers.swift
//  TokoTokoTests
//
//  Created by Test on 2025/05/23.
//

import XCTest
import FirebaseAuth
@testable import TekuToko

/// テスト用のヘルパー関数やモックを提供するクラス
class TestHelpers {

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
    static func createMockGoogleAuthService(resultToReturn: GoogleAuthService.AuthResult = .success) -> MockGoogleAuthService {
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
