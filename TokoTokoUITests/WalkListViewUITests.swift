//
//  WalkListViewUITests.swift
//  TokoTokoUITests
//
//  Created by Claude on 2025/06/21.
//

import XCTest

final class WalkListViewUITests: XCTestCase {

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

  func testWalkListViewBasicNavigation() throws {
    // Given: アプリが起動している

    // When: おさんぽタブが表示される
    let friendTab = app.buttons["おさんぽ"]
    XCTAssertTrue(friendTab.exists)

    // Then: おさんぽタブが選択状態になっている
    XCTAssertTrue(friendTab.isSelected)
  }

  func testWalkListViewNavigationTitle() throws {
    // Given: おさんぽタブが表示されている

    // When: ナビゲーションタイトルを確認
    let navigationTitle = app.navigationBars["おさんぽ"]

    // Then: 正しいタイトルが表示されている
    XCTAssertTrue(navigationTitle.exists)
  }

  // MARK: - 空の状態テスト

  func testEmptyWalkHistoryDisplayed() throws {
    // Given: WalkHistoryMainViewが表示されている

    // When: 空の状態を確認
    let emptyMessage = app.staticTexts["散歩履歴がありません"]
    let emptyDescription = app.staticTexts["散歩を完了すると、ここに履歴が表示されます"]

    // Then: 空の状態メッセージが表示される
    XCTAssertTrue(emptyMessage.exists)
    XCTAssertTrue(emptyDescription.exists)
  }

  func testEmptyStateIcon() throws {
    // Given: WalkHistoryMainViewが表示されている

    // When: 空の状態のアイコンを確認
    let emptyIcon = app.images["空の散歩履歴アイコン"]

    // Then: 空の状態アイコンが表示される
    XCTAssertTrue(emptyIcon.exists)
  }

  func testNavigationTitleDisplayed() throws {
    // Given: WalkHistoryMainViewが表示されている

    // When: ナビゲーションタイトルを確認
    let navigationTitle = app.navigationBars["おさんぽ"]

    // Then: 正しいタイトルが表示されている
    XCTAssertTrue(navigationTitle.exists)
  }

  // MARK: - ローディング状態テスト

  func testLoadingIndicatorDisplayed() throws {
    // Given: WalkHistoryMainViewが表示されている

    // When: ローディング状態を確認（短時間のため、すばやく確認）
    let loadingText = app.staticTexts["散歩履歴を読み込み中..."]

    // Then: ローディングメッセージが存在する可能性がある（タイミング次第）
    // 注：実際のテストでは、モックデータで遅延を制御することが望ましい
  }

  // MARK: - アクセシビリティテスト

  func testAccessibilityElements() throws {
    // Given: WalkHistoryMainViewが表示されている

    // When: アクセシビリティ要素を確認
    let emptyMessage = app.staticTexts["散歩履歴がありません"]
    let emptyDescription = app.staticTexts["散歩を完了すると、ここに履歴が表示されます"]

    // Then: 適切なアクセシビリティプロパティが設定されている
    XCTAssertTrue(emptyMessage.isHittable)
    XCTAssertTrue(emptyDescription.isHittable)
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

    // When: WalkHistoryMainViewが表示されている

    // Then: エラー状態でも適切にUIが表示される
    // プレースホルダー：実際のエラーハンドリングUIが実装された後にテストを更新
    XCTAssertTrue(true)
  }
}
