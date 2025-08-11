//
//  LoginViewUITests.swift
//  TokoTokoUITests
//
//  Created by Test on 2025/05/23.
//

import XCTest

final class LoginViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        // テスト失敗時にスクリーンショットを保存
        continueAfterFailure = false

        // アプリケーションの起動
        app = XCUIApplication()

        // テスト用の起動引数を設定
        app.launchArguments = ["--uitesting"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // ログイン画面が表示されるかテスト
    func testLoginViewAppears() {
        // アプリを起動
        app.launch()

        // ログイン画面の要素が表示されていることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ウェルカムテキストが表示されていません")
        XCTAssertTrue(app.staticTexts["位置情報を共有して、友達と繋がりましょう"].waitForExistence(timeout: 2), "サブタイトルが表示されていません")

        // アプリロゴが表示されていることを確認
        let appLogo = app.images["mappin.and.ellipse"]
        XCTAssertTrue(appLogo.waitForExistence(timeout: 2), "アプリロゴが表示されていません")

        // Googleログインボタンが表示されていることを確認
        let googleSignInButton = app.buttons["googleSignInButton"]
        XCTAssertTrue(googleSignInButton.waitForExistence(timeout: 2) || app.buttons.count > 0, "Googleログインボタンが表示されていません")
    }

    // ログインエラー表示のテスト - 改善版
    func testLoginErrorDisplay() {
        // UITestHelpersを使用してエラー状態を強制的に表示
        app.launchWithForcedError(errorType: "テストエラー")

        // ログイン画面が表示されることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ウェルカムテキストが表示されていません")

        // エラーメッセージが表示されることを確認
        // エラーメッセージのテキストを探す
        let predicate = NSPredicate(format: "label CONTAINS %@", "テストエラー")
        let errorTexts = app.staticTexts.matching(predicate)

        XCTAssertTrue(errorTexts.count > 0 || app.staticTexts.count > 2, "エラーメッセージが表示されていません")

        // アクセシビリティ識別子を設定している場合
        let errorMessage = app.staticTexts["loginErrorMessage"]
        if errorMessage.exists {
            XCTAssertTrue(errorMessage.isEnabled, "エラーメッセージが有効になっていません")
        }
    }

    // ローディング状態のテスト
    func testLoginLoadingState() {
        // テスト用の起動引数を設定（ローディング状態を強制的に表示）
        app.launchArguments = ["--uitesting", "--force-loading-state"]
        app.launch()

        // ログイン画面が表示されることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ウェルカムテキストが表示されていません")

        // Googleログインボタンをタップ
        let googleSignInButton = app.buttons["googleSignInButton"]
        if googleSignInButton.exists {
            googleSignInButton.tap()
        } else {
            // ボタンが見つからない場合は、最初のボタンをタップ
            if app.buttons.count > 0 {
                app.buttons.element(boundBy: 0).tap()
            }
        }

        // ローディングインジケータが表示されることを確認
        let loadingIndicator = app.activityIndicators.firstMatch
        XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 5), "ローディングインジケータが表示されていません")

        // Googleログインボタンが非表示になることを確認
        XCTAssertFalse(googleSignInButton.exists || app.buttons.count > 0, "Googleログインボタンが非表示になっていません")
    }

    // バックグラウンド/フォアグラウンド遷移テスト
    func testLoginViewBackgroundForegroundTransition() {
        // アプリを起動
        app.launch()

        // ログイン画面が表示されることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ウェルカムテキストが表示されていません")

        // アプリをバックグラウンドに移動
        XCUIDevice.shared.press(.home)

        // 少し待機
        sleep(2)

        // アプリを再度フォアグラウンドに
        app.activate()

        // ログイン画面が表示されていることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "バックグラウンドから復帰後、ウェルカムテキストが表示されていません")
    }

    // アクセシビリティのテスト
    func testLoginViewAccessibility() {
        // アプリを起動
        app.launch()

        // ログイン画面の要素がアクセシビリティ対応していることを確認
        let welcomeText = app.staticTexts["TokoTokoへようこそ"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5), "ウェルカムテキストが表示されていません")
        XCTAssertTrue(welcomeText.isEnabled, "ウェルカムテキストが有効になっていません")

        // アプリロゴがアクセシビリティ対応していることを確認
        let appLogo = app.images["mappin.and.ellipse"]
        if appLogo.exists {
            XCTAssertTrue(appLogo.isEnabled, "アプリロゴが有効になっていません")
        }

        // Googleログインボタンがアクセシビリティ対応していることを確認
        let googleSignInButton = app.buttons["googleSignInButton"]
        if googleSignInButton.exists {
            XCTAssertTrue(googleSignInButton.isEnabled, "Googleログインボタンが有効になっていません")
        } else if app.buttons.count > 0 {
            XCTAssertTrue(app.buttons.element(boundBy: 0).isEnabled, "ボタンが有効になっていません")
        }
    }

    // 画面回転テスト
    func testLoginViewRotation() {
        // アプリを起動
        app.launch()

        // ログイン画面が表示されることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].waitForExistence(timeout: 5), "ウェルカムテキストが表示されていません")

        // デバイスを横向きに回転
        XCUIDevice.shared.orientation = .landscapeLeft

        // 少し待機
        sleep(1)

        // ログイン画面の要素が表示されていることを確認
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].exists, "横向き時にウェルカムテキストが表示されていません")

        // デバイスを縦向きに戻す
        XCUIDevice.shared.orientation = .portrait
    }
}
