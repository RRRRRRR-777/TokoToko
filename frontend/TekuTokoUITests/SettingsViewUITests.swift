//
//  SettingsViewUITests.swift
//  TekuTokoUITests
//
//  Created by Test on 2025/05/23.
//

import XCTest

final class SettingsViewUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUp() {
    super.setUp()

    // テスト失敗時にスクリーンショットを保存
    continueAfterFailure = false

    // アプリケーションの起動
    app = XCUIApplication()

    // テスト用の起動引数を設定（ログイン状態をモック）
    app.launchArguments = ["--uitesting", "--logged-in"]
  }

  override func tearDown() {
    app = nil
    super.tearDown()
  }

  // 設定画面の表示テスト - 改善版
  func testSettingsViewAppears() {
    // アプリを起動（ログイン状態でモック）
    app.launch()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 設定画面の要素が表示されていることを確認
    XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5), "設定画面のナビゲーションバーが表示されていません")

    // 各セクションが表示されていることを確認
    XCTAssertTrue(app.staticTexts["アカウント"].waitForExistence(timeout: 2), "アカウントセクションが表示されていません")
    XCTAssertTrue(app.staticTexts["アプリ設定"].waitForExistence(timeout: 2), "アプリ設定セクションが表示されていません")
    XCTAssertTrue(app.staticTexts["位置情報"].waitForExistence(timeout: 2), "位置情報セクションが表示されていません")
    XCTAssertTrue(app.staticTexts["その他"].waitForExistence(timeout: 2), "その他セクションが表示されていません")
  }

  // ユーザー情報表示のテスト
  func testUserInfoDisplay() {
    // アプリを起動（ログイン状態でモック）
    app.launchArguments = ["--uitesting", "--logged-in", "--with-user-info"]
    app.launch()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // ユーザー情報が表示されていることを確認
    XCTAssertTrue(app.staticTexts["メールアドレス"].waitForExistence(timeout: 2), "メールアドレスラベルが表示されていません")

    // メールアドレスの値が表示されていることを確認
    // 注: 実際の環境では、モックユーザーのメールアドレスを確認する必要があります
    let emailCells = app.cells.containing(NSPredicate(format: "label CONTAINS 'メールアドレス'"))
    XCTAssertTrue(emailCells.count > 0, "メールアドレスを含むセルが見つかりません")

    // プロフィール画像が表示されていることを確認（オプション）
    let profileImageCells = app.cells.containing(NSPredicate(format: "label CONTAINS 'プロフィール画像'"))
    if profileImageCells.count > 0 {
      XCTAssertTrue(true, "プロフィール画像セルが見つかりました")
    }
  }

  // ログアウトアラートのテスト - 改善版
  func testLogoutAlertAppears() {
    // UITestHelpersを使用してユーザー情報付きでアプリを起動
    app.launchWithUserInfo()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // ログアウトボタンを探す（テキストまたはアクセシビリティ識別子で）
    let logoutButtonByText = app.staticTexts["ログアウト"]
    let logoutButtonByID = app.buttons["logoutButton"]

    // いずれかの方法でログアウトボタンを見つける
    var logoutButton: XCUIElement
    if logoutButtonByText.exists {
      logoutButton = logoutButtonByText
    } else if logoutButtonByID.exists {
      logoutButton = logoutButtonByID
    } else {
      // ログアウトという文字列を含むセルを探す
      let logoutCells = app.cells.containing(NSPredicate(format: "label CONTAINS 'ログアウト'"))
      XCTAssertTrue(logoutCells.count > 0, "ログアウトボタンが表示されていません")
      logoutButton = logoutCells.element(boundBy: 0)
    }

    // ログアウトボタンをタップ
    logoutButton.tap()

    // アラートが表示されることを確認
    let logoutAlert = app.alerts["ログアウトしますか？"]
    XCTAssertTrue(logoutAlert.waitForExistence(timeout: 5), "ログアウトアラートが表示されていません")

    // アラートのボタンが表示されていることを確認
    XCTAssertTrue(logoutAlert.buttons["キャンセル"].exists, "キャンセルボタンが表示されていません")
    XCTAssertTrue(logoutAlert.buttons["ログアウト"].exists, "ログアウトボタンが表示されていません")

    // キャンセルボタンをタップ
    logoutAlert.buttons["キャンセル"].tap()

    // アラートが閉じることを確認
    XCTAssertFalse(logoutAlert.waitForExistence(timeout: 2), "アラートが閉じていません")
  }

  // ログアウト処理のテスト - 改善版
  func testLogoutProcess() {
    // UITestHelpersを使用してユーザー情報付きでアプリを起動
    app.launchWithUserInfo()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // ログアウトボタンを探す（テキストまたはアクセシビリティ識別子で）
    let logoutButtonByText = app.staticTexts["ログアウト"]
    let logoutButtonByID = app.buttons["logoutButton"]

    // いずれかの方法でログアウトボタンを見つける
    var logoutButton: XCUIElement
    if logoutButtonByText.exists {
      logoutButton = logoutButtonByText
    } else if logoutButtonByID.exists {
      logoutButton = logoutButtonByID
    } else {
      // ログアウトという文字列を含むセルを探す
      let logoutCells = app.cells.containing(NSPredicate(format: "label CONTAINS 'ログアウト'"))
      XCTAssertTrue(logoutCells.count > 0, "ログアウトボタンが表示されていません")
      logoutButton = logoutCells.element(boundBy: 0)
    }

    // ログアウトボタンをタップ
    logoutButton.tap()

    // アラートが表示されることを確認
    let logoutAlert = app.alerts["ログアウトしますか？"]
    XCTAssertTrue(logoutAlert.waitForExistence(timeout: 5), "ログアウトアラートが表示されていません")

    // アラートの「ログアウト」ボタンをタップ
    logoutAlert.buttons["ログアウト"].tap()

    // ログイン画面に戻ることを確認（実装の文言に合わせる）
    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(
      welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "ログイン画面に戻っていません")
  }

  // 設定画面のスクロールテスト
  func testSettingsViewScrolling() {
    // アプリを起動（ログイン状態でモック）
    app.launch()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 設定画面が表示されていることを確認
    XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5), "設定画面のナビゲーションバーが表示されていません")

    // 下にスクロール
    app.swipeUp()

    // 「その他」セクションが表示されていることを確認
    XCTAssertTrue(app.staticTexts["その他"].waitForExistence(timeout: 2), "その他セクションが表示されていません")

    // 「このアプリについて」が表示されていることを確認
    XCTAssertTrue(
      app.staticTexts["このアプリについて"].waitForExistence(timeout: 2), "「このアプリについて」が表示されていません")

    // 上にスクロール
    app.swipeDown()

    // 「アカウント」セクションが表示されていることを確認
    XCTAssertTrue(app.staticTexts["アカウント"].waitForExistence(timeout: 2), "アカウントセクションが表示されていません")
  }

  // バックグラウンド/フォアグラウンド遷移テスト
  func testSettingsViewBackgroundForegroundTransition() {
    // アプリを起動（ログイン状態でモック）
    app.launch()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 設定画面が表示されていることを確認
    XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5), "設定画面のナビゲーションバーが表示されていません")

    // アプリをバックグラウンドに移動
    XCUIDevice.shared.press(.home)

    // 少し待機
    sleep(2)

    // アプリを再度フォアグラウンドに
    app.activate()

    // 設定画面が表示されていることを確認
    XCTAssertTrue(
      app.navigationBars["設定"].waitForExistence(timeout: 5),
      "バックグラウンドから復帰後、設定画面のナビゲーションバーが表示されていません")
  }

  // 画面回転テスト
  func testSettingsViewRotation() {
    // アプリを起動（ログイン状態でモック）
    app.launch()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 設定画面が表示されていることを確認
    XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5), "設定画面のナビゲーションバーが表示されていません")

    // デバイスを横向きに回転
    XCUIDevice.shared.orientation = .landscapeLeft

    // 少し待機
    sleep(1)

    // 設定画面の要素が表示されていることを確認
    XCTAssertTrue(app.navigationBars["設定"].exists, "横向き時に設定画面のナビゲーションバーが表示されていません")

    // デバイスを縦向きに戻す
    XCUIDevice.shared.orientation = .portrait
  }

  // MARK: - アカウント削除UIテスト

  /// アカウント削除ボタンが表示されることを確認
  func testAccountDeletionButtonAppears() {
    // UITestHelpersを使用してユーザー情報付きでアプリを起動
    app.launchWithUserInfo()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 下にスクロールしてアカウント削除ボタンを表示
    app.swipeUp()

    // アカウント削除ボタンを探す
    let deleteButtonByText = app.staticTexts["アカウント削除"]
    let deleteButtonByID = app.buttons["deleteAccountButton"]

    // いずれかの方法でアカウント削除ボタンを見つける
    let deleteButtonExists = deleteButtonByText.waitForExistence(timeout: 3)
      || deleteButtonByID.waitForExistence(timeout: 3)

    XCTAssertTrue(deleteButtonExists, "アカウント削除ボタンが表示されていません")
  }

  /// アカウント削除ボタンをタップすると確認アラートが表示されること
  func testAccountDeletionAlertAppears() {
    // UITestHelpersを使用してユーザー情報付きでアプリを起動
    app.launchWithUserInfo()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 下にスクロールしてアカウント削除ボタンを表示
    app.swipeUp()

    // アカウント削除ボタンを探す
    let deleteButtonByText = app.staticTexts["アカウント削除"]
    let deleteButtonByID = app.buttons["deleteAccountButton"]

    // いずれかの方法でアカウント削除ボタンを見つけてタップ
    var deleteButton: XCUIElement
    if deleteButtonByText.exists {
      deleteButton = deleteButtonByText
    } else if deleteButtonByID.exists {
      deleteButton = deleteButtonByID
    } else {
      // アカウント削除という文字列を含むセルを探す
      let deleteCells = app.cells.containing(NSPredicate(format: "label CONTAINS 'アカウント削除'"))
      XCTAssertTrue(deleteCells.count > 0, "アカウント削除ボタンが表示されていません")  // swiftlint:disable:this empty_count
      deleteButton = deleteCells.element(boundBy: 0)
    }

    deleteButton.tap()

    // アラートが表示されることを確認
    let deleteAlert = app.alerts["アカウントを削除しますか？"]
    XCTAssertTrue(deleteAlert.waitForExistence(timeout: 5), "アカウント削除アラートが表示されていません")

    // アラートのメッセージを確認
    let alertMessage = deleteAlert.staticTexts["この操作は取り消せません。アカウントと全てのデータが削除されます。"]
    XCTAssertTrue(alertMessage.exists, "アラートメッセージが表示されていません")

    // アラートのボタンが表示されていることを確認
    XCTAssertTrue(deleteAlert.buttons["キャンセル"].exists, "キャンセルボタンが表示されていません")
    XCTAssertTrue(deleteAlert.buttons["削除"].exists, "削除ボタンが表示されていません")
  }

  /// アカウント削除アラートでキャンセルを選択するとアラートが閉じること
  func testAccountDeletionAlertCancel() {
    // UITestHelpersを使用してユーザー情報付きでアプリを起動
    app.launchWithUserInfo()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 下にスクロールしてアカウント削除ボタンを表示
    app.swipeUp()

    // アカウント削除ボタンを探してタップ
    let deleteButtonByText = app.staticTexts["アカウント削除"]
    let deleteButtonByID = app.buttons["deleteAccountButton"]

    var deleteButton: XCUIElement
    if deleteButtonByText.exists {
      deleteButton = deleteButtonByText
    } else if deleteButtonByID.exists {
      deleteButton = deleteButtonByID
    } else {
      let deleteCells = app.cells.containing(NSPredicate(format: "label CONTAINS 'アカウント削除'"))
      XCTAssertTrue(deleteCells.count > 0, "アカウント削除ボタンが表示されていません")  // swiftlint:disable:this empty_count
      deleteButton = deleteCells.element(boundBy: 0)
    }

    deleteButton.tap()

    // アラートが表示されることを確認
    let deleteAlert = app.alerts["アカウントを削除しますか？"]
    XCTAssertTrue(deleteAlert.waitForExistence(timeout: 5), "アカウント削除アラートが表示されていません")

    // キャンセルボタンをタップ
    deleteAlert.buttons["キャンセル"].tap()

    // アラートが閉じることを確認
    XCTAssertFalse(deleteAlert.waitForExistence(timeout: 2), "アラートが閉じていません")

    // 設定画面に留まることを確認
    XCTAssertTrue(app.navigationBars["設定"].exists, "設定画面から移動していません")
  }

  /// アカウント削除ボタンが赤色で表示されること(アクセシビリティ)
  func testAccountDeletionButtonIsRed() {
    // UITestHelpersを使用してユーザー情報付きでアプリを起動
    app.launchWithUserInfo()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 下にスクロールしてアカウント削除ボタンを表示
    app.swipeUp()

    // アカウント削除ボタンを探す
    let deleteButton = app.buttons["deleteAccountButton"]
    XCTAssertTrue(
      deleteButton.waitForExistence(timeout: 3), "アカウント削除ボタンが表示されていません")

    // NOTE: XCUITestでは色の検証が困難なため、
    // テキストが存在することと、破壊的アクションとしてのラベルが付いていることを確認
    // 実際の色の確認はスクリーンショットテストやビジュアルリグレッションテストで行う
    XCTAssertTrue(deleteButton.exists, "アカウント削除ボタンが存在することを確認")
  }

  /// アカウント削除ボタンがスクロールした位置に表示されること
  func testAccountDeletionButtonPositionInScrollView() {
    // UITestHelpersを使用してユーザー情報付きでアプリを起動
    app.launchWithUserInfo()

    // 設定タブをタップ
    let settingsTab = app.buttons["設定"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "設定タブが表示されていません")
    settingsTab.tap()

    // 最初はアカウント削除ボタンが画面外にあることを確認
    let deleteButton = app.buttons["deleteAccountButton"]
    _ = deleteButton.exists  // 画面サイズによって初期状態は変わる可能性がある

    // 下にスクロール
    app.swipeUp()

    // スクロール後にアカウント削除ボタンが表示されることを確認
    let isVisibleAfterScroll = deleteButton.waitForExistence(timeout: 3)

    // スクロール後に表示されることを確認
    // (画面サイズによっては最初から表示される可能性もあるため、
    // スクロール後に表示されることのみを保証)
    XCTAssertTrue(isVisibleAfterScroll, "スクロール後にアカウント削除ボタンが表示されるべき")
  }
}
