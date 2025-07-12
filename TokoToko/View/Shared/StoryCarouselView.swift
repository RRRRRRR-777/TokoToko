//
//  StoryCarouselView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/12.
//

import SwiftUI

struct StoryCarouselView: View {
  let onPreviousTap: () -> Void
  let onNextTap: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      // 左側タップ領域（前の散歩）
      Button {
        onPreviousTap()
      } label: {
        Color.clear
      }
      .frame(maxWidth: .infinity)

      // 右側タップ領域（次の散歩）
      Button {
        onNextTap()
      } label: {
        Color.clear
      }
      .frame(maxWidth: .infinity)
    }
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
  .frame(height: 300)
  .background(Color.gray.opacity(0.3))
}
