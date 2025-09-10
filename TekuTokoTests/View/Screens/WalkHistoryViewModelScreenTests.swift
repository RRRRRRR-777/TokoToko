//
//  WalkHistoryViewModelScreenTests.swift
//  TokoTokoTests
//
//  Created by Claude Code on 2025/07/12.
//

import CoreLocation
import XCTest

@testable import TekuToko

final class WalkHistoryViewModelScreenTests: XCTestCase {

  var sut: WalkHistoryViewModel!
  var mockWalks: [Walk]!

  override func setUp() {
    super.setUp()
    setupMockWalks()
  }

  override func tearDown() {
    sut = nil
    mockWalks = nil
    super.tearDown()
  }

  private func setupMockWalks() {
    mockWalks = [
      Walk(
        title: "朝の散歩",
        description: "公園を歩きました",
        id: UUID(),
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 1200,
        totalSteps: 1500,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6812, longitude: 139.7671),
          CLLocation(latitude: 35.6815, longitude: 139.7675),
          CLLocation(latitude: 35.6820, longitude: 139.7680),
          CLLocation(latitude: 35.6825, longitude: 139.7690),
        ]
      ),
      Walk(
        title: "夕方の散歩",
        description: "川沿いを歩きました",
        id: UUID(),
        startTime: Date().addingTimeInterval(-7200),
        endTime: Date().addingTimeInterval(-6600),
        totalDistance: 800,
        totalSteps: 1000,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6700, longitude: 139.7500),
          CLLocation(latitude: 35.6720, longitude: 139.7520),
          CLLocation(latitude: 35.6740, longitude: 139.7540),
          CLLocation(latitude: 35.6760, longitude: 139.7560),
          CLLocation(latitude: 35.6780, longitude: 139.7580),
        ]
      ),
    ]
  }

  // MARK: - Red: 失敗するテスト（TDD手法における初期失敗テスト）

  func test_初期化時_Walk配列と初期インデックスを渡すと_currentWalkが正しく設定される() {
    // Given
    let initialIndex = 0

    // When
    do {
      sut = try WalkHistoryViewModel(walks: mockWalks, initialIndex: initialIndex)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    // Then
    XCTAssertEqual(sut.currentWalk.id, mockWalks[0].id)
    XCTAssertEqual(sut.currentWalk.title, "朝の散歩")
  }

  func test_初期化時_空のWalk配列を渡すと_エラーハンドリングされる() {
    // Given
    let emptyWalks: [Walk] = []

    // When & Then
    XCTAssertThrowsError(try WalkHistoryViewModel(walks: emptyWalks, initialIndex: 0)) {
      error in
      if let validationError = error as? WalkHistoryViewModel.ValidationError {
        XCTAssertEqual(validationError, .emptyWalksArray)
      } else {
        XCTFail("Expected ValidationError, got \(error)")
      }
    }
  }

  func test_初期化時_範囲外のインデックスを渡すと_エラーハンドリングされる() {
    // Given
    let invalidIndex = 5

    // When & Then
    XCTAssertThrowsError(
      try WalkHistoryViewModel(walks: mockWalks, initialIndex: invalidIndex)
    ) { error in
      if let validationError = error as? WalkHistoryViewModel.ValidationError {
        XCTAssertEqual(validationError, .invalidIndex)
      } else {
        XCTFail("Expected ValidationError, got \(error)")
      }
    }
  }

  // MARK: - 散歩履歴切り替えテスト

  func test_selectNextWalk_次の散歩に切り替わる() {
    // Given
    do {
      sut = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    // When
    sut.selectNextWalk()

    // Then
    XCTAssertEqual(sut.currentWalk.id, mockWalks[1].id)
    XCTAssertEqual(sut.currentWalk.title, "夕方の散歩")
  }

  func test_selectNextWalk_最後の散歩で呼ぶと最初の散歩に戻る() {
    // Given
    do {
      sut = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 1)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    // When
    sut.selectNextWalk()

    // Then
    XCTAssertEqual(sut.currentWalk.id, mockWalks[0].id)
    XCTAssertEqual(sut.currentWalk.title, "朝の散歩")
  }

  func test_selectPreviousWalk_前の散歩に切り替わる() {
    // Given
    do {
      sut = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 1)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    // When
    sut.selectPreviousWalk()

    // Then
    XCTAssertEqual(sut.currentWalk.id, mockWalks[0].id)
    XCTAssertEqual(sut.currentWalk.title, "朝の散歩")
  }

  func test_selectPreviousWalk_最初の散歩で呼ぶと最後の散歩に戻る() {
    // Given
    do {
      sut = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    // When
    sut.selectPreviousWalk()

    // Then
    XCTAssertEqual(sut.currentWalk.id, mockWalks[1].id)
    XCTAssertEqual(sut.currentWalk.title, "夕方の散歩")
  }

  // MARK: - 統計情報バー表示制御テスト

  func test_toggleStatsBar_初期値はtrue() {
    // Given
    do {
      sut = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    // Then
    XCTAssertTrue(sut.isStatsBarVisible)
  }

  func test_toggleStatsBar_呼ぶと表示状態が反転する() {
    // Given
    do {
      sut = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
    let initialState = sut.isStatsBarVisible

    // When
    sut.toggleStatsBar()

    // Then
    XCTAssertEqual(sut.isStatsBarVisible, !initialState)
  }
}
