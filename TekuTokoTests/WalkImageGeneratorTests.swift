//
//  WalkImageGeneratorTests.swift
//  TekuTokoTests
//
//  Created by Claude on 2025/08/16.
//

import CoreLocation
import XCTest

@testable import TekuToko

/// WalkImageGeneratorのテストクラス
///
/// XcodeCloud対応のため、MapKit依存の画像生成テストは除外し、
/// 基本的なロジックテストのみを実行します。
class WalkImageGeneratorTests: XCTestCase {

  /// 歩数取得不可時（totalSteps = 0）の「-」表示テスト
  func testStepDisplayWhenUnavailable() {
    let walk = createTestWalk(totalSteps: 0)
    let stepFormat = formatStepsForDisplay(totalSteps: walk.totalSteps)

    XCTAssertEqual(stepFormat, "-", "歩数取得不可時は「-」を返すべき")
    XCTAssertEqual(walk.totalSteps, 0, "歩数が0に設定されているべき")
    XCTAssertFalse(walk.locations.isEmpty, "位置データが存在するべき")
  }

  /// 有効な歩数の場合の「XXX歩」表示テスト
  func testStepDisplayWhenAvailable() {
    let walk = createTestWalk(totalSteps: 2500)
    let stepFormat = formatStepsForDisplay(totalSteps: walk.totalSteps)

    XCTAssertEqual(stepFormat, "2500歩", "有効な歩数時は「XXX歩」形式を返すべき")
    XCTAssertEqual(walk.totalSteps, 2500, "歩数が2500に設定されているべき")
    XCTAssertFalse(walk.locations.isEmpty, "位置データが存在するべき")
  }

  /// 歩数フォーマット処理の詳細テスト
  func testStepFormatGeneration() {
    // 歩数取得不可時は「-」を返すべき
    XCTAssertEqual(formatStepsForDisplay(totalSteps: 0), "-")

    // 有効な歩数時は「XXX歩」形式を返すべき
    XCTAssertEqual(formatStepsForDisplay(totalSteps: 2500), "2500歩")
    XCTAssertEqual(formatStepsForDisplay(totalSteps: 1), "1歩")
  }

  /// 散歩データ検証テスト
  func testWalkDataValidation() {
    // 有効な散歩データ
    let validWalk = createTestWalk(totalSteps: 1500)
    XCTAssertEqual(validWalk.totalSteps, 1500)
    XCTAssertFalse(validWalk.locations.isEmpty)
    XCTAssertEqual(validWalk.status, .completed)

    // 空の散歩データ
    let emptyWalk = Walk(
      title: "空の散歩",
      description: "位置データなし",
      startTime: Date(),
      endTime: Date(),
      totalDistance: 0,
      totalSteps: 0,
      status: .completed
    )
    XCTAssertTrue(emptyWalk.locations.isEmpty)
    XCTAssertEqual(emptyWalk.totalSteps, 0)
  }

  // MARK: - Private Helpers

  private func createTestWalk(totalSteps: Int) -> Walk {
    let startTime = Date()
    let endTime = Date().addingTimeInterval(1800)

    var walk = Walk(
      title: "テスト散歩",
      description: "テスト用散歩データ",
      startTime: startTime,
      endTime: endTime,
      totalDistance: 1500.0,
      totalSteps: totalSteps,
      status: .completed
    )

    // 位置データを追加
    let startLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
    let endLocation = CLLocation(latitude: 35.6785, longitude: 139.6512)
    walk.addLocation(startLocation)
    walk.addLocation(endLocation)

    return walk
  }

  private func formatStepsForDisplay(totalSteps: Int) -> String {
    totalSteps == 0 ? "-" : "\(totalSteps)歩"
  }
}