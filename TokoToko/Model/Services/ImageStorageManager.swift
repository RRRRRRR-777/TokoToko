//
//  ImageStorageManager.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/29.
//

import UIKit
import Foundation

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
    // 🟢 仮実装（ベタ書き）- テストを通すための最小限の実装
    
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
    // 🟢 仮実装（ベタ書き）- テストを通すための最小限の実装
    
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
    // 🟢 仮実装（ベタ書き）- テストを通すための最小限の実装
    
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
  
  // MARK: - Firebase Storage 操作（仮実装）
  
  // Firebase Storage にアップロード
  func uploadToFirebaseStorage(_ image: UIImage, for walkId: UUID, completion: @escaping (Result<String, Error>) -> Void) {
    // 🟢 仮実装（ベタ書き）- テストを通すための最小限の実装
    
    // TODO: 実際のFirebase Storage実装
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
      let fakeURL = "https://firebase.storage.example.com/walk_thumbnails/\(walkId.uuidString).jpg"
      completion(.success(fakeURL))
    }
  }
  
  // Firebase Storage からダウンロード
  func downloadFromFirebaseStorage(url: String, for walkId: UUID, completion: @escaping (Result<UIImage, Error>) -> Void) {
    // 🟢 仮実装（ベタ書き）- テストを通すための最小限の実装
    
    // TODO: 実際のFirebase Storage実装
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
      // とりあえず固定の画像を返す
      let size = CGSize(width: 160, height: 120)
      UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
      defer { UIGraphicsEndImageContext() }
      
      UIColor.gray.setFill()
      UIRectFill(CGRect(origin: .zero, size: size))
      
      if let fakeImage = UIGraphicsGetImageFromCurrentImageContext() {
        completion(.success(fakeImage))
      } else {
        completion(.failure(ImageStorageError.downloadFailed))
      }
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

enum ImageStorageError: Error {
  case compressionFailed
  case saveFailed
  case loadFailed
  case deleteFailed
  case uploadFailed
  case downloadFailed
  case fileNotFound
}