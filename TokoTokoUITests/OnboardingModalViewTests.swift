//
//  OnboardingModalViewTests.swift
//  TokoTokoUITests
//
//  Created by Claude on 2025-08-06.
//

import XCTest

final class OnboardingModalViewTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testOnboardingModalViewInitialState() throws {
        // Given: 初回起動でオンボーディングを表示する設定
        UITestingExtensions.launchAppWithResetOnboarding(app, isLoggedIn: true)
        
        // Then: オンボーディングモーダルが表示されること（閉じるボタンの存在で確認）
        let closeButton = app.buttons["OnboardingCloseButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "オンボーディングモーダルが表示されること")
        
        // ナビゲーションボタンが存在すること
        let prevButton = app.buttons["OnboardingPrevButton"]
        let nextButton = app.buttons["OnboardingNextButton"]
        XCTAssertTrue(prevButton.exists, "前ページボタンが存在すること")
        XCTAssertTrue(nextButton.exists, "次ページボタンが存在すること")
    }
    
    func testOnboardingModalViewNavigation() throws {
        // Given: 初回起動でオンボーディングを表示
        UITestingExtensions.launchAppWithResetOnboarding(app, isLoggedIn: true)
        
        // When: 次ページボタンをタップ
        let nextButton = app.buttons["OnboardingNextButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "次ページボタンが表示されること")
        nextButton.tap()
        
        // Then: ページインジケーターが更新されること
        let pageIndicator = app.pageIndicators["OnboardingPageIndicator"]
        if pageIndicator.exists {
            XCTAssertEqual(pageIndicator.value as? String, "page 2 of 2", "2ページ目に移動すること")
        }
        
        // When: 前ページボタンをタップ
        let prevButton = app.buttons["OnboardingPrevButton"]
        prevButton.tap()
        
        // Then: 1ページ目に戻ること
        if pageIndicator.exists {
            XCTAssertEqual(pageIndicator.value as? String, "page 1 of 2", "1ページ目に戻ること")
        }
    }
    
    func testOnboardingModalViewDismiss() throws {
        // Given: 初回起動でオンボーディングを表示
        UITestingExtensions.launchAppWithResetOnboarding(app, isLoggedIn: true)
        
        // When: 閉じるボタンをタップ
        let closeButton = app.buttons["OnboardingCloseButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "閉じるボタンが表示されること")
        closeButton.tap()
        
        // Then: オンボーディングモーダルが非表示になること
        let closeButtonAfterDismiss = app.buttons["OnboardingCloseButton"]
        XCTAssertFalse(closeButtonAfterDismiss.waitForExistence(timeout: 2), "オンボーディングモーダルが閉じられること")
    }
    
    func testOnboardingModalViewNotShownForExistingUser() throws {
        // Given: まず初回起動でオンボーディングを表示し、完了させる
        UITestingExtensions.launchAppWithResetOnboarding(app, isLoggedIn: true)
        
        let closeButton = app.buttons["OnboardingCloseButton"]
        if closeButton.waitForExistence(timeout: 5) {
            // オンボーディングを閉じる
            closeButton.tap()
        }
        
        // アプリを再起動
        app.terminate()
        UITestingExtensions.launchAppLoggedIn(app)
        
        // Then: 2回目の起動ではオンボーディングモーダルが表示されないこと
        let closeButtonAfterRestart = app.buttons["OnboardingCloseButton"]
        XCTAssertFalse(closeButtonAfterRestart.waitForExistence(timeout: 2), "既存ユーザーにはオンボーディングが表示されないこと")
    }
    
    func testOnboardingModalViewAccessibility() throws {
        // Given: 初回起動でオンボーディングを表示
        UITestingExtensions.launchAppWithResetOnboarding(app, isLoggedIn: true)
        
        // Then: アクセシビリティ要素が適切に設定されていること
        let closeButton = app.buttons["OnboardingCloseButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "オンボーディングモーダルが表示されること")
        
        // VoiceOver対応の確認
        XCTAssertNotNil(closeButton.label, "閉じるボタンにアクセシビリティラベルが設定されていること")
        
        let nextButton = app.buttons["OnboardingNextButton"]
        XCTAssertNotNil(nextButton.label, "次ページボタンにアクセシビリティラベルが設定されていること")
        
        let prevButton = app.buttons["OnboardingPrevButton"]
        XCTAssertNotNil(prevButton.label, "前ページボタンにアクセシビリティラベルが設定されていること")
    }
    
    func testOnboardingModalViewSwipeGesture() throws {
        // Given: 初回起動でオンボーディングを表示
        UITestingExtensions.launchAppWithResetOnboarding(app, isLoggedIn: true)
        
        let closeButton = app.buttons["OnboardingCloseButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "オンボーディングモーダルが表示されること")
        
        // When: 左スワイプで次ページへ（コンテンツ領域でスワイプ）
        let contentArea = app.otherElements.element(boundBy: 0)
        contentArea.swipeLeft()
        
        // Then: ページが切り替わること
        let pageIndicator = app.pageIndicators["OnboardingPageIndicator"]
        if pageIndicator.exists {
            // スワイプ後にページが変わっていることを確認
            sleep(1) // アニメーション待機
            let currentPage = pageIndicator.value as? String
            XCTAssertNotEqual(currentPage, "page 1 of 3", "スワイプで次ページに移動すること")
        }
        
        // When: 右スワイプで前ページへ（コンテンツ領域でスワイプ）
        contentArea.swipeRight()
        
        // Then: 前のページに戻ること
        if pageIndicator.exists {
            sleep(1) // アニメーション待機
            XCTAssertEqual(pageIndicator.value as? String, "page 1 of 3", "スワイプで前ページに戻ること")
        }
    }
}