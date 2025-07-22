# MapItem

マップ上に表示するアイテムのデータモデル

## Overview

`MapItem`構造体は、マップ上にピンやマーカーとして表示される要素を表現するデータモデルです。散歩ルート上の特定の地点や写真の撮影場所などを表示する際に使用されます。

## 主要機能

### 座標管理
- `CLLocationCoordinate2D`による位置情報の管理
- 緯度・経度の精密な座標指定

### 表示制御
- タイトル表示による地点の説明
- カスタムアイコンの設定
- マップ上での識別子管理

## プロパティ

### 必須プロパティ
- **id**: 一意識別子（UUID）
- **coordinate**: 地理座標（緯度・経度）
- **title**: 表示タイトル

### オプションプロパティ  
- **imageName**: アイコン画像名（デフォルト: "mappin.circle.fill"）

## 使用例

```swift
// 基本的なマップアイテムの作成
let mapItem = MapItem(
    coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
    title: "東京駅"
)

// カスタムアイコンを指定
let photoItem = MapItem(
    coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
    title: "写真撮影地点",
    imageName: "camera.circle.fill"
)
```

## 関連項目

- ``MapViewComponent``: マップの表示コンポーネント
- ``Walk``: 散歩データでのマップアイテム使用
- SwiftUI `Map`: マップ表示の基盤フレームワーク