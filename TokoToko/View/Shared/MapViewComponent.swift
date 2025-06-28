//
//  MapViewComponent.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/18.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapViewComponent: View {
  // 位置情報マネージャー
  private let locationManager = LocationManager.shared
  @State private var region: MKCoordinateRegion

  // 表示するアノテーション
  var annotations: [MapItem] = []

  // 表示するポリライン座標
  var polylineCoordinates: [CLLocationCoordinate2D] = []

  // ユーザー位置を表示するかどうか
  var showsUserLocation: Bool = true

  init(
    region: MKCoordinateRegion = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),  // 東京駅をデフォルト位置に
      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ),
    annotations: [MapItem] = [],
    polylineCoordinates: [CLLocationCoordinate2D] = [],
    showsUserLocation: Bool = true
  ) {
    _region = State(initialValue: region)
    self.annotations = annotations
    self.polylineCoordinates = polylineCoordinates
    self.showsUserLocation = showsUserLocation
  }

  var body: some View {
    // マップコンポーネント初期化の計測
    let _ = PerformanceMeasurement.shared.startMeasurement(
      operationName: "MapViewComponent.init",
      additionalInfo: [
        "annotationCount": annotations.count,
        "polylinePointCount": polylineCoordinates.count,
        "showsUserLocation": showsUserLocation
      ]
    )
    
    // iOS 17以上と未満で分岐
    let mapView = Group {
      if #available(iOS 17.0, *) {
        iOS17MapView(
          region: $region, annotations: annotations, polylineCoordinates: polylineCoordinates,
          showsUserLocation: showsUserLocation, locationManager: locationManager)
      } else {
        iOS15MapView(
          region: $region, annotations: annotations, polylineCoordinates: polylineCoordinates,
          showsUserLocation: showsUserLocation, locationManager: locationManager)
      }
    }
    .onAppear {
      // マップ表示完了の計測
      PerformanceMeasurement.shared.endMeasurement(
        operationName: "MapViewComponent.init",
        additionalInfo: [
          "annotationCount": annotations.count,
          "polylinePointCount": polylineCoordinates.count,
          "showsUserLocation": showsUserLocation
        ]
      )
    }
    
    return mapView
  }
}

// iOS 17以上用のマップビュー
@available(iOS 17.0, *)
private struct iOS17MapView: View {
  @Binding var region: MKCoordinateRegion
  var annotations: [MapItem]
  var polylineCoordinates: [CLLocationCoordinate2D]
  var showsUserLocation: Bool
  var locationManager: LocationManager
  @State private var cameraPosition: MapCameraPosition

  init(
    region: Binding<MKCoordinateRegion>,
    annotations: [MapItem],
    polylineCoordinates: [CLLocationCoordinate2D],
    showsUserLocation: Bool,
    locationManager: LocationManager
  ) {
    self._region = region
    self.annotations = annotations
    self.polylineCoordinates = polylineCoordinates
    self.showsUserLocation = showsUserLocation
    self.locationManager = locationManager
    self._cameraPosition = State(
      initialValue: .userLocation(followsHeading: true, fallback: .region(region.wrappedValue)))
  }

