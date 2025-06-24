//
//  DetailView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import MapKit
import SwiftUI

struct DetailView: View {
  @State private var walk: Walk
  @State private var isLoading = false

  // リポジトリ
  private let walkRepository = WalkRepository.shared

  init(walk: Walk) {
    _walk = State(initialValue: walk)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // ヘッダー情報
        VStack(alignment: .leading, spacing: 8) {
          Text(walk.title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .accessibilityIdentifier(walk.title)

          if !walk.description.isEmpty {
            Text(walk.description)
              .font(.body)
              .foregroundColor(.secondary)
              .accessibilityIdentifier(walk.description)
          }

          // 状態表示
          HStack {
            statusBadge
            Spacer()
            Text(dateString)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        // 散歩統計情報
        if walk.isCompleted || walk.isInProgress {
          statisticsSection
        }

        // 位置情報がある場合はマップを表示
        if walk.hasLocation {
          mapSection
        }

        Spacer(minLength: 50)
      }
      .padding()
    }
    .navigationTitle("散歩詳細")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      Button(action: { refreshWalkDetails() }) {
        Image(systemName: "arrow.clockwise")
      }
    }
    .loadingOverlay(isLoading: isLoading)
    .onAppear {
      refreshWalkDetails()
    }
  }

  // 状態バッジ
  private var statusBadge: some View {
    Text(walk.status.displayName)
      .font(.caption)
      .fontWeight(.medium)
      .padding(.horizontal, 12)
      .padding(.vertical, 4)
      .background(statusColor.opacity(0.1))
      .foregroundColor(statusColor)
      .cornerRadius(8)
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

  // 統計情報セクション
  private var statisticsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("散歩情報")
        .font(.headline)

      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible())
        ], spacing: 16
      ) {
        StatisticCard(
          title: "経過時間",
          value: walk.durationString,
          icon: "clock"
        )

        StatisticCard(
          title: "距離",
          value: walk.distanceString,
          icon: "figure.walk"
        )

        if walk.totalSteps > 0 {
          StatisticCard(
            title: "歩数",
            value: "\(walk.totalSteps)歩",
            icon: "shoe"
          )
        }

        StatisticCard(
          title: "記録地点",
          value: "\(walk.locations.count)地点",
          icon: "location"
        )
      }
    }
  }

  // マップセクション
  private var mapSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("ルートマップ")
        .font(.headline)

      if let location = walk.location {
        // iOS 17以上と未満で分岐
        if #available(iOS 17.0, *) {
          // iOS 17以上用のマップ表示
          Map(
            initialPosition: .region(
              MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
              ))
          ) {
            // 散歩の軌跡を表示
            ForEach(Array(walk.locations.enumerated()), id: \.offset) { index, walkLocation in
              let isStart = index == 0
              let isEnd = index == walk.locations.count - 1

              Annotation(
                isStart ? "開始地点" : (isEnd ? "終了地点" : ""),
                coordinate: walkLocation.coordinate
              ) {
                Image(
                  systemName: isStart
                    ? "play.circle.fill" : (isEnd ? "stop.circle.fill" : "circle.fill")
                )
                .foregroundColor(isStart ? .green : (isEnd ? .red : .blue))
                .font(.title2)
              }
            }
          }
          .frame(height: 250)
          .cornerRadius(12)
        } else {
          // iOS 15-16用のマップ表示
          let region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
          )

          let annotations = walk.locations.enumerated().map { index, walkLocation in
            let isStart = index == 0
            let isEnd = index == walk.locations.count - 1
            return MapItem(
              coordinate: walkLocation.coordinate,
              title: isStart ? "開始地点" : (isEnd ? "終了地点" : ""),
              imageName: isStart ? "play.circle.fill" : (isEnd ? "stop.circle.fill" : "circle.fill")
            )
          }

          Map(coordinateRegion: .constant(region), annotationItems: annotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
              Image(systemName: item.imageName)
                .foregroundColor(.red)
                .font(.title2)
            }
          }
          .frame(height: 250)
          .cornerRadius(12)
        }
      }

      // 位置情報の詳細
      if let startTime = walk.startTime {
        VStack(alignment: .leading, spacing: 4) {
          Text("開始時刻: \(startTime.formatted(date: .abbreviated, time: .shortened))")
            .font(.caption)
            .foregroundColor(.secondary)

          if let endTime = walk.endTime {
            Text("終了時刻: \(endTime.formatted(date: .abbreviated, time: .shortened))")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
    }
  }

  // 日時文字列
  private var dateString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")

    if let startTime = walk.startTime {
      return formatter.string(from: startTime)
    } else {
      return formatter.string(from: walk.createdAt)
    }
  }

  // 記録の詳細を更新
  private func refreshWalkDetails() {
    isLoading = true
    walkRepository.fetchWalk(withID: walk.id) { result in
      DispatchQueue.main.async {
        self.isLoading = false
        switch result {
        case .success(let updatedWalk):
          self.walk = updatedWalk
        case .failure(let error):
          // エラーログは適切なロギングシステムに記録
          #if DEBUG
          print("Error refreshing walk details: \(error)")
          #endif
        }
      }
    }
  }
}

// 統計カード
struct StatisticCard: View {
  let title: String
  let value: String
  let icon: String

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.blue)

      VStack(spacing: 2) {
        Text(value)
          .font(.headline)
          .fontWeight(.bold)

        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }
}

#Preview {
  NavigationView {
    DetailView(
      walk: Walk(
        title: "朝の散歩",
        description: "公園を一周しました。天気が良くて気持ちよかったです。",
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 1200,
        totalSteps: 1500,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6812, longitude: 139.7671),
          CLLocation(latitude: 35.6815, longitude: 139.7675),
          CLLocation(latitude: 35.6818, longitude: 139.7680)
        ]
      ))
  }
}
