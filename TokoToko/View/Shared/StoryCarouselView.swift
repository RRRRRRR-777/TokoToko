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
    HStack {
      // 左側タップ領域（前の散歩）
      Button {
        onPreviousTap()
      } label: {
        Image(systemName: "chevron.left")
          .font(.title)
          .frame(width: 50, height: 100)
          .contentShape(Rectangle())
      }

      Spacer()

      // 右側タップ領域（次の散歩）
      Button {
        onNextTap()
      } label: {
        Image(systemName: "chevron.right")
          .font(.title)
          .frame(width: 50, height: 100)
          .contentShape(Rectangle())
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
