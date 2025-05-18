//
//  Walk.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import Foundation

struct Walk: Identifiable {
  let id: UUID
  var title: String
  var description: String
  var location: CLLocationCoordinate2D?
  var createdAt: Date

  init(
    id: UUID = UUID(), title: String, description: String, location: CLLocationCoordinate2D? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.location = location
    self.createdAt = createdAt
  }

  // 位置情報を持っているかどうか
  var hasLocation: Bool {
    return location != nil
  }

  // 位置情報を文字列で表示
  var locationString: String {
    guard let location = location else { return "位置情報なし" }
    return "緯度: \(location.latitude), 経度: \(location.longitude)"
  }
}
