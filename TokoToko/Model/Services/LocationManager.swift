//
//  LocationManager.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import Foundation
import MapKit

// 位置情報の更新を通知するためのプロトコル
protocol LocationUpdateDelegate: AnyObject {
  func didUpdateLocation(_ location: CLLocation)
  func didFailWithError(_ error: Error)
}

class LocationManager: NSObject, ObservableObject {
  // シングルトンインスタンス
  static let shared = LocationManager()

  // CoreLocationマネージャー
  private let locationManager = CLLocationManager()

  // 現在の位置情報
  @Published var currentLocation: CLLocation?
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

  // デリゲート
  weak var delegate: LocationUpdateDelegate?

  // ログ
  private let logger = EnhancedVibeLogger.shared

  // 初期化
  override private init() {
    super.init()
    setupLocationManager()
  }

  // 位置情報マネージャーの設定
  private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters  // バッテリー効率を考慮
    locationManager.distanceFilter = 15  // 15メートル移動したら更新
    locationManager.pausesLocationUpdatesAutomatically = false  // 自動停止を無効化
  }

  // 位置情報の使用許可をリクエスト（アプリ使用中のみ）
  func requestWhenInUseAuthorization() {
    locationManager.requestWhenInUseAuthorization()
  }

  // 位置情報の使用許可をリクエスト（常時）
  func requestAlwaysAuthorization() {
    locationManager.requestAlwaysAuthorization()
  }

  // 位置情報の更新を開始
  func startUpdatingLocation() {
    logger.logMethodStart(context: [
      "authorization_status": authorizationStatus.rawValue.description
    ])

    // バックグラウンド更新の設定を確認
    configureBackgroundLocationUpdates()
    locationManager.startUpdatingLocation()

    logger.info(
      operation: "startUpdatingLocation",
      message: "位置情報の更新を開始しました",
      context: [
        "authorization_status": authorizationStatus.rawValue.description,
        "desired_accuracy": String(locationManager.desiredAccuracy),
        "distance_filter": String(locationManager.distanceFilter),
      ]
    )
  }

  // バックグラウンド位置情報更新の設定
  private func configureBackgroundLocationUpdates() {
    if authorizationStatus == .authorizedAlways {
      if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
        let backgroundModes =
          Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        if backgroundModes.contains("location") {
          locationManager.allowsBackgroundLocationUpdates = true
          locationManager.showsBackgroundLocationIndicator = false  // バッテリー節約のためfalse
          logger.info(
            operation: "configureBackgroundLocationUpdates",
            message: "バックグラウンド位置情報更新を有効にしました",
            context: [
              "authorization_status": "authorizedAlways",
              "background_modes": backgroundModes.joined(separator: ","),
              "background_indicator": "false",
            ]
          )
        }
      }
    } else {
      locationManager.allowsBackgroundLocationUpdates = false
      logger.info(
        operation: "configureBackgroundLocationUpdates",
        message: "バックグラウンド位置情報更新を無効にしました",
        context: ["authorization_status": authorizationStatus.rawValue.description]
      )
    }
  }

  // 位置情報の更新を停止
  func stopUpdatingLocation() {
    logger.logMethodStart()
    locationManager.stopUpdatingLocation()

    logger.info(
      operation: "stopUpdatingLocation",
      message: "位置情報の更新を停止しました",
      context: ["authorization_status": authorizationStatus.rawValue.description]
    )
  }

  // 位置情報の許可状態を確認
  func checkAuthorizationStatus() -> CLAuthorizationStatus {
    locationManager.authorizationStatus
  }

  // 指定された座標を中心とするマップ領域を作成
  func region(
    for location: CLLocation, latitudinalMeters: CLLocationDistance = 1000,
    longitudinalMeters: CLLocationDistance = 1000
  ) -> MKCoordinateRegion {
    MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: latitudinalMeters,
      longitudinalMeters: longitudinalMeters
    )
  }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
  // 位置情報の更新時に呼ばれる
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    currentLocation = location

    logger.logLocationBugPrevention(
      location: location,
      accuracy: location.horizontalAccuracy,
      batteryLevel: UIDevice.current.batteryLevel,
      duration: Date().timeIntervalSince(location.timestamp),
      context: [
        "locations_count": String(locations.count),
        "speed": String(location.speed),
        "altitude": String(location.altitude),
        "course": String(location.course),
      ]
    )

    delegate?.didUpdateLocation(location)
  }

  // エラー発生時に呼ばれる
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    logger.logError(
      error,
      operation: "locationManager:didFailWithError",
      humanNote: "位置情報の取得に失敗しました",
      aiTodo: "位置情報の権限と設定を確認してください"
    )
    delegate?.didFailWithError(error)
  }

  // 位置情報の許可状態が変更された時に呼ばれる
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let previousStatus = authorizationStatus
    authorizationStatus = manager.authorizationStatus

    logger.info(
      operation: "locationManagerDidChangeAuthorization",
      message: "位置情報の許可状態が変更されました",
      context: [
        "previous_status": previousStatus.rawValue.description,
        "new_status": authorizationStatus.rawValue.description,
      ]
    )

    switch manager.authorizationStatus {
    case .authorizedWhenInUse:
      // 使用中のみ許可された場合は位置情報の更新を開始
      startUpdatingLocation()
      // バックグラウンド更新は無効
      locationManager.allowsBackgroundLocationUpdates = false
      logger.info(
        operation: "locationManagerDidChangeAuthorization",
        message: "使用中のみ許可 - 位置情報更新を開始",
        context: ["background_updates": "disabled"]
      )
    case .authorizedAlways:
      // 常に許可された場合は位置情報の更新を開始
      startUpdatingLocation()
      logger.info(
        operation: "locationManagerDidChangeAuthorization",
        message: "常に許可 - 位置情報更新を開始",
        context: ["background_updates": "enabled"]
      )
    case .denied, .restricted:
      // 拒否された場合はエラーメッセージを表示
      logger.warning(
        operation: "locationManagerDidChangeAuthorization",
        message: "位置情報の使用が拒否されました",
        context: ["status": authorizationStatus.rawValue.description],
        humanNote: "設定アプリから許可してください",
        aiTodo: "ユーザーに位置情報許可を促すUI表示を検討"
      )
    case .notDetermined:
      // まだ決定されていない場合は何もしない
      logger.info(
        operation: "locationManagerDidChangeAuthorization",
        message: "位置情報の許可状態が未決定",
        context: ["status": "notDetermined"]
      )
    @unknown default:
      logger.warning(
        operation: "locationManagerDidChangeAuthorization",
        message: "不明な位置情報許可状態",
        context: ["status": "unknown"],
        aiTodo: "新しい許可状態への対応を検討"
      )
    }
  }
}
