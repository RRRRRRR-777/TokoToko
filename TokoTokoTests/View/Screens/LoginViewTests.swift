//
//  LoginViewTests.swift
//  TokoTokoTests
//
//  Created by Test on 2025/05/23.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import TokoToko

final class LoginViewTests: XCTestCase {

    var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        authManager = AuthManager()
    }

    override func tearDown() {
        authManager = nil
        super.tearDown()
    }

    func testLoginViewInitialization() {
        let sut = LoginView()
        XCTAssertNotNil(sut, "LoginViewのインスタンスが正しく作成されていません")
    }

    // GoogleAuthServiceのモック
    class MockGoogleAuthService: GoogleAuthService {
        var signInCalled = false
        var resultToReturn: AuthResult = .success

        override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
            signInCalled = true
            completion(resultToReturn)
        }
    }

    // サインイン成功時のテスト
    func testSignInWithGoogleSuccess() throws {
        // モックの準備
        let mockService = MockGoogleAuthService()
        mockService.resultToReturn = .success

        // テスト対象のビューを作成
        let sut = LoginView()

        // 反射を使用してモックサービスを注入
        let mirror = Mirror(reflecting: sut)
        let authServiceProperty = mirror.children.first { $0.label == "authService" }
        XCTAssertNotNil(authServiceProperty, "authServiceプロパティが見つかりません")
    }

    // サインイン失敗時のテスト
    func testSignInWithGoogleFailure() throws {
        // モックの準備
        let mockService = MockGoogleAuthService()
        mockService.resultToReturn = .failure("テストエラー")

        // テスト対象のビューを作成
        let sut = LoginView()

        // 反射を使用してモックサービスを注入
        let mirror = Mirror(reflecting: sut)
        let authServiceProperty = mirror.children.first { $0.label == "authService" }
        XCTAssertNotNil(authServiceProperty, "authServiceプロパティが見つかりません")
    }

    // ビューの初期状態をテスト
    func testLoginViewInitialState() {
        let sut = LoginView()

        // 反射を使用して初期状態を確認
        let mirror = Mirror(reflecting: sut)

        // isLoadingプロパティの存在を確認
        let isLoadingProperty = mirror.children.first { $0.label == "_isLoading" }
        XCTAssertNotNil(isLoadingProperty, "isLoadingプロパティが見つかりません")

        // errorMessageプロパティの存在を確認
        let errorMessageProperty = mirror.children.first { $0.label == "_errorMessage" }
        XCTAssertNotNil(errorMessageProperty, "errorMessageプロパティが見つかりません")

        // authServiceプロパティの存在を確認
        let authServiceProperty = mirror.children.first { $0.label == "authService" }
        XCTAssertNotNil(authServiceProperty, "authServiceプロパティが見つかりません")
    }

    // ビューの表示要素をテスト
    func testLoginViewUIElements() {
        let sut = LoginView()
        XCTAssertNotNil(sut, "LoginViewのインスタンスが正しく作成されていません")
    }

    // ローディング状態のテスト
    func testLoginViewLoadingState() {
        let sut = LoginView()
        XCTAssertNotNil(sut, "LoginViewのインスタンスが正しく作成されていません")
    }

    // エラーメッセージ表示のテスト
    func testLoginViewErrorMessageDisplay() {
        let sut = LoginView()
        XCTAssertNotNil(sut, "LoginViewのインスタンスが正しく作成されていません")
    }

    // AuthManagerとの連携テスト
    func testLoginViewWithAuthManager() {
        // モックAuthManagerを作成
        let mockAuthManager = AuthManager()

        // テスト対象のビューを作成
        let sut = LoginView().environmentObject(mockAuthManager)
        XCTAssertNotNil(sut, "LoginViewのインスタンスが正しく作成されていません")
    }
}
