//
//  ThumbnailImageView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/29.
//

import SwiftUI
import UIKit

// サムネイル画像の表示を管理するビュー
struct ThumbnailImageView: View {
  let walkId: UUID
  let thumbnailImageUrl: String?

  @State private var image: UIImage?
  @State private var isLoading = true
  @State private var hasError = false

  // 画像管理マネージャー
  private let walkManager = WalkManager.shared

  var body: some View {
    Group {
      if let image = image {
        // 画像が読み込まれた場合
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .clipped()
      } else if isLoading {
        // 読み込み中
        Rectangle()
          .fill(Color(.systemGray5))
          .overlay(
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(0.8)
          )
      } else {
        // 読み込み失敗またはフォールバック
        Rectangle()
          .fill(Color(.systemGray5))
          .overlay(
            VStack(spacing: 4) {
              Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(.secondary)
              Text("画像を表示できません")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          )
      }
    }
    .onAppear {
      loadThumbnailImage()
    }
  }

  // サムネイル画像の読み込み（ハイブリッド戦略）
  private func loadThumbnailImage() {
    isLoading = true
    hasError = false

    // 🟢 仮実装（ベタ書き）- テストを通すための最小限の実装

    // 1. ローカルストレージから試行
    if let localImage = walkManager.loadImageLocally(for: walkId) {
      self.image = localImage
      self.isLoading = false
      return
    }

    // 2. Firebase Storage URLがある場合はダウンロード試行
    if let urlString = thumbnailImageUrl, !urlString.isEmpty {
      walkManager.downloadFromFirebaseStorage(url: urlString, for: walkId) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let downloadedImage):
            self.image = downloadedImage
            self.isLoading = false

            // ダウンロード成功時はローカルにもキャッシュ
            _ = self.walkManager.saveImageLocally(downloadedImage, for: self.walkId)

          case .failure(_):
            // Firebase Storageダウンロード失敗
            self.hasError = true
            self.isLoading = false
          }
        }
      }
    } else {
      // Firebase Storage URLがない場合
      self.hasError = true
      self.isLoading = false
    }
  }
}

#Preview {
  VStack(spacing: 16) {
    // 成功例（ローカル画像が存在する想定）
    ThumbnailImageView(
      walkId: UUID(),
      thumbnailImageUrl: "https://example.com/image1.jpg"
    )
    .frame(height: 120)
    .cornerRadius(8)

    // Firebase URLのみ
    ThumbnailImageView(
      walkId: UUID(),
      thumbnailImageUrl: "https://firebase.storage.example.com/image2.jpg"
    )
    .frame(height: 120)
    .cornerRadius(8)

    // フォールバック例
    ThumbnailImageView(
      walkId: UUID(),
      thumbnailImageUrl: nil
    )
    .frame(height: 120)
    .cornerRadius(8)
  }
  .padding()
}
