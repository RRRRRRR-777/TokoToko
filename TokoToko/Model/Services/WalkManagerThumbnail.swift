//
//  WalkManagerThumbnail.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/08/30.
//

import CoreLocation
import MapKit
import UIKit

// MARK: - Thumbnail Generation Extension

/// WalkManagerのマップサムネイル生成機能拡張
extension WalkManager {

  // MARK: - サムネイル生成機能

  /// 散歩記録のサムネイル生成と保存
  func generateAndSaveThumbnail(for walk: Walk) {
    logger.info(operation: "generateThumbnail", message: "サムネイル生成開始")

    generateThumbnail(from: walk) { [weak self] thumbnail in
      guard let self = self, let thumbnail = thumbnail else {
        self?.logger.warning(operation: "generateThumbnail", message: "サムネイル生成失敗")
        return
      }

      let saved = self.saveImageLocally(thumbnail, for: walk.id)
      if saved {
        self.logger.info(
          operation: "generateThumbnail",
          message: "サムネイル保存完了",
          context: ["walkId": walk.id.uuidString]
        )
      } else {
        self.logger.warning(
          operation: "generateThumbnail",
          message: "サムネイル保存失敗"
        )
      }
    }
  }

  /// 散歩データからサムネイル画像を生成
  private func generateThumbnail(from walk: Walk, completion: @escaping (UIImage?) -> Void) {
    // Issue #65: 散歩リスト画像表示機能廃止により、サムネイル生成を無効化
    logger.info(operation: "generateThumbnail", message: "サムネイル生成は廃止されました (Issue #65)")
    completion(nil)
    return

    guard walk.status == .completed else {
      logger.warning(operation: "generateThumbnail", message: "散歩が完了していません")
      completion(nil)
      return
    }

    guard !walk.locations.isEmpty else {
      logger.warning(operation: "generateThumbnail", message: "位置情報がありません")
      completion(nil)
      return
    }

    let region = calculateMapRegion(from: walk.locations)
    let size = CGSize(width: 160, height: 120)

    let options = MKMapSnapshotter.Options()
    options.region = region
    options.size = size
    options.scale = UIScreen.main.scale
    options.mapType = .standard
    options.showsBuildings = true

    let snapshotter = MKMapSnapshotter(options: options)

    snapshotter.start { snapshot, error in
      DispatchQueue.main.async {
        guard let snapshot = snapshot else {
          if let error = error {
            self.logger.logError(
              error,
              operation: "generateThumbnail",
              humanNote: "マップスナップショット生成エラー"
            )
          }
          let fallbackImage = self.generateStaticMapImage(for: walk, size: size)
          completion(fallbackImage)
          return
        }

        let finalImage = self.addPolylineToSnapshot(snapshot, walk: walk)
        completion(finalImage)
      }
    }
  }

  /// 散歩ルートから最適なマップ領域を計算
  private func calculateMapRegion(from locations: [CLLocation]) -> MKCoordinateRegion {
    guard !locations.isEmpty else {
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }

    if locations.count == 1 {
      return MKCoordinateRegion(
        center: locations[0].coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
      )
    }

    let coordinates = locations.map { $0.coordinate }
    let minLat = coordinates.map { $0.latitude }.min()!
    let maxLat = coordinates.map { $0.latitude }.max()!
    let minLon = coordinates.map { $0.longitude }.min()!
    let maxLon = coordinates.map { $0.longitude }.max()!

    let center = CLLocationCoordinate2D(
      latitude: (minLat + maxLat) / 2,
      longitude: (minLon + maxLon) / 2
    )

    let latDelta = max((maxLat - minLat) * 1.3, 0.005)
    let lonDelta = max((maxLon - minLon) * 1.3, 0.005)

    return MKCoordinateRegion(
      center: center,
      span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
  }

  /// スナップショットにポリラインを描画
  private func addPolylineToSnapshot(_ snapshot: MKMapSnapshotter.Snapshot, walk: Walk) -> UIImage {
    let image = snapshot.image

    UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
    image.draw(at: CGPoint.zero)

    guard let context = UIGraphicsGetCurrentContext() else {
      UIGraphicsEndImageContext()
      return image
    }

    let coordinates = walk.locations.map { $0.coordinate }
    drawStartEndMarkers(on: snapshot, coordinates: coordinates)

    if coordinates.count >= 2 {
      context.setStrokeColor(UIColor.systemBlue.cgColor)
      context.setLineWidth(3.0)
      context.setLineCap(.round)
      context.setLineJoin(.round)

      let firstPoint = snapshot.point(for: coordinates[0])
      context.move(to: firstPoint)

      for i in 1..<coordinates.count {
        let point = snapshot.point(for: coordinates[i])
        context.addLine(to: point)
      }
      context.strokePath()
    }

    let resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
    UIGraphicsEndImageContext()

    return resultImage
  }

  /// スタート・ゴール地点のマーカーを描画
  private func drawStartEndMarkers(
    on snapshot: MKMapSnapshotter.Snapshot,
    coordinates: [CLLocationCoordinate2D]
  ) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    guard !coordinates.isEmpty else { return }

    let markerRadius: CGFloat = 6.0

    // スタートマーカー（緑）
    let startPoint = snapshot.point(for: coordinates[0])
    context.setFillColor(UIColor.systemGreen.cgColor)
    context.fillEllipse(in: CGRect(
      x: startPoint.x - markerRadius,
      y: startPoint.y - markerRadius,
      width: markerRadius * 2,
      height: markerRadius * 2
    ))

    // ゴールマーカー（赤）
    if coordinates.count > 1 {
      let endPoint = snapshot.point(for: coordinates[coordinates.count - 1])
      context.setFillColor(UIColor.systemRed.cgColor)
      context.fillEllipse(in: CGRect(
        x: endPoint.x - markerRadius,
        y: endPoint.y - markerRadius,
        width: markerRadius * 2,
        height: markerRadius * 2
      ))
    }
  }

