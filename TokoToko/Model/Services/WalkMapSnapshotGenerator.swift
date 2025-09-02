//
//  WalkMapSnapshotGenerator.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/08/30.
//

import CoreLocation
import MapKit
import UIKit

/// 散歩データからマップスナップショット画像を生成するクラス
enum WalkMapSnapshotGenerator {

  /// 散歩データからマップスナップショット画像を生成します
  ///
  /// - Parameters:
  ///   - walk: スナップショット対象の散歩データ
  ///   - size: スナップショットのサイズ
  /// - Returns: 生成されたマップ画像
  /// - Throws: WalkImageGeneratorError
  static func generateMapSnapshot(from walk: Walk, size: CGSize) async throws -> UIImage {
    try await withCheckedThrowingContinuation { continuation in
      let options = MKMapSnapshotter.Options()
      options.size = size

      let region = calculateRegion(for: walk.locations)
      options.region = region

      options.camera = MKMapCamera()
      options.camera.heading = 0
      options.camera.centerCoordinate = region.center
      options.camera.altitude = altitudeForRegion(region)

      let snapshotter = MKMapSnapshotter(options: options)

      snapshotter.start { snapshot, error in
        if let error = error {
          print("マップスナップショット生成エラー: \(error)")
          continuation.resume(throwing: WalkImageGeneratorError.mapSnapshotFailed)
          return
        }

        guard let snapshot = snapshot else {
          continuation.resume(throwing: WalkImageGeneratorError.mapSnapshotFailed)
          return
        }

        let finalMapImage = drawPolylineOnSnapshot(
          snapshot: snapshot,
          locations: walk.locations
        )
        continuation.resume(returning: finalMapImage)
      }
    }
  }

  /// スナップショットにポリラインを描画します
  ///
  /// - Parameters:
  ///   - snapshot: ベースとなるマップスナップショット
  ///   - locations: 散歩の位置情報配列
  /// - Returns: ポリライン描画済みの画像
  private static func drawPolylineOnSnapshot(
    snapshot: MKMapSnapshotter.Snapshot,
    locations: [CLLocation]
  ) -> UIImage {
    let image = snapshot.image

    UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
    image.draw(at: CGPoint.zero)

    guard let context = UIGraphicsGetCurrentContext() else {
      UIGraphicsEndImageContext()
      return image
    }

    if locations.count == 1 {
      drawSinglePointMarker(
        context: context,
        snapshot: snapshot,
        location: locations[0]
      )
    } else if locations.count >= 2 {
      drawPolyline(
        context: context,
        snapshot: snapshot,
        locations: locations
      )
    }

    let resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
    UIGraphicsEndImageContext()

    return resultImage
  }

  /// 単一点のマーカーを描画
  private static func drawSinglePointMarker(
    context: CGContext,
    snapshot: MKMapSnapshotter.Snapshot,
    location: CLLocation
  ) {
    let point = snapshot.point(for: location.coordinate)
    let markerRadius = WalkImageGeneratorConstants.MarkerSize.radius
    let innerRadius = WalkImageGeneratorConstants.MarkerSize.innerRadius

    context.setFillColor(UIColor.systemBlue.cgColor)
    context.fillEllipse(in: CGRect(
      x: point.x - markerRadius,
      y: point.y - markerRadius,
      width: markerRadius * 2,
      height: markerRadius * 2
    ))

    context.setFillColor(UIColor.white.cgColor)
    context.fillEllipse(in: CGRect(
      x: point.x - innerRadius,
      y: point.y - innerRadius,
      width: innerRadius * 2,
      height: innerRadius * 2
    ))
  }

  /// ポリラインを描画
  private static func drawPolyline(
    context: CGContext,
    snapshot: MKMapSnapshotter.Snapshot,
    locations: [CLLocation]
  ) {
    context.setStrokeColor(UIColor.systemBlue.cgColor)
    context.setLineWidth(8.0)
    context.setLineCap(.round)
    context.setLineJoin(.round)

    let firstPoint = snapshot.point(for: locations[0].coordinate)
    context.move(to: firstPoint)

    for i in 1..<locations.count {
      let point = snapshot.point(for: locations[i].coordinate)
      context.addLine(to: point)
    }

    context.strokePath()
  }

  /// 散歩ルートに適したマップリージョンを計算します
  ///
  /// - Parameter locations: 散歩の位置情報配列
  /// - Returns: 計算されたマップリージョン
  private static func calculateRegion(for locations: [CLLocation]) -> MKCoordinateRegion {
    guard !locations.isEmpty else {
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(
          latitudeDelta: WalkImageGeneratorConstants.MapSpan.defaultRegion,
          longitudeDelta: WalkImageGeneratorConstants.MapSpan.defaultRegion
        )
      )
    }

    if locations.count == 1 {
      return MKCoordinateRegion(
        center: locations[0].coordinate,
        span: MKCoordinateSpan(
          latitudeDelta: WalkImageGeneratorConstants.MapSpan.singlePoint,
          longitudeDelta: WalkImageGeneratorConstants.MapSpan.singlePoint
        )
      )
    }

    let coordinates = locations.map { $0.coordinate }
    guard let minLat = coordinates.map({ $0.latitude }).min(),
          let maxLat = coordinates.map({ $0.latitude }).max(),
          let minLon = coordinates.map({ $0.longitude }).min(),
          let maxLon = coordinates.map({ $0.longitude }).max() else {
      // 座標計算が失敗した場合はデフォルトリージョン（東京）を返す
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(
          latitudeDelta: WalkImageGeneratorConstants.MapSpan.defaultRegion,
          longitudeDelta: WalkImageGeneratorConstants.MapSpan.defaultRegion
        )
      )
    }

    let center = CLLocationCoordinate2D(
      latitude: (minLat + maxLat) / 2,
      longitude: (minLon + maxLon) / 2
    )

    let span = MKCoordinateSpan(
      latitudeDelta: (maxLat - minLat) * WalkImageGeneratorConstants.MapSpan.multiPointPadding / WalkImageGeneratorConstants.mapScaleFactor,
      longitudeDelta: (maxLon - minLon) * WalkImageGeneratorConstants.MapSpan.multiPointPadding / WalkImageGeneratorConstants.mapScaleFactor
    )

    return MKCoordinateRegion(center: center, span: span)
  }

  /// リージョンに適したカメラ高度を計算します
  ///
  /// - Parameter region: マップリージョン
  /// - Returns: カメラ高度（メートル）
  private static func altitudeForRegion(_ region: MKCoordinateRegion) -> CLLocationDistance {
    let latitudeDelta = region.span.latitudeDelta
    let baseAltitude: CLLocationDistance = 50000

    return baseAltitude * latitudeDelta / 0.01
  }
}
