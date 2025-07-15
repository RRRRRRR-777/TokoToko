//
//  ArchGalleryView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/12.
//

import SwiftUI

struct ArchGalleryView: View {
  let photoURLs: [String]
  let onImageTap: (Int) -> Void

  private let imageSize: CGFloat = 55
  private let maxWidth: CGFloat = 280  // 10枚表示時の基準横幅
  private let normalSpacing: CGFloat = 2  // 重ならない時のスペーシング
  private let overlapSpacing: CGFloat = -30  // 重なる時のスペーシング

  private func calculateSpacing() -> CGFloat {
    let imageCount = photoURLs.count
    guard imageCount > 1 else {
      return normalSpacing
    }

    // 通常スペーシングでの横幅を計算
    let normalWidth = CGFloat(imageCount) * imageSize + CGFloat(imageCount - 1) * normalSpacing

    // 最大横幅を超える場合は重ねて表示
    return normalWidth > maxWidth ? overlapSpacing : normalSpacing
  }

  var body: some View {
    HStack(spacing: calculateSpacing()) {
      ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, url in
        Button {
          onImageTap(index)
        } label: {
          AsyncImage(url: URL(string: url)) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Rectangle()
              .fill(Color.gray.opacity(0.3))
          }
          .frame(width: imageSize, height: imageSize)
          .clipShape(Circle())
          .overlay(
            Circle()
              .stroke(Color.white, lineWidth: 3)
          )
          .shadow(radius: 3)
        }
        .zIndex(Double(photoURLs.count - index))
      }
    }
  }

}

#Preview {
  ArchGalleryView(
    photoURLs: [
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
    ]
  ) { index in
    print("Tapped image at index: \(index)")
  }
  .padding()
  .background(Color.black.opacity(0.1))
}
