//
//  MapThumbnailGenerator.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/29.
//

import UIKit
import CoreLocation
import MapKit

// マップのサムネイル画像生成を担当するクラス
class MapThumbnailGenerator {
  
  init() {}
  
  // 散歩データからサムネイル画像を生成（非同期版）
  func generateThumbnail(from walk: Walk, completion: @escaping (UIImage?) -> Void) {
    // 🔵 Refactor - 実際のMapKitを使用したサムネイル生成
    
    #if DEBUG
    print("🗺️ サムネイル生成開始 - Walk ID: \(walk.id)")
    print("  - Status: \(walk.status)")
    print("  - Locations count: \(walk.locations.count)")
    #endif
    
    // 完了していない散歩はnilを返す
    guard walk.status == .completed else {
      #if DEBUG
      print("❌ 散歩が完了していません: \(walk.status)")
      #endif
      completion(nil)
      return
    }
    
    // 位置情報がない場合はnilを返す
    guard !walk.locations.isEmpty else {
      #if DEBUG
      print("❌ 位置情報がありません")
      #endif
      completion(nil)
      return
    }
    
    // MapKitSnapshotterを使用して実際のマップ画像を生成
    let region = calculateMapRegion(from: walk.locations)
    let size = CGSize(width: 160, height: 120) // 4:3のアスペクト比
    
    #if DEBUG
    print("🔍 MapKitSnapshotter設定:")
    print("  - Region center: \(region.center)")
    print("  - Region span: \(region.span)")
    #endif
    
    // MapKit Snapshotter を使用して実際の地図画像を生成
    // シミュレーターでも試行する
    
    let options = MKMapSnapshotter.Options()
    options.region = region
    options.size = size
    options.scale = UIScreen.main.scale // デバイスに適した解像度
    options.mapType = .standard
    options.showsBuildings = true
    options.showsPointsOfInterest = true // POIを表示して実際の地図らしくする
    
    #if DEBUG
    print("🛠️ MapKitSnapshotter設定:")
    print("  - mapType: \(options.mapType.rawValue)")
    print("  - scale: \(options.scale)")
    print("  - showsBuildings: \(options.showsBuildings)")
    print("  - showsPointsOfInterest: \(options.showsPointsOfInterest)")
    #endif
    
    let snapshotter = MKMapSnapshotter(options: options)
    
    // 非同期でスナップショットを取得
    snapshotter.start { snapshot, error in
      DispatchQueue.main.async {
        guard let snapshot = snapshot else {
          #if DEBUG
          if let error = error {
            print("❌ マップスナップショット生成エラー: \(error.localizedDescription)")
            print("  エラー詳細: \(error)")
          } else {
            print("❌ マップスナップショットがnilです")
          }
          print("🔍 デバッグ情報:")
          print("  - Region: \(region)")
          print("  - Size: \(size)")
          print("  - Walk locations count: \(walk.locations.count)")
          if let firstLocation = walk.locations.first {
            print("  - First location: \(firstLocation.coordinate)")
          }
          print("🔄 静的マップ画像にフォールバック")
          #endif
          
          // フォールバック画像を返す
          let fallbackImage = self.generateStaticMapImage(for: walk, size: size)
          completion(fallbackImage)
          return
        }
        
        #if DEBUG
        print("✅ マップスナップショット生成成功")
        #endif
        
        // ポリラインを描画したコンテキスト画像を作成
        let finalImage = self.addPolylineToSnapshot(snapshot, walk: walk)
        completion(finalImage)
      }
    }
  }
  
  // MARK: - Private Methods
  
