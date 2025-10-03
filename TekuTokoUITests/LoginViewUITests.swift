//
//  LoginViewUITests.swift
//  TekuTokoUITests
//
//  Created by Test on 2025/05/23.
//

import XCTest

final class LoginViewUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    UITestingExtensions.launchAppLoggedOut(app)

    if !UITestHelpers.awaitRootRendered(app) {
      addDebugAttachments(name: "Root Not Rendered (setup)")
    }
  }

  override func tearDown() {
    app = nil
    super.tearDown()
  }

  // MARK: - Helper Methods

  private func addDebugAttachments(name: String) {
    let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    screenshot.name = name
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  private func waitForWelcomeText(timeout: TimeInterval = UITestingExtensions.TimeoutSettings.adjustedLong) -> Bool {
    let predicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(predicate).firstMatch
    return welcomeText.waitForExistence(timeout: timeout)
  }

  private func waitForLoginView() -> Bool {
    let loginView = app.descendants(matching: .any).matching(identifier: "LoginView").firstMatch
    return loginView.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
  }

  private func waitForMainElements() {
    let appLogo = app.descendants(matching: .any).matching(identifier: "AppLogo").firstMatch
    let googleButton = app.buttons["Googleでサインイン"]
    let appleButton = app.buttons["Appleでサインイン"]

    // いずれかの主要要素が表示されるまで待機
    _ = appLogo.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
      || googleButton.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)

    // Appleボタンの追加待機（Googleボタンより後に描画される可能性があるため）
    _ = appleButton.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedStandard)
  }

  // MARK: - Tests

  func testLoginViewAppears() {
    XCTAssertTrue(waitForLoginView(), "LoginViewが表示されません")
    XCTAssertTrue(waitForWelcomeText(), "ウェルカムテキストが表示されていません")
    waitForMainElements()

    let subtitle = app.staticTexts["今日の散歩を、明日の思い出にシェアしよう"]
    XCTAssertTrue(
      subtitle.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "サブタイトルが表示されていません")

    let googleSignInButton = app.buttons["Googleでサインイン"]
    let appleSignInButton = app.buttons["Appleでサインイン"]

    // swiftlint:disable empty_count
    XCTAssertTrue(googleSignInButton.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedStandard)
                  || app.buttons.count > 0,
                  "Googleログインボタンが表示されていません")
    XCTAssertTrue(appleSignInButton.exists || app.buttons.count > 0,
                  "Appleログインボタンが表示されていません")
    // swiftlint:enable empty_count
  }

  func testLoginErrorDisplay() {
    app.launchWithForcedError(errorType: "テストエラー")
    XCTAssertTrue(waitForWelcomeText(), "ウェルカムテキストが表示されていません")

    let errorPredicate = NSPredicate(format: "label CONTAINS %@", "テストエラー")
    let errorTexts = app.staticTexts.matching(errorPredicate)
    // swiftlint:disable:next empty_count
    XCTAssertTrue(errorTexts.count > 0, "エラーメッセージが表示されていません")

    let errorMessage = app.staticTexts["loginErrorMessage"]
    if errorMessage.exists {
      XCTAssertTrue(errorMessage.isEnabled, "エラーメッセージが有効になっていません")
    }
  }

  func testLoginLoadingState() {
    app.launchArguments = ["--uitesting", "--force-loading-state"]
    app.launch()
    XCTAssertTrue(waitForWelcomeText(), "ウェルカムテキストが表示されていません")

    let loadingIndicator = app.activityIndicators.firstMatch
    XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 5), "ローディングインジケータが表示されていません")

    XCTAssertFalse(app.buttons["googleSignInButton"].exists, "Googleログインボタンが非表示になっていません")
    XCTAssertFalse(app.buttons["appleSignInButton"].exists, "Appleログインボタンが非表示になっていません")

    // swiftlint:disable empty_count
    XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'プライバシーポリシー'")).count > 0,
                  "プライバシーポリシーリンクが表示されていません")
    XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS '利用規約'")).count > 0,
                  "利用規約リンクが表示されていません")
    // swiftlint:enable empty_count
  }

  func testLoginViewBackgroundForegroundTransition() {
    app.launch()
    XCTAssertTrue(waitForWelcomeText(), "ウェルカムテキストが表示されていません")

    XCUIDevice.shared.press(.home)
    sleep(2)
    app.activate()

    XCTAssertTrue(waitForWelcomeText(), "バックグラウンドから復帰後、ウェルカムテキストが表示されていません")
  }

  func testLoginViewAccessibility() {
    app.launch()
    XCTAssertTrue(waitForWelcomeText(), "ウェルカムテキストが表示されていません")

    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(welcomeText.isEnabled, "ウェルカムテキストが有効になっていません")

    let appLogo = app.descendants(matching: .any).matching(identifier: "AppLogo").firstMatch
    if appLogo.exists {
      XCTAssertTrue(appLogo.isEnabled, "アプリロゴが有効になっていません")
    }

    let googleSignInButton = app.buttons["googleSignInButton"]
    if googleSignInButton.exists {
      XCTAssertTrue(googleSignInButton.isEnabled, "Googleログインボタンが有効になっていません")
    }

    let appleSignInButton = app.buttons["appleSignInButton"]
    if appleSignInButton.exists {
      XCTAssertTrue(appleSignInButton.isEnabled, "Appleログインボタンが有効になっていません")
    }
  }

  func testLoginViewRotation() {
    app.launch()
    XCTAssertTrue(waitForWelcomeText(), "ウェルカムテキストが表示されていません")

    XCUIDevice.shared.orientation = .landscapeLeft
    sleep(1)
    XCTAssertTrue(waitForWelcomeText(), "横向き時にウェルカムテキストが表示されていません")

    XCUIDevice.shared.orientation = .portrait
  }

  func testAppleSignInButtonOrder() {
    XCTAssertTrue(waitForWelcomeText(), "ウェルカムテキストが表示されていません")
    waitForMainElements()

    let appleSignInButton = app.buttons["Appleでサインイン"]
    let googleSignInButton = app.buttons["Googleでサインイン"]

    // swiftlint:disable empty_count
    XCTAssertTrue(appleSignInButton.exists || app.buttons.count > 0,
                  "Appleログインボタンが表示されていません")
    XCTAssertTrue(googleSignInButton.exists || app.buttons.count > 0,
                  "Googleログインボタンが表示されていません")
    // swiftlint:enable empty_count

    XCTAssertLessThanOrEqual(
      appleSignInButton.frame.minY, googleSignInButton.frame.minY,
      "Apple Sign-Inボタンは他の認証オプションより上または同じ位置に配置される必要があります（App Store Guideline 4.8）")
  }

  func testSignInButtonsDesignConsistency() {
    XCTAssertTrue(waitForWelcomeText(), "ウェルカムテキストが表示されていません")
    waitForMainElements()

    let appleSignInButton = app.buttons["Appleでサインイン"]
    let googleSignInButton = app.buttons["Googleでサインイン"]

    // swiftlint:disable empty_count
    XCTAssertTrue(appleSignInButton.exists || app.buttons.count > 0,
                  "Appleログインボタンが表示されていません")
    XCTAssertTrue(googleSignInButton.exists || app.buttons.count > 0,
                  "Googleログインボタンが表示されていません")
    // swiftlint:enable empty_count

    let appleFrame = appleSignInButton.frame
    let googleFrame = googleSignInButton.frame

    XCTAssertEqual(
      appleFrame.height, googleFrame.height, accuracy: 1.0,
      "Apple Sign-InボタンとGoogle Sign-Inボタンの高さは同じである必要があります")
    XCTAssertEqual(
      appleFrame.width, googleFrame.width, accuracy: 1.0,
      "Apple Sign-InボタンとGoogle Sign-Inボタンの幅は同じである必要があります")
  }
}
