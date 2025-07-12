//
//  StatsBarView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/12.
//

import SwiftUI

struct StatsBarView: View {
  let walk: Walk

  var body: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text("距離")
          .font(.caption)
          .foregroundColor(.white)
          .bold()
        Text(walk.distanceString)
          .font(.headline)
          .fontWeight(.semibold)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("時間")
          .font(.caption)
          .foregroundColor(.white)
          .bold()
        Text(walk.durationString)
          .font(.headline)
          .fontWeight(.semibold)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("歩数")
          .font(.caption)
          .foregroundColor(.white)
          .bold()
        Text("\(walk.totalSteps)歩")
          .font(.headline)
          .fontWeight(.semibold)
      }
    }
    .frame(alignment: .center)
    .padding()
    .background(Color.black.opacity(0.7))
    .foregroundColor(.white)
    .cornerRadius(12)
  }
}

#Preview {
  StatsBarView(
    walk: Walk(
      title: "サンプル散歩",
      description: "テスト用",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1500,
      totalSteps: 2000,
      status: .completed
    )
  )
  .padding()
}
