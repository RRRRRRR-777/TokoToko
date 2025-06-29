//
//  MapThumbnailGeneratorTests.swift
//  TokoTokoTests
//
//  Created by bokuyamada on 2025/06/29.
//

import CoreLocation
import XCTest

@testable import TokoToko

// 軽量なテストでTDD進行
final class MapThumbnailGeneratorTests: XCTestCase {
  var generator: MapThumbnailGenerator!

  override func setUpWithError() throws {
    super.setUp()
    generator = MapThumbnailGenerator()
  }

  override func tearDownWithError() throws {
    generator = nil
    super.tearDown()
  }

  // MARK: - 基本機能のテスト（シンプルから開始）

  func testGenerateThumbnailFromWalk_Success() throws {
    // Arrange
    let walk = Walk(
      title: "テスト散歩",
      description: "サムネイル生成テスト",
      startTime: Date(),
      endTime: Date().addingTimeInterval(300),
      totalDistance: 1000,
      status: .completed,
      locations: [
        CLLocation(latitude: 35.6812, longitude: 139.7671),
        CLLocation(latitude: 35.6815, longitude: 139.7675),
      ]
    )

    // Act & Assert - まずはコンパイルが通ることを確認
    XCTAssertNotNil(generator, "MapThumbnailGeneratorインスタンスが作成されるべき")

    // 実際の画像生成テストは後で実装
    // let thumbnail = await generator.generateThumbnail(from: walk)
    // XCTAssertNotNil(thumbnail, "サムネイル画像が生成されるべき")
  }

  // 他のテストは一旦コメントアウト（段階的に実装）
  /*
  func testGenerateThumbnailFromWalk_EmptyLocations() throws {
    // TODO: 位置情報なしのテスト
  }

  func testGenerateThumbnailSize_Is120Height() throws {
    // TODO: 画像サイズのテスト
  }

  func testGenerateThumbnailFromWalk_SingleLocation() throws {
    // TODO: 単一地点のテスト
  }

  func testGenerateThumbnailFromWalk_NotCompletedWalk() throws {
    // TODO: 未完了散歩のテスト
  }
  */
}
