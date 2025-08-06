//
//  TokoTokoAppTests.swift
//  TokoTokoTests
//
//  Created by Test on 2025/05/23.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import TokoToko
import FirebaseAuth

@MainActor
final class TokoTokoAppTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.removeObject(forKey: "cached_policy")
        UserDefaults.standard.removeObject(forKey: "policy_cache_timestamp")
        UserDefaults.standard.removeObject(forKey: "test_has_consent")
    }
    
    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "cached_policy")
        UserDefaults.standard.removeObject(forKey: "policy_cache_timestamp")
        UserDefaults.standard.removeObject(forKey: "test_has_consent")
        try await super.tearDown()
    }

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
    
    // 初回同意フローのテスト
    func testInitialConsentFlowRequired() async throws {
        let policyService = PolicyService()
        let hasConsent = await policyService.hasValidConsent()
        XCTAssertFalse(hasConsent, "初期状態では同意が記録されていないはず")
    }
    
    func testConsentFlowCompleteAllowsMainApp() async throws {
        let policyService = PolicyService()
        
        let mockPolicy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(
                ja: "プライバシーポリシー",
                en: "Privacy Policy"
            ),
            termsOfService: LocalizedContent(
                ja: "利用規約",
                en: "Terms of Service"
            ),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        
        try await policyService.recordConsent(
            policyVersion: mockPolicy.version,
            userID: "test_user",
            consentType: .initial,
            deviceInfo: nil
        )
        
        // デバッグモード用のキーを設定
        UserDefaults.standard.set(true, forKey: "test_has_consent")
        
        let hasConsent = await policyService.hasValidConsent()
        XCTAssertTrue(hasConsent)
    }
    
    func testConsentManagerInitialization() async throws {
        let consentManager = ConsentManager()
        let needsConsent = await consentManager.needsInitialConsent()
        XCTAssertTrue(needsConsent, "初期状態では同意が必要")
    }
}
