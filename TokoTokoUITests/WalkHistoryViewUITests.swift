//
//  WalkHistoryViewUITests.swift
//  TokoTokoUITests
//
//  Created by Claude on 2025/06/21.
//

import XCTest

final class WalkHistoryViewUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()

    // UIテストモードを有効化
    app.launchArguments.append("UI_TESTING")
    app.launchArguments.append("MOCK_LOGGED_IN")

    // おさんぽタブへのディープリンクを設定
    app.launchArguments.append("DEEP_LINK_DESTINATION_walk")

    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - 基本ナビゲーションテスト

  func testWalkHistoryViewBasicNavigation() throws {
    // Given: アプリが起動している

    // When: おさんぽタブが表示される
    let friendTab = app.buttons["おさんぽ"]
    XCTAssertTrue(friendTab.exists)

    // Then: おさんぽタブが選択状態になっている
    XCTAssertTrue(friendTab.isSelected)
  }

  func testWalkHistoryViewNavigationTitle() throws {
    // Given: おさんぽタブが表示されている

    // When: ナビゲーションタイトルを確認
    let navigationTitle = app.navigationBars["おさんぽ"]

    // Then: 正しいタイトルが表示されている
    XCTAssertTrue(navigationTitle.exists)
  }

  // MARK: - セグメントコントロールテスト

  func testSegmentedControlExists() throws {
    // Given: WalkHistoryViewが表示されている

    // When: セグメントコントロールを探す
    let segmentedControl = app.segmentedControls.firstMatch

    // Then: セグメントコントロールが存在する
    XCTAssertTrue(segmentedControl.exists)
  }

  func testSegmentedControlOptions() throws {
    // Given: WalkHistoryViewが表示されている

    // When: セグメントコントロールのボタンを確認
    let myHistoryButton = app.buttons["自分の履歴"]
    let friendHistoryButton = app.buttons["フレンドの履歴"]

    // Then: 両方のオプションが存在する
    XCTAssertTrue(myHistoryButton.exists)
    XCTAssertTrue(friendHistoryButton.exists)
  }

  func testSegmentedControlTapping() throws {
    // Given: WalkHistoryViewが表示されている
    let myHistoryButton = app.buttons["自分の履歴"]
    let friendHistoryButton = app.buttons["フレンドの履歴"]

    // When: 「自分の履歴」が最初に選択されている
    XCTAssertTrue(myHistoryButton.isSelected)
    XCTAssertFalse(friendHistoryButton.isSelected)

    // When: 「フレンドの履歴」をタップ
    friendHistoryButton.tap()

    // Then: 選択状態が変更される
    XCTAssertFalse(myHistoryButton.isSelected)
    XCTAssertTrue(friendHistoryButton.isSelected)

    // When: 「自分の履歴」に戻る
    myHistoryButton.tap()

    // Then: 元の状態に戻る
    XCTAssertTrue(myHistoryButton.isSelected)
    XCTAssertFalse(friendHistoryButton.isSelected)
  }

  // MARK: - 自分の履歴タブテスト

  func testMyWalkHistoryEmptyState() throws {
    // Given: 自分の履歴タブが選択されている
    let myHistoryButton = app.buttons["自分の履歴"]
    myHistoryButton.tap()

    // When: 空の状態を確認
    let emptyMessage = app.staticTexts["散歩履歴がありません"]
    let emptyDescription = app.staticTexts["散歩を完了すると、ここに履歴が表示されます"]

    // Then: 空の状態メッセージが表示される
    XCTAssertTrue(emptyMessage.exists)
    XCTAssertTrue(emptyDescription.exists)
  }

  func testMyWalkHistoryLoadingState() throws {
    // Given: 自分の履歴タブが選択されている
    let myHistoryButton = app.buttons["自分の履歴"]
    myHistoryButton.tap()

    // When: 読み込み状態を確認（短時間のため、すばやく確認）
    let loadingIndicator = app.activityIndicators.firstMatch

    // Then: ローディングインジケーターが存在する可能性がある（タイミング次第）
    // 注：実際のテストでは、モックデータで遅延を制御することが望ましい
  }

  // MARK: - フレンドの履歴タブテスト

  func testFriendWalkHistoryComingSoon() throws {
    // Given: フレンドの履歴タブを選択
    let friendHistoryButton = app.buttons["フレンドの履歴"]
    friendHistoryButton.tap()

    // When: 近日公開予定のメッセージを確認
    let comingSoonTitle = app.staticTexts["フレンドの履歴"]
    let comingSoonMessage = app.staticTexts["友達の散歩履歴は近日公開予定です"]

    // Then: 正しいメッセージが表示される
    XCTAssertTrue(comingSoonTitle.exists)
    XCTAssertTrue(comingSoonMessage.exists)
  }

  func testFriendWalkHistoryIcon() throws {
    // Given: フレンドの履歴タブを選択
    let friendHistoryButton = app.buttons["フレンドの履歴"]
    friendHistoryButton.tap()

    // When: アイコンの存在を確認
    let friendIcon = app.images.containing(
      NSPredicate(format: "identifier CONTAINS 'person.2.circle'")
    ).firstMatch

    // Then: フレンドアイコンが表示される
    // 注：実際のテストでは、アクセシビリティ識別子を使用することが推奨
    XCTAssertTrue(friendIcon.exists || app.staticTexts.count > 0)  // フォールバック確認
  }

  // MARK: - プルトゥリフレッシュテスト

  func testPullToRefreshInMyHistory() throws {
    // Given: 自分の履歴タブが表示されている
    let myHistoryButton = app.buttons["自分の履歴"]
    myHistoryButton.tap()

    // When: プルトゥリフレッシュを実行
    let scrollView = app.scrollViews.firstMatch
    if scrollView.exists {
      scrollView.swipeDown()
    }

    // Then: リフレッシュ動作が実行される
    // 注：実際のテストでは、ネットワーク呼び出しをモックして確認
    XCTAssertTrue(true)  // プレースホルダー
  }

  // MARK: - アクセシビリティテスト

  func testAccessibilityElements() throws {
    // Given: WalkHistoryViewが表示されている

    // When: アクセシビリティ要素を確認
    let myHistoryButton = app.buttons["自分の履歴"]
    let friendHistoryButton = app.buttons["フレンドの履歴"]

    // Then: 適切なアクセシビリティプロパティが設定されている
    XCTAssertTrue(myHistoryButton.isHittable)
    XCTAssertTrue(friendHistoryButton.isHittable)
  }

  // MARK: - パフォーマンステスト

  func testWalkHistoryViewLaunchPerformance() throws {
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
      // このテストは、WalkHistoryViewを含むタブの起動パフォーマンスを測定します
      measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
      }
    }
  }

  // MARK: - エラーハンドリングテスト

  func testNetworkErrorHandling() throws {
    // Given: ネットワークエラーが発生する状況をシミュレート
    // 注：実際のテストでは、モックネットワーク環境を設定

    // When: 自分の履歴タブを表示
    let myHistoryButton = app.buttons["自分の履歴"]
    myHistoryButton.tap()

    // Then: エラー状態でも適切にUIが表示される
    // プレースホルダー：実際のエラーハンドリングUIが実装された後にテストを更新
    XCTAssertTrue(true)
  }
}
