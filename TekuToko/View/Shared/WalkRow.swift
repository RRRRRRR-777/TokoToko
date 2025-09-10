//
//  WalkRow.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/06/03.
//

import SwiftUI

struct WalkRow: View {
  let walk: Walk

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        walkInfoSection
        Spacer()
        dateSection
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
  }

  // MARK: - Walk Information Section

  /// 散歩情報セクション
  private var walkInfoSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      titleAndDescription
      statusOrMetricsSection
    }
  }

  /// タイトルと説明
  private var titleAndDescription: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(walk.title)
        .font(.headline)
        .foregroundColor(.black)

      if !walk.description.isEmpty {
        Text(walk.description)
          .font(.caption)
          .foregroundColor(.gray)
          .lineLimit(2)
      }
    }
  }

  /// ステータスまたは統計情報セクション
  private var statusOrMetricsSection: some View {
    HStack(spacing: 16) {
      if walk.isCompleted {
        completedWalkMetrics
      } else {
        statusBadge
      }
    }
  }

  /// 完了済み散歩の統計情報
  private var completedWalkMetrics: some View {
    Group {
      durationMetric
      distanceMetric
      if walk.totalSteps > 0 {
        stepsMetric
      }
    }
  }

  /// 時間統計
  private var durationMetric: some View {
    MetricView(
      iconName: "clock",
      value: walk.durationString
    )
  }

  /// 距離統計
  private var distanceMetric: some View {
    MetricView(
      iconName: "point.topleft.down.curvedto.point.bottomright.up",
      value: walk.distanceString
    )
  }

  /// 歩数統計
  private var stepsMetric: some View {
    MetricView(
      iconName: "figure.walk",
      value: "\(walk.totalSteps) 歩"
    )
  }

  /// ステータスバッジ（進行中・未開始）
  private var statusBadge: some View {
    Text(walk.status.displayName)
      .font(.caption)
      .foregroundColor(.orange)
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .background(Color.orange.opacity(0.1))
      .cornerRadius(4)
  }

  // MARK: - Date Section

  /// 日時表示セクション
  private var dateSection: some View {
    VStack(alignment: .trailing, spacing: 2) {
      Text(dateString)
        .font(.caption)
        .foregroundColor(.gray)
    }
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

// MARK: - Helper Views

/// 統計情報表示用のヘルパービュー
private struct MetricView: View {
  let iconName: String
  let value: String

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: iconName)
        .font(.caption)
        .foregroundColor(.gray)
      Text(value)
        .font(.caption)
        .foregroundColor(.gray)
        .fixedSize(horizontal: true, vertical: false)
        .lineLimit(1)
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
