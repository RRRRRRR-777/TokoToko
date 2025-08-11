//
//  MapItem.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/18.
//

import CoreLocation
import Foundation

/// マップ上に表示するアイテムのデータモデル
///
/// `MapItem`構造体は、マップ上にピンやマーカーとして表示される要素を表現します。
/// 散歩ルート上の特定の地点や写真の撮影場所などの表示に使用されます。
///
/// ## Overview
///
/// このデータモデルはシンプルで軽量な設計となっており、以下の特徴を持ちます：
/// - 精密な地理座標の管理
/// - カスタマイズ可能なアイコン表示
/// - ユーザーフレンドリーな表示名
/// - SwiftUI Mapとのシームレスな連携
///
/// ## Topics
///
/// ### Creating a MapItem
/// - ``init(coordinate:title:imageName:id:)``
///
/// ### Properties
/// - ``id``
/// - ``coordinate``
/// - ``title``
/// - ``imageName``
struct MapItem: Identifiable {
  /// アイテムの一意識別子
  ///
  /// マップアイテムを識別するための固有のUUID。作成時に自動生成されます。
  let id: UUID

  /// 地理座標（緯度・経度）
  ///
  /// アイテムがマップ上で表示される正確な位置。CoreLocationの座標系を使用します。
  let coordinate: CLLocationCoordinate2D

  /// マップ上に表示されるタイトル
  ///
  /// ユーザーに表示される説明テキスト。ピンをタップした際に表示されます。
  let title: String

  /// アイコン画像名
  ///
  /// SF Symbolsまたはカスタム画像の名前。マップ上での視覚的な表示に使用されます。
  let imageName: String

  /// MapItemインスタンスを作成します
  ///
  /// 新しいマップアイテムを作成し、指定された座標と表示情報で初期化します。
  /// アイコンとIDはオプションで、デフォルト値が設定されています。
  ///
  /// ## Usage Example
  /// ```swift
  /// // 基本的なマップアイテムの作成
  /// let item = MapItem(
  ///     coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
  ///     title: "東京駅"
  /// )
  ///
  /// // カスタムアイコンを指定
  /// let photoItem = MapItem(
  ///     coordinate: coordinate,
  ///     title: "写真撮影地点",
  ///     imageName: "camera.circle.fill"
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - coordinate: 地理座標（緯度・経度）
  ///   - title: 表示タイトル
  ///   - imageName: アイコン画像名（デフォルト: "mappin.circle.fill"）
  ///   - id: 一意識別子（デフォルト: 新しいUUID）
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
