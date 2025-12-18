//
//  UITestHelpers.swift
//  TekuTokoUITests
//
//  Created by Test on 2025/05/23.
//

import XCTest

/// UIテスト用のヘルパー関数を提供するクラス
class UITestHelpers {

  /// アプリをログイン状態で起動するヘルパーメソッド
  static func launchAppAsLoggedIn(_ app: XCUIApplication) {
    // テスト用の起動引数を設定
    app.launchArguments = ["--uitesting", "--logged-in"]
    app.launch()
    _ = awaitRootRendered(app)
  }

  /// 指定した要素が表示されるまで待機するヘルパーメソッド
  static func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    return element.waitForExistence(timeout: timeout)
  }

  /// タブを切り替えるヘルパーメソッド
  static func switchToTab(_ app: XCUIApplication, tabName: String) -> Bool {
    let tabButton = app.buttons[tabName]
    if tabButton.exists {
      tabButton.tap()
      return tabButton.isSelected
    }
    return false
  }

  /// アラートのボタンをタップするヘルパーメソッド
  static func tapAlertButton(_ app: XCUIApplication, alertTitle: String, buttonTitle: String)
    -> Bool
  {
    let alert = app.alerts[alertTitle]
    if alert.waitForExistence(timeout: 2) {
      let button = alert.buttons[buttonTitle]
      if button.exists {
        button.tap()
        return true
      }
    }
    return false
  }

  /// スクリーンショットを撮影するヘルパーメソッド
  static func takeScreenshot(_ app: XCUIApplication, name: String) {
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    XCTContext.runActivity(named: "Take screenshot: \(name)") { activity in
      activity.add(attachment)
    }
  }

  /// 起動直後のUIがレンダリングされるまで待機する
  /// - Returns: レンダリング検出に成功したか
  @discardableResult
  static func awaitRootRendered(
    _ app: XCUIApplication, timeout: TimeInterval = UITestingExtensions.TimeoutSettings.adjustedLong
  ) -> Bool {
    _ = app.wait(for: .runningForeground, timeout: timeout)
    let start = Date()
    while Date().timeIntervalSince(start) < timeout {
      handleSystemAlertsIfNeeded(app)
      if app.otherElements["UITestRootWindow"].exists
        || app.otherElements["LoginView"].exists
        || app.otherElements["MainTabBar"].exists
        || app.buttons["おでかけ"].exists
      {
        return true
      }
      app.activate()
      usleep(200_000)  // 0.2s ポーリング
    }
    return false
  }

  /// メインタブバー（または主要タブボタン）が表示されるまで待機する
  /// - Parameters:
  ///   - app: XCUIApplicationインスタンス
  ///   - timeout: 待機時間
  /// - Returns: タブUIが表示された場合はtrue
  static func waitForMainTabInterface(
    _ app: XCUIApplication, timeout: TimeInterval = UITestingExtensions.TimeoutSettings.adjustedLong
  ) -> Bool {
    let mainTabBar = app.otherElements["MainTabBar"]
    if mainTabBar.waitForExistence(timeout: timeout) {
      return true
    }

    let start = Date()
    let tabLabels = ["おでかけ", "おさんぽ", "設定"]

    while Date().timeIntervalSince(start) < timeout {
      handleSystemAlertsIfNeeded(app)
      if tabLabels.contains(where: { app.buttons[$0].exists }) {
        return true
      }
      usleep(200_000)
    }
    return false
  }

  /// システムアラート（位置情報許可など）を検出して適切なボタンをタップする
  @discardableResult
  static func handleSystemAlertsIfNeeded(_ app: XCUIApplication) -> Bool {
    let alert = app.alerts.firstMatch
    guard alert.exists else { return false }

    let allowButtonTitles = [
      "Allow While Using App",
      "Allow Once",
      "Allow",
      "許可",
      "アプリの使用中は許可",
      "OK"
    ]

    for title in allowButtonTitles {
      let button = alert.buttons[title]
      if button.exists {
        button.tap()
        return true
      }
    }

    // fallback: タップ可能な最初のボタンを押す
    if let firstButton = alert.buttons.allElementsBoundByIndex.first, firstButton.exists {
      firstButton.tap()
      return true
    }

    return false
  }
}

/// アプリの起動引数を設定するための拡張
extension XCUIApplication {

  /// ログイン状態でアプリを起動する
  func launchAsLoggedIn() {
    UITestingExtensions.launchAppLoggedIn(self)
  }

  /// テストモードでアプリを起動する
  func launchInTestMode() {
    UITestingExtensions.launchApp(
      self, options: UITestingExtensions.LaunchOptions(isUITesting: true, isLoggedIn: false))
  }

  /// ディープリンクでアプリを起動する
  func launchWithDeepLink(to destination: String) {
    UITestingExtensions.launchAppWithDeepLink(self, destination: destination)
  }

  /// エラー状態を強制してアプリを起動する
  func launchWithForcedError(errorType: String) {
    terminate()
    launchArguments = ["--uitesting"]
    launchArguments.append(contentsOf: ["--force-error", "--error-type", errorType])
    launch()
  }

  /// ローディング状態を強制してアプリを起動する
  func launchWithForcedLoadingState() {
    terminate()
    launchArguments = ["--uitesting", "--force-loading-state"]
    launch()
  }

  /// ユーザー情報を設定してアプリを起動する
  func launchWithUserInfo(email: String = "test@example.com") {
    terminate()
    launchArguments = ["--uitesting", "--logged-in", "--with-user-info", "--email", email]
    launch()
  }
}

/// UIテスト用のアサーションヘルパー
extension XCTestCase {

  /// 要素が表示されることを確認する
  func assertElementExists(_ element: XCUIElement, timeout: TimeInterval = 5, message: String) {
    XCTAssertTrue(element.waitForExistence(timeout: timeout), message)
  }

  /// 要素が表示されないことを確認する
  func assertElementDoesNotExist(_ element: XCUIElement, timeout: TimeInterval = 2, message: String)
  {
    // 少し待機してから確認
    sleep(UInt32(timeout))
    XCTAssertFalse(element.exists, message)
  }

  /// タブが選択されていることを確認する
  func assertTabIsSelected(_ app: XCUIApplication, tabName: String, message: String) {
    let tabButton = app.buttons[tabName]
    XCTAssertTrue(tabButton.waitForExistence(timeout: 2), "\(tabName)タブが表示されていません")
    XCTAssertTrue(tabButton.isSelected, message)
  }
}
