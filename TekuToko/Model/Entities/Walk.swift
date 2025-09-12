//
//  Walk.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import FirebaseFirestore
import Foundation

/// 散歩の進行状況を表す列挙型
///
/// 散歩の開始から終了までの各段階を表現し、アプリのUI表示とロジック制御に使用されます。
/// 各状態は適切な順序で遷移し、散歩の実際の進行状況を反映します。
///
/// ## Topics
///
/// ### Cases
/// - ``notStarted``
/// - ``inProgress``
/// - ``paused``
/// - ``completed``
///
/// ### Properties
/// - ``displayName``
enum WalkStatus: String, CaseIterable, Codable {
  /// 散歩が開始される前の状態
  case notStarted = "not_started"

  /// 散歩が進行中の状態
  case inProgress = "in_progress"

  /// 散歩が一時停止された状態
  case paused = "paused"

  /// 散歩が終了した状態
  case completed = "completed"

  /// 散歩状態のローカライズされた表示名
  ///
  /// UI表示用の日本語文字列を返します。
  ///
  /// - Returns: 状態に応じた日本語の表示文字列
  var displayName: String {
    switch self {
    case .notStarted:
      return "未開始"
    case .inProgress:
      return "記録中"
    case .paused:
      return "一時停止"
    case .completed:
      return "完了"
    }
  }
}

/// 散歩セッションの情報を管理するデータモデル
///
/// `Walk`構造体は、散歩の開始から終了までの全ての情報を管理するコアデータモデルです。
/// 位置情報の追跡、時間の計測、状態管理、Firebase連携などの機能を提供します。
///
/// ## Overview
///
/// 散歩データには以下の主要な情報が含まれます：
/// - 基本情報（タイトル、説明、ユーザーID）
/// - 時間管理（開始時刻、終了時刻、一時停止時間）
/// - 位置情報（GPSトラック、総距離、ポリライン）
/// - 状態管理（進行状況、一時停止状態）
/// - メタデータ（作成日、更新日、サムネイル）
///
/// ## Topics
///
/// ### Creating a Walk
/// - ``init(title:description:userId:id:startTime:endTime:totalDistance:totalSteps:polylineData:thumbnailImageUrl:status:pausedAt:totalPausedDuration:locations:createdAt:updatedAt:)``
///
/// ### Basic Properties
/// - ``id``
/// - ``userId``
/// - ``title``
/// - ``description``
/// - ``createdAt``
/// - ``updatedAt``
///
/// ### Time Management
/// - ``startTime``
/// - ``endTime``
/// - ``duration``
/// - ``durationString``
/// - ``pausedAt``
/// - ``totalPausedDuration``
///
/// ### Location & Distance
/// - ``locations``
/// - ``location``
/// - ``totalDistance``
/// - ``distanceString``
/// - ``polylineData``
/// - ``hasLocation``
/// - ``locationString``
///
/// ### State Management
/// - ``status``
/// - ``isInProgress``
/// - ``isCompleted``
///
/// ### Walk Control
/// - ``start()``
/// - ``pause()``
/// - ``resume()``
/// - ``complete()``
/// - ``addLocation(_:)``
///
/// ### Additional Data
/// - ``totalSteps``
/// - ``thumbnailImageUrl``
struct Walk: Identifiable, Codable {
  /// 散歩の一意識別子
  ///
  /// 散歩セッションを識別するための固有のUUID。作成時に自動生成されます。
  let id: UUID
  /// 散歩を行ったユーザーのID
  ///
  /// Firebase Authenticationのユーザー識別子。匿名ユーザーの場合はnilになります。
  var userId: String?
  /// 散歩のタイトル
  ///
  /// ユーザーが設定した散歩の名前。デフォルトでは日時ベースの名前が設定されます。
  var title: String
  /// 散歩の説明
  ///
  /// ユーザーが入力した散歩に関する詳細な説明やメモ。
  var description: String
  /// 散歩開始時刻
  ///
  /// 散歩が開始された実際の日時。散歩が開始されていない場合はnil。
  var startTime: Date?
  /// 散歩終了時刻
  ///
  /// 散歩が終了した実際の日時。散歩が終了していない場合はnil。
  var endTime: Date?
  /// 散歩の総距離（メートル単位）
  ///
  /// GPS位置情報から計算された散歩の総距離。位置情報が追加されるたびに自動更新されます。
  var totalDistance: Double = 0.0
  /// 散歩中の総歩数
  ///
  /// ヘルスキットから取得した散歩中の総歩数。システムの許可が必要です。
  var totalSteps: Int = 0
  /// 散歩ルートのポリラインデータ
  ///
  /// Google Mapsエンコード形式のポリライン文字列。マップ上でのルート表示に使用されます。
  var polylineData: String?
  /// サムネイル画像のURL
  ///
  /// Firebase Storageにアップロードされたサムネイル画像のURL。散歩リストでの表示に使用されます。
  var thumbnailImageUrl: String?
  /// 散歩の現在状態
  ///
  /// 散歩の進行状況を表す列挙値。UI表示とロジック制御の基本となります。
  var status: WalkStatus = .notStarted
  /// 一時停止開始時刻
  ///
  /// 散歩が一時停止された時刻。一時停止中でない場合はnil。
  var pausedAt: Date?
  /// 累積一時停止時間
  ///
  /// 散歩開始から現在までの総一時停止時間（秒）。実際の散歩時間計算に使用されます。
  var totalPausedDuration: TimeInterval = 0.0
  /// GPS位置情報の配列
  ///
  /// 散歩中に記録されたGPS位置情報の配列。ルート表示や距離計算に使用されます。
  var locations: [CLLocation] = []
  /// 開始地点の座標
  ///
  /// 散歩の最初の位置情報から取得した座標。位置情報がない場合はnil。
  ///
  /// - Returns: 最初の位置の座標、または位置情報がない場合はnil
  var location: CLLocationCoordinate2D? {
    locations.first?.coordinate
  }
  /// 散歩データの作成日時
  ///
  /// 散歩レコードが最初に作成された日時。
  var createdAt: Date

