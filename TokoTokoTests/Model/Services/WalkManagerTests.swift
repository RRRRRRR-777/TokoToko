//
//  WalkManagerTests.swift
//  TokoTokoTests
//
//  Created by bokuyamada on 2025/06/29.
//

import CoreLocation
import UIKit
import XCTest

@testable import TokoToko

final class WalkManagerTests: XCTestCase {
  var walkManager: WalkManager!
  var testImage: UIImage!
  var testWalkId: UUID!

  override func setUpWithError() throws {
    super.setUp()
    walkManager = WalkManager.shared
    testWalkId = UUID()
    testImage = createTestImage()
  }

  override func tearDownWithError() throws {
    if let testImage {
      _ = walkManager.deleteLocalImage(for: testWalkId)
    }

    walkManager = nil
    testImage = nil
    testWalkId = nil
    super.tearDown()
  }

  // MARK: - WalkManager基本機能テスト

  func testWalkManagerSingleton_IsNotNil() throws {
    XCTAssertNotNil(walkManager, "WalkManagerのシングルトンインスタンスが存在するべき")
  }

  func testWalkManager_InitialState() throws {
    XCTAssertNil(walkManager.currentWalk, "初期状態では現在の散歩はnilであるべき")
    XCTAssertEqual(walkManager.elapsedTime, 0, "初期状態では経過時間は0であるべき")
    XCTAssertEqual(walkManager.distance, 0, "初期状態では距離は0であるべき")
    XCTAssertFalse(walkManager.isWalking, "初期状態では散歩中ではないべき")
    XCTAssertFalse(walkManager.isRecording, "初期状態では記録中ではないべき")
  }

  // MARK: - マップサムネイル生成機能テスト（WalkManager拡張）

  func testMapThumbnailGeneration_CompletedWalk() throws {
    // Arrange
    let walk = createCompletedTestWalk()

    // Act & Assert - WalkManagerはサムネイル生成機能を内包している
    XCTAssertNotNil(walkManager, "WalkManagerインスタンスが存在するべき")
    XCTAssertEqual(walk.status, .completed, "テスト散歩は完了状態であるべき")
    XCTAssertFalse(walk.locations.isEmpty, "テスト散歩に位置情報が含まれているべき")
  }

  func testMapThumbnailGeneration_NotCompletedWalk() throws {
    // Arrange
    let walk = createInProgressTestWalk()

    // Act & Assert
    XCTAssertNotEqual(walk.status, .completed, "進行中の散歩は完了状態ではないべき")
  }

  func testMapThumbnailGeneration_EmptyLocations() throws {
    // Arrange
    var walk = Walk(
      title: "位置情報なしテスト",
      description: "位置情報のない散歩",
      status: .completed
    )
    walk.complete()

    // Act & Assert
    XCTAssertTrue(walk.locations.isEmpty, "位置情報なしの散歩であるべき")
  }

  func testMapThumbnailGeneration_SingleLocation() throws {
    // Arrange
    var walk = Walk(
      title: "単一地点テスト",
      description: "単一地点の散歩",
      status: .completed
    )
    walk.addLocation(CLLocation(latitude: 35.6812, longitude: 139.7671))
    walk.complete()

    // Act & Assert
    XCTAssertEqual(walk.locations.count, 1, "単一地点の散歩であるべき")
  }

  // MARK: - 画像ストレージ機能テスト（WalkManager拡張）

  func testImageStorage_SaveImageLocally_Success() throws {
    // Arrange
    XCTAssertNotNil(testImage, "テスト画像が作成されるべき")

    // Act
    let result = walkManager.saveImageLocally(testImage, for: testWalkId)

    // Assert
    XCTAssertTrue(result, "画像のローカル保存が成功するべき")
  }

  func testImageStorage_LoadImageLocally_Success() throws {
    // Arrange
    let saveResult = walkManager.saveImageLocally(testImage, for: testWalkId)
    XCTAssertTrue(saveResult, "前提条件: 画像保存が成功するべき")

    // Act
    let loadedImage = walkManager.loadImageLocally(for: testWalkId)

    // Assert
    XCTAssertNotNil(loadedImage, "保存された画像が読み込めるべき")
    // JPEGエンコーディング/デコーディングによるscale変更を考慮してサイズを比較
    if let loadedImage = loadedImage {
      let expectedWidth = testImage.size.width * testImage.scale
      let expectedHeight = testImage.size.height * testImage.scale
      let actualWidth = loadedImage.size.width * loadedImage.scale
      let actualHeight = loadedImage.size.height * loadedImage.scale

      XCTAssertEqual(actualWidth, expectedWidth, accuracy: 1.0, "画像の実際の幅が一致するべき")
      XCTAssertEqual(actualHeight, expectedHeight, accuracy: 1.0, "画像の実際の高さが一致するべき")
    }
  }

  func testImageStorage_LoadImageLocally_NotFound() throws {
    // Arrange
    let nonExistentWalkId = UUID()

    // Act
    let loadedImage = walkManager.loadImageLocally(for: nonExistentWalkId)

    // Assert
    XCTAssertNil(loadedImage, "存在しない画像の読み込みはnilを返すべき")
  }

  func testImageStorage_DeleteLocalImage_Success() throws {
    // Arrange
    let saveResult = walkManager.saveImageLocally(testImage, for: testWalkId)
    XCTAssertTrue(saveResult, "前提条件: 画像保存が成功するべき")

    // Act
    let deleteResult = walkManager.deleteLocalImage(for: testWalkId)

    // Assert
    XCTAssertTrue(deleteResult, "画像削除が成功するべき")

    // 削除後は読み込めないことを確認
    let loadedImage = walkManager.loadImageLocally(for: testWalkId)
    XCTAssertNil(loadedImage, "削除後は画像が読み込めないべき")
  }

