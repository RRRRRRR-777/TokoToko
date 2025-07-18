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
        // UIテストモードで未ログイン状態を明示的に設定
        app.launchArguments = ["--uitesting"]
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

        // メインタブバーが表示されるまで待機
        let mainTabBar = app.otherElements["MainTabBar"]
        XCTAssertTrue(mainTabBar.waitForExistence(timeout: 10), "メインタブバーが表示されていません")

        // おでかけタブが選択されていることを確認
        let outingTab = app.buttons["おでかけ"]
        XCTAssertTrue(outingTab.waitForExistence(timeout: 5), "おでかけタブが表示されていません")
        XCTAssertTrue(outingTab.isSelected, "おでかけタブが選択されていません")

        // おさんぽタブをタップ
        let walkTab = app.buttons["おさんぽ"]
        XCTAssertTrue(walkTab.waitForExistence(timeout: 5), "おさんぽタブが表示されていません")
        walkTab.tap()
        XCTAssertTrue(walkTab.isSelected, "おさんぽタブが選択されていません")

        // 設定タブをタップ
        let settingsTab = app.buttons["設定"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected, "設定タブが選択されていません")

        // おでかけタブに戻る
        outingTab.tap()
        XCTAssertTrue(outingTab.isSelected, "おでかけタブが選択されていません")
    }

    // アプリの状態保持テスト（バックグラウンド→フォアグラウンド）- 未ログイン状態
    func testAppStatePreservationWhenNotLoggedIn() {
        // UIテストモードで未ログイン状態を明示的に設定
        app.launchArguments = ["--uitesting"]
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

        // メインタブバーが表示されるまで待機
        let mainTabBar = app.otherElements["MainTabBar"]
        XCTAssertTrue(mainTabBar.waitForExistence(timeout: 10), "メインタブバーが表示されていません")

        // おでかけタブが表示されることを確認
        let outingTab = app.buttons["おでかけ"]
        XCTAssertTrue(outingTab.waitForExistence(timeout: 5), "おでかけタブが表示されていません")

        // 設定タブをタップ
        let settingsTab = app.buttons["設定"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected, "設定タブが選択されていません")

        // アプリをバックグラウンドに移動
        XCUIDevice.shared.press(.home)

        // 少し待機
        sleep(2)

        // アプリを再度フォアグラウンドに
        app.activate()

        // アプリの状態が保持されていることを確認（設定タブが選択されたまま）
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10), "設定タブが表示されていません")
        XCTAssertTrue(settingsTab.isSelected, "アプリの状態が保持されていません（設定タブ）")
    }

    // ディープリンクテスト
    func testDeepLinking() {
        // UITestHelpersを使用してディープリンクでアプリを起動
        app.launchWithDeepLink(to: "walk")

        // メインタブバーが表示されるまで待機
        let mainTabBar = app.otherElements["MainTabBar"]
        XCTAssertTrue(mainTabBar.waitForExistence(timeout: 10), "メインタブバーが表示されていません")

        // ディープリンクによっておさんぽ画面が表示されることを確認
        let walkTab = app.buttons["おさんぽ"]
        XCTAssertTrue(walkTab.waitForExistence(timeout: 5), "おさんぽタブが表示されていません")
        XCTAssertTrue(walkTab.isSelected, "おさんぽタブが選択されていません")

        // 設定画面へのディープリンクもテスト
        app.terminate()
        app.launchWithDeepLink(to: "settings")

        // メインタブバーが表示されるまで待機
        let mainTabBar2 = app.otherElements["MainTabBar"]
        XCTAssertTrue(mainTabBar2.waitForExistence(timeout: 10), "メインタブバーが表示されていません")

        // 設定タブが選択されていることを確認
        let settingsTab = app.buttons["設定"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
        XCTAssertTrue(settingsTab.isSelected, "設定タブが選択されていません")
    }

    // アプリの初期状態テスト - 未ログイン
    func testInitialStateWhenNotLoggedIn() {
        // UIテストモードで未ログイン状態を明示的に設定
        app.launchArguments = ["--uitesting"]
        app.launch()

        // ログイン画面が表示されることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ログイン画面が表示されていません")

        // タブバーが表示されないことを確認
        XCTAssertFalse(app.buttons["おでかけ"].exists, "未ログイン状態でタブバーが表示されています")
    }

    // アプリの初期状態テスト - ログイン済み
    func testInitialStateWhenLoggedIn() {
        // テスト用の起動引数を設定（ログイン状態をモック）
        app.launchArguments = ["--uitesting", "--logged-in"]
        app.launch()

        // メインタブバーが表示されるまで待機
        let mainTabBar = app.otherElements["MainTabBar"]
        XCTAssertTrue(mainTabBar.waitForExistence(timeout: 10), "メインタブバーが表示されていません")

        // タブバーが表示されることを確認
        XCTAssertTrue(app.buttons["おでかけ"].waitForExistence(timeout: 5), "タブバーが表示されていません")

        // おでかけタブが選択されていることを確認
        let outingTab = app.buttons["おでかけ"]
        XCTAssertTrue(outingTab.waitForExistence(timeout: 5), "おでかけタブが表示されていません")
        XCTAssertTrue(outingTab.isSelected, "おでかけタブが選択されていません")

        // おでかけ画面のマップビューが表示されていることを確認
        let mapView = app.otherElements["MapView"]
          if !mapView.waitForExistence(timeout: 10) {
              // マップビューが見つからない場合、代替方法で確認
              let allElements = app.descendants(matching: .any)
              print("🔍 全UI要素数: \(allElements.count)")
            
              // Map関連の要素を探す
              let mapElements = app.maps.allElementsBoundByIndex
              print("🔍 Map要素数: \(mapElements.count)")
            
              // 位置情報許可関連の要素を確認
              let locationPermissionText = app.staticTexts["位置情報の使用許可が必要です"]
              let locationDeniedText = app.staticTexts["位置情報へのアクセスが拒否されています"]
            
              if locationPermissionText.exists {
                  print("❌ 位置情報許可要求画面が表示されています")
                  XCTFail("位置情報許可要求画面が表示されています。マップビューが表示されません")
              } else if locationDeniedText.exists {
                  print("❌ 位置情報アクセス拒否画面が表示されています")
                  XCTFail("位置情報アクセス拒否画面が表示されています。マップビューが表示されません")
              } else {
                  print("❌ マップビューが表示されていません")
                  XCTFail("マップビューが表示されていません")
              }
          }
    }

    // アプリの画面回転テスト
    func testAppRotation() {
        // テスト用の起動引数を設定（ログイン状態をモック）
        app.launchArguments = ["--uitesting", "--logged-in"]
        app.launch()

        // メインタブバーが表示されるまで待機
        let mainTabBar = app.otherElements["MainTabBar"]
        XCTAssertTrue(mainTabBar.waitForExistence(timeout: 10), "メインタブバーが表示されていません")

        // デバイスを横向きに回転
        XCUIDevice.shared.orientation = .landscapeLeft

        // 少し待機
        sleep(1)

        // タブバーが表示されていることを確認
        XCTAssertTrue(app.buttons["おでかけ"].waitForExistence(timeout: 5), "横向き時にタブバーが表示されていません")

        // デバイスを縦向きに戻す
        XCUIDevice.shared.orientation = .portrait
    }

    // アクセシビリティのテスト
    func testAppAccessibility() {
        // テスト用の起動引数を設定（ログイン状態をモック）
        app.launchArguments = ["--uitesting", "--logged-in"]
        app.launch()

        // メインタブバーが表示されるまで待機
        let mainTabBar = app.otherElements["MainTabBar"]
        XCTAssertTrue(mainTabBar.waitForExistence(timeout: 10), "メインタブバーが表示されていません")

        // タブバーのボタンがアクセシビリティ対応していることを確認
        let outingTab = app.buttons["おでかけ"]
        XCTAssertTrue(outingTab.waitForExistence(timeout: 5), "おでかけタブが表示されていません")
        XCTAssertTrue(outingTab.isEnabled, "おでかけタブが有効になっていません")

        let walkTab = app.buttons["おさんぽ"]
        XCTAssertTrue(walkTab.waitForExistence(timeout: 5), "おさんぽタブが表示されていません")
        XCTAssertTrue(walkTab.isEnabled, "おさんぽタブが有効になっていません")

        let settingsTab = app.buttons["設定"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
        XCTAssertTrue(settingsTab.isEnabled, "設定タブが有効になっていません")
    }
}