  /// 散歩データの最終更新日時
  ///
  /// 散歩データが最後に更新された日時。位置情報追加や状態変更時に自動更新されます。
  var updatedAt: Date

  /// Walkインスタンスを作成します
  ///
  /// 新しい散歩セッションを作成するためのイニシャライザです。
  /// ほとんどのパラメーターはオプションで、デフォルト値が設定されています。
  ///
  /// - Parameters:
  ///   - title: 散歩のタイトル
  ///   - description: 散歩の説明
  ///   - userId: ユーザーID（デフォルト: nil）
  ///   - id: 一意識別子（デフォルト: 新しいUUID）
  ///   - startTime: 開始時刻（デフォルト: nil）
  ///   - endTime: 終了時刻（デフォルト: nil）
  ///   - totalDistance: 総距離（デフォルト: 0.0）
  ///   - totalSteps: 総歩数（デフォルト: 0）
  ///   - polylineData: ポリラインデータ（デフォルト: nil）
  ///   - thumbnailImageUrl: サムネイルURL（デフォルト: nil）
  ///   - status: 状態（デフォルト: .notStarted）
  ///   - pausedAt: 一時停止時刻（デフォルト: nil）
  ///   - totalPausedDuration: 累積一時停止時間（デフォルト: 0.0）
  ///   - locations: 位置情報配列（デフォルト: 空の配列）
  ///   - createdAt: 作成日時（デフォルト: 現在時刻）
  ///   - updatedAt: 更新日時（デフォルト: 現在時刻）
  init(
    title: String,
    description: String,
    userId: String? = nil,
    id: UUID = UUID(),
    startTime: Date? = nil,
    endTime: Date? = nil,
    totalDistance: Double = 0.0,
    totalSteps: Int = 0,
    polylineData: String? = nil,
    thumbnailImageUrl: String? = nil,
    status: WalkStatus = .notStarted,
    pausedAt: Date? = nil,
    totalPausedDuration: TimeInterval = 0.0,
    locations: [CLLocation] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.userId = userId
    self.title = title
    self.description = description
    self.startTime = startTime
    self.endTime = endTime
    self.totalDistance = totalDistance
    self.totalSteps = totalSteps
    self.polylineData = polylineData
    self.thumbnailImageUrl = thumbnailImageUrl
    self.status = status
    self.pausedAt = pausedAt
    self.totalPausedDuration = totalPausedDuration
    self.locations = locations
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  /// 位置情報が記録されているかどうか
  ///
  /// GPS位置情報が1つ以上記録されているかどうかを返します。
  ///
  /// - Returns: 位置情報があるtrue、ない場合false
  var hasLocation: Bool {
    !locations.isEmpty
  }

  /// 位置情報の文字列表現
  ///
  /// 散歩の開始地点の緯度・経度を文字列で返します。
  ///
  /// - Returns: 「緯度: XX.XXXX, 経度: XX.XXXX」形式の文字列、または「位置情報なし」
  var locationString: String {
    guard let location = location else {
      return "位置情報なし"
    }
    return "緯度: \(location.latitude), 経度: \(location.longitude)"
  }

  /// 散歩の実際の経過時間
  ///
  /// 散歩開始から現在または終了までの時間から、一時停止時間を除いた実際の散歩時間。
  /// 一時停止中の場合は、現在の一時停止時間も除外されます。
  ///
  /// - Returns: 実際の散歩時間（秒）
  var duration: TimeInterval {
    guard let startTime = startTime else {
      return 0
    }
    let endTime = self.endTime ?? Date()
    let totalTime = endTime.timeIntervalSince(startTime)

    // 現在一時停止中の場合、pausedAtからの時間も除外する
    var currentPauseDuration: TimeInterval = 0
    if status == .paused, let pausedAt = pausedAt {
      currentPauseDuration = Date().timeIntervalSince(pausedAt)
    }

    // 総時間から累積一時停止時間と現在の一時停止時間を引く
    return totalTime - totalPausedDuration - currentPauseDuration
  }

  /// 散歩時間の文字列表現
  ///
  /// 散歩の経過時間を"HH:MM:SS"または"MM:SS"形式で返します。
  /// 1時間未満の場合は"MM:SS"、1時間以上の場合は"H:MM:SS"形式で表示されます。
  ///
  /// - Returns: フォーマットされた時間文字列
  var durationString: String {
    let duration = self.duration
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }

  /// 距離の文字列表現
  ///
  /// 総距離を適切な単位（メートルまたはキロメートル）で返します。
  /// 1000m未満の場合はメートル、以上の場合はキロメートルで表示されます。
  ///
  /// - Returns: フォーマットされた距離文字列（例: "1.23 km"、"500 m"）
  var distanceString: String {
    if totalDistance >= 1000 {
      return String(format: "%.2f km", totalDistance / 1000)
    } else {
      return String(format: "%.0f m", totalDistance)
    }
  }

  /// 散歩が進行中かどうか
  ///
  /// 散歩の状態が`inProgress`であるかどうかを返します。
  ///
  /// - Returns: 進行中の場合true、そうでなければfalse
  var isInProgress: Bool {
    status == .inProgress
  }

  /// 散歩が完了しているかどうか
  ///
  /// 散歩の状態が`completed`であるかどうかを返します。
  ///
  /// - Returns: 完了している場合true、そうでなければfalse
  var isCompleted: Bool {
    status == .completed
  }

  /// 新しい位置情報を追加します
  ///
  /// GPS位置情報を散歩ルートに追加し、総距離を再計算します。
  /// 更新日時も自動的に更新されます。
  ///
  /// - Parameter location: 追加するGPS位置情報
  mutating func addLocation(_ location: CLLocation) {
    locations.append(location)
    updateDistance()
    updatedAt = Date()
  }

  /// 総距離を再計算します
  ///
  /// 記録された位置情報から総距離を計算し、`totalDistance`を更新します。
  /// 2点未満の場合は距離を0に設定します。
  private mutating func updateDistance() {
    guard locations.count > 1 else {
      totalDistance = 0
      return
    }

    var distance: Double = 0
    for i in 1..<locations.count {
      distance += locations[i - 1].distance(from: locations[i])
    }
    totalDistance = distance
  }

  /// 散歩を開始します
  ///
  /// 散歩の状態を`inProgress`に設定し、開始時刻を記録します。
  /// 更新日時も自動的に更新されます。
  mutating func start() {
    startTime = Date()
    status = .inProgress
    updatedAt = Date()
  }

  /// 散歩を一時停止します
  ///
  /// 散歩が進行中の場合のみ、状態を`paused`に設定し一時停止時刻を記録します。
  /// 進行中でない場合は何もしません。
  mutating func pause() {
    guard status == .inProgress else {
      return
    }
    status = .paused
    pausedAt = Date()
    updatedAt = Date()
  }

  /// 散歩を再開します
  ///
  /// 一時停止中の散歩を再開し、状態を`inProgress`に戻します。
  /// 一時停止時間を累積時間に追加し、一時停止時刻をクリアします。
  /// 一時停止中でない場合は何もしません。
  mutating func resume() {
    guard status == .paused, let pausedAt = pausedAt else {
      return
    }
    status = .inProgress

    // 一時停止していた時間を累積に追加
    let pauseDuration = Date().timeIntervalSince(pausedAt)
    totalPausedDuration += pauseDuration

    // 一時停止時刻をクリア
    self.pausedAt = nil
    updatedAt = Date()
  }

  /// 散歩を完了します
  ///
  /// 散歩の状態を`completed`に設定し、終了時刻を記録します。
  /// 一時停止中に完了した場合は、最後の一時停止時間も累積時間に追加します。
  mutating func complete() {
    // 一時停止中に完了した場合、最後の一時停止時間も累積に追加
    if status == .paused, let pausedAt = pausedAt {
      let pauseDuration = Date().timeIntervalSince(pausedAt)
      totalPausedDuration += pauseDuration
      self.pausedAt = nil
    }

    endTime = Date()
    status = .completed
    updatedAt = Date()
  }
}

// MARK: - Firestore Codable Support

/// Firebase Firestore連携のための拡張
///
/// Firestoreのデータ形式とSwiftのデータ構造を相互変換するための機能を提供します。
/// CLLocationのようなFirestoreが直接サポートしないタイプのシリアライゼーションも処理します。
extension Walk {
  /// Firestoreデータベースのフィールド名とSwiftプロパティのマッピング
  ///
  /// Firestoreのスネークケース命名規則とSwiftのキャメルケースを対応付けます。
  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case title
    case description
    case startTime = "start_time"
    case endTime = "end_time"
    case totalDistance = "total_distance"
    case totalSteps = "total_steps"
    case polylineData = "polyline_data"
    case thumbnailImageUrl = "thumbnail_image_url"
    case status
    case pausedAt = "paused_at"
    case totalPausedDuration = "total_paused_duration"
    case locationData = "location_data"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  /// CLLocationのFirestore保存用データ構造体
  ///
  /// CoreLocationのCLLocationクラスはFirestoreに直接保存できないため、
  /// 必要なプロパティを抽出してシリアライズ可能な形式に変換します。
  struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
    let horizontalAccuracy: Double
    let verticalAccuracy: Double
    let speed: Double
    let course: Double

