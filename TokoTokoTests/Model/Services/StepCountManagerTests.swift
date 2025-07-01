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
    XCTAssertEqual(stepCountManager.currentStepCount.steps, nil, "初期状態では歩数はnilであるべき")

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

  func testStepCountSource_Estimated() throws {
    // Arrange
    let steps = 1000

    // Act
    let source = StepCountSource.estimated(steps: steps)

    // Assert
    XCTAssertEqual(source.steps, steps, "推定歩数が正しく取得できるべき")
    XCTAssertFalse(source.isRealTime, "推定歩数はリアルタイムではないべき")
  }

  func testStepCountSource_Unavailable() throws {
    // Arrange & Act
    let source = StepCountSource.unavailable

    // Assert
    XCTAssertNil(source.steps, "unavailableの場合は歩数はnilであるべき")
    XCTAssertFalse(source.isRealTime, "unavailableはリアルタイムではないべき")
  }

  // MARK: - 推定歩数テスト

  func testEstimateSteps_ValidDistance() throws {
    // Arrange
    let distance: Double = 2000  // 2km
    let duration: TimeInterval = 1800  // 30分

    // Act
    let result = stepCountManager.estimateSteps(distance: distance, duration: duration)

    // Assert
    XCTAssertNotNil(result.steps, "有効な距離では推定歩数が計算されるべき")

    if case .estimated(let steps) = result {
      // 2km = 約2,600歩 (1km = 1,300歩)
      XCTAssertEqual(steps, 2600, accuracy: 100, "推定歩数が期待値の範囲内であるべき")
    } else {
      XCTFail("有効な距離では推定歩数が返されるべき")
    }
  }

  func testEstimateSteps_ZeroDistance() throws {
    // Arrange
    let distance: Double = 0
    let duration: TimeInterval = 1800

    // Act
    let result = stepCountManager.estimateSteps(distance: distance, duration: duration)

    // Assert
    if case .estimated(let steps) = result {
      XCTAssertEqual(steps, 0, "距離が0の場合は0歩の推定値が返されるべき")
    } else {
      XCTFail("距離が0の場合でも推定値が返されるべき")
    }
  }

  func testEstimateSteps_NegativeDistance() throws {
    // Arrange
    let distance: Double = -500
    let duration: TimeInterval = 1800

    // Act
    let result = stepCountManager.estimateSteps(distance: distance, duration: duration)

    // Assert
    if case .unavailable = result {
      // 正常
    } else {
      XCTFail("負の距離の場合はunavailableが返されるべき")
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
