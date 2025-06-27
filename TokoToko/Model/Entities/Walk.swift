//
//  Walk.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import FirebaseFirestore
import Foundation

// 散歩の状態を表す列挙型
enum WalkStatus: String, CaseIterable, Codable {
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

struct Walk: Identifiable, Codable {
  let id: UUID
  var userId: String?
  var title: String
  var description: String
  var startTime: Date?
  var endTime: Date?
  var totalDistance: Double = 0.0  // メートル単位
  var totalSteps: Int = 0
  var polylineData: String?  // 散歩ルートのポリライン文字列
  // 散歩の状態管理
  var status: WalkStatus = .notStarted
  // 一時停止時間の記録
  var pausedAt: Date?  // 一時停止された時刻
  var totalPausedDuration: TimeInterval = 0.0  // 累積一時停止時間
  // 位置情報の配列（散歩中に記録される位置情報）
  var locations: [CLLocation] = []
  // 従来の互換性のための位置情報（開始地点として使用）
  var location: CLLocationCoordinate2D? {
    locations.first?.coordinate
  }
  var createdAt: Date
  var updatedAt: Date

  init(
    title: String,
    description: String,
    userId: String? = nil,
    id: UUID = UUID(),
    startTime: Date? = nil,
    endTime: Date? = nil,
    totalDistance: Double = 0.0,
    totalSteps: Int = 0,
    polylineData: String? = nil,
    status: WalkStatus = .notStarted,
    pausedAt: Date? = nil,
    totalPausedDuration: TimeInterval = 0.0,
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
    self.pausedAt = pausedAt
    self.totalPausedDuration = totalPausedDuration
    self.locations = locations
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  // 位置情報を持っているかどうか
  var hasLocation: Bool {
    !locations.isEmpty
  }

  // 位置情報を文字列で表示
  var locationString: String {
    guard let location = location else { return "位置情報なし" }
    return "緯度: \(location.latitude), 経度: \(location.longitude)"
  }

  // 散歩の経過時間を計算（一時停止時間を除く）
  var duration: TimeInterval {
    guard let startTime = startTime else { return 0 }
    let endTime = self.endTime ?? Date()
    let totalTime = endTime.timeIntervalSince(startTime)

    // 現在一時停止中の場合、pausedAtからの時間も除外する
    var currentPauseDuration: TimeInterval = 0
    if status == .paused, let pausedAt = pausedAt {
      currentPauseDuration = Date().timeIntervalSince(pausedAt)
    }

    // 総時間から累積一時停止時間と現在の一時停止時間を引く
    return totalTime - totalPausedDuration - currentPauseDuration
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
    status == .inProgress
  }

  // 散歩が完了しているかどうか
  var isCompleted: Bool {
    status == .completed
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
    guard status == .inProgress else { return }
    status = .paused
    pausedAt = Date()
    updatedAt = Date()
  }

  // 散歩を再開
  mutating func resume() {
    guard status == .paused, let pausedAt = pausedAt else { return }
    status = .inProgress

    // 一時停止していた時間を累積に追加
    let pauseDuration = Date().timeIntervalSince(pausedAt)
    totalPausedDuration += pauseDuration

    // 一時停止時刻をクリア
    self.pausedAt = nil
    updatedAt = Date()
  }

  // 散歩を完了
  mutating func complete() {
    // 一時停止中に完了した場合、最後の一時停止時間も累積に追加
    if status == .paused, let pausedAt = pausedAt {
      let pauseDuration = Date().timeIntervalSince(pausedAt)
      totalPausedDuration += pauseDuration
      self.pausedAt = nil
    }

    endTime = Date()
    status = .completed
    updatedAt = Date()
  }
}

// MARK: - Firestore Codable Support
extension Walk {
  // Firestore用のCodingKeys
  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case title
    case description
    case startTime = "start_time"
    case endTime = "end_time"
    case totalDistance = "total_distance"
    case totalSteps = "total_steps"
    case polylineData = "polyline_data"
    case status
    case pausedAt = "paused_at"
    case totalPausedDuration = "total_paused_duration"
    case locationData = "location_data"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  // CLLocationをシリアライズするための構造体
  struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
    let horizontalAccuracy: Double
    let verticalAccuracy: Double
    let speed: Double
    let course: Double

    init(from location: CLLocation) {
      self.latitude = location.coordinate.latitude
      self.longitude = location.coordinate.longitude
      self.altitude = location.altitude
      self.timestamp = location.timestamp
      self.horizontalAccuracy = location.horizontalAccuracy
      self.verticalAccuracy = location.verticalAccuracy
      self.speed = location.speed
      self.course = location.course
    }

    func toCLLocation() -> CLLocation {
      let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      return CLLocation(
        coordinate: coordinate,
        altitude: altitude,
        horizontalAccuracy: horizontalAccuracy,
        verticalAccuracy: verticalAccuracy,
        course: course,
        speed: speed,
        timestamp: timestamp
      )
    }
  }

  // カスタムエンコーディング
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id.uuidString, forKey: .id)
    try container.encodeIfPresent(userId, forKey: .userId)
    try container.encode(title, forKey: .title)
    try container.encode(description, forKey: .description)
    try container.encodeIfPresent(startTime, forKey: .startTime)
    try container.encodeIfPresent(endTime, forKey: .endTime)
    try container.encode(totalDistance, forKey: .totalDistance)
    try container.encode(totalSteps, forKey: .totalSteps)
    try container.encodeIfPresent(polylineData, forKey: .polylineData)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(pausedAt, forKey: .pausedAt)
    try container.encode(totalPausedDuration, forKey: .totalPausedDuration)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)

    // CLLocation配列をLocationData配列に変換
    let locationDataArray = locations.map { LocationData(from: $0) }
    try container.encode(locationDataArray, forKey: .locationData)
  }

  // カスタムデコーディング
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let idString = try container.decode(String.self, forKey: .id)
    guard let uuid = UUID(uuidString: idString) else {
      throw DecodingError.dataCorruptedError(
        forKey: .id, in: container, debugDescription: "Invalid UUID string")
    }
    self.id = uuid

    self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
    self.title = try container.decode(String.self, forKey: .title)
    self.description = try container.decode(String.self, forKey: .description)
    self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
    self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
    self.totalDistance = try container.decode(Double.self, forKey: .totalDistance)
    self.totalSteps = try container.decode(Int.self, forKey: .totalSteps)
    self.polylineData = try container.decodeIfPresent(String.self, forKey: .polylineData)
    self.status = try container.decode(WalkStatus.self, forKey: .status)
    self.pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
    self.totalPausedDuration = try container.decode(TimeInterval.self, forKey: .totalPausedDuration)
    self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)

    // LocationData配列をCLLocation配列に変換
    let locationDataArray = try container.decode([LocationData].self, forKey: .locationData)
    self.locations = locationDataArray.map { $0.toCLLocation() }
  }
}
