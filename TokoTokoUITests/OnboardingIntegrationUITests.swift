//
//  OnboardingIntegrationUITests.swift
//  TokoTokoUITests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
@testable import TokoToko

final class OnboardingIntegrationUITests: XCTestCase {

    func testOnboardingManagerIntegrationWithApp() throws {
        // Given: 初回起動状態
        let onboardingManager = OnboardingManager()
        
        // When: 初回起動のオンボーディング表示判定を行う
        let shouldShow = onboardingManager.shouldShowOnboarding(for: .firstLaunch)
        
        // Then: 初回起動時はtrueを返すこと
        XCTAssertTrue(shouldShow, "初回起動時はオンボーディングを表示すること")
        
        // When: オンボーディングを表示済みにマーク
        onboardingManager.markOnboardingAsShown(for: .firstLaunch)
        
        // Then: 2回目の判定ではfalseを返すこと
        let shouldShowAgain = onboardingManager.shouldShowOnboarding(for: .firstLaunch)
        XCTAssertFalse(shouldShowAgain, "2回目以降はオンボーディングを表示しないこと")
    }
    
    func testOnboardingManagerObservableObjectConformance() {
        // Given/When: OnboardingManagerを作成
        let onboardingManager = OnboardingManager()
        
        // Then: ObservableObjectに準拠していることを確認
        XCTAssertTrue(onboardingManager is ObservableObject, "OnboardingManagerがObservableObjectに準拠していること")
    }
}