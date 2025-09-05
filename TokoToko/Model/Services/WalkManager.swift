//
//  WalkManager.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import Combine
import CoreLocation
import CoreMotion
import FirebaseAuth
import FirebaseStorage
import Foundation
import MapKit
import UIKit

/// 散歩セッションを管理するメインコントローラー
///
/// `WalkManager`は散歩の開始から終了までの全ライフサイクルを管理するシングルトンクラスです。
/// GPS位置情報の追跡、歩数カウント、時間計測、サムネイル生成などの機能を統合的に提供します。
///
/// ## Overview
///
/// このクラスは以下の主要な機能を提供します：
/// - **散歩制御**: 開始、一時停止、再開、終了の状態管理
/// - **位置情報追跡**: GPSデータの収集と距離計算
/// - **歩数計測**: CoreMotionを使った歩数カウント
/// - **データ永続化**: ローカルストレージとFirebase連携
/// - **サムネイル生成**: 散歩ルートのマップスナップショット
///
/// ## Architecture
///
/// WalkManagerは以下のコンポーネントと連携します：
/// - ``LocationManager``: GPS位置情報の取得と管理
/// - ``StepCountManager``: 歩数計測とCoreMotion連携
/// - ``WalkRepository``: 散歩データの永続化層
/// - ``EnhancedVibeLogger``: ログライティングとデバッグ
///
/// ## Topics
///
/// ### Creating WalkManager
/// - ``shared``
///
/// ### Walk State Management
/// - ``startWalk(title:description:)``
/// - ``pauseWalk()``
/// - ``resumeWalk()``
/// - ``stopWalk()``
/// - ``cancelWalk()``
///
/// ### Current Walk Information
/// - ``currentWalk``
/// - ``isWalking``
/// - ``isRecording``
/// - ``elapsedTime``
/// - ``distance``
/// - ``totalSteps``
///
/// ### Location and Steps
/// - ``currentLocation``
/// - ``currentStepCount``
///
/// ### Display Formatters
/// - ``elapsedTimeString``
/// - ``distanceString``
///
/// ### Thumbnail Generation
/// - ``generateAndSaveThumbnail(for:)``
/// - ``saveImageLocally(_:for:)``
/// - ``loadImageLocally(for:)``
///
/// ### Delegates
/// - ``LocationManagerDelegate``
/// - ``StepCountDelegate``
class WalkManager: NSObject, ObservableObject, StepCountDelegate {
  /// WalkManagerのシングルトンインスタンス
  ///
  /// アプリ全体で単一のWalkManagerインスタンスを使用し、散歩状態の一貫性を保証します。
  static let shared = WalkManager()

  /// 現在進行中の散歩セッション
  ///
  /// 散歩が開始されている場合のWalkインスタンス。散歩が行われていない場合はnil。
  @Published var currentWalk: Walk?

  /// 散歩の経過時間（秒）
  ///
  /// 一時停止時間を除いた実際の散歩時間。リアルタイムで更新されます。
  @Published var elapsedTime: TimeInterval = 0

  /// 現在の総距離（メートル）
  ///
  /// GPS位置情報から計算された散歩の総距離。位置情報が更新される度に再計算されます。
  @Published var distance: Double = 0

  /// 現在のGPS位置情報
  ///
  /// LocationManagerから取得した最新の位置情報。位置情報が利用できない場合はnil。
  @Published var currentLocation: CLLocation?

  /// 現在の歩数カウントソース
  ///
  /// CoreMotionからの実際の歩数、または利用不可状態。
  @Published var currentStepCount: StepCountSource = .unavailable

  /// 散歩セッションがアクティブかどうか
  ///
  /// 散歩が進行中または一時停止中の場合にtrue。散歩が未開始または終了している場合はfalse。
  ///
  /// - Returns: 散歩セッションがアクティブな場合true
  var isWalking: Bool {
    currentWalk?.status == .inProgress || currentWalk?.status == .paused
  }

