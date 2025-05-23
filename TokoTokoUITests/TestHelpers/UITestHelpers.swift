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
        launchArguments = ["--uitesting", "--logged-in"]
        launch()
    }

    /// テストモードでアプリを起動する
    func launchInTestMode() {
        launchArguments = ["--uitesting"]
        launch()
    }
}
