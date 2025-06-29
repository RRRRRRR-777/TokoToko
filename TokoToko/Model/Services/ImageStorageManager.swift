//
//  ImageStorageManager.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/29.
//

import UIKit
import Foundation
import FirebaseStorage

// 画像の保存・読み込みを管理するクラス（ローカル + Firebase Storage）
class ImageStorageManager {

  // シングルトンインスタンス
  static let shared = ImageStorageManager()

  // ローカル保存用ディレクトリ
  private let documentsDirectory: URL
  private let thumbnailsDirectoryName = "walk_thumbnails"

  init() {
    // Documents ディレクトリの取得
    documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first!

    // サムネイル用ディレクトリの作成
    createThumbnailsDirectoryIfNeeded()
  }

  // MARK: - ローカルストレージ操作

  // 画像をローカルに保存
  func saveImageLocally(_ image: UIImage, for walkId: UUID) -> Bool {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      return false
    }

    let fileURL = localImageURL(for: walkId)

    do {
      try imageData.write(to: fileURL)
      return true
    } catch {
      #if DEBUG
      print("❌ ローカル画像保存エラー: \(error)")
      #endif
      return false
    }
  }

  // ローカルから画像を読み込み
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

  // ローカルの画像を削除
  func deleteLocalImage(for walkId: UUID) -> Bool {
    let fileURL = localImageURL(for: walkId)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return true // 既に存在しない場合は成功とする
    }

    do {
      try FileManager.default.removeItem(at: fileURL)
      return true
    } catch {
      #if DEBUG
      print("❌ ローカル画像削除エラー: \(error)")
      #endif
      return false
    }
  }

  // MARK: - Firebase Storage 操作

  // Firebase Storage にアップロード
  func uploadToFirebaseStorage(_ image: UIImage, for walkId: UUID, completion: @escaping (Result<String, Error>) -> Void) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      completion(.failure(ImageStorageError.compressionFailed))
      return
    }

    // Firebase Storage reference
    let storage = Storage.storage()
    let storageRef = storage.reference()
    let thumbnailsRef = storageRef.child("walk_thumbnails/\(walkId.uuidString).jpg")

    // メタデータ設定
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    metadata.customMetadata = [
      "walkId": walkId.uuidString,
      "uploadTime": ISO8601DateFormatter().string(from: Date())
    ]

    #if DEBUG
    print("📤 Firebase Storage アップロード開始: \(walkId.uuidString)")
    #endif

    // アップロード実行
    thumbnailsRef.putData(imageData, metadata: metadata) { metadata, error in
      if let error = error {
        #if DEBUG
        print("❌ Firebase Storage アップロードエラー: \(error.localizedDescription)")
        #endif
        completion(.failure(error))
        return
      }

      // ダウンロードURL取得
      thumbnailsRef.downloadURL { url, error in
        if let error = error {
          #if DEBUG
          print("❌ Firebase Storage URL取得エラー: \(error.localizedDescription)")
          #endif
          completion(.failure(error))
          return
        }

        guard let downloadURL = url else {
          completion(.failure(ImageStorageError.uploadFailed))
          return
        }

        #if DEBUG
        print("✅ Firebase Storage アップロード完了: \(downloadURL.absoluteString)")
        #endif
        completion(.success(downloadURL.absoluteString))
      }
    }
  }

  // Firebase Storage からダウンロード
  func downloadFromFirebaseStorage(url: String, for walkId: UUID, completion: @escaping (Result<UIImage, Error>) -> Void) {
    guard let downloadURL = URL(string: url) else {
      completion(.failure(ImageStorageError.invalidURL))
      return
    }

    // Firebase Storage URLの基本的な形式をチェック
    guard let host = downloadURL.host,
          host.contains("googleapis.com") else {
      #if DEBUG
      print("❌ Invalid Firebase Storage URL: \(url)")
      #endif
      completion(.failure(ImageStorageError.invalidURL))
      return
    }

    #if DEBUG
    print("📥 Firebase Storage ダウンロード開始: \(walkId.uuidString)")
    print("   URL: \(url)")
    #endif

    // Firebase Storage reference
    let storage = Storage.storage()

    do {
      let storageRef = storage.reference(forURL: url)

      // 最大ダウンロードサイズを5MBに制限
      let maxSize: Int64 = 5 * 1024 * 1024

      storageRef.getData(maxSize: maxSize) { data, error in
        if let error = error {
          #if DEBUG
          print("❌ Firebase Storage ダウンロードエラー: \(error.localizedDescription)")
          #endif
          completion(.failure(error))
          return
        }

        guard let imageData = data, let image = UIImage(data: imageData) else {
          #if DEBUG
          print("❌ 画像データの変換に失敗")
          #endif
          completion(.failure(ImageStorageError.downloadFailed))
          return
        }

        #if DEBUG
        print("✅ Firebase Storage ダウンロード完了: \(image.size)")
        #endif
        completion(.success(image))
      }
    } catch {
      #if DEBUG
      print("❌ Firebase Storage reference作成エラー: \(error.localizedDescription)")
      #endif
      completion(.failure(ImageStorageError.invalidURL))
    }
  }

  // MARK: - Private ヘルパーメソッド

  private func createThumbnailsDirectoryIfNeeded() {
    let thumbnailsDirectory = documentsDirectory.appendingPathComponent(thumbnailsDirectoryName)

    if !FileManager.default.fileExists(atPath: thumbnailsDirectory.path) {
      do {
        try FileManager.default.createDirectory(at: thumbnailsDirectory,
                                               withIntermediateDirectories: true,
                                               attributes: nil)
      } catch {
        #if DEBUG
        print("❌ サムネイルディレクトリ作成エラー: \(error)")
        #endif
      }
    }
  }

  private func localImageURL(for walkId: UUID) -> URL {
    let thumbnailsDirectory = documentsDirectory.appendingPathComponent(thumbnailsDirectoryName)
    return thumbnailsDirectory.appendingPathComponent("\(walkId.uuidString).jpg")
  }
}

// MARK: - エラー定義

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
    case .storageLimitExceeded:
      return "Storage limit exceeded"
    case .invalidURL:
      return "Invalid URL"
    }
  }
}
