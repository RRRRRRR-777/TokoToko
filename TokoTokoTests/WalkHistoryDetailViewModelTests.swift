//
//  WalkHistoryDetailViewModelTests.swift
//  TokoTokoTests
//
//  Created by Claude Code on 2025/07/12.
//

import CoreLocation
import XCTest

@testable import TokoToko

final class WalkHistoryDetailViewModelTests: XCTestCase {

  var sut: WalkHistoryDetailViewModel!
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
          CLLocation(latitude: 35.6820, longitude: 139.7680),
          CLLocation(latitude: 35.6825, longitude: 139.7685),
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
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: initialIndex)
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
    XCTAssertThrowsError(try WalkHistoryDetailViewModel(walks: emptyWalks, initialIndex: 0)) {
      error in
      if let validationError = error as? WalkHistoryDetailViewModel.ValidationError {
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
      try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: invalidIndex)
    ) { error in
      if let validationError = error as? WalkHistoryDetailViewModel.ValidationError {
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
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: 0)
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
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: 1)
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
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: 1)
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
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: 0)
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
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    // Then
    XCTAssertTrue(sut.isStatsBarVisible)
  }

  func test_toggleStatsBar_呼ぶと表示状態が反転する() {
    // Given
    do {
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
    let initialState = sut.isStatsBarVisible

    // When
    sut.toggleStatsBar()

    // Then
    XCTAssertEqual(sut.isStatsBarVisible, !initialState)
  }

  // MARK: - 画像選択ロジックテスト

  func test_selectImage_画像インデックスが正しく設定される() {
    // Given
    do {
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    // When
    sut.selectImage(at: 2)

    // Then
    XCTAssertEqual(sut.selectedImageIndex, 2)
  }

  func test_deselectImage_画像選択が解除される() {
    // Given
    do {
      sut = try WalkHistoryDetailViewModel(walks: mockWalks, initialIndex: 0)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
    sut.selectImage(at: 1)

    // When
    sut.deselectImage()

    // Then
    XCTAssertNil(sut.selectedImageIndex)
  }
}