  // 散歩ルートから最適なマップ領域を計算
  private func calculateMapRegion(from locations: [CLLocation]) -> MKCoordinateRegion {
    guard !locations.isEmpty else {
      // デフォルト位置（東京駅周辺）
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }
    
    // 1つの座標のみの場合
    if locations.count == 1 {
      let coordinate = locations[0].coordinate
      // 座標が有効かチェック
      guard CLLocationCoordinate2DIsValid(coordinate) else {
        return MKCoordinateRegion(
          center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
          span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
      }
      
      return MKCoordinateRegion(
        center: coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
      )
    }
    
    // 複数の座標がある場合
    let coordinates = locations.map { $0.coordinate }.filter { CLLocationCoordinate2DIsValid($0) }
    
    guard !coordinates.isEmpty else {
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }
    
    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }
    
    let minLat = latitudes.min() ?? 0
    let maxLat = latitudes.max() ?? 0
    let minLon = longitudes.min() ?? 0
    let maxLon = longitudes.max() ?? 0
    
    // 中心点を計算
    let centerLat = (minLat + maxLat) / 2
    let centerLon = (minLon + maxLon) / 2
    
    // スパンを計算（ルート全体が確実に表示されるよう余裕を持たせる）
    // 長い距離のルートでも見切れないように、より大きなマージンを設定
    let baseLatDelta = maxLat - minLat
    let baseLonDelta = maxLon - minLon
    
    // 短い距離の場合は最小値を確保、長い距離の場合はより大きなマージンを設定
    let latDelta: Double
    let lonDelta: Double
    
    if baseLatDelta < 0.002 || baseLonDelta < 0.002 {
      // 短い距離の場合（200m未満程度）
      latDelta = max(baseLatDelta * 2.5, 0.008)
      lonDelta = max(baseLonDelta * 2.5, 0.008)
    } else if baseLatDelta > 0.02 || baseLonDelta > 0.02 {
      // とても長い距離の場合（2km以上程度）、より大きなマージンを確保
      latDelta = baseLatDelta * 2.5
      lonDelta = baseLonDelta * 2.5
    } else {
      // 中距離の場合
      latDelta = baseLatDelta * 2.2
      lonDelta = baseLonDelta * 2.2
    }
    
    // 計算結果をデバッグ出力
    #if DEBUG
    let routeType = baseLatDelta < 0.002 || baseLonDelta < 0.002 ? "短距離" : 
                   (baseLatDelta > 0.02 || baseLonDelta > 0.02 ? "長距離" : "中距離")
    
    print("🗺️ 領域計算結果:")
    print("  - Route type: \(routeType)")
    print("  - Center: (\(centerLat), \(centerLon))")
    print("  - Base delta: lat(\(baseLatDelta)), lon(\(baseLonDelta))")
    print("  - Final span: lat(\(latDelta)), lon(\(lonDelta))")
    print("  - Bounds: lat(\(minLat) to \(maxLat)), lon(\(minLon) to \(maxLon))")
    print("  - Margin ratio: \(String(format: "%.1f", latDelta / max(baseLatDelta, 0.001)))x")
    #endif
    
    let region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
      span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
    
    return region
  }
  
