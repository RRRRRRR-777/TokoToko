//
//  WalkRow.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import SwiftUI

struct WalkRow: View {
  let walk: Walk

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        // 散歩情報
        VStack(alignment: .leading, spacing: 4) {
          Text(walk.title)
            .font(.headline)
            .foregroundColor(.primary)

          if !walk.description.isEmpty {
            Text(walk.description)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(2)
          }

          HStack(spacing: 16) {
            if walk.isCompleted {
              // 完了した散歩の情報
              HStack(spacing: 4) {
                Image(systemName: "clock")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text(walk.durationString)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .fixedSize(horizontal: true, vertical: false)
                  .lineLimit(1)
              }

              HStack(spacing: 4) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text(walk.distanceString)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .fixedSize(horizontal: true, vertical: false)
                  .lineLimit(1)
              }

              if walk.totalSteps > 0 {
                HStack(spacing: 4) {
                  Image(systemName: "figure.walk")
                    .font(.caption)
                    .foregroundColor(.secondary)
                  Text("\(walk.totalSteps) 歩")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
                    .lineLimit(1)
                }
              }
            } else {
              // 進行中または未開始の散歩
              Text(walk.status.displayName)
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            }
          }
        }

        Spacer()

        // 日時表示
        VStack(alignment: .trailing, spacing: 2) {
          Text(dateString)
            .font(.caption)
            .foregroundColor(.secondary)

        }
      }

    }
    .padding(.vertical, 4)
  }

  // 日時文字列
  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")

    if let startTime = walk.startTime {
      return formatter.string(from: startTime)
    } else {
      return formatter.string(from: walk.createdAt)
    }
  }
}

#Preview {
  List {
    WalkRow(
      walk: Walk(
        title: "朝の散歩",
        description: "公園を一周しました",
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 1200,
        totalSteps: 1500,
        status: .completed
      ))

    WalkRow(
      walk: Walk(
        title: "夕方の散歩",
        description: "商店街を歩きました",
        startTime: Date().addingTimeInterval(-1800),
        totalDistance: 800,
        totalSteps: 950,
        status: .inProgress
      ))

    WalkRow(
      walk: Walk(
        title: "お昼の散歩",
        description: "",
        startTime: Date().addingTimeInterval(-900),
        totalDistance: 300,
        totalSteps: 400,
        status: .paused
      ))

    WalkRow(
      walk: Walk(
        title: "新しい散歩",
        description: "まだ開始していません",
        status: .notStarted
      ))

    WalkRow(
      walk: Walk(
        title: "長距離ウォーキング",
        description: "健康のために長い距離を歩きました。とても気持ちよかったです。",
        startTime: Date().addingTimeInterval(-7200),
        endTime: Date().addingTimeInterval(-5400),
        totalDistance: 5500,
        totalSteps: 7500,
        status: .completed
      ))

    WalkRow(
      walk: Walk(
        title: "歩数ゼロの散歩",
        description: "歩数計測なし",
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 800,
        totalSteps: 0,
        status: .completed
      ))

    WalkRow(
      walk: Walk(
        title: "短時間散歩",
        description: "5分間の軽い散歩",
        startTime: Date().addingTimeInterval(-300),
        endTime: Date().addingTimeInterval(-0),
        totalDistance: 200,
        totalSteps: 250,
        status: .completed
      ))
  }
}