    /// CLLocationからLocationDataを作成します
    ///
    /// - Parameter location: 変換元のCLLocationインスタンス
    init(from location: CLLocation) {
      self.latitude = location.coordinate.latitude
      self.longitude = location.coordinate.longitude
      self.altitude = location.altitude
      self.timestamp = location.timestamp
      self.horizontalAccuracy = location.horizontalAccuracy
      self.verticalAccuracy = location.verticalAccuracy
      self.speed = location.speed
      self.course = location.course
    }

    /// LocationDataからCLLocationを再構成します
    ///
    /// - Returns: 復元されたCLLocationインスタンス
    func toCLLocation() -> CLLocation {
      let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      return CLLocation(
        coordinate: coordinate,
        altitude: altitude,
        horizontalAccuracy: horizontalAccuracy,
        verticalAccuracy: verticalAccuracy,
        course: course,
        speed: speed,
        timestamp: timestamp
      )
    }
  }

  /// Firestore用のカスタムエンコーディング
  ///
  /// WalkインスタンスをFirestoreに保存可能な形式に変換します。
  /// CLLocation配列はLocationData配列に変換してシリアライズします。
  ///
  /// - Parameter encoder: エンコーダー
  /// - Throws: エンコーディングエラー
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id.uuidString, forKey: .id)
    try container.encodeIfPresent(userId, forKey: .userId)
    try container.encode(title, forKey: .title)
    try container.encode(description, forKey: .description)
    try container.encodeIfPresent(startTime, forKey: .startTime)
    try container.encodeIfPresent(endTime, forKey: .endTime)
    try container.encode(totalDistance, forKey: .totalDistance)
    try container.encode(totalSteps, forKey: .totalSteps)
    try container.encodeIfPresent(polylineData, forKey: .polylineData)
    try container.encodeIfPresent(thumbnailImageUrl, forKey: .thumbnailImageUrl)
    try container.encode(status, forKey: .status)
    try container.encodeIfPresent(pausedAt, forKey: .pausedAt)
    try container.encode(totalPausedDuration, forKey: .totalPausedDuration)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)

    // CLLocation配列をLocationData配列に変換
    let locationDataArray = locations.map { LocationData(from: $0) }
    try container.encode(locationDataArray, forKey: .locationData)
  }

  /// Firestore用のカスタムデコーディング
  ///
  /// Firestoreから取得したデータをWalkインスタンスに変換します。
  /// LocationData配列をCLLocation配列に復元します。
  ///
  /// - Parameter decoder: デコーダー
  /// - Throws: デコーディングエラー（UUID変換エラーを含む）
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let idString = try container.decode(String.self, forKey: .id)
    guard let uuid = UUID(uuidString: idString) else {
      throw DecodingError.dataCorruptedError(
        forKey: .id, in: container, debugDescription: "Invalid UUID string")
    }
    self.id = uuid

    self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
    self.title = try container.decode(String.self, forKey: .title)
    self.description = try container.decode(String.self, forKey: .description)
    self.startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
    self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
    self.totalDistance = try container.decode(Double.self, forKey: .totalDistance)
    self.totalSteps = try container.decode(Int.self, forKey: .totalSteps)
    self.polylineData = try container.decodeIfPresent(String.self, forKey: .polylineData)
    self.thumbnailImageUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailImageUrl)
    self.status = try container.decode(WalkStatus.self, forKey: .status)
    self.pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
    self.totalPausedDuration = try container.decode(TimeInterval.self, forKey: .totalPausedDuration)
    self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)

    // LocationData配列をCLLocation配列に変換
    let locationDataArray = try container.decode([LocationData].self, forKey: .locationData)
    self.locations = locationDataArray.map { $0.toCLLocation() }
  }
}
