//
//  LocationManager.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import Foundation
import MapKit

/// 位置情報の更新を通知するデリゲートプロトコル
///
/// LocationManagerからの位置情報更新やエラーを受け取るためのプロトコルです。
protocol LocationUpdateDelegate: AnyObject {
  /// 位置情報が更新された時に呼び出されます
  /// - Parameter location: 更新された位置情報
  func didUpdateLocation(_ location: CLLocation)

  /// 位置情報の取得でエラーが発生した時に呼び出されます
  /// - Parameter error: 発生したエラー
  func didFailWithError(_ error: Error)
}

/// GPS位置情報の取得と管理を行うマネージャー
///
/// `LocationManager`はCoreLocationをラップし、アプリ全体で一貫したGPS位置情報管理を提供します。
/// バックグラウンド位置情報追跡、権限管理、精度調整などの機能を提供します。
///
/// ## Overview
///
/// 主要な機能：
/// - **権限管理**: 位置情報アクセス権限の要求と状態監視
/// - **位置情報追跡**: 高精度GPSデータの収集とフィルタリング
/// - **バックグラウンドサポート**: アプリが非アクティブ時の位置情報追跡
/// - **バッテリー最適化**: 適切な精度設定と更新間隔
/// - **UIテストサポート**: シミュレーターでのモック位置情報
///
/// ## Topics
///
/// ### Creating LocationManager
/// - ``shared``
///
/// ### Location Data
/// - ``currentLocation``
/// - ``authorizationStatus``
///
/// ### Permission Management
/// - ``requestWhenInUseAuthorization()``
/// - ``requestAlwaysAuthorization()``
/// - ``checkAuthorizationStatus()``
///
/// ### Location Tracking
/// - ``startUpdatingLocation()``
/// - ``stopUpdatingLocation()``
///
/// ### Delegate
/// - ``delegate``
/// - ``LocationUpdateDelegate``
///
/// ### Utilities
/// - ``region(from:)``
class LocationManager: NSObject, ObservableObject {
  /// LocationManagerのシングルトンインスタンス
  ///
  /// アプリ全体で単一のLocationManagerインスタンスを使用し、
  /// 位置情報状態の一貫性を保証します。
  static let shared = LocationManager()

  /// CoreLocationマネージャーのインスタンス
  ///
  /// システムのCore Location Frameworkとの通信を管理します。
  /// 位置情報の設定と制御の中核となるオブジェクトです。
  private let locationManager = CLLocationManager()

  /// 現在取得している位置情報
  ///
  /// 最後に受信したGPS位置情報。位置情報が取得されていない場合はnilです。
  /// @Publishedにより、値が変更されるとUI側に自動的に反映されます。
  @Published var currentLocation: CLLocation?

  /// 位置情報アクセスの許可状態
  ///
  /// アプリの位置情報使用許可の現在の状態を表します。
  /// @Publishedにより、権限状態の変更がUI側に自動的に反映されます。
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

  /// 位置情報更新の通知デリゲート
  ///
  /// 位置情報の更新やエラーを受け取るためのweakリファレンス。
  /// LocationUpdateDelegateプロトコルを実装したオブジェクトを設定します。
  weak var delegate: LocationUpdateDelegate?

  /// ログ出力用のEnhancedVibeLoggerインスタンス
  ///
  /// 位置情報関連のデバッグ情報、エラー、動作状況を記録するために使用します。
  private let logger = EnhancedVibeLogger.shared

  /// UIテスト支援ヘルパー
  ///
  /// UIテスト実行時のモック位置情報や状態管理に使用されます。
  private let testingHelper = UITestingHelper.shared

  /// 位置情報設定適用オブジェクト
  ///
  /// LocationSettingsApplicableプロトコルを実装したオブジェクト。
  /// デフォルトはLocationSettingsManager.sharedですが、テスト時はモックを注入可能です。
  private let settingsApplicator: LocationSettingsApplicable