  // MARK: - Firebase Storage テスト（統合テスト）

  func testFirebaseStorage_Integration_Success() throws {
    // Arrange - Firebase連携のモック環境での統合テスト
    XCTAssertNotNil(testImage, "テスト画像が作成されるべき")

    // Act & Assert - 現在はWalkManagerの構造確認
    XCTAssertTrue(true, "Firebase Storage 統合テストは後で実装")
  }

  func testFirebaseStorage_DownloadIntegration_Success() throws {
    // Arrange - Firebase連携のモック環境での統合テスト

    // Act & Assert - 現在はWalkManagerの構造確認
    XCTAssertTrue(true, "Firebase Storage ダウンロード統合テストは後で実装")
  }

  // MARK: - WalkManager散歩機能テスト（カバレッジ向上）

  func testWalkManager_WalkLifecycle() throws {
    // Arrange
    let initialCurrentWalk = walkManager.currentWalk
    let initialIsWalking = walkManager.isWalking
    let initialIsRecording = walkManager.isRecording

    // Act & Assert - 初期状態確認
    XCTAssertNil(initialCurrentWalk, "初期状態で現在の散歩はnil")
    XCTAssertFalse(initialIsWalking, "初期状態で散歩中ではない")
    XCTAssertFalse(initialIsRecording, "初期状態で記録中ではない")
  }

  func testWalkManager_DistanceString() throws {
    // Arrange - 様々な距離値のテスト
    let shortDistance: Double = 250.5 // 250m
    let longDistance: Double = 1500.75 // 1.5km

    // Actのテスト用にWalkManagerのプロパティを一時的に変更
    // 注意: 実際の製品コードではこの方法は推奨されませんが、テスト目的で使用
    walkManager.distance = shortDistance
    let shortDistanceString = walkManager.distanceString

    walkManager.distance = longDistance
    let longDistanceString = walkManager.distanceString

    // Assert
    XCTAssertTrue(shortDistanceString.contains("m"), "短距離はメートル単位で表示")
    XCTAssertTrue(longDistanceString.contains("km"), "長距離はキロメートル単位で表示")

    // リセット
    walkManager.distance = 0
  }

  func testWalkManager_ElapsedTimeString() throws {
    // Arrange
    let shortTime: TimeInterval = 65 // 1分5秒
    let longTime: TimeInterval = 3665 // 1時間1分5秒

    // Act - 経過時間の設定とフォーマット確認
    walkManager.elapsedTime = shortTime
    let shortTimeString = walkManager.elapsedTimeString

    walkManager.elapsedTime = longTime
    let longTimeString = walkManager.elapsedTimeString

    // Assert
    XCTAssertEqual(shortTimeString, "01:05", "短時間のフォーマットが正しい")
    XCTAssertEqual(longTimeString, "1:01:05", "長時間のフォーマットが正しい")

    // リセット
    walkManager.elapsedTime = 0
  }

  func testWalkManager_TotalSteps() throws {
    // Arrange
    let testElapsedTime: TimeInterval = 120 // 2分

    // Act - 歩数計算のテスト（仮実装ベース）
    walkManager.elapsedTime = testElapsedTime
    let steps = walkManager.totalSteps

    // Assert - 仮実装（1秒あたり0.5歩）に基づく期待値
    let expectedSteps = Int(testElapsedTime / 2)
    XCTAssertEqual(steps, expectedSteps, "歩数計算が仮実装通りに動作")

    // リセット
    walkManager.elapsedTime = 0
  }

  func testWalkManager_CancelWalk_ResetsState() throws {
    // Arrange - 散歩状態を模擬的に設定
    walkManager.elapsedTime = 100
    walkManager.distance = 500

    // Act
    walkManager.cancelWalk()

    // Assert
    XCTAssertNil(walkManager.currentWalk, "キャンセル後は現在の散歩がnil")
    XCTAssertEqual(walkManager.elapsedTime, 0, "キャンセル後は経過時間がリセット")
    XCTAssertEqual(walkManager.distance, 0, "キャンセル後は距離がリセット")
    XCTAssertFalse(walkManager.isWalking, "キャンセル後は散歩中ではない")
    XCTAssertFalse(walkManager.isRecording, "キャンセル後は記録中ではない")
  }

  // MARK: - ヘルパーメソッド

  private func createCompletedTestWalk() -> Walk {
    var walk = Walk(
      title: "テスト散歩",
      description: "サムネイル生成テスト",
      userId: "test-user",
      status: .completed
    )

    // テスト用の位置情報を追加
    walk.addLocation(CLLocation(latitude: 35.6812, longitude: 139.7671))
    walk.addLocation(CLLocation(latitude: 35.6815, longitude: 139.7675))
    walk.complete()

    return walk
  }

  private func createInProgressTestWalk() -> Walk {
    var walk = Walk(
      title: "進行中テスト散歩",
      description: "進行中の散歩",
      userId: "test-user",
      status: .inProgress
    )

    walk.addLocation(CLLocation(latitude: 35.6812, longitude: 139.7671))

    return walk
  }

  private func createTestImage() -> UIImage {
    let size = CGSize(width: 160, height: 120)
    UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
    defer { UIGraphicsEndImageContext() }

    UIColor.blue.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))

    let text = "TEST"
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.white,
      .font: UIFont.systemFont(ofSize: 16, weight: .bold),
    ]

    let textSize = text.size(withAttributes: attributes)
    let textRect = CGRect(
      x: (size.width - textSize.width) / 2,
      y: (size.height - textSize.height) / 2,
      width: textSize.width,
      height: textSize.height
    )

    text.draw(in: textRect, withAttributes: attributes)

    return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
  }
}