  // スナップショットにポリラインを追加
  private func addPolylineToSnapshot(_ snapshot: MKMapSnapshotter.Snapshot, walk: Walk) -> UIImage {
    let image = snapshot.image
    
    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
    defer { UIGraphicsEndImageContext() }
    
    // 元の地図画像を描画
    image.draw(at: .zero)
    
    // ポリラインを描画
    guard walk.locations.count > 1 else {
      return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    let context = UIGraphicsGetCurrentContext()
    
    // ポリラインのスタイル設定（適度な太さで見やすく）
    context?.setStrokeColor(UIColor.systemBlue.cgColor)
    context?.setLineWidth(2.5)  // 線幅を細くする
    context?.setLineCap(.round)
    context?.setLineJoin(.round)
    
    // 影を追加してルートを強調（控えめに）
    context?.setShadow(offset: CGSize(width: 0.5, height: 0.5), blur: 1, color: UIColor.black.withAlphaComponent(0.2).cgColor)
    
    // 座標をピクセル座標に変換して線を描画
    let coordinates = walk.locations.map { $0.coordinate }
    for i in 1..<coordinates.count {
      let startPoint = snapshot.point(for: coordinates[i-1])
      let endPoint = snapshot.point(for: coordinates[i])
      
      context?.move(to: startPoint)
      context?.addLine(to: endPoint)
    }
    
    context?.strokePath()
    
    // 開始・終了地点のマーカーを描画
    drawStartEndMarkers(on: snapshot, coordinates: coordinates)
    
    return UIGraphicsGetImageFromCurrentImageContext() ?? image
  }
  
  // 開始・終了地点のマーカーを描画
  private func drawStartEndMarkers(on snapshot: MKMapSnapshotter.Snapshot, coordinates: [CLLocationCoordinate2D]) {
    guard let context = UIGraphicsGetCurrentContext(), !coordinates.isEmpty else { return }
    
    let markerSize: CGFloat = 12.0  // マーカーサイズを大きくして見やすくする
    
    // 影をリセット（マーカー用）
    context.setShadow(offset: CGSize.zero, blur: 0, color: nil)
    
    // 開始地点（緑色）
    let startPoint = snapshot.point(for: coordinates[0])
    context.setFillColor(UIColor.systemGreen.cgColor)
    context.fillEllipse(in: CGRect(
      x: startPoint.x - markerSize/2,
      y: startPoint.y - markerSize/2,
      width: markerSize,
      height: markerSize
    ))
    
    // 終了地点（赤色、開始地点と異なる場合のみ）
    if coordinates.count > 1 {
      let endPoint = snapshot.point(for: coordinates.last!)
      context.setFillColor(UIColor.systemRed.cgColor)
      context.fillEllipse(in: CGRect(
        x: endPoint.x - markerSize/2,
        y: endPoint.y - markerSize/2,
        width: markerSize,
        height: markerSize
      ))
    }
  }
  
  // 静的なマップ風画像の生成（シミュレーター環境用）
  private func generateStaticMapImage(for walk: Walk, size: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
    defer { UIGraphicsEndImageContext() }
    
    guard let context = UIGraphicsGetCurrentContext() else {
      return generateFallbackImage(size: size)
    }
    
    // 地図風の背景（薄い緑色）
    UIColor.systemGreen.withAlphaComponent(0.1).setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    
    // グリッド線を描画（地図風）
    context.setStrokeColor(UIColor.systemGray4.cgColor)
    context.setLineWidth(0.5)
    
    let gridSize: CGFloat = 20
    for x in stride(from: 0, through: size.width, by: gridSize) {
      context.move(to: CGPoint(x: x, y: 0))
      context.addLine(to: CGPoint(x: x, y: size.height))
    }
    for y in stride(from: 0, through: size.height, by: gridSize) {
      context.move(to: CGPoint(x: 0, y: y))
      context.addLine(to: CGPoint(x: size.width, y: y))
    }
    context.strokePath()
    
    // 散歩ルートを描画
    if walk.locations.count > 1 {
      drawWalkRoute(in: context, walk: walk, size: size)
    }
    
    // 距離と時間の情報を表示
    let infoText = "\(walk.distanceString) • \(walk.durationString)"
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.label,
      .font: UIFont.systemFont(ofSize: 10, weight: .medium),
      .backgroundColor: UIColor.systemBackground.withAlphaComponent(0.8)
    ]
    
    let textSize = infoText.size(withAttributes: attributes)
    let textRect = CGRect(
      x: 8,
      y: size.height - textSize.height - 8,
      width: textSize.width + 4,
      height: textSize.height + 2
    )
    
    // 背景を描画
    context.setFillColor(UIColor.systemBackground.withAlphaComponent(0.9).cgColor)
    context.fill(textRect.insetBy(dx: -2, dy: -1))
    
    infoText.draw(in: textRect, withAttributes: attributes)
    
    return UIGraphicsGetImageFromCurrentImageContext() ?? generateFallbackImage(size: size)
  }
  
