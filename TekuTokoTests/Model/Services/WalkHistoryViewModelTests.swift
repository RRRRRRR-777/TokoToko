//
//  WalkHistoryViewModelTests.swift
//  TokoTokoTests
//
//  Created by Claude Code on 2025/07/21.
//

import CoreLocation
import XCTest
@testable import TekuToko

final class WalkHistoryViewModelTests: XCTestCase {
  
  var viewModel: WalkHistoryViewModel!
  var mockWalks: [Walk]!
  
  override func setUp() {
    super.setUp()
    mockWalks = createMockWalks()
  }
  
  override func tearDown() {
    viewModel = nil
    mockWalks = nil
    super.tearDown()
  }
  
  // MARK: - Test Helper Methods
  
  private func createMockWalks() -> [Walk] {
    return [
      Walk(
        title: "最新の散歩",
        description: "今日の散歩",
        id: UUID(),
        startTime: Date(),
        endTime: Date().addingTimeInterval(1800),
        totalDistance: 1000,
        totalSteps: 1200,
        status: .completed,
        locations: [CLLocation(latitude: 35.6812, longitude: 139.7671)]
      ),
      Walk(
        title: "昨日の散歩", 
        description: "昨日の散歩",
        id: UUID(),
        startTime: Date().addingTimeInterval(-86400),
        endTime: Date().addingTimeInterval(-84600),
        totalDistance: 800,
        totalSteps: 1000,
        status: .completed,
        locations: [CLLocation(latitude: 35.6815, longitude: 139.7675)]
      ),
      Walk(
        title: "一昨日の散歩",
        description: "一昨日の散歩", 
        id: UUID(),
        startTime: Date().addingTimeInterval(-172800),
        endTime: Date().addingTimeInterval(-171000),
        totalDistance: 1200,
        totalSteps: 1500,
        status: .completed,
        locations: [CLLocation(latitude: 35.6818, longitude: 139.7680)]
      )
    ]
  }
  
  // MARK: - Delete Logic Tests
  
  func testRemoveWalk_deletesCurrentWalk_movesToNewerWalk() throws {
    // Given: 3つの散歩があり、真ん中の散歩を選択
    viewModel = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 1)
    let currentWalkId = viewModel.currentWalk.id
    
    // When: 現在の散歩を削除
    let hasRemainingWalks = viewModel.removeWalk(withId: currentWalkId)
    
    // Then: より新しい散歩（インデックス0）に遷移
    XCTAssertTrue(hasRemainingWalks, "他の散歩が残っているはず")
    XCTAssertEqual(viewModel.currentWalk.title, "最新の散歩", "より新しい散歩に遷移するはず")
    XCTAssertEqual(viewModel.walkCount, 2, "散歩数が1つ減るはず")
  }
  
  func testRemoveWalk_deletesNewestWalk_staysAtSameIndex() throws {
    // Given: 最新の散歩を選択
    viewModel = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 0)
    let currentWalkId = viewModel.currentWalk.id
    
    // When: 最新の散歩を削除
    let hasRemainingWalks = viewModel.removeWalk(withId: currentWalkId)
    
    // Then: 次に新しい散歩に遷移
    XCTAssertTrue(hasRemainingWalks, "他の散歩が残っているはず")
    XCTAssertEqual(viewModel.currentWalk.title, "昨日の散歩", "次に新しい散歩に遷移するはず")
    XCTAssertEqual(viewModel.walkCount, 2, "散歩数が1つ減るはず")
  }
  
  func testRemoveWalk_deletesOldestWalk_staysAtSameWalk() throws {
    // Given: 最古の散歩を選択
    viewModel = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 2)
    let oldestWalkId = mockWalks[2].id
    
    // When: 最古の散歩を削除
    let hasRemainingWalks = viewModel.removeWalk(withId: oldestWalkId)
    
    // Then: 現在の散歩は変わらない
    XCTAssertTrue(hasRemainingWalks, "他の散歩が残っているはず")
    XCTAssertEqual(viewModel.currentWalk.title, "昨日の散歩", "現在の散歩は変わらないはず")
    XCTAssertEqual(viewModel.walkCount, 2, "散歩数が1つ減るはず")
  }
  
  func testRemoveWalk_deletesAllWalks_returnsEmptyState() throws {
    // Given: 1つだけの散歩
    let singleWalk = [mockWalks[0]]
    viewModel = try WalkHistoryViewModel(walks: singleWalk, initialIndex: 0)
    let walkId = viewModel.currentWalk.id
    
    // When: 最後の散歩を削除
    let hasRemainingWalks = viewModel.removeWalk(withId: walkId)
    
    // Then: 散歩がなくなったことを示す
    XCTAssertFalse(hasRemainingWalks, "散歩がなくなったのでfalseを返すはず")
    XCTAssertEqual(viewModel.walkCount, 0, "散歩数が0になるはず")
  }
  
  func testRemoveWalk_nonExistentWalk_returnsFailure() throws {
    // Given: 3つの散歩がある
    viewModel = try WalkHistoryViewModel(walks: mockWalks, initialIndex: 1)
    let nonExistentWalkId = UUID()
    let originalWalkCount = viewModel.walkCount
    
    // When: 存在しない散歩IDで削除を試行
    let hasRemainingWalks = viewModel.removeWalk(withId: nonExistentWalkId)
    
    // Then: 削除は失敗し、何も変わらない
    XCTAssertFalse(hasRemainingWalks, "存在しない散歩なので削除失敗")
    XCTAssertEqual(viewModel.walkCount, originalWalkCount, "散歩数は変わらないはず")
  }
  
  func testRemoveWalk_twoWalks_movesCorrectly() throws {
    // Given: 2つの散歩があり、古い方を選択
    let twoWalks = Array(mockWalks.prefix(2))
    viewModel = try WalkHistoryViewModel(walks: twoWalks, initialIndex: 1)
    let currentWalkId = viewModel.currentWalk.id
    
    // When: 古い散歩を削除
    let hasRemainingWalks = viewModel.removeWalk(withId: currentWalkId)
    
    // Then: 新しい散歩に遷移
    XCTAssertTrue(hasRemainingWalks, "他の散歩が残っているはず")
    XCTAssertEqual(viewModel.currentWalk.title, "最新の散歩", "残った散歩に遷移するはず")
    XCTAssertEqual(viewModel.walkCount, 1, "散歩数が1つになるはず")
  }
}
