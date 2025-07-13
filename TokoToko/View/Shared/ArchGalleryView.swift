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
  private let spacing: CGFloat = 10

  var body: some View {
    HStack(spacing: -30) {
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
    ],
    onImageTap: { index in
      print("Tapped image at index: \(index)")
    }
  )
  .padding()
  .background(Color.black.opacity(0.1))
}
