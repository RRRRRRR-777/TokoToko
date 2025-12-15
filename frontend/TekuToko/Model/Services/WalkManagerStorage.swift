//
//  WalkManagerStorage.swift
//  TekuToko
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
    // UIテスト時は外部依存を避ける（Storage未初期化のため）
    if UITestingHelper.shared.isUITesting {
      completion(.failure(ImageStorageError.networkUnavailable))
      return
    }
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
    // UIテスト時は外部依存を避ける
    if UITestingHelper.shared.isUITesting {
      completion(.failure(ImageStorageError.networkUnavailable))
      return
    }
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

  // MARK: - Offline Walk Storage

  /// オフライン保存用ディレクトリ名
  private var offlineWalksDirectoryName: String { "offline_walks" }

  /// オフライン保存用ディレクトリURL
  private var offlineWalksDirectory: URL {
    documentsDirectory.appendingPathComponent(offlineWalksDirectoryName)
  }

  /// オフライン保存用ディレクトリの作成
  private func createOfflineWalksDirectoryIfNeeded() {
    if !FileManager.default.fileExists(atPath: offlineWalksDirectory.path) {
      do {
        try FileManager.default.createDirectory(
          at: offlineWalksDirectory,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        logger.logError(
          error,
          operation: "createOfflineWalksDirectory",
          humanNote: "オフライン散歩ディレクトリ作成エラー"
        )
      }
    }
  }

  /// オフライン散歩データのファイルURL
  private func offlineWalkURL(for walkId: UUID) -> URL {
    offlineWalksDirectory.appendingPathComponent("\(walkId.uuidString).json")
  }

  /// 散歩データをローカルに一時保存
  ///
  /// ネットワークエラー時に散歩データをJSONとしてローカルに保存します。
  /// アプリ再起動時に自動で再送信を試みます。
  ///
  /// - Parameter walk: 保存する散歩データ
  /// - Returns: 保存成功時true
  func saveWalkLocally(_ walk: Walk) -> Bool {
    createOfflineWalksDirectoryIfNeeded()

    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let jsonData = try encoder.encode(walk)
      let fileURL = offlineWalkURL(for: walk.id)
      try jsonData.write(to: fileURL)

      logger.info(
        operation: "saveWalkLocally",
        message: "散歩データをローカルに保存しました",
        context: ["walkId": walk.id.uuidString]
      )
      return true
    } catch {
      logger.logError(
        error,
        operation: "saveWalkLocally",
        humanNote: "ローカル散歩データ保存エラー"
      )
      return false
    }
  }

  /// 未送信の散歩データを全て読み込み
  ///
  /// - Returns: ローカルに保存されている散歩データの配列
  func loadPendingWalks() -> [Walk] {
    createOfflineWalksDirectoryIfNeeded()

    var pendingWalks: [Walk] = []

    do {
      let fileURLs = try FileManager.default.contentsOfDirectory(
        at: offlineWalksDirectory,
        includingPropertiesForKeys: nil,
        options: .skipsHiddenFiles
      )

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      for fileURL in fileURLs where fileURL.pathExtension == "json" {
        do {
          let jsonData = try Data(contentsOf: fileURL)
          let walk = try decoder.decode(Walk.self, from: jsonData)
          pendingWalks.append(walk)
        } catch {
          logger.logError(
            error,
            operation: "loadPendingWalk",
            humanNote: "散歩データ読み込みエラー: \(fileURL.lastPathComponent)"
          )
        }
      }
    } catch {
      logger.logError(
        error,
        operation: "loadPendingWalks",
        humanNote: "オフラインディレクトリ読み込みエラー"
      )
    }

    return pendingWalks
  }

  /// 送信完了した散歩データをローカルから削除
  ///
  /// - Parameter walkId: 削除する散歩のID
  func deletePendingWalk(for walkId: UUID) {
    let fileURL = offlineWalkURL(for: walkId)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }

    do {
      try FileManager.default.removeItem(at: fileURL)
      logger.info(
        operation: "deletePendingWalk",
        message: "ローカル散歩データを削除しました",
        context: ["walkId": walkId.uuidString]
      )
    } catch {
      logger.logError(
        error,
        operation: "deletePendingWalk",
        humanNote: "ローカル散歩データ削除エラー"
      )
    }
  }

  /// 未送信の散歩データが存在するか確認
  ///
  /// - Returns: 未送信データがある場合true
  func hasPendingWalks() -> Bool {
    !loadPendingWalks().isEmpty
  }
}
