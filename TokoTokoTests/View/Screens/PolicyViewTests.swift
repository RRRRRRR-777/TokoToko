import XCTest
import SwiftUI
import ViewInspector
@testable import TokoToko

final class PolicyViewTests: XCTestCase {
    
    func test_PolicyView_初期化() throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        
        // When
        let view = PolicyView(policy: policy, policyType: .privacyPolicy)
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func test_PolicyView_プライバシーポリシー表示() throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        let view = PolicyView(policy: policy, policyType: .privacyPolicy)
        
        // When
        let scrollView = try view.inspect().scrollView()
        let text = try scrollView.vStack().text(0)
        
        // Then
        XCTAssertEqual(try text.string(), "プライバシーポリシー本文")
    }
    
    func test_PolicyView_利用規約表示() throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        let view = PolicyView(policy: policy, policyType: .termsOfService)
        
        // When
        let scrollView = try view.inspect().scrollView()
        let text = try scrollView.vStack().text(0)
        
        // Then
        XCTAssertEqual(try text.string(), "利用規約本文")
    }
    
    func test_PolicyView_PolicyType_Title() {
        // Given/When/Then
        XCTAssertEqual(PolicyType.privacyPolicy.title, "プライバシーポリシー")
        XCTAssertEqual(PolicyType.termsOfService.title, "利用規約")
    }
    
    func test_PolicyView_最終更新日表示() throws {
        // Given
        let updatedAt = Date()
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: updatedAt,
            effectiveDate: Date()
        )
        let view = PolicyView(policy: policy, policyType: .privacyPolicy)
        
        // When
        let scrollView = try view.inspect().scrollView()
        let vStack = try scrollView.vStack()
        let lastUpdatedText = try vStack.text(1)
        
        // Then
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年MM月dd日"
        let expectedDate = formatter.string(from: updatedAt)
        XCTAssertTrue(try lastUpdatedText.string().contains(expectedDate))
    }
}