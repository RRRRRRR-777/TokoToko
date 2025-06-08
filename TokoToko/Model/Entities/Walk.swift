//
//  Walk.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import Foundation

// 散歩の状態を表す列挙型
enum WalkStatus: String, CaseIterable {
  case notStarted = "not_started"
  case inProgress = "in_progress"
  case paused = "paused"
  case completed = "completed"

  var displayName: String {
    switch self {
    case .notStarted:
      return "未開始"
    case .inProgress:
      return "記録中"
    case .paused:
      return "一時停止"
    case .completed:
      return "完了"
    }
  }
}

struct Walk: Identifiable {
  let id: UUID
  var userId: String?  // ユーザーID（ER図に合わせて追加）
  var title: String
  var description: String

  // ER図に合わせた散歩記録の詳細情報
  var startTime: Date?
  var endTime: Date?
  var totalDistance: Double = 0.0  // メートル単位
  var totalSteps: Int = 0
  var polylineData: String?  // 散歩ルートのポリライン文字列

  // 散歩の状態管理
  var status: WalkStatus = .notStarted

  // 位置情報の配列（散歩中に記録される位置情報）
  var locations: [CLLocation] = []

  // 従来の互換性のための位置情報（開始地点として使用）
  var location: CLLocationCoordinate2D? {
    return locations.first?.coordinate
  }

  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    userId: String? = nil,
    title: String,
    description: String,
    startTime: Date? = nil,
    endTime: Date? = nil,
    totalDistance: Double = 0.0,
    totalSteps: Int = 0,
    polylineData: String? = nil,
    status: WalkStatus = .notStarted,
    locations: [CLLocation] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.userId = userId
    self.title = title
    self.description = description
    self.startTime = startTime
    self.endTime = endTime
    self.totalDistance = totalDistance
    self.totalSteps = totalSteps
    self.polylineData = polylineData
    self.status = status
    self.locations = locations
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  // 位置情報を持っているかどうか
  var hasLocation: Bool {
    return !locations.isEmpty
  }

  // 位置情報を文字列で表示
  var locationString: String {
    guard let location = location else { return "位置情報なし" }
    return "緯度: \(location.latitude), 経度: \(location.longitude)"
  }

  // 散歩の経過時間を計算
  var duration: TimeInterval {
    guard let startTime = startTime else { return 0 }
    let endTime = self.endTime ?? Date()
    return endTime.timeIntervalSince(startTime)
  }

  // 散歩の経過時間を文字列で表示
  var durationString: String {
    let duration = self.duration
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }

  // 距離を文字列で表示
  var distanceString: String {
    if totalDistance >= 1000 {
      return String(format: "%.2f km", totalDistance / 1000)
    } else {
      return String(format: "%.0f m", totalDistance)
    }
  }

  // 散歩が進行中かどうか
  var isInProgress: Bool {
    return status == .inProgress
  }

  // 散歩が完了しているかどうか
  var isCompleted: Bool {
    return status == .completed
  }

  // 位置情報を追加
  mutating func addLocation(_ location: CLLocation) {
    locations.append(location)
    updateDistance()
    updatedAt = Date()
  }

  // 距離を再計算
  private mutating func updateDistance() {
    guard locations.count > 1 else {
      totalDistance = 0
      return
    }

    var distance: Double = 0
    for i in 1..<locations.count {
      distance += locations[i - 1].distance(from: locations[i])
    }
    totalDistance = distance
  }

  // 散歩を開始
  mutating func start() {
    startTime = Date()
    status = .inProgress
    updatedAt = Date()
  }

  // 散歩を一時停止
  mutating func pause() {
    status = .paused
    updatedAt = Date()
  }

  // 散歩を再開
  mutating func resume() {
    status = .inProgress
    updatedAt = Date()
  }

  // 散歩を完了
  mutating func complete() {
    endTime = Date()
    status = .completed
    updatedAt = Date()
  }
}
