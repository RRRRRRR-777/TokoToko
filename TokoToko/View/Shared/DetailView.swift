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
  @State private var showingDeleteAlert = false
  @Environment(\.presentationMode) var presentationMode

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
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button(action: { refreshWalkDetails() }) {
            Label("更新", systemImage: "arrow.clockwise")
          }
          if walk.isCompleted {
            Button(action: { showingDeleteAlert = true }) {
              Label("削除", systemImage: "trash")
            }
            .foregroundColor(.red)
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .loadingOverlay(isLoading: isLoading)
    .alert("散歩を削除", isPresented: $showingDeleteAlert) {
      Button("削除", role: .destructive) {
        deleteWalk()
      }
      Button("キャンセル", role: .cancel) {}
    } message: {
      Text("この散歩記録を削除しますか？この操作は取り消せません。")
    }
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

      if walk.hasLocation {
        MapSectionView(walk: walk)
          .frame(height: 250)
          .cornerRadius(12)
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

  // 散歩ルート全体を含む領域を計算
  private func calculateRegionForWalk() -> MKCoordinateRegion {
    guard !walk.locations.isEmpty else {
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }

    // 1つの座標のみの場合
    if walk.locations.count == 1 {
      guard let firstLocation = walk.locations.first else {
        return MKCoordinateRegion(
          center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
          span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
      }
      return MKCoordinateRegion(
        center: firstLocation.coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }

    // 全座標の境界を計算
    let coordinates = walk.locations.map { $0.coordinate }
    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }

    let minLat = latitudes.min() ?? 0
    let maxLat = latitudes.max() ?? 0
    let minLon = longitudes.min() ?? 0
    let maxLon = longitudes.max() ?? 0

    // 中心点を計算
    let centerLat = (minLat + maxLat) / 2
    let centerLon = (minLon + maxLon) / 2

    // スパンを計算（詳細画面ではルート全体が確実に表示されるよう余裕を持たせる）
    let latDelta = max((maxLat - minLat) * 1.4, 0.004)  // 詳細画面では40%のマージンと適切な最小値を設定
    let lonDelta = max((maxLon - minLon) * 1.4, 0.004)  // 詳細画面では40%のマージンと適切な最小値を設定

    return MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
      span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
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

  // 散歩を削除
  private func deleteWalk() {
    isLoading = true
    walkRepository.deleteWalk(withID: walk.id) { result in
      DispatchQueue.main.async {
        self.isLoading = false
        switch result {
        case .success:
          // 削除成功時は前の画面に戻る
          self.presentationMode.wrappedValue.dismiss()
        case .failure(let error):
          // エラーログは適切なロギングシステムに記録
          #if DEBUG
            print("Error deleting walk: \(error)")
          #endif
        }
      }
    }
  }
}

// マップセクション用のビュー
struct MapSectionView: View {
  let walk: Walk
  @State private var region: MKCoordinateRegion

  init(walk: Walk) {
    self.walk = walk
    self._region = State(initialValue: Self.calculateRegionForWalk(walk))
  }

  var body: some View {
    MapViewComponent(
      region: $region,
      annotations: mapAnnotations,
      polylineCoordinates: walk.locations.map { $0.coordinate },
      showsUserLocation: false
    )
    .onAppear {
      region = Self.calculateRegionForWalk(walk)
    }
  }

  private var mapAnnotations: [MapItem] {
    guard !walk.locations.isEmpty else { return [] }

    var items: [MapItem] = []

    // 開始地点
    if let firstLocation = walk.locations.first {
      items.append(
        MapItem(
          coordinate: firstLocation.coordinate,
          title: "開始地点",
          imageName: "play.circle.fill"
        )
      )
    }

    // 終了地点（開始地点と異なる場合のみ）
    if let lastLocation = walk.locations.last, walk.locations.count > 1 {
      items.append(
        MapItem(
          coordinate: lastLocation.coordinate,
          title: "終了地点",
          imageName: "checkmark.circle.fill"
        )
      )
    }

    return items
  }

  private static func calculateRegionForWalk(_ walk: Walk) -> MKCoordinateRegion {
    guard !walk.locations.isEmpty else {
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }

    if walk.locations.count == 1 {
      let coordinate = walk.locations[0].coordinate
      return MKCoordinateRegion(
        center: coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }

    let coordinates = walk.locations.map { $0.coordinate }
    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }

    let minLat = latitudes.min() ?? 0
    let maxLat = latitudes.max() ?? 0
    let minLon = longitudes.min() ?? 0
    let maxLon = longitudes.max() ?? 0

    let centerLat = (minLat + maxLat) / 2
    let centerLon = (minLon + maxLon) / 2

    let latDelta = max((maxLat - minLat) * 1.4, 0.004)
    let lonDelta = max((maxLon - minLon) * 1.4, 0.004)

    return MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
      span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
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
