//
//  TokoTokoAppUITests.swift
//  TokoTokoUITests
//
//  Created by Test on 2025/05/23.
//

import XCTest

final class TokoTokoAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        // テスト失敗時にスクリーンショットを保存
        continueAfterFailure = false

        // アプリケーションの起動
        app = XCUIApplication()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // アプリの起動テスト
    func testAppLaunch() {
        app.launch()

        // アプリが正常に起動することを確認
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5), "アプリが正常に起動しませんでした")
    }

    // 未ログイン時にログイン画面が表示されるかテスト
    func testLoginScreenAppearsWhenNotLoggedIn() {
        app.launch()

        // ログイン画面の要素が表示されていることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ログイン画面が表示されていません")
        XCTAssertTrue(app.staticTexts["位置情報を共有して、友達と繋がりましょう"].waitForExistence(timeout: 2), "サブタイトルが表示されていません")
    }

    // タブ切り替えのテスト（ログイン状態が必要）
    func testTabSwitching() {
        // テスト用の起動引数を設定（ログイン状態をモック）
        app.launchArguments = ["--uitesting", "--logged-in"]
        app.launch()

        // ホームタブが選択されていることを確認
        let homeTab = app.tabBars.buttons["ホーム"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "ホームタブが表示されていません")
        XCTAssertTrue(homeTab.isSelected, "ホームタブが選択されていません")

        // マップタブをタップ
        let mapTab = app.tabBars.buttons["マップ"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 2), "マップタブが表示されていません")
        mapTab.tap()
        XCTAssertTrue(mapTab.isSelected, "マップタブが選択されていません")

        // 設定タブをタップ
        let settingsTab = app.tabBars.buttons["設定"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 2), "設定タブが表示されていません")
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected, "設定タブが選択されていません")

        // ホームタブに戻る
        homeTab.tap()
        XCTAssertTrue(homeTab.isSelected, "ホームタブが選択されていません")
    }

    // アプリの状態保持テスト（バックグラウンド→フォアグラウンド）- 未ログイン状態
    func testAppStatePreservationWhenNotLoggedIn() {
        app.launch()

        // ログイン画面が表示されることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ログイン画面が表示されていません")

        // アプリをバックグラウンドに移動
        XCUIDevice.shared.press(.home)

        // 少し待機
        sleep(2)

        // アプリを再度フォアグラウンドに
        app.activate()

        // アプリの状態が保持されていることを確認（未ログイン状態）
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "アプリの状態が保持されていません（ログイン画面）")
    }

    // アプリの状態保持テスト（バックグラウンド→フォアグラウンド）- ログイン状態
    func testAppStatePreservationWhenLoggedIn() {
        // テスト用の起動引数を設定（ログイン状態をモック）
        app.launchArguments = ["--uitesting", "--logged-in"]
        app.launch()

        // ホームタブが表示されることを確認
        let homeTab = app.tabBars.buttons["ホーム"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "ホームタブが表示されていません")

        // 設定タブをタップ
        let settingsTab = app.tabBars.buttons["設定"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 2), "設定タブが表示されていません")
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected, "設定タブが選択されていません")

        // アプリをバックグラウンドに移動
        XCUIDevice.shared.press(.home)

        // 少し待機
        sleep(2)

        // アプリを再度フォアグラウンドに
        app.activate()

        // アプリの状態が保持されていることを確認（設定タブが選択されたまま）
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
        XCTAssertTrue(settingsTab.isSelected, "アプリの状態が保持されていません（設定タブ）")
    }

    // ディープリンクテスト
    func testDeepLinking() {
        // UITestHelpersを使用してディープリンクでアプリを起動
        app.launchWithDeepLink(to: "map")

        // ディープリンクによってマップ画面が表示されることを確認
        let mapTab = app.tabBars.buttons["マップ"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "マップタブが表示されていません")
        XCTAssertTrue(mapTab.isSelected, "マップタブが選択されていません")

        // 設定画面へのディープリンクもテスト
        app.terminate()
        app.launchWithDeepLink(to: "settings")

        // 設定タブが選択されていることを確認
        let settingsTab = app.tabBars.buttons["設定"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
        XCTAssertTrue(settingsTab.isSelected, "設定タブが選択されていません")
    }

    // アプリの初期状態テスト - 未ログイン
    func testInitialStateWhenNotLoggedIn() {
        app.launch()

        // ログイン画面が表示されることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ログイン画面が表示されていません")

        // タブバーが表示されないことを確認
        XCTAssertFalse(app.tabBars.element.exists, "未ログイン状態でタブバーが表示されています")
    }

    // アプリの初期状態テスト - ログイン済み
    func testInitialStateWhenLoggedIn() {
        // テスト用の起動引数を設定（ログイン状態をモック）
        app.launchArguments = ["--uitesting", "--logged-in"]
        app.launch()

        // タブバーが表示されることを確認
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5), "タブバーが表示されていません")

        // ホームタブが選択されていることを確認
        let homeTab = app.tabBars.buttons["ホーム"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2), "ホームタブが表示されていません")
        XCTAssertTrue(homeTab.isSelected, "ホームタブが選択されていません")

        // ホーム画面の要素が表示されていることを確認
        XCTAssertTrue(app.navigationBars.element.exists, "ナビゲーションバーが表示されていません")
    }

    // アプリの画面回転テスト
    func testAppRotation() {
        // テスト用の起動引数を設定（ログイン状態をモック）
        app.launchArguments = ["--uitesting", "--logged-in"]
        app.launch()

        // タブバーが表示されることを確認
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5), "タブバーが表示されていません")

        // デバイスを横向きに回転
        XCUIDevice.shared.orientation = .landscapeLeft

        // 少し待機
        sleep(1)

        // タブバーが表示されていることを確認
        XCTAssertTrue(app.tabBars.element.exists, "横向き時にタブバーが表示されていません")

        // デバイスを縦向きに戻す
        XCUIDevice.shared.orientation = .portrait
    }

    // アクセシビリティのテスト
    func testAppAccessibility() {
        // テスト用の起動引数を設定（ログイン状態をモック）
        app.launchArguments = ["--uitesting", "--logged-in"]
        app.launch()

        // タブバーが表示されることを確認
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5), "タブバーが表示されていません")

        // タブバーのボタンがアクセシビリティ対応していることを確認
        let homeTab = app.tabBars.buttons["ホーム"]
        XCTAssertTrue(homeTab.isEnabled, "ホームタブが有効になっていません")

        let mapTab = app.tabBars.buttons["マップ"]
        XCTAssertTrue(mapTab.isEnabled, "マップタブが有効になっていません")

        let settingsTab = app.tabBars.buttons["設定"]
        XCTAssertTrue(settingsTab.isEnabled, "設定タブが有効になっていません")
    }
}
