# Walk

散歩セッションの情報を管理するデータモデル

## Overview

`Walk`構造体は、散歩の開始から終了までの全ての情報を管理するコアデータモデルです。位置情報の追跡、時間の計測、状態管理などの機能を提供します。

## 主要機能

### 状態管理
散歩は以下の状態を持ちます：
- **未開始** (`notStarted`): 散歩が開始される前の状態
- **記録中** (`inProgress`): 散歩が進行中の状態  
- **一時停止** (`paused`): 散歩が一時停止された状態
- **完了** (`completed`): 散歩が終了した状態

### 位置情報追跡
- GPS位置情報の配列として散歩ルートを記録
- ポリラインデータとして可視化用データを保存
- 総距離の自動計算

### 時間管理
- 散歩開始時刻と終了時刻の記録
- 一時停止時間の累積計算
- 実際の散歩時間の算出

## 使用例

```swift
// 新しい散歩の作成
var walk = Walk(id: UUID(), title: "朝の散歩")
walk.status = .inProgress
walk.startTime = Date()

// 位置情報の追加
let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
walk.locations.append(location)

// 散歩の完了
walk.status = .completed
walk.endTime = Date()
```

## 関連項目

- ``WalkManager``: 散歩の作成と管理
- ``WalkRepository``: 散歩データの永続化
- ``LocationManager``: 位置情報の取得