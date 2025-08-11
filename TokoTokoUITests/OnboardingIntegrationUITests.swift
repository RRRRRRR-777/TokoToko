//
//  OnboardingIntegrationUITests.swift
//  TokoTokoUITests
//
//  Created by Claude on 2025-08-06.
//

import XCTest

final class OnboardingIntegrationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // UITestingExtensionsを使用してオンボーディング状態をリセットして起動
        UITestingExtensions.launchAppWithResetOnboarding(app, isLoggedIn: true)
    }

    // MARK: - TDD Red Phase: End-to-Endテスト

    func testOnboardingModalDisplayOnFirstLaunch() throws {
        // TDD Red: 初回起動時のオンボーディングモーダル表示テスト（失敗するはず）
        // Given: アプリが初回起動状態
        
        // When: アプリが起動してMainTabViewが表示される
        
        // Then: オンボーディングモーダルが表示されること
        let onboardingModal = app.otherElements["OnboardingModalView"]
        XCTAssertTrue(onboardingModal.waitForExistence(timeout: 5.0), "初回起動時にオンボーディングモーダルが表示されること")
        
        // オンボーディングのタイトルが表示されること
        let titleText = app.staticTexts["TokoTokoへようこそ"]
        XCTAssertTrue(titleText.exists, "オンボーディングのタイトルが表示されること")
    }
    
    func testOnboardingModalNavigation() throws {
        // TDD Red: オンボーディングページナビゲーションテスト（失敗するはず）
        // Given: オンボーディングモーダルが表示されている
        let onboardingModal = app.otherElements["OnboardingModalView"]
        XCTAssertTrue(onboardingModal.waitForExistence(timeout: 5.0))
        
        // When: 次ページボタンをタップ
        let nextButton = app.buttons["OnboardingNextButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2.0), "次ページボタンが存在すること")
        nextButton.tap()
        
        // Then: 2ページ目が表示されること
        let secondPageTitle = app.staticTexts["簡単操作"]
        XCTAssertTrue(secondPageTitle.waitForExistence(timeout: 2.0), "2ページ目のタイトルが表示されること")
        
        // When: 前ページボタンをタップ
        let prevButton = app.buttons["OnboardingPrevButton"]
        XCTAssertTrue(prevButton.exists, "前ページボタンが存在すること")
        prevButton.tap()
        
        // Then: 1ページ目に戻ること
        let firstPageTitle = app.staticTexts["TokoTokoへようこそ"]
        XCTAssertTrue(firstPageTitle.waitForExistence(timeout: 2.0), "1ページ目に戻ること")
    }
    
    func testOnboardingModalDismissal() throws {
        // TDD Red: オンボーディングモーダル閉じるテスト（失敗するはず）
        // Given: オンボーディングモーダルが表示されている
        let onboardingModal = app.otherElements["OnboardingModalView"]
        XCTAssertTrue(onboardingModal.waitForExistence(timeout: 5.0))
        
        // When: 閉じるボタンをタップ
        let closeButton = app.buttons["OnboardingCloseButton"]
        XCTAssertTrue(closeButton.exists, "閉じるボタンが存在すること")
        closeButton.tap()
        
        // Then: オンボーディングモーダルが非表示になること
        XCTAssertFalse(onboardingModal.waitForExistence(timeout: 2.0), "閉じるボタンタップ後にモーダルが非表示になること")
        
        // HomeViewが表示されること
        let homeView = app.otherElements["HomeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 3.0), "モーダル閉じる後にHomeViewが表示されること")
    }
    
    func testOnboardingNotDisplayedOnSecondLaunch() throws {
        // TDD Red: 2回目起動時にオンボーディングが表示されないテスト（失敗するはず）
        // Given: 1回目の起動でオンボーディングを表示済み
        let onboardingModal = app.otherElements["OnboardingModalView"]
        if onboardingModal.waitForExistence(timeout: 5.0) {
            let closeButton = app.buttons["OnboardingCloseButton"]
            closeButton.tap()
        }
        
        // When: アプリを再起動（2回目起動）
        app.terminate()
        UITestingExtensions.launchAppLoggedIn(app)
        
        // Then: オンボーディングモーダルが表示されないこと
        XCTAssertFalse(onboardingModal.waitForExistence(timeout: 3.0), "2回目起動時はオンボーディングが表示されないこと")
        
        // HomeViewが直接表示されること
        let homeView = app.otherElements["HomeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 5.0), "2回目起動時は直接HomeViewが表示されること")
    }

}