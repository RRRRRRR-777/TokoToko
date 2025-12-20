//
//  OnboardingIntegrationUITests.swift
//  TekuTokoUITests
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
    // TDD Red: 初回起動時のオンボーディングモーダル表示テスト（位置情報許可後に表示）
    // Given: アプリが初回起動状態

    // When: アプリが起動してHomeViewが表示される（位置情報許可は自動的に設定される）
    let homeView = app.otherElements["HomeView"]
    XCTAssertTrue(
      homeView.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "HomeViewが表示されること")

    // Then: 位置情報許可後にオンボーディングモーダルが表示されること
    let onboardingModal = app.otherElements["OnboardingModalView"]
    XCTAssertTrue(
      onboardingModal.waitForExistence(
        timeout: UITestingExtensions.TimeoutSettings.adjustedOnboarding),
      "位置情報許可後にオンボーディングモーダルが表示されること")

    // インジケータの初期値を4ページ仕様で確認
    let pageIndicator = app.pageIndicators["OnboardingPageIndicator"]
    if pageIndicator.exists {
      XCTAssertEqual(pageIndicator.value as? String, "page 1 of 4", "オンボーディングが4ページ構成で初期表示されること")
    }
  }

  func testOnboardingModalNavigation() throws {
    // TDD Red: オンボーディングページナビゲーションテスト（位置情報許可後に表示）
    // Given: HomeViewが表示された後、オンボーディングモーダルが表示されている
    let homeView = app.otherElements["HomeView"]
    XCTAssertTrue(
      homeView.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "HomeViewが表示されること")

    let onboardingModal = app.otherElements["OnboardingModalView"]
    XCTAssertTrue(
      onboardingModal.waitForExistence(
        timeout: UITestingExtensions.TimeoutSettings.adjustedOnboarding),
      "位置情報許可後にオンボーディングモーダルが表示されること")

    // When: 次ページボタンをタップ
    let nextButton = app.buttons["OnboardingNextButton"]
    XCTAssertTrue(
      nextButton.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort),
      "次ページボタンが存在すること")
    nextButton.tap()

    // Then: 2ページ目が表示されること（仕様準拠のタイトル）
    let secondPageTitle = app.staticTexts["散歩を始めましょう"]
    XCTAssertTrue(
      secondPageTitle.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort),
      "2ページ目のタイトルが表示されること")

    // When: 前ページボタンをタップ
    let prevButton = app.buttons["OnboardingPrevButton"]
    XCTAssertTrue(prevButton.exists, "前ページボタンが存在すること")
    prevButton.tap()

    // Then: 1ページ目に戻ること
    let firstPageTitle = app.staticTexts["てくとこへようこそ"]
    XCTAssertTrue(
      firstPageTitle.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort),
      "1ページ目に戻ること")
  }

  func testOnboardingModalDismissal() throws {
    // TDD Red: オンボーディングモーダル閉じるテスト（位置情報許可後に表示）
    // Given: HomeViewが表示された後、オンボーディングモーダルが表示されている
    let homeView = app.otherElements["HomeView"]
    XCTAssertTrue(
      homeView.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "HomeViewが表示されること")

    let onboardingModal = app.otherElements["OnboardingModalView"]
    XCTAssertTrue(
      onboardingModal.waitForExistence(
        timeout: UITestingExtensions.TimeoutSettings.adjustedOnboarding),
      "位置情報許可後にオンボーディングモーダルが表示されること")

    // When: 閉じるボタンをタップ
    let closeButton = app.buttons["OnboardingCloseButton"]
    XCTAssertTrue(closeButton.exists, "閉じるボタンが存在すること")
    closeButton.tap()

    // Then: オンボーディングモーダルが非表示になること
    XCTAssertFalse(
      onboardingModal.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort),
      "閉じるボタンタップ後にモーダルが非表示になること")

    // HomeViewが表示されること
    XCTAssertTrue(
      homeView.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedStandard),
      "モーダル閉じる後にHomeViewが表示されること")
  }

  func testOnboardingNotDisplayedOnSecondLaunch() throws {
    // TDD Red: 2回目起動時にオンボーディングが表示されないテスト（位置情報許可後の動作確認）
    // Given: 1回目の起動でオンボーディングを表示済み
    let homeView = app.otherElements["HomeView"]
    XCTAssertTrue(
      homeView.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "HomeViewが表示されること")

    let onboardingModal = app.otherElements["OnboardingModalView"]
    if onboardingModal.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong) {
      let closeButton = app.buttons["OnboardingCloseButton"]
      closeButton.tap()
    }

    // When: アプリを再起動（2回目起動）
    app.terminate()
    UITestingExtensions.launchAppLoggedIn(app)

    // Then: オンボーディングモーダルが表示されないこと
    XCTAssertFalse(
      onboardingModal.waitForExistence(
        timeout: UITestingExtensions.TimeoutSettings.adjustedStandard), "2回目起動時はオンボーディングが表示されないこと")

    // HomeViewが直接表示されること
    let homeViewAfterRelaunch = app.otherElements["HomeView"]
    XCTAssertTrue(
      homeViewAfterRelaunch.waitForExistence(
        timeout: UITestingExtensions.TimeoutSettings.adjustedStandard), "2回目起動時は直接HomeViewが表示されること")
  }

}
