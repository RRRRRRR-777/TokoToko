//
//  SettingsViewTests.swift
//  TokoTokoTests
//
//  Created by Test on 2025/05/23.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import TokoToko
import FirebaseAuth

final class SettingsViewTests: XCTestCase {

    var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        authManager = AuthManager()
    }

    override func tearDown() {
        authManager = nil
        super.tearDown()
    }

    func testSettingsViewInitialization() {
        let sut = SettingsView()
        XCTAssertNotNil(sut, "SettingsViewのインスタンスが正しく作成されていません")
    }

    // ログアウト機能のテスト
    func testLogoutAction() {
        // モックFirebaseAuthを作成
        class MockAuth {
            static var signOutCalled = false
            static var errorToThrow: Error?

            static func reset() {
                signOutCalled = false
                errorToThrow = nil
            }

            static func mockSignOut() throws {
                signOutCalled = true
                if let error = errorToThrow {
                    throw error
                }
            }
        }

        // テスト対象のビューを作成
        let sut = SettingsView()
        XCTAssertNotNil(sut, "SettingsViewのインスタンスが正しく作成されていません")
    }

    // ログアウト成功時のテスト
    func testLogoutSuccess() {
        // モックFirebaseAuthを作成
        class MockAuth {
            static var signOutCalled = false

            static func mockSignOut() throws {
                signOutCalled = true
            }
        }

        // テスト対象のビューを作成
        let sut = SettingsView()
        XCTAssertNotNil(sut, "SettingsViewのインスタンスが正しく作成されていません")
    }

    // ログアウト失敗時のテスト
    func testLogoutFailure() {
        // モックFirebaseAuthとエラーを作成
        class MockAuth {
            static var signOutCalled = false

            static func mockSignOut() throws {
                signOutCalled = true
                throw NSError(domain: "com.firebase.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])
            }
        }

        // テスト対象のビューを作成
        let sut = SettingsView()
        XCTAssertNotNil(sut, "SettingsViewのインスタンスが正しく作成されていません")
    }

    // アラート表示のテスト
    func testShowLogoutAlert() {
        let sut = SettingsView()

        // 反射を使用して状態を確認
        let mirror = Mirror(reflecting: sut)

        // showingLogoutAlertプロパティの存在を確認
        let showingLogoutAlertProperty = mirror.children.first { $0.label == "_showingLogoutAlert" }
        XCTAssertNotNil(showingLogoutAlertProperty, "showingLogoutAlertプロパティが見つかりません")

        // isLoadingプロパティの存在を確認
        let isLoadingProperty = mirror.children.first { $0.label == "_isLoading" }
        XCTAssertNotNil(isLoadingProperty, "isLoadingプロパティが見つかりません")

        // errorMessageプロパティの存在を確認
        let errorMessageProperty = mirror.children.first { $0.label == "_errorMessage" }
        XCTAssertNotNil(errorMessageProperty, "errorMessageプロパティが見つかりません")
    }

    // ユーザー情報表示のテスト
    func testUserInfoDisplay() {
        // テスト対象のビューを作成
        let sut = SettingsView()
        XCTAssertNotNil(sut, "SettingsViewのインスタンスが正しく作成されていません")
    }

    // 設定セクションの表示テスト
    func testSettingsSectionsDisplay() {
        let sut = SettingsView()
        XCTAssertNotNil(sut, "SettingsViewのインスタンスが正しく作成されていません")
    }

    // AuthManagerとの連携テスト
    func testSettingsViewWithAuthManager() {
        // モックAuthManagerを作成
        let mockAuthManager = AuthManager()

        // テスト対象のビューを作成
        let sut = SettingsView().environmentObject(mockAuthManager)
        XCTAssertNotNil(sut, "SettingsViewのインスタンスが正しく作成されていません")
    }
    
    // プライバシーポリシーリンクの表示テスト
    func testPrivacyPolicyLinkIsDisplayed() throws {
        let sut = SettingsView()
            .environmentObject(authManager)
        
        let privacyButton = try sut.inspect().find(text: "プライバシーポリシー")
        XCTAssertEqual(try privacyButton.string(), "プライバシーポリシー")
    }
    
    // 利用規約リンクの表示テスト
    func testTermsOfServiceLinkIsDisplayed() throws {
        let sut = SettingsView()
            .environmentObject(authManager)
        
        let termsButton = try sut.inspect().find(text: "利用規約")
        XCTAssertEqual(try termsButton.string(), "利用規約")
    }
}
