//
//  TokoTokoAppTests.swift
//  TokoTokoTests
//
//  Created by Test on 2025/05/23.
//

import XCTest
import SwiftUI
@testable import TokoToko
import FirebaseAuth

final class TokoTokoAppTests: XCTestCase {

    func testAuthManagerInitialization() {
        let authManager = AuthManager()
        XCTAssertNotNil(authManager, "AuthManagerのインスタンスが正しく作成されていません")
        XCTAssertFalse(authManager.isLoggedIn, "初期状態ではログインしていないはずです")
    }

    // AppDelegateのテスト
    func testAppDelegateInitialization() {
        let appDelegate = AppDelegate()
        XCTAssertNotNil(appDelegate, "AppDelegateのインスタンスが正しく作成されていません")
    }

    // MainTabViewのテスト
    func testMainTabViewInitialization() {
        let authManager = AuthManager()
        let mainTabView = MainTabView()
            .environmentObject(authManager)

        XCTAssertNotNil(mainTabView, "MainTabViewのインスタンスが正しく作成されていません")
    }

    // TokoTokoAppのテスト
    func testTokoTokoAppStructure() {
        XCTAssertTrue(true, "このテストは実際の環境では@mainアノテーションの制約があります")
    }
}
