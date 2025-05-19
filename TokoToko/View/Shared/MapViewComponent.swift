//
//  MapViewComponent.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/18.
//

import MapKit
import SwiftUI
import _MapKit_SwiftUI

struct MapViewComponent: View {
  // 位置情報マネージャー
  private let locationManager = LocationManager.shared
  @State private var region: MKCoordinateRegion
  @State private var cameraPosition: MapCameraPosition

  // 表示するアノテーション
  var annotations: [MapItem] = []

  init(
    region: MKCoordinateRegion = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),  // 東京駅をデフォルト位置に
      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ), annotations: [MapItem] = []
  ) {
    _region = State(initialValue: region)
    _cameraPosition = State(
      initialValue: .userLocation(followsHeading: true, fallback: .region(region)))
    self.annotations = annotations
  }

  var body: some View {
    Map(position: $cameraPosition) {
      ForEach(annotations) { item in
        Annotation(item.title, coordinate: item.coordinate) {
          VStack {
            Image(systemName: item.imageName)
              .foregroundColor(.red)
              .font(.title)

            Text(item.title)
              .font(.caption)
              .foregroundColor(.black)
              .background(Color.white.opacity(0.7))
              .cornerRadius(5)
          }
        }
      }
    }
    .mapControls {
      MapUserLocationButton()
    }
    .onAppear {
      // 現在位置が取得できている場合は、その位置にマップを移動
      if let location = locationManager.currentLocation {
        region = locationManager.region(for: location)
        cameraPosition = .userLocation(followsHeading: true, fallback: .region(region))
      }

      // 位置情報の許可状態を確認し、許可されている場合のみ更新を開始
      let status = locationManager.checkAuthorizationStatus()
      if status == .authorizedWhenInUse || status == .authorizedAlways {
        locationManager.startUpdatingLocation()
      }
    }
    .onDisappear {
      // 画面を離れる時に位置情報の更新を停止（必要に応じて）
      // locationManager.stopUpdatingLocation()
    }
    .onChange(of: locationManager.currentLocation) { oldLocation, newLocation in
      // 位置情報が更新されたらマップを移動
      if let location = newLocation {
        region = locationManager.region(for: location)
        cameraPosition = .userLocation(followsHeading: true, fallback: .region(region))
      }
    }
  }
}

#Preview {
  MapViewComponent()
}
