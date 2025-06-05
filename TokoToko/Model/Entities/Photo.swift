//
//  Photo.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import CoreLocation
import Foundation

struct Photo: Identifiable {
  let id: UUID
  var walkId: UUID // 関連する散歩のID
  var imageUrl: String // 写真が保存されているURL
  var latitude: Double // 撮影場所の緯度
  var longitude: Double // 撮影場所の経度
  var timestamp: Date // 撮影時刻
  var order: Int // 表示順（1～10など）
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    walkId: UUID,
    imageUrl: String,
    latitude: Double,
    longitude: Double,
    timestamp: Date = Date(),
    order: Int = 1,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.walkId = walkId
    self.imageUrl = imageUrl
    self.latitude = latitude
    self.longitude = longitude
    self.timestamp = timestamp
    self.order = order
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  // 撮影場所の座標を取得
  var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  // 撮影場所のCLLocationを取得
  var location: CLLocation {
    return CLLocation(
      coordinate: coordinate,
      altitude: 0,
      horizontalAccuracy: 0,
      verticalAccuracy: 0,
      timestamp: timestamp
    )
  }

  // 画像URLが有効かどうか
  var hasValidImageUrl: Bool {
    return !imageUrl.isEmpty && URL(string: imageUrl) != nil
  }

  // 撮影時刻を文字列で表示
  var timestampString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: timestamp)
  }

  // 位置情報を文字列で表示
  var locationString: String {
    return "緯度: \(latitude), 経度: \(longitude)"
  }
}
