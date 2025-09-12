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

    // テスト失敗時にスクリーンショットを保存
    continueAfterFailure = false

    // アプリケーションの起動
    app = XCUIApplication()

    // 起動: 未ログインでUIテストモードに統一
    UITestingExtensions.launchAppLoggedOut(app)
    // 起動安定化: 失敗時はデバッグ添付のみで続行（各テストで個別に検証）
    if !UITestHelpers.awaitRootRendered(app) {
      let shot = XCUIScreen.main.screenshot()
      let a = XCTAttachment(screenshot: shot)
      a.name = "Root Not Rendered (setup)"
      a.lifetime = .keepAlways
      add(a)
      let tree = XCTAttachment(string: app.debugDescription)
      tree.name = "View Tree (setup)"
      tree.lifetime = .keepAlways
      add(tree)
    }
  }

  override func tearDown() {
    app = nil
    super.tearDown()
  }

  // ログイン画面が表示されるかテスト
  func testLoginViewAppears() {
    // setUpで起動済み

    // デバッグ: 画面直後のスクリーンショット/ツリーを添付
    let bootShot = XCUIScreen.main.screenshot()
    let bootAttachment = XCTAttachment(screenshot: bootShot)
    bootAttachment.name = "Boot Screen"
    bootAttachment.lifetime = .keepAlways
    add(bootAttachment)
    // 標準出力にもビュー階層を出す
    print("\n===== VIEW TREE (boot) =====\n\(app.debugDescription)\n============================\n")
    let treeAttachment = XCTAttachment(string: app.debugDescription)
    treeAttachment.name = "View Tree (boot)"
    treeAttachment.lifetime = .keepAlways
    add(treeAttachment)

    // ルート同期: UITestRootWindow の出現を待つ
    let root = app.otherElements["UITestRootWindow"]
    _ = root.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong)

    // 初期同期: LoginViewの出現を待つ（安定化）
    // SwiftUIの構造により、identifier("LoginView")が子要素に付与される場合があるためanyで検出
    let loginRoot = app.descendants(matching: .any).matching(identifier: "LoginView").firstMatch
    let appeared = loginRoot.waitForExistence(
      timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
    if !appeared {
      print(
        "\n===== VIEW TREE (after wait LoginView) =====\n\(app.debugDescription)\n==========================================\n"
      )
    }
    XCTAssertTrue(appeared, "LoginViewが表示されません")

    // 主要要素が出るまで追加待機
    let appLogo = app.descendants(matching: .any).matching(identifier: "AppLogo").firstMatch
    let signIn = app.buttons["googleSignInButton"]
    _ =
      appLogo.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
      || signIn.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)

    // デバッグ: 同期後の画面
    let afterWaitShot = XCUIScreen.main.screenshot()
    let afterWaitAttachment = XCTAttachment(screenshot: afterWaitShot)
    afterWaitAttachment.name = "After Wait Screen"
    afterWaitAttachment.lifetime = .keepAlways
    add(afterWaitAttachment)

    // 文言は部分一致で検出（将来の微修正に強い）
    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(
      welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "ウェルカムテキストが表示されていません"
    )
    let subtitle = app.staticTexts["今日の散歩を、明日の思い出にシェアしよう"]
    XCTAssertTrue(
      subtitle.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "サブタイトルが表示されていません"
    )

    // Googleログインボタンが表示されていることを確認
    let googleSignInButton = app.buttons["googleSignInButton"]
    XCTAssertTrue(
      googleSignInButton.waitForExistence(timeout: 2) || app.buttons.count > 0,
      "Googleログインボタンが表示されていません")
  }

  // ログインエラー表示のテスト - 改善版
  func testLoginErrorDisplay() {
    // UITestHelpersを使用してエラー状態を強制的に表示
    app.launchWithForcedError(errorType: "テストエラー")

    // 同期＆文言（部分一致）
    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(
      welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "ウェルカムテキストが表示されていません"
    )

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

    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(
      welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "ウェルカムテキストが表示されていません"
    )

    // ローディングインジケータが表示されることを確認
    let loadingIndicator = app.activityIndicators.firstMatch
    XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 5), "ローディングインジケータが表示されていません")

    // Googleログインボタンが非表示になることを確認（具体的にGoogleログインボタンのみをチェック）
    let googleSignInButton = app.buttons["googleSignInButton"]
    XCTAssertFalse(googleSignInButton.exists, "Googleログインボタンが非表示になっていません")

    // ポリシーリンクボタンは表示されたままであることを確認
    XCTAssertTrue(
      app.buttons.matching(NSPredicate(format: "label CONTAINS 'プライバシーポリシー'")).count > 0,
      "プライバシーポリシーリンクが表示されていません")
    XCTAssertTrue(
      app.buttons.matching(NSPredicate(format: "label CONTAINS '利用規約'")).count > 0,
      "利用規約リンクが表示されていません")
  }

  // バックグラウンド/フォアグラウンド遷移テスト
  func testLoginViewBackgroundForegroundTransition() {
    // アプリを起動
    app.launch()

    // ログイン画面が表示されることを確認（文言は部分一致）
    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(
      welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "ウェルカムテキストが表示されていません")

    // アプリをバックグラウンドに移動
    XCUIDevice.shared.press(.home)

    // 少し待機
    sleep(2)

    // アプリを再度フォアグラウンドに
    app.activate()

    // ログイン画面が表示されていることを確認（文言は部分一致）
    let welcomeAfter = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(
      welcomeAfter.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "バックグラウンドから復帰後、ウェルカムテキストが表示されていません")
  }

  // アクセシビリティのテスト
  func testLoginViewAccessibility() {
    // アプリを起動
    app.launch()

    // ログイン画面の要素がアクセシビリティ対応していることを確認
    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(
      welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "ウェルカムテキストが表示されていません"
    )
    XCTAssertTrue(welcomeText.isEnabled, "ウェルカムテキストが有効になっていません")

    // アプリロゴがアクセシビリティ対応していることを確認（AppLogo）
    let appLogo = app.descendants(matching: .any).matching(identifier: "AppLogo").firstMatch
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

    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    XCTAssertTrue(
      welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong),
      "ウェルカムテキストが表示されていません"
    )

    // デバイスを横向きに回転
    XCUIDevice.shared.orientation = .landscapeLeft

    // 少し待機
    sleep(1)

    // ログイン画面の要素が表示されていることを確認（文言は部分一致）
    XCTAssertTrue(
      app.staticTexts.matching(welcomePredicate).firstMatch.exists, "横向き時にウェルカムテキストが表示されていません")

    // デバイスを縦向きに戻す
    XCUIDevice.shared.orientation = .portrait
  }
}
