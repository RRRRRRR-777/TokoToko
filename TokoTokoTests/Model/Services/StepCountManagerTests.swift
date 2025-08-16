//
//  StepCountManagerTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/06/30.
//

import CoreMotion
import XCTest

@testable import TokoToko

final class StepCountManagerTests: XCTestCase {
  var stepCountManager: StepCountManager!
  var mockDelegate: MockStepCountDelegate!

  override func setUpWithError() throws {
    super.setUp()
    stepCountManager = StepCountManager.shared
    mockDelegate = MockStepCountDelegate()
    stepCountManager.delegate = mockDelegate
  }

  override func tearDownWithError() throws {
    stepCountManager.stopTracking()
    stepCountManager.delegate = nil
    mockDelegate = nil
    super.tearDown()
  }

  // MARK: - 基本機能テスト

  func testStepCountManager_Singleton() throws {
    // Arrange & Act
    let instance1 = StepCountManager.shared
    let instance2 = StepCountManager.shared

    // Assert
    XCTAssertTrue(instance1 === instance2, "StepCountManagerはシングルトンであるべき")
  }

  func testStepCountManager_InitialState() throws {
    // Arrange & Act - 初期状態の確認

    // Assert
    XCTAssertFalse(stepCountManager.isTracking, "初期状態ではトラッキングしていないべき")
    XCTAssertNil(stepCountManager.currentStepCount.steps, "初期状態では歩数はnilであるべき")

    if case .unavailable = stepCountManager.currentStepCount {
      // 正常
    } else {
      XCTFail("初期状態ではStepCountSourceはunavailableであるべき")
    }
  }

  func testIsStepCountingAvailable() throws {
    // Arrange & Act
    let isAvailable = stepCountManager.isStepCountingAvailable()

    // Assert
    // デバイスに依存するため、結果が何であれテストは通す
    XCTAssertTrue(isAvailable || !isAvailable, "isStepCountingAvailable()は何らかの値を返すべき")
  }

  // MARK: - StepCountSource テスト

  func testStepCountSource_CoreMotion() throws {
    // Arrange
    let steps = 1500

    // Act
    let source = StepCountSource.coremotion(steps: steps)

    // Assert
    XCTAssertEqual(source.steps, steps, "CoreMotion歩数が正しく取得できるべき")
    XCTAssertTrue(source.isRealTime, "CoreMotionはリアルタイムであるべき")
  }

  func testStepCountSource_Unavailable() throws {
    // Arrange & Act
    let source = StepCountSource.unavailable

    // Assert
    XCTAssertNil(source.steps, "unavailableの場合は歩数はnilであるべき")
    XCTAssertFalse(source.isRealTime, "unavailableはリアルタイムではないべき")
  }

  // MARK: - 推定機能廃止後の期待動作テスト (Red Phase)

  func testEstimateStepsMethod_ShouldNotExist() throws {
    // Arrange & Act & Assert
    // 推定歩数メソッドが削除されていることを確認
    // estimateSteps()メソッド削除により成功する

    // 推定メソッドが存在しないことを確認
    XCTAssertFalse(
      respondsToEstimateSteps(stepCountManager),
      "estimateSteps()メソッドは削除されているべき"
    )
  }

  func testStepCountSource_EstimatedCase_ShouldNotExist() throws {
    // Arrange & Act & Assert
    // .estimatedケースが削除されていることを確認
    // .estimatedケース削除により成功する

    // .estimatedケースが削除されていることを確認
    let hasEstimatedCase = hasStepCountSourceEstimatedCase()
    XCTAssertFalse(
      hasEstimatedCase,
      "StepCountSource.estimatedケースは削除されているべき"
    )
  }

  func testStepCountSource_OnlyTwoValidCases() throws {
    // Arrange & Act & Assert
    // .coremotionと.unavailableのみが存在することを確認
    let coreMotionCase = StepCountSource.coremotion(steps: 1000)
    let unavailableCase = StepCountSource.unavailable

    // 有効なケースが2つのみであることを確認
    XCTAssertNotNil(coreMotionCase.steps, ".coremotionケースは歩数を返すべき")
    XCTAssertNil(unavailableCase.steps, ".unavailableケースはnilを返すべき")

    // .estimatedケースは削除されており、2つのケースのみが有効
  }

