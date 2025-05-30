//
//  UITestHelpers.swift
//  TokoTokoUITests
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
    }

    /// 指定した要素が表示されるまで待機するヘルパーメソッド
    static func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// タブを切り替えるヘルパーメソッド
    static func switchToTab(_ app: XCUIApplication, tabName: String) -> Bool {
        let tabButton = app.tabBars.buttons[tabName]
        if tabButton.exists {
            tabButton.tap()
            return tabButton.isSelected
        }
        return false
    }

    /// アラートのボタンをタップするヘルパーメソッド
    static func tapAlertButton(_ app: XCUIApplication, alertTitle: String, buttonTitle: String) -> Bool {
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
}

/// アプリの起動引数を設定するための拡張
extension XCUIApplication {

    /// ログイン状態でアプリを起動する
    func launchAsLoggedIn() {
        UITestingExtensions.launchAppLoggedIn(self)
    }

    /// テストモードでアプリを起動する
    func launchInTestMode() {
        UITestingExtensions.launchApp(self, options: UITestingExtensions.LaunchOptions(isUITesting: true, isLoggedIn: false))
    }

    /// ディープリンクでアプリを起動する
    func launchWithDeepLink(to destination: String) {
        UITestingExtensions.launchAppWithDeepLink(self, destination: destination)
    }

    /// エラー状態を強制してアプリを起動する
    func launchWithForcedError(errorType: String) {
        let options = UITestingExtensions.LaunchOptions(isUITesting: true)
        UITestingExtensions.launchApp(self, options: options)
        // 追加の引数を設定
        launchArguments.append("--force-error")
        launchArguments.append("--error-type")
        launchArguments.append(errorType)
        launch()
    }

    /// ローディング状態を強制してアプリを起動する
    func launchWithForcedLoadingState() {
        let options = UITestingExtensions.LaunchOptions(isUITesting: true)
        UITestingExtensions.launchApp(self, options: options)
        // 追加の引数を設定
        launchArguments.append("--force-loading-state")
        launch()
    }

    /// ユーザー情報を設定してアプリを起動する
    func launchWithUserInfo(email: String = "test@example.com") {
        let options = UITestingExtensions.LaunchOptions(isUITesting: true, isLoggedIn: true)
        UITestingExtensions.launchApp(self, options: options)
        // 追加の引数を設定
        launchArguments.append("--with-user-info")
        launchArguments.append("--email")
        launchArguments.append(email)
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
    func assertElementDoesNotExist(_ element: XCUIElement, timeout: TimeInterval = 2, message: String) {
        // 少し待機してから確認
        sleep(UInt32(timeout))
        XCTAssertFalse(element.exists, message)
    }

    /// タブが選択されていることを確認する
    func assertTabIsSelected(_ app: XCUIApplication, tabName: String, message: String) {
        let tabButton = app.tabBars.buttons[tabName]
        XCTAssertTrue(tabButton.waitForExistence(timeout: 2), "\(tabName)タブが表示されていません")
        XCTAssertTrue(tabButton.isSelected, message)
    }
}
