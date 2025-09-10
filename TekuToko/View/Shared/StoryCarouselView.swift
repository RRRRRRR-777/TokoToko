//
//  StoryCarouselView.swift
//  TekuToko
//
//  Created by Claude Code on 2025/07/12.
//

import SwiftUI

struct StoryCarouselView: View {
  let onPreviousTap: () -> Void
  let onNextTap: () -> Void

  var body: some View {
    HStack(spacing: 2) {
      // 左側タップ領域（前の散歩）
      Button {
        onPreviousTap()
      } label: {
        Image(systemName: "chevron.left")
          .font(.title)
          .frame(width: 50, height: 100)
          .contentShape(Rectangle())
          .foregroundColor(Color(red: 0 / 255, green: 204 / 255, blue: 156 / 255))
          .shadow(color: .black.opacity(0.5), radius: 2, x: 4, y: 4)
      }

      // 中央エリア
      Spacer()
        .frame(maxWidth: .infinity)

      // 右側タップ領域（次の散歩）
      Button {
        onNextTap()
      } label: {
        Image(systemName: "chevron.right")
          .font(.title)
          .frame(width: 50, height: 100)
          .contentShape(Rectangle())
          .foregroundColor(Color(red: 0 / 255, green: 204 / 255, blue: 156 / 255))
          .shadow(color: .black.opacity(0.5), radius: 2, x: 4, y: 4)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

#Preview {
  StoryCarouselView(
    onPreviousTap: {
      print("Previous walk tapped")
    },
    onNextTap: {
      print("Next walk tapped")
    }
  )
  .frame(maxHeight: .infinity)
  .background(Color.gray.opacity(0.3))
}
