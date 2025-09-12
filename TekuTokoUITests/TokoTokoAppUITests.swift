//
//  TekuTokoAppUITests.swift
//  TekuTokoUITests
//
//  Created by Test on 2025/05/23.
//

import XCTest

final class TekuTokoAppUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUp() {
    super.setUp()

    // テスト失敗時にスクリーンショットを保存
    continueAfterFailure = false

    // アプリケーションの起動
    app = XCUIApplication()
    // 既定でUIテストモード引数を付与（個別テストで上書き可）
    app.launchArguments = ["--uitesting"]
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
    // 起動: 未ログインでUIテストモードに統一
    UITestingExtensions.launchAppLoggedOut(app)
    XCTAssertTrue(UITestHelpers.awaitRootRendered(app))

    // ログイン画面の検出を強化（識別子 or 代表要素 or 文言部分一致のいずれか）
    let loginRoot = app.otherElements["LoginView"]
    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    let appLogo = app.descendants(matching: .any).matching(identifier: "AppLogo").firstMatch
    let signInButton = app.buttons["googleSignInButton"]

    let appeared =
      loginRoot.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
      || welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
      || appLogo.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
      || signInButton.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)

    if !appeared {
      // デバッグ用添付
      let shot = XCUIScreen.main.screenshot()
      let attachment = XCTAttachment(screenshot: shot)
      attachment.name = "Login Not Appeared"
      attachment.lifetime = .keepAlways
      add(attachment)
      let treeAttachment = XCTAttachment(string: app.debugDescription)
      treeAttachment.name = "View Tree (login)"
      treeAttachment.lifetime = .keepAlways
      add(treeAttachment)
    }
    XCTAssertTrue(appeared, "ログイン画面が表示されていません")
    // 主要要素の存在（柔軟な検出）
    XCTAssertTrue(
      appLogo.exists || signInButton.exists || welcomeText.exists || loginRoot.exists,
      "ログイン画面の主要要素が見つかりません")
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
    // 起動: 未ログインでUIテストモード
    UITestingExtensions.launchAppLoggedOut(app)
    XCTAssertTrue(UITestHelpers.awaitRootRendered(app))

    // ログイン画面を確認（識別子 or 代表要素 or 文言部分一致）
    let loginRoot = app.otherElements["LoginView"]
    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    let appLogo = app.descendants(matching: .any).matching(identifier: "AppLogo").firstMatch
    let signInButton = app.buttons["googleSignInButton"]
    let appeared =
      loginRoot.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
      || welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
      || appLogo.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
      || signInButton.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
    if !appeared {
      let shot = XCUIScreen.main.screenshot()
      let attachment = XCTAttachment(screenshot: shot)
      attachment.name = "Login Not Appeared (state preservation)"
      attachment.lifetime = .keepAlways
      add(attachment)
      let treeAttachment = XCTAttachment(string: app.debugDescription)
      treeAttachment.name = "View Tree (state preservation)"
      treeAttachment.lifetime = .keepAlways
      add(treeAttachment)
    }
    XCTAssertTrue(appeared, "ログイン画面が表示されていません")

    // アプリをバックグラウンド→フォアグラウンド
    XCUIDevice.shared.press(.home)
    sleep(2)
    app.activate()

    // ルート再同期（未ログインではタブバー操作は不可のため、画面遷移は行わない）
    app.activate()
    _ = UITestHelpers.awaitRootRendered(app)

    // 未ログイン状態が保持されていることを確認（再クエリ＋複合条件）
    let loginRootAfterResume = app.otherElements["LoginView"]
    let welcomePredicateAfter = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeTextAfter = app.staticTexts.matching(welcomePredicateAfter).firstMatch
    let appLogoAfter = app.descendants(matching: .any).matching(identifier: "AppLogo").firstMatch
    let signInButtonAfter = app.buttons["googleSignInButton"]
    let reappeared =
      loginRootAfterResume.waitForExistence(
        timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
      || welcomeTextAfter.waitForExistence(
        timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
      || appLogoAfter.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
      || signInButtonAfter.waitForExistence(
        timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
    if !reappeared {
      let shot = XCUIScreen.main.screenshot()
      let attachment = XCTAttachment(screenshot: shot)
      attachment.name = "Login Not Reappeared (after resume)"
      attachment.lifetime = .keepAlways
      add(attachment)
      let treeAttachment = XCTAttachment(string: app.debugDescription)
      treeAttachment.name = "View Tree (after resume)"
      treeAttachment.lifetime = .keepAlways
      add(treeAttachment)
    }
    XCTAssertTrue(reappeared, "アプリの状態が保持されていません（ログイン画面）")
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
    // 起動: 未ログイン
    UITestingExtensions.launchAppLoggedOut(app)
    XCTAssertTrue(UITestHelpers.awaitRootRendered(app))

    // ログイン画面が表示されることを確認（識別子/代表要素/部分一致）
    let loginRoot = app.otherElements["LoginView"]
    let welcomePredicate = NSPredicate(format: "label CONTAINS %@", "ようこそ")
    let welcomeText = app.staticTexts.matching(welcomePredicate).firstMatch
    let appLogo = app.descendants(matching: .any).matching(identifier: "AppLogo").firstMatch
    let signInButton = app.buttons["googleSignInButton"]
    let appeared =
      loginRoot.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
      || welcomeText.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedLong)
      || appLogo.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
      || signInButton.waitForExistence(timeout: UITestingExtensions.TimeoutSettings.adjustedShort)
    if !appeared {
      let shot = XCUIScreen.main.screenshot()
      let attachment = XCTAttachment(screenshot: shot)
      attachment.name = "Login Not Appeared (initial state)"
      attachment.lifetime = .keepAlways
      add(attachment)
      let treeAttachment = XCTAttachment(string: app.debugDescription)
      treeAttachment.name = "View Tree (initial state)"
      treeAttachment.lifetime = .keepAlways
      add(treeAttachment)
    }
    XCTAssertTrue(appeared, "ログイン画面が表示されていません")

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
    // NavigationView内にあるMapViewを探す
    let mapView = app.otherElements["MapView"]
    let mapExists = mapView.waitForExistence(
      timeout: UITestingExtensions.TimeoutSettings.adjustedLong)

    if !mapExists {
      // より広範囲で探す - descendantsを使用
      let mapViewDescendant = app.descendants(matching: .other).matching(identifier: "MapView")
      if mapViewDescendant.count > 0 {
        // descendantsで見つかったので、階層の問題
        XCTAssertTrue(true, "MapViewが階層内で見つかりました")
      } else {
        let locationPermissionText = app.staticTexts["位置情報の使用許可が必要です"]
        let locationDeniedText = app.staticTexts["位置情報へのアクセスが拒否されています"]

        if locationPermissionText.exists {
          XCTFail("位置情報許可要求画面が表示されています。マップビューが表示されません")
        } else if locationDeniedText.exists {
          XCTFail("位置情報アクセス拒否画面が表示されています。マップビューが表示されません")
        } else {
          // HomeViewが表示されているか確認
          let homeView = app.otherElements["HomeView"]
          if homeView.exists {
            XCTFail("HomeViewは表示されていますが、MapViewが見つかりません")
          } else {
            XCTFail("HomeViewが表示されていません")
          }
        }
      }
    } else {
      XCTAssertTrue(mapExists, "MapViewが正常に表示されています")
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
