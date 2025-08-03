import XCTest
import SwiftUI
import ViewInspector
@testable import TokoToko

final class ConsentViewTests: XCTestCase {
    
    func test_ConsentView_初期化() throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        
        // When
        let view = ConsentView(
            policy: policy,
            onAgree: {},
            onDecline: {}
        )
        
        // Then
        XCTAssertNotNil(view)
    }
    
    func test_ConsentView_タイトル表示() throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        let view = ConsentView(
            policy: policy,
            onAgree: {},
            onDecline: {}
        )
        
        // When
        let vStack = try view.inspect().vStack()
        let scrollView = try vStack.scrollView(0)
        let innerVStack = try scrollView.vStack()
        let titleText = try innerVStack.text(0)
        
        // Then
        XCTAssertEqual(try titleText.string(), "アプリのご利用にあたって")
    }
    
    func test_ConsentView_説明文表示() throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        let view = ConsentView(
            policy: policy,
            onAgree: {},
            onDecline: {}
        )
        
        // When
        let vStack = try view.inspect().vStack()
        let scrollView = try vStack.scrollView(0)
        let innerVStack = try scrollView.vStack()
        let descriptionText = try innerVStack.text(1)
        
        // Then
        XCTAssertTrue(try descriptionText.string().contains("同意が必要です"))
    }
    
    func test_ConsentView_同意ボタン無効_初期状態() throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        let view = ConsentView(
            policy: policy,
            onAgree: {},
            onDecline: {}
        )
        
        // When
        let vStack = try view.inspect().vStack()
        let buttonHStack = try vStack.hStack(1)
        let agreeButton = try buttonHStack.button(1)
        
        // Then
        XCTAssertTrue(agreeButton.isDisabled())
    }
    
    func test_ConsentView_同意しないボタン表示() throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy"),
            termsOfService: LocalizedContent(ja: "利用規約本文", en: "Terms of Service"),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        let view = ConsentView(
            policy: policy,
            onAgree: {},
            onDecline: {}
        )
        
        // When
        let vStack = try view.inspect().vStack()
        let buttonHStack = try vStack.hStack(1)
        let declineButton = try buttonHStack.button(0)
        let declineText = try declineButton.labelView().text()
        
        // Then
        XCTAssertEqual(try declineText.string(), "同意しない")
    }
}