  // 散歩ルートを画像内に描画
  private func drawWalkRoute(in context: CGContext, walk: Walk, size: CGSize) {
    let coordinates = walk.locations.map { $0.coordinate }
    guard coordinates.count > 1 else { return }
    
    // 座標の境界を計算
    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }
    
    let minLat = latitudes.min() ?? 0
    let maxLat = latitudes.max() ?? 0
    let minLon = longitudes.min() ?? 0
    let maxLon = longitudes.max() ?? 0
    
    let latRange = maxLat - minLat
    let lonRange = maxLon - minLon
    
    // マージンを設定（動的にマージンを調整）
    let baseMargin: CGFloat = 18  // ベースマージンを増加
    
    // 距離が長い場合は、より大きなマージンを確保
    let routeRange = max(latRange, lonRange)
    let marginMultiplier: CGFloat = routeRange > 0.01 ? 1.8 : 1.2  // より大きなマージン倍率
    
    let margin = baseMargin * marginMultiplier
    let drawableWidth = size.width - (margin * 2)
    let drawableHeight = size.height - (margin * 2)
    
    #if DEBUG
    print("📐 静的マップ描画設定:")
    print("  - Route range: \(routeRange)")
    print("  - Margin: \(margin)pt")
    print("  - Drawable area: \(drawableWidth)x\(drawableHeight)")
    #endif
    
    // 座標をピクセル座標に変換する関数
    func coordinateToPoint(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
      let x = margin + ((coordinate.longitude - minLon) / (lonRange == 0 ? 1 : lonRange)) * drawableWidth
      let y = margin + ((maxLat - coordinate.latitude) / (latRange == 0 ? 1 : latRange)) * drawableHeight
      return CGPoint(x: x, y: y)
    }
    
    // ルートラインを描画
    context.setStrokeColor(UIColor.systemBlue.cgColor)
    context.setLineWidth(2.5)  // 線幅を細くする
    context.setLineCap(.round)
    context.setLineJoin(.round)
    
    let startPoint = coordinateToPoint(coordinates[0])
    context.move(to: startPoint)
    
    for coordinate in coordinates.dropFirst() {
      let point = coordinateToPoint(coordinate)
      context.addLine(to: point)
    }
    
    context.strokePath()
    
    // 開始・終了地点のマーカー
    let markerSize: CGFloat = 8.0
    
    // 開始地点（緑色）
    context.setFillColor(UIColor.systemGreen.cgColor)
    let startMarkerRect = CGRect(
      x: startPoint.x - markerSize/2,
      y: startPoint.y - markerSize/2,
      width: markerSize,
      height: markerSize
    )
    context.fillEllipse(in: startMarkerRect)
    
    // 終了地点（赤色）
    if coordinates.count > 1 {
      let endPoint = coordinateToPoint(coordinates.last!)
      context.setFillColor(UIColor.systemRed.cgColor)
      let endMarkerRect = CGRect(
        x: endPoint.x - markerSize/2,
        y: endPoint.y - markerSize/2,
        width: markerSize,
        height: markerSize
      )
      context.fillEllipse(in: endMarkerRect)
    }
  }
  
  // フォールバック画像の生成
  private func generateFallbackImage(size: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
    defer { UIGraphicsEndImageContext() }
    
    // グレーの背景
    UIColor.systemGray5.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    
    // マップアイコンとテキスト
    let text = "地図を生成できませんでした"
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.secondaryLabel,
      .font: UIFont.systemFont(ofSize: 10, weight: .medium)
    ]
    
    let textSize = text.size(withAttributes: attributes)
    let textRect = CGRect(
      x: (size.width - textSize.width) / 2,
      y: (size.height - textSize.height) / 2 + 8,
      width: textSize.width,
      height: textSize.height
    )
    
    text.draw(in: textRect, withAttributes: attributes)
    
    return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
  }
}
