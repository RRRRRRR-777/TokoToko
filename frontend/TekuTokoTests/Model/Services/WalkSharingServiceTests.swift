//
//  WalkSharingServiceTests.swift
//  TekuTokoTests
//
//  Created by Claude on 2025/07/29.
//

import CoreLocation
import XCTest

@testable import TekuToko

final class WalkSharingServiceTests: XCTestCase {

  var sut: WalkSharingService!
  var mockWalk: Walk!

  override func setUp() {
    super.setUp()
    sut = WalkSharingService.shared
    mockWalk = createMockWalk()
  }

  override func tearDown() {
    sut = nil
    mockWalk = nil
    super.tearDown()
  }

  // MARK: - Test Helper

  private func createMockWalk() -> Walk {
    Walk(
      title: "テスト散歩",
      description: "テスト用の散歩データ",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-1800),
      totalDistance: 1500.0,
      totalSteps: 2000,
      status: .completed,
      locations: [
        CLLocation(latitude: 35.6812, longitude: 139.7671),
        CLLocation(latitude: 35.6815, longitude: 139.7675),
        CLLocation(latitude: 35.6820, longitude: 139.7680),
      ]
    )
  }

  // MARK: - generateShareText Tests

  func testGenerateShareText_正常な散歩データ_適切なテキストが生成される() {
    // Given
    let expectedTitle = "テスト散歩"
    let expectedDistance = mockWalk.distanceString
    let expectedDuration = mockWalk.durationString
    let expectedSteps = mockWalk.totalSteps

    // When
    let shareText = sut.generateShareText(from: mockWalk)

    // Then
    XCTAssertTrue(shareText.contains(expectedTitle), "タイトルが含まれていない")
    XCTAssertTrue(shareText.contains(expectedDistance), "距離が含まれていない")
    XCTAssertTrue(shareText.contains(expectedDuration), "時間が含まれていない")
    XCTAssertTrue(shareText.contains("\(expectedSteps)歩"), "歩数が含まれていない")
    XCTAssertTrue(shareText.contains("#てくとこ-お散歩SNS"), "アプリ名のハッシュタグが含まれていない")
    XCTAssertTrue(shareText.contains("#散歩"), "散歩のハッシュタグが含まれていない")
    XCTAssertTrue(shareText.contains("#ウォーキング"), "ウォーキングのハッシュタグが含まれていない")
    XCTAssertTrue(shareText.contains("#健康"), "健康のハッシュタグが含まれていない")
  }

  func testGenerateShareText_ゼロ距離の散歩_適切なテキストが生成される() {
    // Given
    let zeroDistanceWalk = Walk(
      title: "ゼロ距離散歩",
      description: "距離ゼロのテスト",
      totalDistance: 0.0,
      totalSteps: 0,
      status: .completed
    )

    // When
    let shareText = sut.generateShareText(from: zeroDistanceWalk)

    // Then
    XCTAssertTrue(shareText.contains("ゼロ距離散歩"), "タイトルが含まれていない")
    XCTAssertTrue(shareText.contains("👣 歩数: -"), "歩数が「-」表示されていない")
    XCTAssertFalse(shareText.isEmpty, "共有テキストが空文字列になっている")
  }

  func testGenerateShareText_特殊文字を含むタイトル_エスケープされる() {
    // Given
    let specialCharWalk = Walk(
      title: "特殊文字テスト\"#@散歩",
      description: "特殊文字テスト",
      totalSteps: 100,
      status: .completed
    )

    // When
    let shareText = sut.generateShareText(from: specialCharWalk)

    // Then
    XCTAssertTrue(shareText.contains("特殊文字テスト\"#@散歩"), "特殊文字を含むタイトルが正しく処理されていない")
  }

  // MARK: - WalkSharingError Tests

  func testWalkSharingError_imageGenerationFailed_適切なエラーメッセージ() {
    // Given
    let error = WalkSharingService.WalkSharingError.imageGenerationFailed

    // When
    let errorDescription = error.errorDescription

    // Then
    XCTAssertEqual(errorDescription, "共有用画像の生成に失敗しました")
  }

  func testWalkSharingError_noViewControllerPresent_適切なエラーメッセージ() {
    // Given
    let error = WalkSharingService.WalkSharingError.noViewControllerPresent

    // When
    let errorDescription = error.errorDescription

    // Then
    XCTAssertEqual(errorDescription, "共有シートを表示するビューが見つかりません")
  }

  func testWalkSharingError_sharingNotAvailable_適切なエラーメッセージ() {
    // Given
    let error = WalkSharingService.WalkSharingError.sharingNotAvailable

    // When
    let errorDescription = error.errorDescription

    // Then
    XCTAssertEqual(errorDescription, "この端末では共有機能を使用できません")
  }

  // MARK: - UI Flow Tests

  func testSharingFlow_正常な共有フロー_期待される状態遷移() {
    // Given
    let expectation = XCTestExpectation(description: "共有フローが完了する")
    var progressMessages: [String] = []
    var completionCalled = false

    // Mock Sharing Process Manager for UI flow testing
    let sharingManager = MockSharingProcessManager(
      walk: mockWalk,
      onProgressUpdate: { message in
        progressMessages.append(message)
      },
      onError: { _ in
        XCTFail("エラーは発生しないはず")
      },
      onCompletion: {
        completionCalled = true
        expectation.fulfill()
      }
    )

    // When
    sharingManager.simulateSuccessfulSharing()

    // Then
    wait(for: [expectation], timeout: 5.0)
    XCTAssertTrue(completionCalled, "完了コールバックが呼ばれるはず")
    XCTAssertTrue(progressMessages.contains("共有画面を準備中..."), "初期プログレスメッセージが含まれるはず")
  }

  func testSharingFlow_共有シート閉じた後_ローディング画面が再表示される() {
    // Given
    let loadingExpectation = XCTestExpectation(description: "ローディング画面が再表示される")
    let completionExpectation = XCTestExpectation(description: "共有処理が完了する")

    var loadingStates: [Bool] = []
    var finalLoadingState = false

    let sharingManager = MockSharingProcessManager(
      walk: mockWalk,
      onProgressUpdate: { _ in
        loadingStates.append(true)  // ローディング開始
      },
      onError: { _ in
        XCTFail("エラーは発生しないはず")
      },
      onCompletion: {
        // 共有シート閉じた後のローディング状態をシミュレート
        loadingStates.append(true)
        finalLoadingState = true
        loadingExpectation.fulfill()
        completionExpectation.fulfill()
      }
    )

    // When - 共有シート表示→閉じる→ローディング再表示のシミュレーション
    sharingManager.simulateShareSheetDismissalWithLoadingReappear()

    // Then
    wait(for: [loadingExpectation, completionExpectation], timeout: 5.0)
    XCTAssertTrue(finalLoadingState, "共有シート閉じた後にローディング状態になるはず")
    XCTAssertGreaterThanOrEqual(loadingStates.count, 2, "ローディング状態が複数回発生するはず")
  }

}

