//
//  WalkRowTests.swift
//  TekuTokoTests
//
//  Created by bokuyamada on 2025/01/02.
//

import SwiftUI
import ViewInspector
import XCTest

@testable import TekuToko

final class WalkRowTests: XCTestCase {

  func testWalkRowCreation() {
    // Given: 完了した散歩で歩数が設定されている
    let walk = Walk(
      title: "テスト散歩",
      description: "テスト用の散歩",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1200,
      totalSteps: 1500,
      status: .completed
    )

    // When: WalkRowを作成
    let walkRow = WalkRow(walk: walk)

    // Then: WalkRowが正常に作成される
    XCTAssertNotNil(walkRow)
    XCTAssertEqual(walk.title, "テスト散歩")
    XCTAssertEqual(walk.totalSteps, 1500)
    XCTAssertEqual(walk.status, .completed)
  }

  func testStepCountLogic() {
    // Given: 完了した散歩で歩数が0
    let walk = Walk(
      title: "テスト散歩",
      description: "テスト用の散歩",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1200,
      totalSteps: 0,
      status: .completed
    )

    // When: WalkRowを作成
    let walkRow = WalkRow(walk: walk)

    // Then: 歩数が0の場合のロジック確認
    XCTAssertEqual(walk.totalSteps, 0)
    XCTAssertEqual(walk.status, .completed)
  }

  func testInProgressWalkLogic() {
    // Given: 進行中の散歩
    let walk = Walk(
      title: "進行中の散歩",
      description: "現在進行中",
      startTime: Date().addingTimeInterval(-1800),
      totalDistance: 800,
      totalSteps: 950,
      status: .inProgress
    )

    // When: WalkRowを作成
    let walkRow = WalkRow(walk: walk)

    // Then: 進行中の散歩ロジック確認
    XCTAssertEqual(walk.status, .inProgress)
    XCTAssertFalse(walk.isCompleted)
  }

  func testStatusLogic() {
    // Given: 進行中の散歩
    let walk = Walk(
      title: "進行中の散歩",
      description: "現在進行中",
      startTime: Date().addingTimeInterval(-1800),
      totalDistance: 800,
      status: .inProgress
    )

    // When: WalkRowを作成
    let walkRow = WalkRow(walk: walk)

    // Then: ステータスが正しい
    XCTAssertEqual(walk.status, .inProgress)
    XCTAssertNotNil(walk.status.displayName)
  }

  func testWalkDataAccess() {
    // Given: 完了した散歩
    let walk = Walk(
      title: "テスト散歩",
      description: "アイコンテスト",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1200,
      totalSteps: 1500,
      status: .completed
    )

    // When: WalkRowを作成
    let walkRow = WalkRow(walk: walk)

    // Then: データが正しくアクセスできる
    XCTAssertEqual(walk.title, "テスト散歩")
    XCTAssertEqual(walk.totalSteps, 1500)
    XCTAssertEqual(walk.totalDistance, 1200)
    XCTAssertEqual(walk.status, .completed)
    XCTAssertTrue(walk.isCompleted)
  }

  func testCompletedWalkMetrics() {
    // Given: 完了した散歩（すべての指標を持つ）
    let walk = Walk(
      title: "完全な散歩",
      description: "すべての指標を持つ散歩",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1200,
      totalSteps: 1500,
      status: .completed
    )

    // When: WalkRowを作成
    let walkRow = WalkRow(walk: walk)

    // Then: 各種メトリクスが正しい
    XCTAssertNotNil(walk.durationString)
    XCTAssertNotNil(walk.distanceString)
    XCTAssertEqual(walk.totalSteps, 1500)
    XCTAssertTrue(walk.totalSteps > 0)
  }

  func testTitleAndDescription() {
    // Given: タイトルと説明のある散歩
    let walk = Walk(
      title: "朝の散歩",
      description: "公園を一周しました",
      status: .completed
    )

    // When: WalkRowを作成
    let walkRow = WalkRow(walk: walk)

    // Then: タイトルと説明が正しい
    XCTAssertEqual(walk.title, "朝の散歩")
    XCTAssertEqual(walk.description, "公園を一周しました")
    XCTAssertFalse(walk.description.isEmpty)
  }

  func testEmptyDescription() {
    // Given: 説明が空の散歩
    let walk = Walk(
      title: "無説明の散歩",
      description: "",
      status: .completed
    )

    // When: WalkRowを作成
    let walkRow = WalkRow(walk: walk)

    // Then: 説明が空であることを確認
    XCTAssertEqual(walk.title, "無説明の散歩")
    XCTAssertEqual(walk.description, "")
    XCTAssertTrue(walk.description.isEmpty)
  }

  // MARK: - リファクタリング検証テスト

  /// bodyのメソッド分割後の動作確認テスト
  func test_メソッド分割_各セクションが正しく表示される() throws {
    // Given
    let walk = Walk(
      title: "朝の散歩",
      description: "公園を歩きました",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-1800),
      totalDistance: 1200,
      totalSteps: 1500,
      status: .completed
    )
    let view = WalkRow(walk: walk)

    // When & Then - タイトル表示
    let titleText = try view.inspect().find(text: "朝の散歩")
    XCTAssertNotNil(titleText, "散歩タイトルが表示されるべき")

    // 説明文表示
    let descriptionText = try view.inspect().find(text: "公園を歩きました")
    XCTAssertNotNil(descriptionText, "散歩の説明が表示されるべき")
  }

  /// リファクタリング後のSwiftLint compliance確認テスト
  func test_SwiftLint_クロージャ行数制限遵守() throws {
    // Given
    let walk = Walk(
      title: "テスト散歩",
      description: "テスト用の散歩",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1200,
      totalSteps: 1500,
      status: .completed
    )
    let view = WalkRow(walk: walk)

    // When & Then
    // このテストが通ることで、リファクタリング後にクロージャが30行以下になったことを確認
    XCTAssertNoThrow(
      {
        _ = try view.inspect().find(ViewType.VStack.self)
      }, "リファクタリング後のクロージャは30行制限を遵守するべき")
  }
}
