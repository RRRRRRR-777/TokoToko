//
//  StatsBarViewTests.swift
//  TokoTokoTests
//
//  Created by Claude Code on 2025/07/12.
//

import CoreLocation
import SwiftUI
import ViewInspector
import XCTest

@testable import TokoToko

final class StatsBarViewTests: XCTestCase {

  var mockWalk: Walk!

  override func setUp() {
    super.setUp()
    mockWalk = Walk(
      title: "テスト散歩",
      description: "テスト用の散歩です",
      id: UUID(),
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1500,
      totalSteps: 2000,
      status: .completed,
      locations: [
        CLLocation(latitude: 35.6812, longitude: 139.7671),
        CLLocation(latitude: 35.6815, longitude: 139.7675),
      ]
    )
  }

  override func tearDown() {
    mockWalk = nil
    super.tearDown()
  }

  // MARK: - Red: 失敗するテスト（TDD手法における初期失敗テスト）

  func test_StatsBarView_Walkデータを渡すと距離が正しく表示される() throws {
    // Given
    let view = StatsBarView(walk: mockWalk, isExpanded: .constant(true), onToggle: {}, onWalkDeleted: nil)

    // When & Then
    let distanceText = try view.inspect().find(text: mockWalk.distanceString)
    XCTAssertNotNil(distanceText)
  }

  func test_StatsBarView_Walkデータを渡すと時間が正しく表示される() throws {
    // Given
    let view = StatsBarView(walk: mockWalk, isExpanded: .constant(true), onToggle: {}, onWalkDeleted: nil)

    // When & Then
    let durationText = try view.inspect().find(text: mockWalk.durationString)
    XCTAssertNotNil(durationText)
  }

  func test_StatsBarView_Walkデータを渡すと歩数が正しく表示される() throws {
    // Given
    let view = StatsBarView(walk: mockWalk, isExpanded: .constant(true), onToggle: {}, onWalkDeleted: nil)

    // When & Then
    let stepsText = try view.inspect().find(text: "2000歩")
    XCTAssertNotNil(stepsText)
  }
}