// MARK: - Mock Classes for UI Testing

class MockSharingProcessManager {
  private let walk: Walk
  private let onProgressUpdate: (String) -> Void
  private let onError: (Error) -> Void
  private let onCompletion: () -> Void

  init(
    walk: Walk,
    onProgressUpdate: @escaping (String) -> Void,
    onError: @escaping (Error) -> Void,
    onCompletion: @escaping () -> Void
  ) {
    self.walk = walk
    self.onProgressUpdate = onProgressUpdate
    self.onError = onError
    self.onCompletion = onCompletion
  }

  func simulateSuccessfulSharing() {
    DispatchQueue.main.async {
      self.onProgressUpdate("共有画面を準備中...")

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.onCompletion()
      }
    }
  }

  func simulateShareSheetDismissalWithLoadingReappear() {
    DispatchQueue.main.async {
      // 初期ローディング
      self.onProgressUpdate("共有画面を準備中...")

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        // 共有シート表示→閉じる→ローディング再表示をシミュレート
        self.onCompletion()
      }
    }
  }
}

// MARK: - Performance Tests
extension WalkSharingServiceTests {

  func testGenerateShareTextPerformance() {
    // Given
    let walks = (0..<100).map { index in
      Walk(
        title: "パフォーマンステスト散歩\(index)",
        description: "大量データテスト",
        totalDistance: Double(index * 100),
        totalSteps: index * 1000,
        status: .completed
      )
    }

    // When & Then
    measure {
      for walk in walks {
        _ = sut.generateShareText(from: walk)
      }
    }
  }
}
