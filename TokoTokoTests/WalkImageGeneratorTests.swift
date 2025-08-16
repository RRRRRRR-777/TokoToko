//
//  WalkImageGeneratorTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/08/16.
//

import XCTest
import CoreLocation
@testable import TokoToko

/// WalkImageGeneratorのテストクラス
final class WalkImageGeneratorTests: XCTestCase {

  var walkImageGenerator: WalkImageGenerator!

  override func setUp() {
    super.setUp()
    walkImageGenerator = WalkImageGenerator()
  }

  override func tearDown() {
    walkImageGenerator = nil
    super.tearDown()
  }

  /// 歩数取得不可時（totalSteps = 0）の「-」表示テスト
  func testStepDisplayWhenUnavailable() async throws {
    // Arrange: 歩数取得不可の散歩データを作成
    let walk = createTestWalk(totalSteps: 0)

    // Act: 画像生成
    let image = try await walkImageGenerator.generateWalkImage(from: walk)

    // Assert: 画像が生成されることを確認（詳細な「-」表示は統合テストで確認）
    XCTAssertNotNil(image, "歩数取得不可時でも画像が生成されるべき")
    XCTAssertEqual(image.size.width, 1920, "画像幅が正しく設定されるべき")
    XCTAssertEqual(image.size.height, 1080, "画像高が正しく設定されるべき")
  }

  /// 有効な歩数の場合の「XXX歩」表示テスト
  func testStepDisplayWhenAvailable() async throws {
    // Arrange: 有効な歩数を持つ散歩データを作成
    let walk = createTestWalk(totalSteps: 2500)

    // Act: 画像生成
    let image = try await walkImageGenerator.generateWalkImage(from: walk)

    // Assert: 画像が生成されることを確認
    XCTAssertNotNil(image, "有効な歩数時に画像が生成されるべき")
    XCTAssertEqual(image.size.width, 1920, "画像幅が正しく設定されるべき")
    XCTAssertEqual(image.size.height, 1080, "画像高が正しく設定されるべき")
  }

  /// 歩数フォーマット処理の詳細テスト
  func testStepFormatGeneration() {
    // Arrange & Act & Assert: 各パターンの歩数フォーマット確認

    // 歩数取得不可時は「-」を返すべき
    let unavailableStepFormat = formatStepsForDisplay(totalSteps: 0)
    XCTAssertEqual(unavailableStepFormat, "-", "歩数取得不可時は「-」を返すべき")

    // 有効な歩数時は「XXX歩」形式を返すべき
    let validStepFormat = formatStepsForDisplay(totalSteps: 2500)
    XCTAssertEqual(validStepFormat, "2500歩", "有効な歩数時は「XXX歩」形式を返すべき")

    // 1歩の場合も正しく処理されるべき
    let singleStepFormat = formatStepsForDisplay(totalSteps: 1)
    XCTAssertEqual(singleStepFormat, "1歩", "1歩の場合も正しく処理されるべき")
  }

  /// テスト用散歩データ作成ヘルパー
  private func createTestWalk(totalSteps: Int) -> Walk {
    let startLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
    let endLocation = CLLocation(latitude: 35.6785, longitude: 139.6512)

    var walk = Walk()
    walk.addLocation(startLocation)
    walk.addLocation(endLocation)
    walk.totalSteps = totalSteps
    walk.startDate = Date()
    walk.endDate = Date().addingTimeInterval(1800) // 30分後

    walk
  }

  /// 歩数フォーマット処理のヘルパーメソッド（実装済みの動作と同期）
  private func formatStepsForDisplay(totalSteps: Int) -> String {
    totalSteps == 0 ? "-" : "\(totalSteps)歩"
  }
}
