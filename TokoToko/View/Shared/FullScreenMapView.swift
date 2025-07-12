//
//  FullScreenMapView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/12.
//

import MapKit
import SwiftUI

struct FullScreenMapView: View {
  let walk: Walk
  @State private var region: MKCoordinateRegion

  init(walk: Walk) {
    self.walk = walk
    self._region = State(initialValue: Self.calculateRegionForWalk(walk))
  }

  var body: some View {
    ZStack {
      MapViewComponent(
        region: region,
        annotations: mapAnnotations,
        polylineCoordinates: walk.locations.map { $0.coordinate },
        showsUserLocation: false
      )
    }
    .ignoresSafeArea()
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
        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
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

#Preview {
  FullScreenMapView(
    walk: Walk(
      title: "サンプル散歩",
      description: "テスト用",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1500,
      totalSteps: 2000,
      status: .completed,
      locations: [
        CLLocation(latitude: 35.6812, longitude: 139.7671),
        CLLocation(latitude: 35.6815, longitude: 139.7675),
        CLLocation(latitude: 35.6818, longitude: 139.7680),
      ]
    )
  )
}