  /// LocationManagerの初期化メソッド
  ///
  /// シングルトンパターンによりプライベート初期化子を定義します。
  /// 初期化時に位置情報マネージャーの設定を行い、UIテストモードの場合は
  /// モック位置情報を設定します。
  ///
  /// - Parameter settingsApplicator: 位置情報設定適用オブジェクト。デフォルトはLocationSettingsManager.shared
  private init(settingsApplicator: LocationSettingsApplicable = LocationSettingsManager.shared) {
    self.settingsApplicator = settingsApplicator
    super.init()
    setupLocationManager()

    // UIテストモードの場合は初期化時にモック状態を設定
    if testingHelper.isUITesting {
      setupMockLocationForTesting()
    }
  }

  /// 位置情報マネージャーの初期設定
  ///
  /// CLLocationManagerのデリゲート設定と精度・フィルター等のパラメーター設定を行います。
  /// 注入された設定適用オブジェクトから設定を読み込み、ユーザーが選択した精度モードを適用します。
  private func setupLocationManager() {
    locationManager.delegate = self

    // 注入された設定適用オブジェクトから設定を適用
    settingsApplicator.applySettingsToLocationManager(locationManager)

    // 自動停止は常に無効化
    locationManager.pausesLocationUpdatesAutomatically = false
  }

  /// アプリ使用中のみの位置情報アクセス許可をリクエスト
  ///
  /// ユーザーに位置情報の使用許可を求めるシステムダイアログを表示します。
  /// アプリがフォアグラウンドで動作している間のみ位置情報にアクセスできます。
  ///
  /// ## Usage
  /// 散歩の記録開始前に権限を確認し、未許可の場合に呼び出します。
  func requestWhenInUseAuthorization() {
    locationManager.requestWhenInUseAuthorization()
  }

  /// 常時位置情報アクセス許可をリクエスト
  ///
  /// ユーザーにバックグラウンドでの位置情報アクセス許可を求めるシステムダイアログを表示します。
  /// アプリが非アクティブ状態でも継続的に位置情報を取得できるようになります。
  ///
  /// ## Note
  /// バックグラウンド位置情報の使用にはInfo.plistでの設定とユーザーの明示的な許可が必要です。
  func requestAlwaysAuthorization() {
    locationManager.requestAlwaysAuthorization()
  }

  /// GPS位置情報の更新を開始
  ///
  /// CoreLocationManagerに位置情報の継続的な追跡を指示します。
  /// 権限状態に応じてバックグラウンド更新も自動設定されます。
  ///
  /// ## Behavior
  /// - 現在の権限状態をログに記録
  /// - バックグラウンド更新設定の確認と適用
  /// - 位置情報更新の開始
  /// - 設定内容の詳細ログ出力
  func startUpdatingLocation() {
    logger.logMethodStart(context: [
      "authorization_status": authorizationStatus.rawValue.description
    ])

    // 注入された設定適用オブジェクトから最新の設定を適用
    settingsApplicator.applySettingsToLocationManager(locationManager)

    // バックグラウンド更新の設定を確認
    configureBackgroundLocationUpdates()
    locationManager.startUpdatingLocation()

    logger.info(
      operation: "startUpdatingLocation",
      message: "位置情報の更新を開始しました",
      context: [
        "authorization_status": authorizationStatus.rawValue.description,
        "desired_accuracy": String(locationManager.desiredAccuracy),
        "distance_filter": String(locationManager.distanceFilter)
      ]
    )
  }

  /// バックグラウンド位置情報更新の設定
  ///
  /// 権限状態とInfo.plistの設定に基づいて、バックグラウンドでの位置情報更新を有効/無効にします。
  /// 常時許可の場合のみバックグラウンド更新を有効化し、バッテリー使用量を最適化します。
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
              "background_indicator": "false"
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

  /// GPS位置情報の更新を停止
  ///
  /// CoreLocationManagerの位置情報追跡を停止します。
  /// 散歩終了時やアプリの非アクティブ時に呼び出されます。
  ///
  /// ## Behavior
  /// - 位置情報更新の停止
  /// - 停止処理のログ出力
  /// - バッテリー消費の停止
  func stopUpdatingLocation() {
    logger.logMethodStart()
    locationManager.stopUpdatingLocation()

    logger.info(
      operation: "stopUpdatingLocation",
      message: "位置情報の更新を停止しました",
      context: ["authorization_status": authorizationStatus.rawValue.description]
    )
  }

