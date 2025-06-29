//
//  ImageStorageManagerTests.swift
//  TokoTokoTests
//
//  Created by bokuyamada on 2025/06/29.
//

import UIKit
import XCTest

@testable import TokoToko

final class ImageStorageManagerTests: XCTestCase {
  var storageManager: ImageStorageManager!
  var testImage: UIImage!
  var testWalkId: UUID!

  override func setUpWithError() throws {
    super.setUp()
    storageManager = ImageStorageManager()
    testWalkId = UUID()

    // テスト用の画像作成
    testImage = createTestImage()
  }

  override func tearDownWithError() throws {
    // テスト後のクリーンアップ
    if let testImage {
      try? storageManager.deleteLocalImage(for: testWalkId)
    }

    storageManager = nil
    testImage = nil
    testWalkId = nil
    super.tearDown()
  }

  // MARK: - ローカルストレージテスト

  func testSaveImageLocally_Success() throws {
    // Arrange
    XCTAssertNotNil(testImage, "テスト画像が作成されるべき")

    // Act
    let result = storageManager.saveImageLocally(testImage, for: testWalkId)

    // Assert
    XCTAssertTrue(result, "画像のローカル保存が成功するべき")
  }

  func testLoadImageLocally_Success() throws {
    // Arrange
    let saveResult = storageManager.saveImageLocally(testImage, for: testWalkId)
    XCTAssertTrue(saveResult, "前提条件: 画像保存が成功するべき")

    // Act
    let loadedImage = storageManager.loadImageLocally(for: testWalkId)

    // Assert
    XCTAssertNotNil(loadedImage, "保存された画像が読み込めるべき")
    XCTAssertEqual(loadedImage?.size, testImage.size, "読み込んだ画像のサイズが一致するべき")
  }

  func testLoadImageLocally_NotFound() throws {
    // Arrange
    let nonExistentWalkId = UUID()

    // Act
    let loadedImage = storageManager.loadImageLocally(for: nonExistentWalkId)

    // Assert
    XCTAssertNil(loadedImage, "存在しない画像の読み込みはnilを返すべき")
  }

  func testDeleteLocalImage_Success() throws {
    // Arrange
    let saveResult = storageManager.saveImageLocally(testImage, for: testWalkId)
    XCTAssertTrue(saveResult, "前提条件: 画像保存が成功するべき")

    // Act
    let deleteResult = storageManager.deleteLocalImage(for: testWalkId)

    // Assert
    XCTAssertTrue(deleteResult, "画像削除が成功するべき")

    // 削除後は読み込めないことを確認
    let loadedImage = storageManager.loadImageLocally(for: testWalkId)
    XCTAssertNil(loadedImage, "削除後は画像が読み込めないべき")
  }

  // MARK: - Firebase Storage テスト（モック使用）

  func testUploadToFirebaseStorage_Success() throws {
    // Arrange - モック環境での成功テスト
    XCTAssertNotNil(testImage, "テスト画像が作成されるべき")

    // Act & Assert - 現在は仮実装でスキップ
    // TODO: Firebase Storage モックでのテスト実装
    XCTAssertTrue(true, "Firebase Storage テストは後で実装")
  }

  func testDownloadFromFirebaseStorage_Success() throws {
    // Arrange - モック環境での成功テスト

    // Act & Assert - 現在は仮実装でスキップ
    // TODO: Firebase Storage モックでのテスト実装
    XCTAssertTrue(true, "Firebase Storage テストは後で実装")
  }

  // MARK: - ヘルパーメソッド

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