  /// 散歩のデータ記録がアクティブかどうか
  ///
  /// 散歩が現在進行中で、GPSデータや歩数が記録されている状態かどうか。
  /// 一時停止中は記録停止とみなされます。
  ///
  /// - Returns: データ記録中の場合true、一時停止中や未開始の場合false
  var isRecording: Bool {
    currentWalk?.status == .inProgress
  }

  // 散歩開始待機中のパラメータ（権限要求中に使用）
  var pendingWalkTitle: String?
  var pendingWalkDescription: String?

  // 依存関係
  let locationManager = LocationManager.shared
  let walkRepository = WalkRepository.shared
  let stepCountManager = StepCountManager.shared
  let logger = EnhancedVibeLogger.shared

  // タイマー
  var timer: Timer?
  var cancellables = Set<AnyCancellable>()

  // ローカル保存用ディレクトリ
  lazy var documentsDirectory: URL = {
    guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      fatalError("Documents directory not found")
    }
    return url
  }()
  let thumbnailsDirectoryName = "walk_thumbnails"

  override private init() {
    super.init()
    createThumbnailsDirectoryIfNeeded()
    setupLocationManager()
    setupStepCountManager()
  }

  deinit {
    cancellables.removeAll()
    timer?.invalidate()
    stepCountManager.stopTracking(finalStop: true)
  }

  // MARK: - Setup Methods

  private func setupLocationManager() {
    locationManager.delegate = self

    locationManager.$currentLocation
      .sink { [weak self] location in
        self?.currentLocation = location
        if let location = location, self?.isRecording == true {
          self?.addLocationToCurrentWalk(location)
        }
      }
      .store(in: &cancellables)

    locationManager.$authorizationStatus
      .sink { [weak self] status in
        self?.handleAuthorizationStatusChange(status)
      }
      .store(in: &cancellables)
  }

  private func setupStepCountManager() {
    stepCountManager.delegate = self
  }

  // MARK: - Walk Control Methods

  /// 新しい散歩セッションを開始します
  func startWalk(title: String = "", description: String = "") {
    logger.logMethodStart(context: ["title": title, "description": description])

    guard !isWalking else {
      logger.warning(
        operation: "startWalk",
        message: "散歩が既に開始されています"
      )
      return
    }

    guard let userId = Auth.auth().currentUser?.uid else {
      logger.error(operation: "startWalk", message: "ユーザー認証が必要です")
      return
    }

    let authStatus = locationManager.checkAuthorizationStatus()
    if authStatus != .authorizedAlways {
      handleLocationPermissionRequest(title: title, description: description)
      return
    }

    performWalkStart(title: title, description: description, userId: userId)
  }

  private func handleLocationPermissionRequest(title: String, description: String) {
    logger.info(
      operation: "startWalk",
      message: "バックグラウンド位置情報権限を要求します"
    )
    pendingWalkTitle = title
    pendingWalkDescription = description
    locationManager.requestAlwaysAuthorization()
  }

  private func performWalkStart(title: String, description: String, userId: String) {
    let finalTitle = title.isEmpty ? defaultWalkTitle() : title

    var newWalk = Walk(
      title: finalTitle,
      description: description,
      userId: userId,
      status: .inProgress
    )
    newWalk.start()

    if let location = currentLocation {
      newWalk.addLocation(location)
      logger.logLocationBugPrevention(
        location: location,
        accuracy: location.horizontalAccuracy,
        batteryLevel: UIDevice.current.batteryLevel,
        duration: 0,
        context: ["action": "walk_start", "title": finalTitle]
      )
    }

    currentWalk = newWalk
    elapsedTime = 0
    distance = 0

    startLocationTracking()
    startStepCounting()
    startTimer()

    logger.info(
      operation: "startWalk",
      message: "散歩開始完了",
      context: ["title": finalTitle, "walk_id": newWalk.id.uuidString]
    )
  }

  private func startLocationTracking() {
    locationManager.startUpdatingLocation()
  }

  private func startStepCounting() {
    if stepCountManager.isStepCountingAvailable() {
      stepCountManager.startTracking(newWalk: true)
      logger.info(operation: "startWalk", message: "歩数トラッキング開始")
    } else {
      logger.warning(operation: "startWalk", message: "歩数計測利用不可")
      currentStepCount = .unavailable
    }
  }

  /// 散歩を一時停止
  func pauseWalk() {
    logger.logMethodStart()

    guard isRecording, var walk = currentWalk else {
      logger.warning(operation: "pauseWalk", message: "散歩が進行中ではありません")
      return
    }

    walk.pause()
    currentWalk = walk
    locationManager.stopUpdatingLocation()
    stepCountManager.stopTracking(finalStop: false)
    stopTimer()

    logger.info(operation: "pauseWalk", message: "散歩を一時停止しました")
  }

  /// 散歩を再開
  func resumeWalk() {
    logger.logMethodStart()

    guard currentWalk?.status == .paused, var walk = currentWalk else {
      logger.warning(operation: "resumeWalk", message: "散歩が一時停止されていません")
      return
    }

    walk.resume()
    currentWalk = walk
    locationManager.startUpdatingLocation()
    stepCountManager.startTracking()
    startTimer()

    logger.info(operation: "resumeWalk", message: "散歩を再開しました")
  }

  /// 散歩を終了
  func stopWalk() {
    logger.logMethodStart()

    guard isWalking, var walk = currentWalk else {
      logger.warning(operation: "stopWalk", message: "散歩が開始されていません")
      return
    }

    // 合意仕様: 実測歩数のみ保存（不可時は0）
    walk.totalSteps = currentStepCount.steps ?? 0

    walk.complete()
    currentWalk = walk

    locationManager.stopUpdatingLocation()
    stepCountManager.stopTracking(finalStop: true)
    stopTimer()

    saveCurrentWalk()
    generateAndSaveThumbnail(for: walk)

    currentWalk = nil
    elapsedTime = 0
    distance = 0
    currentStepCount = .unavailable

    logger.info(operation: "stopWalk", message: "散歩を終了しました")
  }

  /// 散歩をキャンセル
  func cancelWalk() {
    logger.logMethodStart()

    locationManager.stopUpdatingLocation()
    stepCountManager.stopTracking(finalStop: true)
    stopTimer()

    currentWalk = nil
    elapsedTime = 0
    distance = 0
    currentStepCount = .unavailable

    logger.info(operation: "cancelWalk", message: "散歩をキャンセルしました")
  }

  // MARK: - Helper Methods

  private func addLocationToCurrentWalk(_ location: CLLocation) {
    guard var walk = currentWalk else {
      return
    }
    walk.addLocation(location)
    currentWalk = walk
    distance = walk.totalDistance
  }

  private func saveCurrentWalk() {
    guard let walk = currentWalk else {
      return
    }

    walkRepository.saveWalk(walk) { [weak self] result in
      switch result {
      case .success(let savedWalk):
        self?.logger.info(operation: "saveWalk", message: "散歩データを保存しました", context: ["walkId": savedWalk.id.uuidString])
      case .failure(let error):
        self?.logger.logError(error, operation: "saveWalk")
      }
    }
  }

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.updateElapsedTime()
    }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func updateElapsedTime() {
    guard let walk = currentWalk, walk.status == .inProgress else {
      return
    }
    elapsedTime = walk.duration
  }

  private func defaultWalkTitle() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M/d の散歩"
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: Date())
  }

  private func handleAuthorizationStatusChange(_ status: CLAuthorizationStatus) {
    if status == .authorizedAlways,
       let title = pendingWalkTitle,
       let description = pendingWalkDescription,
       let userId = Auth.auth().currentUser?.uid {
      pendingWalkTitle = nil
      pendingWalkDescription = nil
      performWalkStart(title: title, description: description, userId: userId)
    }
  }
}