  /// 位置情報アクセス許可の現在状態を取得
  ///
  /// システムの位置情報アクセス許可状態を確認します。
  /// UIテストモード時は自動的にモック状態を返します。
  ///
  /// - Returns: 現在の位置情報アクセス許可状態
  func checkAuthorizationStatus() -> CLAuthorizationStatus {
    // UIテストモードの場合はモック状態を返す
    if testingHelper.isUITesting {
      return .authorizedWhenInUse
    }
    return locationManager.authorizationStatus
  }

  /// UIテスト用のモック位置情報設定
  ///
  /// UIテスト実行時に使用する固定の位置情報とアクセス許可状態を設定します。
  /// 東京駅の座標を基準位置として使用し、テストの一貫性を保証します。
  ///
  /// ## Mock Settings
  /// - 位置: 東京駅（35.6812, 139.7671）
  /// - 許可状態: authorizedWhenInUse
  private func setupMockLocationForTesting() {
    // 東京駅の座標をモック位置として設定
    let mockLocation = CLLocation(latitude: 35.6812, longitude: 139.7671)
    currentLocation = mockLocation
    authorizationStatus = .authorizedWhenInUse

    logger.info(
      operation: "setupMockLocationForTesting",
      message: "UIテスト用のモック位置情報を設定しました",
      context: [
        "latitude": "\(mockLocation.coordinate.latitude)",
        "longitude": "\(mockLocation.coordinate.longitude)",
        "authorization_status": "authorizedWhenInUse"
      ]
    )
  }

  /// 指定位置を中心とするマップ表示領域を作成
  ///
  /// CLLocationから地図表示用のMKCoordinateRegionを生成します。
  /// デフォルトでは1km四方の領域を表示範囲として設定します。
  ///
  /// - Parameters:
  ///   - location: 中心点となる位置情報
  ///   - latitudinalMeters: 南北方向の表示範囲（メートル、デフォルト: 1000m）
  ///   - longitudinalMeters: 東西方向の表示範囲（メートル、デフォルト: 1000m）
  /// - Returns: マップ表示用の座標領域
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

/// CLLocationManagerDelegateプロトコルの実装
///
/// CoreLocationからのコールバック処理を実装し、位置情報の更新、エラー処理、
/// 権限状態の変更に対応します。各イベントは適切にログに記録され、
/// デリゲートオブジェクトに通知されます。
extension LocationManager: CLLocationManagerDelegate {
  /// 位置情報が更新された時のコールバック処理
  ///
  /// CoreLocationManagerから新しい位置情報を受信した際に呼び出されます。
  /// 最新の位置情報を保存し、詳細なログを記録してデリゲートに通知します。
  ///
  /// - Parameters:
  ///   - manager: 位置情報を送信したCLLocationManagerインスタンス
  ///   - locations: 受信した位置情報の配列（最新が末尾）
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      return
    }
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
        "course": String(location.course)
      ]
    )

    delegate?.didUpdateLocation(location)
  }

  /// 位置情報取得エラー時のコールバック処理
  ///
  /// CoreLocationManagerで位置情報の取得に失敗した際に呼び出されます。
  /// エラー内容を詳細にログに記録し、デリゲートに通知します。
  ///
  /// - Parameters:
  ///   - manager: エラーが発生したCLLocationManagerインスタンス
  ///   - error: 発生したエラーの詳細情報
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    logger.logError(
      error,
      operation: "locationManager:didFailWithError",
      humanNote: "位置情報の取得に失敗しました",
      aiTodo: "位置情報の権限と設定を確認してください"
    )
    delegate?.didFailWithError(error)
  }

  /// 位置情報アクセス許可状態変更時のコールバック処理
  ///
  /// ユーザーが位置情報アクセス許可を変更した際にシステムから呼び出されます。
  /// 新しい許可状態に応じて位置情報の追跡を開始/停止し、詳細なログを記録します。
  ///
  /// - Parameter manager: 許可状態が変更されたCLLocationManagerインスタンス
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let previousStatus = authorizationStatus
    authorizationStatus = manager.authorizationStatus

    logger.info(
      operation: "locationManagerDidChangeAuthorization",
      message: "位置情報の許可状態が変更されました",
      context: [
        "previous_status": previousStatus.rawValue.description,
        "new_status": authorizationStatus.rawValue.description
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