  var body: some View {
    Map(position: $cameraPosition) {
      // ユーザー位置表示（散歩中の場合のみ）
      if showsUserLocation {
        UserAnnotation()
      }

      // アノテーション表示
      ForEach(annotations) { item in
        Annotation("", coordinate: item.coordinate) {
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

      // ポリライン表示
      if polylineCoordinates.count >= 2 {
        MapPolyline(coordinates: polylineCoordinates)
          .stroke(.blue, lineWidth: 4.0)
      }
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
    .onChange(of: locationManager.currentLocation) { _, newLocation in
      // 位置情報が更新されたらマップを移動
      if let location = newLocation {
        region = locationManager.region(for: location)
        cameraPosition = .userLocation(followsHeading: true, fallback: .region(region))
      }
    }
  }
}

// iOS 15-16用のマップビュー
private struct iOS15MapView: View {
  @Binding var region: MKCoordinateRegion
  var annotations: [MapItem]
  var polylineCoordinates: [CLLocationCoordinate2D]
  var showsUserLocation: Bool
  var locationManager: LocationManager

  var body: some View {
    ZStack {
      if polylineCoordinates.count >= 2 {
        // ポリライン用のUIViewRepresentableマップ
        iOS15MapWithPolylineView(
          region: $region,
          annotations: annotations,
          polylineCoordinates: polylineCoordinates,
          showsUserLocation: showsUserLocation
        )
      } else {
        // ポリラインなしの通常のマップ
        Map(
          coordinateRegion: $region, showsUserLocation: showsUserLocation,
          annotationItems: annotations
        ) { item in
          MapAnnotation(coordinate: item.coordinate) {
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
    }
    .onAppear {
      // 現在位置が取得できている場合は、その位置にマップを移動
      if let location = locationManager.currentLocation {
        region = locationManager.region(for: location)
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
    .onChange(of: locationManager.currentLocation) { newLocation in
      // 位置情報が更新されたらマップを移動
      if let location = newLocation {
        region = locationManager.region(for: location)
      }
    }
  }
}

// iOS 15-16用のポリライン対応マップビュー
private struct iOS15MapWithPolylineView: UIViewRepresentable {
  @Binding var region: MKCoordinateRegion
  var annotations: [MapItem]
  var polylineCoordinates: [CLLocationCoordinate2D]
  var showsUserLocation: Bool

  func makeUIView(context: Context) -> MKMapView {
    // UIViewRepresentable MKMapView作成の計測
    return measurePerformance(
      operationName: "MapViewComponent.makeUIView",
      additionalInfo: [
        "annotationCount": annotations.count,
        "polylinePointCount": polylineCoordinates.count
      ]
    ) {
      let mapView = MKMapView()
      mapView.delegate = context.coordinator
      mapView.showsUserLocation = showsUserLocation
      mapView.setRegion(region, animated: false)
      return mapView
    }
  }

  func updateUIView(_ mapView: MKMapView, context: Context) {
    // UIView更新の計測
    measurePerformance(
      operationName: "MapViewComponent.updateUIView",
      additionalInfo: [
        "annotationCount": annotations.count,
        "polylinePointCount": polylineCoordinates.count,
        "existingAnnotations": mapView.annotations.count,
        "existingOverlays": mapView.overlays.count
      ]
    ) {
      // リージョンの更新
      if !mapView.region.isApproximatelyEqual(to: region) {
        mapView.setRegion(region, animated: true)
      }

      // 既存のアノテーションとオーバーレイを削除
      mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
      mapView.removeOverlays(mapView.overlays)

      // アノテーションの追加
      for item in annotations {
        let annotation = MKPointAnnotation()
        annotation.coordinate = item.coordinate
        annotation.title = item.title
        mapView.addAnnotation(annotation)
      }

      // ポリラインの追加
      if polylineCoordinates.count >= 2 {
        let polyline = MKPolyline(coordinates: polylineCoordinates, count: polylineCoordinates.count)
        mapView.addOverlay(polyline)
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    var parent: iOS15MapWithPolylineView

    init(_ parent: iOS15MapWithPolylineView) {
      self.parent = parent
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if let polyline = overlay as? MKPolyline {
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
      }
      return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      parent.region = mapView.region
    }
  }
}

// MKCoordinateRegionの比較用拡張
extension MKCoordinateRegion {
  fileprivate func isApproximatelyEqual(to other: MKCoordinateRegion, tolerance: Double = 0.0001)
    -> Bool
  {
    abs(center.latitude - other.center.latitude) < tolerance
      && abs(center.longitude - other.center.longitude) < tolerance
      && abs(span.latitudeDelta - other.span.latitudeDelta) < tolerance
      && abs(span.longitudeDelta - other.span.longitudeDelta) < tolerance
  }
}

#Preview {
  MapViewComponent()
}