  /// 静的マップ画像を生成（フォールバック）
  private func generateStaticMapImage(for walk: Walk, size: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
    defer { UIGraphicsEndImageContext() }

    guard let context = UIGraphicsGetCurrentContext() else {
      return generateFallbackImage(size: size)
    }

    context.setFillColor(UIColor.systemGray6.cgColor)
    context.fill(CGRect(origin: .zero, size: size))

    drawWalkRoute(in: context, walk: walk, size: size)

    return UIGraphicsGetImageFromCurrentImageContext() ?? generateFallbackImage(size: size)
  }

  /// 散歩ルートを描画
  private func drawWalkRoute(in context: CGContext, walk: Walk, size: CGSize) {
    let coordinates = walk.locations.map { $0.coordinate }
    guard coordinates.count >= 2 else { return }

    let region = calculateMapRegion(from: walk.locations)

    func coordinateToPoint(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
      let x = (coordinate.longitude - region.center.longitude + region.span.longitudeDelta / 2)
              / region.span.longitudeDelta * size.width
      let y = (region.center.latitude - coordinate.latitude + region.span.latitudeDelta / 2)
              / region.span.latitudeDelta * size.height
      return CGPoint(x: x, y: y)
    }

    context.setStrokeColor(UIColor.systemBlue.cgColor)
    context.setLineWidth(2.0)
    context.setLineCap(.round)
    context.setLineJoin(.round)

    let firstPoint = coordinateToPoint(coordinates[0])
    context.move(to: firstPoint)

    for i in 1..<coordinates.count {
      let point = coordinateToPoint(coordinates[i])
      context.addLine(to: point)
    }
    context.strokePath()

    // マーカー描画
    let markerRadius: CGFloat = 4.0

    let startPoint = coordinateToPoint(coordinates[0])
    context.setFillColor(UIColor.systemGreen.cgColor)
    context.fillEllipse(in: CGRect(
      x: startPoint.x - markerRadius,
      y: startPoint.y - markerRadius,
      width: markerRadius * 2,
      height: markerRadius * 2
    ))

    let endPoint = coordinateToPoint(coordinates[coordinates.count - 1])
    context.setFillColor(UIColor.systemRed.cgColor)
    context.fillEllipse(in: CGRect(
      x: endPoint.x - markerRadius,
      y: endPoint.y - markerRadius,
      width: markerRadius * 2,
      height: markerRadius * 2
    ))
  }

  /// フォールバック画像を生成
  private func generateFallbackImage(size: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
    defer { UIGraphicsEndImageContext() }

    guard let context = UIGraphicsGetCurrentContext() else {
      return UIImage()
    }

    context.setFillColor(UIColor.systemGray5.cgColor)
    context.fill(CGRect(origin: .zero, size: size))

    let text = "散歩マップ"
    let font = UIFont.systemFont(ofSize: 16, weight: .medium)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor.systemGray
    ]

    let textSize = text.size(withAttributes: attributes)
    let textRect = CGRect(
      x: (size.width - textSize.width) / 2,
      y: (size.height - textSize.height) / 2,
      width: textSize.width,
      height: textSize.height
    )

    text.draw(in: textRect, withAttributes: attributes)

    return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
  }
}
