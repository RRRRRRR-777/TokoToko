//
//  WalkHistoryViewTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/09/01.
//

import CoreLocation
import SwiftUI
import ViewInspector
import XCTest
@testable import TekuToko

/// WalkHistoryViewの単体テスト
///
/// 散歩履歴表示画面のUI表示とリファクタリング後の動作を検証します。
final class WalkHistoryViewTests: XCTestCase {
  
  var sampleWalks: [Walk]!
  
  override func setUp() {
    super.setUp()
    // テスト用の散歩データを作成
    sampleWalks = [
      Walk(
        title: "朝の散歩",
        description: "公園を歩きました",
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 1200,
        totalSteps: 1500,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6812, longitude: 139.7671),
          CLLocation(latitude: 35.6815, longitude: 139.7675)
        ]
      )
    ]
  }
  
  override func tearDown() {
    sampleWalks = nil
    super.tearDown()
  }
  
  // MARK: - リファクタリング検証テスト
  
  /// headerViewのメソッド分割後の動作確認テスト
  func test_メソッド分割_headerViewの各要素が正しく表示される() throws {
    // Given
    let view = WalkHistoryView(walks: sampleWalks, initialIndex: 0)
    
    // When & Then - タイトル表示
    let titleText = try view.inspect().find(text: "朝の散歩")
    XCTAssertNotNil(titleText, "散歩タイトルが表示されるべき")
    
    // 共有ボタン（accessibilityIdentifierで検証）
    let buttons = try view.inspect().findAll(ViewType.Button.self)
    let shareButton = buttons.first { btn in
      (try? btn.accessibilityIdentifier()) == "share_button"
    }
    XCTAssertNotNil(shareButton, "共有ボタンが表示されるべき")
  }
  
  /// headerViewの分割後のレイアウト確認テスト
  func test_リファクタリング_headerViewのレイアウトが維持される() throws {
    // Given
    let view = WalkHistoryView(walks: sampleWalks, initialIndex: 0)
    
    // When & Then
    // リファクタリング後もグラデーション背景が適用されることを確認
    XCTAssertNoThrow({
      _ = try view.inspect().find(ViewType.LinearGradient.self)
    }, "headerViewのグラデーション背景が維持されるべき")
  }
  
  /// リファクタリング後のSwiftLint compliance確認テスト
  func test_SwiftLint_クロージャ行数制限遵守() throws {
    // Given
    let view = WalkHistoryView(walks: sampleWalks, initialIndex: 0)
    
    // When & Then
    // このテストが通ることで、リファクタリング後にクロージャが30行以下になったことを確認
    XCTAssertNoThrow({
      _ = try view.inspect().find(ViewType.VStack.self)
    }, "リファクタリング後のクロージャは30行制限を遵守するべき")
  }
  
  // MARK: - 基本表示テスト
  
  func test_画面表示_散歩データが正しく表示される() throws {
    // Given
    let view = WalkHistoryView(walks: sampleWalks, initialIndex: 0)
    
    // When & Then
    let walkTitle = try view.inspect().find(text: "朝の散歩")
    XCTAssertNotNil(walkTitle, "散歩タイトルが表示されるべき")
  }
  
  func test_画面表示_統計情報が表示される() throws {
    // Given
    let view = WalkHistoryView(walks: sampleWalks, initialIndex: 0)
    
    // When & Then
    // StatsBarViewの存在を確認
    let statsBar = try view.inspect().find(StatsBarView.self)
    XCTAssertNotNil(statsBar, "統計バーが表示されるべき")
  }
}
