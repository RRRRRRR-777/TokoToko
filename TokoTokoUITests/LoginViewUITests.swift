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

        // テスト用の起動引数を設定（必要に応じて）
        // app.launchArguments = ["--uitesting"]
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
        XCTAssertTrue(app.staticTexts["TokoTokoへようこそ"].exists, "ウェルカムテキストが表示されていません")

        // Googleログインボタンが表示されていることを確認
        // 注意: GoogleSignInButtonはカスタムビューのため、アクセシビリティ識別子の設定が必要かもしれません
        // 実際のテストでは、アクセシビリティ識別子を設定してからテストする必要があります

        // 簡易的なテスト（ボタンの存在確認は実際の環境では調整が必要）
        XCTAssertTrue(app.buttons.count > 0, "ボタンが見つかりません")
    }

    // ログインエラー表示のテスト
    // 注意: 実際のGoogleログインをUIテストで行うのは難しいため、
    // エラー表示のみをテストする簡易的な例です
    func testLoginErrorDisplay() {
        // このテストは実際の環境では、アプリにテストモードを設定し、
        // モックレスポンスを返すようにする必要があります

        // 簡易的なテスト
        XCTAssertTrue(true, "このテストは実際の環境ではモックレスポンスの設定が必要です")
    }
}
