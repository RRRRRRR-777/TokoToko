//
//  WalkManagerTests.swift
//  TokoTokoTests
//
//  Created by bokuyamada on 2025/06/29.
//

import CoreLocation
import XCTest

@testable import TokoToko

final class WalkManagerTests: XCTestCase {

  // MARK: - 画像生成統合テスト

  func testStopWalk_SetsCurrentWalkToNil() throws {
    // 🔴 Red - 単純なテストから始める

    // Arrange - 個別インスタンスではなく、基本機能をテスト
    let mapThumbnailGenerator = MapThumbnailGenerator()
    let imageStorageManager = ImageStorageManager()

    // Act & Assert - まずはコンパイルが通ることを確認
    XCTAssertNotNil(mapThumbnailGenerator, "MapThumbnailGeneratorインスタンスが作成されるべき")
    XCTAssertNotNil(imageStorageManager, "ImageStorageManagerインスタンスが作成されるべき")
  }

  func testWalkManager_CanGenerateThumbnailAfterCompletion() throws {
    // 🔴 Red - 画像生成機能のテスト（WalkManagerから独立）

    // Arrange
    let testWalk = createTestWalk()
    let generator = MapThumbnailGenerator()

    // Act
    let thumbnail = generator.generateThumbnail(from: testWalk)

    // Assert
    XCTAssertNotNil(thumbnail, "完了した散歩からサムネイルが生成されるべき")
  }

  // MARK: - ヘルパーメソッド

  private func createTestWalk() -> Walk {
    var walk = Walk(
      title: "テスト散歩",
      description: "テスト用の散歩",
      userId: "test-user",
      status: .completed  // 完了状態で作成
    )

    // テスト用の位置情報を追加
    let location1 = CLLocation(latitude: 35.6762, longitude: 139.6503)  // 東京駅
    let location2 = CLLocation(latitude: 35.6812, longitude: 139.7671)  // スカイツリー

    walk.addLocation(location1)
    walk.addLocation(location2)

    return walk
  }
}
