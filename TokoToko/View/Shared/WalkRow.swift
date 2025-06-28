//
//  WalkRow.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import CoreLocation
import MapKit
import SwiftUI

struct WalkRow: View {
  let walk: Walk

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        // 状態アイコン
        statusIcon
          .frame(width: 40, height: 40)
          .background(statusColor.opacity(0.1))
          .cornerRadius(8)

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
                Image(systemName: "figure.walk")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text(walk.distanceString)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .fixedSize(horizontal: true, vertical: false)
                  .lineLimit(1)
              }
            } else {
              // 進行中または未開始の散歩
              Text(walk.status.displayName)
                .font(.caption)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.1))
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

          if walk.hasLocation {
            Image(systemName: "location.fill")
              .font(.caption)
              .foregroundColor(.blue)
          }
        }
      }

      // 完了した散歩で位置情報がある場合はマップのプレビューを表示
      if walk.isCompleted && walk.hasLocation, let firstLocation = walk.locations.first {
        mapPreview
      }
    }
    .padding(.vertical, 4)
  }

  // マップのプレビュー
  private var mapPreview: some View {
    Group {
      if let firstLocation = walk.locations.first {
        let region = MKCoordinateRegion(
          center: firstLocation.coordinate,
          span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        // 開始・終了地点のアノテーション
        let annotations: [MapItem] = {
          guard !walk.locations.isEmpty else { return [] }

          var items: [MapItem] = []

          // 開始地点
          items.append(
            MapItem(
              coordinate: firstLocation.coordinate,
              title: "開始",
              imageName: "play.circle.fill"
            )
          )

          // 終了地点（開始地点と異なる場合のみ）
          if let lastLocation = walk.locations.last, walk.locations.count > 1 {
            items.append(
              MapItem(
                coordinate: lastLocation.coordinate,
                title: "終了",
                imageName: "checkmark.circle.fill"
              )
            )
          }

          return items
        }()

        // ポリライン座標
        let polylineCoordinates = walk.locations.map { $0.coordinate }

        MapViewComponent(
          region: region,
          annotations: annotations,
          polylineCoordinates: polylineCoordinates,
          showsUserLocation: false
        )
        .frame(height: 120)
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color(.systemGray4), lineWidth: 1)
        )
      }
    }
  }

  // 状態に応じたアイコン
  private var statusIcon: some View {
    Group {
      switch walk.status {
      case .notStarted:
        Image(systemName: "circle")
          .foregroundColor(statusColor)
      case .inProgress:
        Image(systemName: "play.circle.fill")
          .foregroundColor(statusColor)
      case .paused:
        Image(systemName: "pause.circle.fill")
          .foregroundColor(statusColor)
      case .completed:
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(statusColor)
      }
    }
    .font(.title2)
  }

  // 状態に応じた色
  private var statusColor: Color {
    switch walk.status {
    case .notStarted:
      return .gray
    case .inProgress:
      return .green
    case .paused:
      return .orange
    case .completed:
      return .blue
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

#Preview {
  List {
    WalkRow(
      walk: Walk(
        title: "朝の散歩",
        description: "公園を一周しました",
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 1200,
        status: .completed
      ))

    WalkRow(
      walk: Walk(
        title: "夕方の散歩",
        description: "商店街を歩きました",
        startTime: Date().addingTimeInterval(-1800),
        totalDistance: 800,
        status: .inProgress
      ))

    WalkRow(
      walk: Walk(
        title: "お昼の散歩",
        description: "",
        status: .paused
      ))

    WalkRow(
      walk: Walk(
        title: "新しい散歩",
        description: "まだ開始していません",
        status: .notStarted
      ))
  }
}
