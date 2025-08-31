//
//  WalkManagerStorage.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/08/30.
//

import FirebaseStorage
import Foundation
import UIKit

// MARK: - Image Storage Error

/// 画像ストレージ操作で発生するエラー
enum ImageStorageError: Error, LocalizedError {
  case compressionFailed
  case saveFailed
  case loadFailed
  case deleteFailed
  case uploadFailed
  case downloadFailed
  case fileNotFound
  case networkUnavailable
  case authenticationFailed
  case authenticationRequired
  case storageLimitExceeded
  case invalidURL

  var errorDescription: String? {
    switch self {
    case .compressionFailed:
      return "Failed to compress image"
    case .saveFailed:
      return "Failed to save image"
    case .loadFailed:
      return "Failed to load image"
    case .deleteFailed:
      return "Failed to delete image"
    case .uploadFailed:
      return "Failed to upload to Firebase Storage"
    case .downloadFailed:
      return "Failed to download from Firebase Storage"
    case .fileNotFound:
      return "File not found"
    case .networkUnavailable:
      return "Network unavailable"
    case .authenticationFailed:
      return "Authentication failed"
    case .authenticationRequired:
      return "User authentication required"
    case .storageLimitExceeded:
      return "Storage limit exceeded"
    case .invalidURL:
      return "Invalid URL"
    }
  }
}

// MARK: - Image Storage Extension

/// WalkManagerの画像ストレージ機能拡張
extension WalkManager {

  // MARK: - Local Storage Operations

  /// サムネイル用ディレクトリの作成
  func createThumbnailsDirectoryIfNeeded() {
    let thumbnailsDirectory = documentsDirectory.appendingPathComponent(thumbnailsDirectoryName)

    if !FileManager.default.fileExists(atPath: thumbnailsDirectory.path) {
      do {
        try FileManager.default.createDirectory(
          at: thumbnailsDirectory,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        logger.logError(
          error,
          operation: "createThumbnailsDirectory",
          humanNote: "サムネイルディレクトリ作成エラー"
        )
      }
    }
  }

  /// ローカル画像URLの取得
  private func localImageURL(for walkId: UUID) -> URL {
    let thumbnailsDirectory = documentsDirectory.appendingPathComponent(thumbnailsDirectoryName)
    return thumbnailsDirectory.appendingPathComponent("\(walkId.uuidString).jpg")
  }

  /// 画像をローカルに保存
  func saveImageLocally(_ image: UIImage, for walkId: UUID) -> Bool {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      return false
    }

    let fileURL = localImageURL(for: walkId)

    do {
      try imageData.write(to: fileURL)
      return true
    } catch {
      logger.logError(
        error,
        operation: "saveImageLocally",
        humanNote: "ローカル画像保存エラー"
      )
      return false
    }
  }

  /// ローカルから画像を読み込み
  func loadImageLocally(for walkId: UUID) -> UIImage? {
    let fileURL = localImageURL(for: walkId)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return nil
    }

    guard let imageData = try? Data(contentsOf: fileURL) else {
      return nil
    }

    return UIImage(data: imageData)
  }

  /// ローカルの画像を削除
  func deleteLocalImage(for walkId: UUID) -> Bool {
    let fileURL = localImageURL(for: walkId)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return true
    }

    do {
      try FileManager.default.removeItem(at: fileURL)
      return true
    } catch {
      logger.logError(
        error,
        operation: "deleteLocalImage",
        humanNote: "ローカル画像削除エラー"
      )
      return false
    }
  }

  // MARK: - Firebase Storage Operations

  /// Firebase Storageにアップロード
  private func uploadToFirebaseStorage(
    _ image: UIImage,
    for walkId: UUID,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      completion(.failure(ImageStorageError.compressionFailed))
      return
    }

    FirebaseAuthHelper.validateAuthenticationWithToken { result in
      switch result {
      case .success(let userId):
        self.performThumbnailUpload(
          imageData: imageData,
          userId: userId,
          walkId: walkId,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  /// サムネイルアップロードの実行
  private func performThumbnailUpload(
    imageData: Data,
    userId: String,
    walkId: UUID,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    let storageRef = Storage.storage().reference()
    let imageRef = storageRef.child("thumbnails/\(userId)/\(walkId.uuidString).jpg")

    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    metadata.cacheControl = "public, max-age=31536000"

    imageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
      if let error = error {
        self?.logger.logError(
          error,
          operation: "uploadThumbnail",
          humanNote: "Firebase Storageアップロードエラー"
        )
        completion(.failure(ImageStorageError.uploadFailed))
        return
      }

      self?.downloadURLWithRetry(ref: imageRef, maxRetries: 3) { result in
        completion(result)
      }
    }
  }

  /// ダウンロードURLを取得（リトライ機能付き）
  private func downloadURLWithRetry(
    ref: StorageReference,
    maxRetries: Int,
    currentRetry: Int = 0,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    ref.downloadURL { url, error in
      if let error = error {
        if currentRetry < maxRetries {
          DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.downloadURLWithRetry(
              ref: ref,
              maxRetries: maxRetries,
              currentRetry: currentRetry + 1,
              completion: completion
            )
          }
        } else {
          self.logger.logError(
            error,
            operation: "downloadURL",
            humanNote: "ダウンロードURL取得エラー（最大リトライ到達）"
          )
          completion(.failure(ImageStorageError.downloadFailed))
        }
        return
      }

      guard let url = url else {
        completion(.failure(ImageStorageError.invalidURL))
        return
      }

      completion(.success(url.absoluteString))
    }
  }

  /// Firebase Storageからダウンロード
  func downloadFromFirebaseStorage(
    url: String,
    for walkId: UUID,
    completion: @escaping (Result<UIImage, Error>) -> Void
  ) {
    guard let downloadURL = URL(string: url) else {
      completion(.failure(ImageStorageError.invalidURL))
      return
    }

    let task = URLSession.shared.dataTask(with: downloadURL) { [weak self] data, _, error in
      if let error = error {
        self?.logger.logError(
          error,
          operation: "downloadImage",
          humanNote: "Firebase Storageダウンロードエラー"
        )
        completion(.failure(ImageStorageError.downloadFailed))
        return
      }

      guard let data = data, let image = UIImage(data: data) else {
        completion(.failure(ImageStorageError.loadFailed))
        return
      }

      // ローカルに保存
      DispatchQueue.global().async {
        _ = self?.saveImageLocally(image, for: walkId)
      }

      completion(.success(image))
    }

    task.resume()
  }
}
