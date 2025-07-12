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

  private let imageSize: CGFloat = 60
  private let spacing: CGFloat = 10

  var body: some View {
    GeometryReader { geometry in
      ZStack {
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
          .position(archPosition(for: index, in: geometry.size))
        }
      }
    }
    .frame(height: 120)
  }

  private func archPosition(for index: Int, in size: CGSize) -> CGPoint {
    guard photoURLs.count > 0 else { return CGPoint(x: size.width / 2, y: size.height / 2) }

    let centerX = size.width / 2
    let centerY = size.height - 20

    // アーチの半径
    let radius: CGFloat = min(size.width * 0.35, 120)

    // 角度の計算（-120度から+120度の範囲で配置）
    let totalAngle: CGFloat = 80 * .pi / 180  // 120度をラジアンに変換
    let angleStep = photoURLs.count > 1 ? totalAngle / CGFloat(photoURLs.count - 1) : 0
    let startAngle = -totalAngle / 2

    let angle = startAngle + CGFloat(index) * angleStep

    // 円弧上の位置計算
    let x = centerX + radius * sin(angle)
    let y = centerY - radius * cos(angle)

    return CGPoint(x: x, y: y)
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
    ],
    onImageTap: { index in
      print("Tapped image at index: \(index)")
    }
  )
  .padding()
  .background(Color.black.opacity(0.1))
}