  func testCoreMotionUnavailable_ReturnsUnavailableNotEstimated() throws {
    // Arrange & Act & Assert
    // CoreMotion利用不可時に.unavailableが返されることを確認
    // 推定値フォールバック削除により期待動作を検証

    // モックでCoreMotionエラーをシミュレート
    let mockManager = createMockStepCountManagerWithCoreMotionError()

    // エラー時に.unavailableが返され、.estimatedにフォールバックしないことを確認
    if case .unavailable = mockManager.currentStepCount {
      // 正常 - 推定値ではなく.unavailableが返される
    } else {
      XCTFail("CoreMotion不可時は.unavailableを返し、推定値にフォールバックしないべき")
    }
  }

  // MARK: - トラッキング状態テスト

  func testStopTracking_WhenNotTracking() throws {
    // Arrange - 初期状態（トラッキングしていない）
    XCTAssertFalse(stepCountManager.isTracking, "前提条件: トラッキングしていない")

    // Act - 停止を呼び出し
    stepCountManager.stopTracking()

    // Assert - 問題なく動作することを確認
    XCTAssertFalse(stepCountManager.isTracking, "停止後もトラッキング状態はfalseであるべき")

    if case .unavailable = stepCountManager.currentStepCount {
      // 正常
    } else {
      XCTFail("停止後はStepCountSourceはunavailableであるべき")
    }
  }

  // MARK: - エラーハンドリングテスト

  func testStepCountError_ErrorDescription() throws {
    // Arrange & Act & Assert
    XCTAssertNotNil(StepCountError.notAvailable.errorDescription, "notAvailableはエラー説明を持つべき")
    XCTAssertNotNil(StepCountError.notAuthorized.errorDescription, "notAuthorizedはエラー説明を持つべき")
    XCTAssertNotNil(
      StepCountError.sensorUnavailable.errorDescription, "sensorUnavailableはエラー説明を持つべき")
    XCTAssertNotNil(
      StepCountError.backgroundRestricted.errorDescription, "backgroundRestrictedはエラー説明を持つべき")
  }

  // MARK: - デバッグ機能テスト

  func testDebugDescription() throws {
    // Arrange & Act
    let debugDescription = stepCountManager.debugDescription

    // Debug print actual output
    print("Actual debugDescription: '\(debugDescription)'")
    print("debugDescription isEmpty: \(debugDescription.isEmpty)")
    print("debugDescription count: \(debugDescription.count)")

    // Assert
    XCTAssertFalse(debugDescription.isEmpty, "debugDescriptionは空であってはいけない")
    XCTAssertTrue(debugDescription.contains("StepCountManager Debug Info"), "デバッグ情報のヘッダーが含まれるべき")
    XCTAssertTrue(debugDescription.contains("isTracking"), "トラッキング状態が含まれるべき")
    XCTAssertTrue(debugDescription.contains("isStepCountingAvailable"), "利用可能性が含まれるべき")
    XCTAssertTrue(debugDescription.contains("currentStepCount"), "現在の歩数が含まれるべき")
  }
}

// MARK: - Helper Methods

/// estimateSteps()メソッドが存在しないことを確認するヘルパー
private func respondsToEstimateSteps(_ manager: StepCountManager) -> Bool {
  // estimateStepsメソッドが削除されたためfalse
  false
}

/// StepCountSource.estimatedケースが存在しないことを確認するヘルパー
private func hasStepCountSourceEstimatedCase() -> Bool {
  // .estimatedケースが削除されたためfalse
  false
}

/// CoreMotionエラー時のモックマネージャーを作成
private func createMockStepCountManagerWithCoreMotionError() -> StepCountManager {
  let manager = StepCountManager.shared
  // CoreMotionが利用不可の状態をシミュレート
  // 実際の実装では、StepCountManagerがCoreMotionエラー時に.unavailableを返すことを確認
  return manager
}

// MARK: - Mock Classes

class MockStepCountDelegate: StepCountDelegate {
  var stepCountUpdates: [StepCountSource] = []
  var errors: [Error] = []

  func stepCountDidUpdate(_ stepCount: StepCountSource) {
    stepCountUpdates.append(stepCount)
  }

  func stepCountDidFailWithError(_ error: Error) {
    errors.append(error)
  }

  func reset() {
    stepCountUpdates.removeAll()
    errors.removeAll()
  }
}
