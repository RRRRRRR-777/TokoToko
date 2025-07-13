//
//  StatsBarView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/12.
//

import SwiftUI

struct StatsBarView: View {
  let walk: Walk
  @Binding var isExpanded: Bool
  let onToggle: () -> Void

  var body: some View {
    VStack {
      if isExpanded {
        expandedView
      } else {
        collapsedView
      }
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
  }

  private var expandedView: some View {
    VStack(spacing: 16) {
      VStack(spacing: 20) {
        VStack(alignment: .center, spacing: 4) {
          Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
            .font(.title2)
          Text(walk.distanceString)
            .font(.callout)
            .fontWeight(.semibold)
        }

        VStack(alignment: .center, spacing: 4) {
          Image(systemName: "clock")
            .font(.title2)
          Text(walk.durationString)
            .font(.callout)
            .fontWeight(.semibold)
        }

        VStack(alignment: .center, spacing: 4) {
          Image(systemName: "figure.walk")
            .font(.title2)
          Text("\(walk.totalSteps)歩")
            .font(.callout)
            .fontWeight(.semibold)
        }
      }
    }
    .padding(.all, 16)
    .frame(width: 100)
    .background(Color.white.opacity(0.85))
    .foregroundColor(.black)
    .cornerRadius(20)
    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    .onTapGesture {
      onToggle()
    }
  }

  private var collapsedView: some View {
    Button(action: onToggle) {
      Image(systemName: "info.circle.fill")
        .font(.title)
        .foregroundColor(.white)
        .background(Color.black)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
    .accessibilityLabel("統計情報を表示")
  }
}

#Preview {
  @State var isExpanded = true

  return StatsBarView(
    walk: Walk(
      title: "サンプル散歩",
      description: "テスト用",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1500,
      totalSteps: 2000,
      status: .completed
    ),
    isExpanded: $isExpanded,
    onToggle: { isExpanded.toggle() }
  )
  .padding()
}
