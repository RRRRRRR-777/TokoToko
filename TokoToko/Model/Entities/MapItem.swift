//
//  MapItem.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/18.
//

import CoreLocation
import Foundation

// マップ上に表示するアイテムのモデル
struct MapItem: Identifiable {
  let id: UUID
  let coordinate: CLLocationCoordinate2D
  let title: String
  let imageName: String

  init(
    coordinate: CLLocationCoordinate2D,
    title: String,
    imageName: String = "mappin.circle.fill",
    id: UUID = UUID()
  ) {
    self.id = id
    self.coordinate = coordinate
    self.title = title
    self.imageName = imageName
  }
}