//
//  ConsentFlowViewTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/08/03.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import TokoToko

@MainActor
final class ConsentFlowViewTests: XCTestCase {
    
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
    
    func testConsentFlowViewDisplaysWelcomeMessage() throws {
        let consentManager = ConsentManager()
        let view = ConsentFlowView()
            .environmentObject(consentManager)
        
        let welcomeText = try view.inspect().find(text: "TokoTokoへようこそ")
        XCTAssertEqual(try welcomeText.string(), "TokoTokoへようこそ")
    }
    
    func testConsentFlowViewDisplaysDescriptionText() throws {
        let consentManager = ConsentManager()
        let view = ConsentFlowView()
            .environmentObject(consentManager)
        
        let descriptionText = try view.inspect().find(text: "サービスをご利用いただく前に、プライバシーポリシーと利用規約をご確認ください。")
        XCTAssertEqual(try descriptionText.string(), "サービスをご利用いただく前に、プライバシーポリシーと利用規約をご確認ください。")
    }
    
    func testConsentFlowViewDisplaysLoadingWhenPolicyIsNil() throws {
        let consentManager = ConsentManager()
        let view = ConsentFlowView()
            .environmentObject(consentManager)
        
        let loadingText = try view.inspect().find(text: "ポリシー情報を読み込み中...")
        XCTAssertEqual(try loadingText.string(), "ポリシー情報を読み込み中...")
    }
    
    func testConsentFlowViewDisplaysPolicyButtonsWhenPolicyExists() async throws {
        let consentManager = ConsentManager()
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
        consentManager.isLoading = false
        
        let view = ConsentFlowView()
            .environmentObject(consentManager)
        
        let privacyButton = try view.inspect().find(text: "プライバシーポリシー")
        let termsButton = try view.inspect().find(text: "利用規約")
        
        XCTAssertEqual(try privacyButton.string(), "プライバシーポリシー")
        XCTAssertEqual(try termsButton.string(), "利用規約")
    }
    
    func testConsentFlowViewDisplaysConsentButtonWhenPolicyExists() async throws {
        let consentManager = ConsentManager()
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
        consentManager.isLoading = false
        
        let view = ConsentFlowView()
            .environmentObject(consentManager)
        
        let consentButton = try view.inspect().find(text: "同意してサービスを開始")
        XCTAssertEqual(try consentButton.string(), "同意してサービスを開始")
    }
}