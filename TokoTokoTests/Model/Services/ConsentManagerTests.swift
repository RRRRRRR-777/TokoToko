//
//  ConsentManagerTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/08/03.
//

import XCTest
@testable import TekuToko

@MainActor
final class ConsentManagerTests: XCTestCase {
    
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
    
    func testInitialConsentManagerState() async throws {
        let consentManager = ConsentManager()
        
        // 初期状態では同意がない
        XCTAssertFalse(consentManager.hasValidConsent)
        XCTAssertNil(consentManager.currentPolicy)
        XCTAssertNil(consentManager.error)
    }
    
    func testNeedsInitialConsent() async throws {
        let consentManager = ConsentManager()
        let needsConsent = await consentManager.needsInitialConsent()
        
        XCTAssertTrue(needsConsent, "初期状態では同意が必要")
    }
    
    func testRecordConsentUpdatesState() async throws {
        let consentManager = ConsentManager()
        
        // テスト用ポリシーを設定
        consentManager.currentPolicy = Policy(
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
        
        // 同意を記録
        try await consentManager.recordConsent(.initial)
        
        // 状態が更新されることを確認
        XCTAssertTrue(consentManager.hasValidConsent)
    }
    
    func testCheckForReConsentWithSameVersion() async throws {
        let consentManager = ConsentManager()
        
        // 初期ポリシーを設定
        let initialPolicy = Policy(
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
        
        consentManager.currentPolicy = initialPolicy
        consentManager.hasValidConsent = true
        
        // 再同意チェック（バージョンが同じ場合）
        await consentManager.checkForReConsentNeeded()
        
        // 同意状態は維持される
        XCTAssertTrue(consentManager.hasValidConsent)
    }
    
    func testRefreshPolicy() async throws {
        let consentManager = ConsentManager()
        
        // ポリシー再読み込み
        await consentManager.refreshPolicy()
        
        // エラーなく完了することを確認
        XCTAssertFalse(consentManager.isLoading)
    }
}
