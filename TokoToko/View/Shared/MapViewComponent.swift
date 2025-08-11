//
//  MapViewComponent.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/18.
//

import CoreLocation
import MapKit
import SwiftUI

/// 散歩ルートとアノテーションを表示するカスタムマップコンポーネント
///
/// `MapViewComponent`はSwiftUIのMapと組み合わせて、散歩アプリケーション専用の
/// マップ表示機能を提供します。GPS軌跡のポリライン表示、写真位置のマーカー表示、
/// ユーザー位置の追跡機能を統合しています。
///
/// ## Overview
///
/// - **ルート表示**: GPS座標列からポリラインを生成し散歩ルートを可視化
/// - **アノテーション**: 写真撮影地点や特定位置にカスタムマーカーを表示
/// - **位置追跡**: ユーザーの現在位置をリアルタイムで表示
/// - **インタラクティブ**: ズーム、パン、マーカータップなどのユーザー操作に対応
///
/// ## Topics
///
/// ### Properties
/// - ``region``
/// - ``annotations``
/// - ``polylineCoordinates``
/// - ``showsUserLocation``
///
/// ### Initialization
/// - ``init(region:annotations:polylineCoordinates:showsUserLocation:)``
struct MapViewComponent: View {
  /// 位置情報の管理を担当するLocationManagerインスタンス
  ///
  /// GPS位置情報の取得、権限管理、現在位置の監視を統合的に処理します。
  private let locationManager = LocationManager.shared

  /// マップ表示領域の座標範囲
  ///
  /// 表示するマップの中心座標とズームレベルを定義するバインディングプロパティです。
  /// 親ビューから渡され、ユーザーの操作に応じて動的に更新されます。
  @Binding var region: MKCoordinateRegion

  /// マップ上に表示するアノテーション配列
  ///
  /// 写真の撮影地点、興味のあるポイント、その他のカスタムマーカーを表現するMapItemの配列です。
  /// 各アノテーションはタイトル、座標、アイコンを持ちます。
  var annotations: [MapItem] = []

  /// 散歩ルートを描画するためのGPS座標配列
  ///
  /// 散歩中に記録されたGPS位置情報から生成される座標列で、
  /// マップ上にポリライン（線分の連続）として散歩ルートを可視化します。
  var polylineCoordinates: [CLLocationCoordinate2D] = []

  /// ユーザーの現在位置を表示するかどうかのフラグ
  ///
  /// trueの場合、マップ上にユーザーの現在位置が青い円で表示されます。
  /// プライバシー保護や特定の表示モードでfalseに設定可能です。
  var showsUserLocation: Bool = true

  /// MapViewComponentの主要初期化メソッド
  ///
  /// リージョンバインディングとマップ表示要素を指定してマップコンポーネントを初期化します。
  ///
  /// - Parameters:
  ///   - region: マップ表示領域のバインディング
  ///   - annotations: 表示するアノテーションの配列（デフォルト: 空配列）
  ///   - polylineCoordinates: 散歩ルート描画用の座標配列（デフォルト: 空配列）
  ///   - showsUserLocation: ユーザー位置表示の有無（デフォルト: true）
  init(
    region: Binding<MKCoordinateRegion>,
    annotations: [MapItem] = [],
    polylineCoordinates: [CLLocationCoordinate2D] = [],
    showsUserLocation: Bool = true
  ) {
    self._region = region
    self.annotations = annotations
    self.polylineCoordinates = polylineCoordinates
    self.showsUserLocation = showsUserLocation
  }

  /// デフォルトリージョン用の便利な初期化メソッド
  ///
  /// リージョンを東京駅中心の固定値に設定してマップコンポーネントを初期化します。
  /// テストやプロトタイプ、初期位置が不明な場合に使用します。
  ///
  /// - Parameters:
  ///   - annotations: 表示するアノテーションの配列（デフォルト: 空配列）
  ///   - polylineCoordinates: 散歩ルート描画用の座標配列（デフォルト: 空配列）
  ///   - showsUserLocation: ユーザー位置表示の有無（デフォルト: true）
  init(
    annotations: [MapItem] = [],
    polylineCoordinates: [CLLocationCoordinate2D] = [],
    showsUserLocation: Bool = true
  ) {
    self._region = .constant(
      MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),  // 東京駅をデフォルト位置に
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
      ))
    self.annotations = annotations
    self.polylineCoordinates = polylineCoordinates
    self.showsUserLocation = showsUserLocation
  }

  var body: some View {
    // iOS 17以上と未満で分岐
    Group {
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
    .accessibilityIdentifier("MapView")
  }
}

/// iOS 17以上用のマップビュー実装
///
/// iOS 17で導入された新しいMapKit APIを使用したマップビューコンポーネントです。
/// 改善されたパフォーマンスと新機能（MapCameraPosition、Map構文など）を活用しています。
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

/// iOS 15-16用のマップビュー実装
///
/// iOS 15-16で利用可能なMapKit APIを使用したマップビューコンポーネントです。
/// 従来のMap構文とUIViewRepresentableを組み合わせてポリライン表示を実現します。
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

/// iOS 15-16用のポリライン対応マップビュー
///
/// iOS 15-16でポリライン表示を実現するためのUIViewRepresentableラッパーです。
/// MKMapViewを直接使用してポリラインのレンダリングとユーザーインタラクションを処理します。
private struct iOS15MapWithPolylineView: UIViewRepresentable {
  @Binding var region: MKCoordinateRegion
  var annotations: [MapItem]
  var polylineCoordinates: [CLLocationCoordinate2D]
  var showsUserLocation: Bool

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.showsUserLocation = showsUserLocation
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

  /// iOS15MapWithPolylineViewのCoordinator
  ///
  /// MKMapViewDelegateプロトコルを実装し、ポリラインレンダリングと
  /// マップ領域変更イベントを処理します。
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

/// MKCoordinateRegionの比較用拡張
///
/// 座標領域の近似的な等価比較を行うためのヘルパーメソッドを提供します。
/// 浮動小数点数の精度問題を考慮して、指定された許容範囲内での比較を行います。
extension MKCoordinateRegion {
  /// 2つのMKCoordinateRegionが近似的に等しいかどうかを判定
  ///
  /// 浮動小数点数の精度問題を考慮して、指定された許容値内で
  /// 中心座標とスパンが等しいかどうかを判定します。
  ///
  /// - Parameters:
  ///   - other: 比較対象のMKCoordinateRegion
  ///   - tolerance: 許容誤差（デフォルト: 0.0001）
  /// - Returns: 近似的に等しい場合true
  fileprivate func isApproximatelyEqual(to other: MKCoordinateRegion, tolerance: Double = 0.0001)
    -> Bool {
    abs(center.latitude - other.center.latitude) < tolerance
      && abs(center.longitude - other.center.longitude) < tolerance
      && abs(span.latitudeDelta - other.span.latitudeDelta) < tolerance
      && abs(span.longitudeDelta - other.span.longitudeDelta) < tolerance
  }
}

#Preview {
  MapViewComponent(
    annotations: [],
    polylineCoordinates: [],
    showsUserLocation: true
  )
}
