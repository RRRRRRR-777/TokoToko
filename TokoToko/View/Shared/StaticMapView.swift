//
//  StaticMapView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/13.
//

import CoreLocation
import MapKit
import SwiftUI

/// 散歩履歴表示用の静的マップコンポーネント
/// 位置追跡を行わず、指定されたリージョンとデータのみを表示
struct StaticMapView: View {
  @Binding var region: MKCoordinateRegion
  var annotations: [MapItem] = []
  var polylineCoordinates: [CLLocationCoordinate2D] = []

  var body: some View {
    Group {
      if #available(iOS 17.0, *) {
        iOS17StaticMapView(
          region: $region,
          annotations: annotations,
          polylineCoordinates: polylineCoordinates
        )
      } else {
        iOS15StaticMapView(
          region: $region,
          annotations: annotations,
          polylineCoordinates: polylineCoordinates
        )
      }
    }
  }
}

// iOS 17以上用の静的マップビュー
@available(iOS 17.0, *)
private struct iOS17StaticMapView: View {
  @Binding var region: MKCoordinateRegion
  var annotations: [MapItem]
  var polylineCoordinates: [CLLocationCoordinate2D]
  @State private var cameraPosition: MapCameraPosition

  init(
    region: Binding<MKCoordinateRegion>,
    annotations: [MapItem],
    polylineCoordinates: [CLLocationCoordinate2D]
  ) {
    self._region = region
    self.annotations = annotations
    self.polylineCoordinates = polylineCoordinates
    self._cameraPosition = State(initialValue: .region(region.wrappedValue))
  }

  var body: some View {
    Map(position: $cameraPosition) {
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
      cameraPosition = .region(region)
    }
    .onChange(of: region.center.latitude) { _ in
      cameraPosition = .region(region)
    }
    .onChange(of: region.center.longitude) { _ in
      cameraPosition = .region(region)
    }
    .onChange(of: region.span.latitudeDelta) { _ in
      cameraPosition = .region(region)
    }
  }
}

// iOS 15-16用の静的マップビュー
private struct iOS15StaticMapView: View {
  @Binding var region: MKCoordinateRegion
  var annotations: [MapItem]
  var polylineCoordinates: [CLLocationCoordinate2D]

  var body: some View {
    if polylineCoordinates.count >= 2 {
      // ポリライン用のUIViewRepresentableマップ
      iOS15StaticMapWithPolylineView(
        region: $region,
        annotations: annotations,
        polylineCoordinates: polylineCoordinates
      )
    } else {
      // ポリラインなしの通常のマップ
      Map(
        coordinateRegion: $region,
        showsUserLocation: false,
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
}

// iOS 15-16用の静的ポリライン対応マップビュー
private struct iOS15StaticMapWithPolylineView: UIViewRepresentable {
  @Binding var region: MKCoordinateRegion
  var annotations: [MapItem]
  var polylineCoordinates: [CLLocationCoordinate2D]

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.showsUserLocation = false  // 位置追跡を無効化
    mapView.setRegion(region, animated: false)
    return mapView
  }

  func updateUIView(_ mapView: MKMapView, context: Context) {
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

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    var parent: iOS15StaticMapWithPolylineView

    init(_ parent: iOS15StaticMapWithPolylineView) {
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

// MKCoordinateRegionの比較用拡張（再利用）
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
  StaticMapView(
    region: .constant(
      MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    ),
    annotations: [
      MapItem(
        coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        title: "開始地点",
        imageName: "play.circle.fill"
      )
    ],
    polylineCoordinates: [
      CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
      CLLocationCoordinate2D(latitude: 35.6815, longitude: 139.7675),
      CLLocationCoordinate2D(latitude: 35.6818, longitude: 139.7680),
    ]
  )
}
