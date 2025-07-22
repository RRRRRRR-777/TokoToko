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
  /// CoreMotionからの実際の歩数、1歩あたりの距離からの推定、または利用不可状態。
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
  private var pendingWalkTitle: String?
  private var pendingWalkDescription: String?

  // 位置情報マネージャー
  private let locationManager = LocationManager.shared
  private let walkRepository = WalkRepository.shared
  private let stepCountManager = StepCountManager.shared
  private let logger = EnhancedVibeLogger.shared

  // タイマー
  private var timer: Timer?
  private var cancellables = Set<AnyCancellable>()

  // ローカル保存用ディレクトリ
  private lazy var documentsDirectory: URL = {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
  }()
  private let thumbnailsDirectoryName = "walk_thumbnails"

  override private init() {
    super.init()

    // サムネイル用ディレクトリの作成
    createThumbnailsDirectoryIfNeeded()

    setupLocationManager()
    setupStepCountManager()
  }

  deinit {
    cancellables.removeAll()
    timer?.invalidate()
    stepCountManager.stopTracking()
  }

  // 位置情報マネージャーの設定
  private func setupLocationManager() {
    locationManager.delegate = self

    // 位置情報の更新を監視
    locationManager.$currentLocation
      .sink { [weak self] location in
        self?.currentLocation = location
        if let location = location, self?.isRecording == true {
          self?.addLocationToCurrentWalk(location)
        }
      }
      .store(in: &cancellables)

    // 位置情報権限の変更を監視
    locationManager.$authorizationStatus
      .sink { [weak self] status in
        self?.handleAuthorizationStatusChange(status)
      }
      .store(in: &cancellables)
  }

  // 歩数カウントマネージャーの設定
  private func setupStepCountManager() {
    #if DEBUG
      print("🔧 WalkManager: StepCountManager設定開始")
    #endif

    do {
      stepCountManager.delegate = self
      #if DEBUG
        print("✅ WalkManager: StepCountManager設定完了")
        print("📊 WalkManager: StepCountManager利用可能性: \(stepCountManager.isStepCountingAvailable())")
      #endif
    } catch {
      #if DEBUG
        print("❌ WalkManager: StepCountManager設定エラー: \(error)")
      #endif
    }
  }

  /// 新しい散歩セッションを開始します
  ///
  /// 散歩を開始し、GPS位置情報の追跡、歩数カウント、時間計測を開始します。
  /// 既に散歩が開始されている場合や、ユーザーが認証されていない場合は操作が無視されます。
  ///
  /// ## 位置情報権限について
  ///
  /// バックグラウンドでの位置情報追跡のため、「常に」権限が必要です。
  /// 権限が不十分な場合は権限要求が表示され、許可後に散歩が開始されます。
  ///
  /// - Parameters:
  ///   - title: 散歩のタイトル（空の場合はデフォルトタイトルを使用）
  ///   - description: 散歩の説明・メモ
  func startWalk(title: String = "", description: String = "") {
    logger.logMethodStart(context: ["title": title, "description": description])

    guard !isWalking else {
      logger.warning(
        operation: "startWalk",
        message: "散歩が既に開始されています",
        context: ["current_status": currentWalk?.status.rawValue ?? "none"]
      )
      return
    }

    // 認証されたユーザーIDを取得
    guard let userId = Auth.auth().currentUser?.uid else {
      logger.error(
        operation: "startWalk",
        message: "認証されていないユーザーが散歩を開始しようとしました",
        humanNote: "ユーザー認証が必要です",
        aiTodo: "認証フローを確認してください"
      )
      return
    }

    // バックグラウンドでの位置情報追跡のため、常時権限を要求
    let authStatus = locationManager.checkAuthorizationStatus()
    if authStatus != .authorizedAlways {
      logger.info(
        operation: "startWalk",
        message: "バックグラウンド位置情報のため常時権限を要求します",
        context: ["current_status": authStatus.rawValue.description]
      )
      // 散歩開始パラメータを保存
      pendingWalkTitle = title
      pendingWalkDescription = description
      locationManager.requestAlwaysAuthorization()
      return  // 権限が許可されてから再度呼び出される
    }

    // タイトルが空の場合はデフォルトタイトルを使用
    let finalTitle = title.isEmpty ? defaultWalkTitle() : title

    // 新しい散歩を作成
    var newWalk = Walk(
      title: finalTitle,
      description: description,
      userId: userId,
      status: .inProgress
    )
    newWalk.start()

    // 現在位置を開始地点として追加
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

    // 位置情報の更新を開始
    locationManager.startUpdatingLocation()

    // 歩数トラッキングを開始
    logger.info(
      operation: "startWalk",
      message: "歩数トラッキング開始を要求",
      context: ["step_counting_available": String(stepCountManager.isStepCountingAvailable())]
    )

    do {
      // CoreMotion利用可能性を事前チェック
      if stepCountManager.isStepCountingAvailable() {
        stepCountManager.startTracking()
        logger.info(
          operation: "startWalk",
          message: "CoreMotion歩数トラッキング開始",
          context: ["tracking_mode": "coreMotion"]
        )
      } else {
        logger.warning(
          operation: "startWalk",
          message: "CoreMotion利用不可、推定モードで開始",
          context: ["tracking_mode": "estimated"],
          humanNote: "シミュレーターまたは非対応デバイス",
          aiTodo: "実機での動作確認を推奨"
        )
        // シミュレーターや非対応デバイスでは最初から推定モードに設定
        currentStepCount = .estimated(steps: 0)
      }
    } catch {
      logger.logError(
        error,
        operation: "startWalk",
        humanNote: "歩数トラッキング開始でエラー",
        aiTodo: "CoreMotionの権限と設定を確認"
      )
      // エラー時も推定モードで続行
      currentStepCount = .estimated(steps: 0)
    }

    // タイマーを開始
    startTimer()

    logger.logWalkStateTransitionBugPrevention(
      walkId: currentWalk?.id.uuidString ?? "unknown",
      fromState: "notStarted",
      toState: "inProgress",
      trigger: "startWalk",
      context: [
        "title": finalTitle,
        "user_id": userId,
        "has_location": String(currentLocation != nil),
      ]
    )

    logger.info(
      operation: "startWalk",
      message: "散歩開始完了",
      context: ["title": finalTitle, "walk_id": newWalk.id.uuidString]
    )
  }

  /// 現在の散歩セッションを一時停止します
  ///
  /// GPS位置情報の追跡、歩数カウント、時間計測を一時停止します。
  /// 一時停止時間は記録され、最終的な散歩時間から除外されます。
  /// 散歩が進行中でない場合は操作が無視されます。
  func pauseWalk() {
    logger.logMethodStart()

    guard isRecording, var walk = currentWalk else {
      logger.warning(
        operation: "pauseWalk",
        message: "一時停止可能な散歩が存在しません",
        context: [
          "is_recording": String(isRecording), "current_walk": currentWalk?.id.uuidString ?? "none",
        ]
      )
      return
    }

    walk.pause()
    currentWalk = walk

    // タイマーを停止
    stopTimer()

    // 位置情報の更新を停止
    locationManager.stopUpdatingLocation()

    // 歩数トラッキングを停止
    stepCountManager.stopTracking()

    logger.logWalkStateTransitionBugPrevention(
      walkId: currentWalk?.id.uuidString ?? "unknown",
      fromState: "inProgress",
      toState: "paused",
      trigger: "pauseWalk",
      context: [
        "walk_id": walk.id.uuidString,
        "elapsed_time": String(elapsedTime),
        "distance": String(distance),
      ]
    )

    logger.info(
      operation: "pauseWalk",
      message: "散歩を一時停止しました",
      context: ["walk_id": walk.id.uuidString]
    )
  }

  /// 一時停止中の散歩セッションを再開します
  ///
  /// GPS位置情報の追跡、歩数カウント、時間計測を再開します。
  /// 一時停止時間は累積時間に加算され、一時停止状態がクリアされます。
  /// 散歩が一時停止中でない場合は操作が無視されます。
  func resumeWalk() {
    logger.logMethodStart()

    guard !isRecording, var walk = currentWalk, walk.status == .paused else {
      logger.warning(
        operation: "resumeWalk",
        message: "再開可能な散歩が存在しません",
        context: [
          "is_recording": String(isRecording),
          "current_walk": currentWalk?.id.uuidString ?? "none",
          "walk_status": currentWalk?.status.rawValue ?? "none",
        ]
      )
      return
    }

    walk.resume()
    currentWalk = walk

    // 位置情報の更新を再開
    locationManager.startUpdatingLocation()

    // 歩数トラッキングを再開
    stepCountManager.startTracking()

    // タイマーを再開
    startTimer()

    logger.logWalkStateTransitionBugPrevention(
      walkId: currentWalk?.id.uuidString ?? "unknown",
      fromState: "paused",
      toState: "inProgress",
      trigger: "resumeWalk",
      context: [
        "walk_id": walk.id.uuidString,
        "elapsed_time": String(elapsedTime),
        "distance": String(distance),
      ]
    )

    logger.info(
      operation: "resumeWalk",
      message: "散歩を再開しました",
      context: ["walk_id": walk.id.uuidString]
    )
  }

  /// 現在の散歩セッションを終了します
  ///
  /// 散歩を完了状態にし、全ての追跡を停止し、データを保存します。
  /// サムネイル画像の生成、ローカルストレージへの保存、
  /// Firebaseへのアップロードなどが自動的に実行されます。
  /// 散歩が開始されていない場合は操作が無視されます。
  func stopWalk() {
    logger.logMethodStart()

    guard var walk = currentWalk else {
      logger.warning(
        operation: "stopWalk",
        message: "終了可能な散歩が存在しません",
        context: ["current_walk": "none"]
      )
      return
    }

    let previousStatus = walk.status.rawValue

    // 最終歩数を保存
    walk.totalSteps = totalSteps
    walk.complete()
    currentWalk = walk

    // タイマーを停止
    stopTimer()

    // 位置情報の更新を停止
    locationManager.stopUpdatingLocation()

    // 歩数トラッキングを停止
    stepCountManager.stopTracking()

    // サムネイル画像を生成して保存
    generateAndSaveThumbnail(for: walk)

    // 散歩をリポジトリに保存
    saveCurrentWalk()

    logger.logWalkStateTransitionBugPrevention(
      walkId: currentWalk?.id.uuidString ?? "unknown",
      fromState: previousStatus,
      toState: "completed",
      trigger: "stopWalk",
      context: [
        "walk_id": walk.id.uuidString,
        "final_distance": String(walk.totalDistance),
        "final_duration": String(walk.duration),
        "final_steps": String(walk.totalSteps),
        "locations_count": String(walk.locations.count),
      ]
    )

    logger.info(
      operation: "stopWalk",
      message: "散歩を終了しました",
      context: [
        "walk_id": walk.id.uuidString,
        "distance": walk.distanceString,
        "duration": walk.durationString,
        "steps": String(walk.totalSteps),
      ]
    )
  }

  /// 現在の散歩セッションをキャンセルします
  ///
  /// 散歩を中止し、全てのデータを破棄します。保存やサムネイル生成は行われません。
  /// 位置情報追跡、歩数カウント、時間計測を停止し、状態をリセットします。
  func cancelWalk() {
    currentWalk = nil
    elapsedTime = 0
    distance = 0

    // タイマーを停止
    stopTimer()

    // 位置情報の更新を停止
    locationManager.stopUpdatingLocation()

    // 歩数トラッキングを停止
    stepCountManager.stopTracking()

    print("散歩をキャンセルしました")
  }

  // 現在の散歩に位置情報を追加
  private func addLocationToCurrentWalk(_ location: CLLocation) {
    guard var walk = currentWalk, isRecording else { return }

    walk.addLocation(location)
    currentWalk = walk
    distance = walk.totalDistance
  }

  // 現在の散歩を保存
  private func saveCurrentWalk() {
    guard let walk = currentWalk else {
      print("エラー: 保存する散歩がありません")
      return
    }

    print("散歩を保存しています: \(walk.title), userID: \(walk.userId ?? "nil")")

    walkRepository.saveWalk(walk) { result in
      DispatchQueue.main.async {
        switch result {
        case .success:
          break
        case .failure(let error):
          print("❌ 散歩の保存に失敗しました: \(error)")
        }
      }
    }

    // 現在の散歩をクリア
    currentWalk = nil
  }

  // タイマーを開始
  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.updateElapsedTime()
    }
  }

  // タイマーを停止
  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  // 経過時間を更新
  private func updateElapsedTime() {
    guard let walk = currentWalk else { return }
    elapsedTime = walk.duration

    // CoreMotion非対応時は推定歩数をリアルタイム更新
    if case .estimated = currentStepCount {
      let newEstimatedStepCount = stepCountManager.estimateSteps(
        distance: distance,
        duration: elapsedTime
      )
      currentStepCount = newEstimatedStepCount

      #if DEBUG
        if let steps = newEstimatedStepCount.steps {
          print(
            "📊 推定歩数更新: \(steps)歩 (距離: \(String(format: "%.1f", distance))m, 時間: \(String(format: "%.0f", elapsedTime))s)"
          )
        }
      #endif
    }
  }

  /// 散歩経過時間のフォーマット済み文字列
  ///
  /// 経過時間を"HH:MM:SS"または"MM:SS"形式で返します。
  /// 1時間未満の場合は"MM:SS"、1時間以上の場合は"H:MM:SS"形式で表示します。
  ///
  /// - Returns: フォーマットされた時間文字列
  var elapsedTimeString: String {
    let hours = Int(elapsedTime) / 3600
    let minutes = Int(elapsedTime) % 3600 / 60
    let seconds = Int(elapsedTime) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }

  /// 現在の総歩数
  ///
  /// CoreMotionからの実際の歩数、または距離・時間からの推定歩数を返します。
  /// CoreMotionが利用できない場合は、歩行速度から自動的に推定します。
  ///
  /// - Returns: 現在の総歩数
  var totalSteps: Int {
    // StepCountManagerから歩数を取得、フォールバックで推定歩数を使用
    if let steps = currentStepCount.steps {
      return steps
    }

    // CoreMotionが利用できない場合は距離ベースで推定
    let estimatedStepCount = stepCountManager.estimateSteps(
      distance: distance, duration: elapsedTime)
    return estimatedStepCount.steps ?? 0
  }

  /// 距離のフォーマット済み文字列
  ///
  /// 総距離を適切な単位（メートルまたはキロメートル）で返します。
  /// 1000m未満の場合はメートル、以上の場合はキロメートルで表示されます。
  ///
  /// - Returns: フォーマットされた距離文字列（例: "1.23 km"、"500 m"）
  var distanceString: String {
    if distance >= 1000 {
      return String(format: "%.2f km", distance / 1000)
    } else {
      return String(format: "%.0f m", distance)
    }
  }

  /// デフォルトの散歩タイトルを生成します
  ///
  /// ユーザーがタイトルを指定しなかった場合に使用する、
  /// 日付ベースのデフォルトタイトルを生成します。
  ///
  /// - Returns: "M月d日の散歩"形式のタイトル文字列
  private func defaultWalkTitle() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M月d日"
    formatter.locale = Locale(identifier: "ja_JP")
    return "\(formatter.string(from: Date()))の散歩"
  }

  // 位置情報権限の変更を処理
  private func handleAuthorizationStatusChange(_ status: CLAuthorizationStatus) {
    switch status {
    case .authorizedAlways:
      // 常時権限が許可された場合、待機中の散歩があれば開始
      if let title = pendingWalkTitle, let description = pendingWalkDescription {
        print("常時権限が許可されました。散歩を開始します。")
        let finalTitle = title.isEmpty ? defaultWalkTitle() : title
        pendingWalkTitle = nil
        pendingWalkDescription = nil
        startWalk(title: finalTitle, description: description)
      }
    case .denied, .restricted:
      // 権限が拒否された場合、待機中の散歩をクリア
      if pendingWalkTitle != nil {
        print("位置情報の権限が拒否されました。散歩を開始できません。")
        pendingWalkTitle = nil
        pendingWalkDescription = nil
      }
    default:
      break
    }
  }

  // MARK: - サムネイル生成機能

  // 散歩完了時にサムネイル画像を生成して保存
  /// 散歩ルートのサムネイル画像を生成し保存します
  ///
  /// 散歩のGPSデータからマップスナップショットを生成し、
  /// ローカルストレージとFirebase Storageに保存します。
  /// 処理は非同期で実行され、UIのブロックを防いでます。
  ///
  /// - Parameter walk: サムネイルを生成する散歩データ
  private func generateAndSaveThumbnail(for walk: Walk) {
    print("📸 サムネイル画像の生成を開始しました")

    // 非同期でサムネイル画像を生成
    generateThumbnail(from: walk) { [weak self] thumbnailImage in
      guard let self = self, let thumbnailImage = thumbnailImage else {
        print("⚠️ サムネイル画像の生成に失敗しました")
        return
      }

      #if DEBUG
        print("✅ サムネイル画像生成完了: \(thumbnailImage.size)")
      #endif

      // ローカルに保存
      let localSaveSuccess = self.saveImageLocally(thumbnailImage, for: walk.id)
      if !localSaveSuccess {
        print("⚠️ サムネイル画像のローカル保存に失敗しました")
        return
      }

      #if DEBUG
        print("✅ ローカル保存完了")
      #endif

      // Firebase Storageにアップロード（非同期）
      self.uploadToFirebaseStorage(thumbnailImage, for: walk.id) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let url):
            // 成功: URLをWalkに設定してFirestoreを更新
            var updatedWalk = walk
            updatedWalk.thumbnailImageUrl = url
            self.walkRepository.saveWalk(updatedWalk) { _ in }
            print("✅ サムネイル画像のFirebase保存完了: \(url)")

          case .failure(let error):
            print("⚠️ サムネイル画像のFirebase保存に失敗: \(error)")
          }
        }
      }
    }
  }
}

// MARK: - LocationUpdateDelegate

/// LocationManagerからの位置情報更新を処理する拡張
extension WalkManager: LocationUpdateDelegate {
  /// 位置情報が更新された時に呼び出されます
  ///
  /// 位置情報の更新は`$currentLocation`のCombine監視で処理されるため、
  /// このメソッドでは直接的な処理は行いません。
  ///
  /// - Parameter location: 更新されたGPS位置情報
  func didUpdateLocation(_ location: CLLocation) {
    // 位置情報の更新は$currentLocationの監視で処理
  }

  /// 位置情報の取得エラーが発生した時に呼び出されます
  ///
  /// GPSシグナルの取得失敗、権限エラーなどの位置情報関連エラーをログ出力します。
  ///
  /// - Parameter error: 発生したエラー
  func didFailWithError(_ error: Error) {
    print("位置情報の取得に失敗しました: \(error.localizedDescription)")
  }
}

// MARK: - StepCountDelegate

/// StepCountManagerからの歩数更新を処理する拡張
extension WalkManager {
  /// 歩数カウントが更新された時に呼び出されます
  ///
  /// CoreMotionからの実際の歩数、または距離・時間からの推定歩数を受け取り、
  /// UI更新のためにメインスレッドで`currentStepCount`を更新します。
  ///
  /// - Parameter stepCount: 更新された歩数データ
  func stepCountDidUpdate(_ stepCount: StepCountSource) {
    DispatchQueue.main.async { [weak self] in
      self?.currentStepCount = stepCount

      #if DEBUG
        if let steps = stepCount.steps {
          print("📊 歩数更新: \(steps)歩 (\(stepCount.isRealTime ? "実測" : "推定"))")
        }
      #endif
    }
  }

  func stepCountDidFailWithError(_ error: Error) {
    DispatchQueue.main.async { [weak self] in
      self?.currentStepCount = .unavailable

      #if DEBUG
        print("❌ 歩数取得エラー: \(error.localizedDescription)")
      #endif

      // エラー発生時は距離ベースの推定値にフォールバック
      if let self = self, self.isRecording {
        let estimatedStepCount = self.stepCountManager.estimateSteps(
          distance: self.distance,
          duration: self.elapsedTime
        )
        self.currentStepCount = estimatedStepCount
      }
    }
  }
}

// MARK: - 画像ストレージ機能（統合）
extension WalkManager {

  // MARK: - ローカルストレージ操作

  // サムネイル用ディレクトリの作成
  private func createThumbnailsDirectoryIfNeeded() {
    let thumbnailsDirectory = documentsDirectory.appendingPathComponent(thumbnailsDirectoryName)

    if !FileManager.default.fileExists(atPath: thumbnailsDirectory.path) {
      do {
        try FileManager.default.createDirectory(
          at: thumbnailsDirectory,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        #if DEBUG
          print("❌ サムネイルディレクトリ作成エラー: \(error)")
        #endif
      }
    }
  }

  // ローカル画像URLの取得
  private func localImageURL(for walkId: UUID) -> URL {
    let thumbnailsDirectory = documentsDirectory.appendingPathComponent(thumbnailsDirectoryName)
    return thumbnailsDirectory.appendingPathComponent("\(walkId.uuidString).jpg")
  }

  // 画像をローカルに保存
  func saveImageLocally(_ image: UIImage, for walkId: UUID) -> Bool {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      return false
    }

    let fileURL = localImageURL(for: walkId)

    do {
      try imageData.write(to: fileURL)
      return true
    } catch {
      #if DEBUG
        print("❌ ローカル画像保存エラー: \(error)")
      #endif
      return false
    }
  }

  // ローカルから画像を読み込み
  func loadImageLocally(for walkId: UUID) -> UIImage? {
    let fileURL = localImageURL(for: walkId)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return nil
    }

    guard let imageData = try? Data(contentsOf: fileURL) else {
      return nil
    }

    return UIImage(data: imageData)
  }

  // ローカルの画像を削除
  func deleteLocalImage(for walkId: UUID) -> Bool {
    let fileURL = localImageURL(for: walkId)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return true  // 既に存在しない場合は成功とする
    }

    do {
      try FileManager.default.removeItem(at: fileURL)
      return true
    } catch {
      #if DEBUG
        print("❌ ローカル画像削除エラー: \(error)")
      #endif
      return false
    }
  }

  // MARK: - Firebase Storage 操作

  // Firebase Storage にアップロード
  private func uploadToFirebaseStorage(
    _ image: UIImage, for walkId: UUID, completion: @escaping (Result<String, Error>) -> Void
  ) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      completion(.failure(ImageStorageError.compressionFailed))
      return
    }

    // Firebase Storage reference
    let storage = Storage.storage()
    let storageRef = storage.reference()
    let thumbnailsRef = storageRef.child("walk_thumbnails/\(walkId.uuidString).jpg")

    // メタデータ設定
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    metadata.customMetadata = [
      "walkId": walkId.uuidString,
      "uploadTime": ISO8601DateFormatter().string(from: Date()),
    ]

    #if DEBUG
      print("📤 Firebase Storage アップロード開始: \(walkId.uuidString)")
    #endif

    // アップロード実行
    thumbnailsRef.putData(imageData, metadata: metadata) { _, error in
      if let error = error {
        #if DEBUG
          print("❌ Firebase Storage アップロードエラー: \(error.localizedDescription)")
        #endif
        completion(.failure(error))
        return
      }

      // ダウンロードURL取得
      thumbnailsRef.downloadURL { url, error in
        if let error = error {
          #if DEBUG
            print("❌ Firebase Storage URL取得エラー: \(error.localizedDescription)")
          #endif
          completion(.failure(error))
          return
        }

        guard let downloadURL = url else {
          completion(.failure(ImageStorageError.uploadFailed))
          return
        }

        #if DEBUG
          print("✅ Firebase Storage アップロード完了: \(downloadURL.absoluteString)")
        #endif
        completion(.success(downloadURL.absoluteString))
      }
    }
  }

  // Firebase Storage からダウンロード
  func downloadFromFirebaseStorage(
    url: String, for walkId: UUID, completion: @escaping (Result<UIImage, Error>) -> Void
  ) {
    guard let downloadURL = URL(string: url) else {
      completion(.failure(ImageStorageError.invalidURL))
      return
    }

    // Firebase Storage URLの基本的な形式をチェック
    guard let host = downloadURL.host,
      host.contains("googleapis.com")
    else {
      #if DEBUG
        print("❌ Invalid Firebase Storage URL: \(url)")
      #endif
      completion(.failure(ImageStorageError.invalidURL))
      return
    }

    #if DEBUG
      print("📥 Firebase Storage ダウンロード開始: \(walkId.uuidString)")
      print("   URL: \(url)")
    #endif

    // Firebase Storage reference
    let storage = Storage.storage()
    let storageRef = storage.reference(forURL: url)

    // 最大ダウンロードサイズを5MBに制限
    let maxSize: Int64 = 5 * 1024 * 1024

    storageRef.getData(maxSize: maxSize) { data, error in
      if let error = error {
        #if DEBUG
          print("❌ Firebase Storage ダウンロードエラー: \(error.localizedDescription)")
        #endif
        completion(.failure(error))
        return
      }

      guard let imageData = data, let image = UIImage(data: imageData) else {
        #if DEBUG
          print("❌ 画像データの変換に失敗")
        #endif
        completion(.failure(ImageStorageError.downloadFailed))
        return
      }

      #if DEBUG
        print("✅ Firebase Storage ダウンロード完了: \(image.size)")
      #endif
      completion(.success(image))
    }
  }
}

// MARK: - マップサムネイル生成機能（統合）
extension WalkManager {

  // 散歩データからサムネイル画像を生成（非同期版）
  private func generateThumbnail(from walk: Walk, completion: @escaping (UIImage?) -> Void) {
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
    let size = CGSize(width: 160, height: 120)  // 4:3のアスペクト比

    let options = MKMapSnapshotter.Options()
    options.region = region
    options.size = size
    options.scale = UIScreen.main.scale  // デバイスに適した解像度
    options.mapType = .standard
    options.showsBuildings = true

    let snapshotter = MKMapSnapshotter(options: options)

    // 非同期でスナップショットを取得
    snapshotter.start { snapshot, error in
      DispatchQueue.main.async {
        guard let snapshot = snapshot else {
          #if DEBUG
            if let error = error {
              print("❌ マップスナップショット生成エラー: \(error.localizedDescription)")
            } else {
              print("❌ マップスナップショットがnilです")
            }
          #endif

          // フォールバック画像を返す
          let fallbackImage = self.generateStaticMapImage(for: walk, size: size)
          completion(fallbackImage)
          return
        }

        // ポリラインを描画したコンテキスト画像を作成
        let finalImage = self.addPolylineToSnapshot(snapshot, walk: walk)
        completion(finalImage)
      }
    }
  }

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
    let baseLatDelta = maxLat - minLat
    let baseLonDelta = maxLon - minLon

    let latDelta: Double
    let lonDelta: Double

    if baseLatDelta < 0.002 || baseLonDelta < 0.002 {
      // 短い距離の場合（200m未満程度）
      latDelta = max(baseLatDelta * 2.5, 0.008)
      lonDelta = max(baseLonDelta * 2.5, 0.008)
    } else if baseLatDelta > 0.02 || baseLonDelta > 0.02 {
      // とても長い距離の場合（2km以上程度）
      latDelta = baseLatDelta * 2.5
      lonDelta = baseLonDelta * 2.5
    } else {
      // 中距離の場合
      latDelta = baseLatDelta * 2.2
      lonDelta = baseLonDelta * 2.2
    }

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

    // ポリラインのスタイル設定
    context?.setStrokeColor(UIColor.systemBlue.cgColor)
    context?.setLineWidth(2.5)
    context?.setLineCap(.round)
    context?.setLineJoin(.round)

    // 影を追加してルートを強調
    context?.setShadow(
      offset: CGSize(width: 0.5, height: 0.5), blur: 1,
      color: UIColor.black.withAlphaComponent(0.2).cgColor)

    // 座標をピクセル座標に変換して線を描画
    let coordinates = walk.locations.map { $0.coordinate }
    for i in 1..<coordinates.count {
      let startPoint = snapshot.point(for: coordinates[i - 1])
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
  private func drawStartEndMarkers(
    on snapshot: MKMapSnapshotter.Snapshot, coordinates: [CLLocationCoordinate2D]
  ) {
    guard let context = UIGraphicsGetCurrentContext(), !coordinates.isEmpty else { return }

    let markerSize: CGFloat = 12.0

    // 影をリセット（マーカー用）
    context.setShadow(offset: CGSize.zero, blur: 0, color: nil)

    // 開始地点（緑色）
    let startPoint = snapshot.point(for: coordinates[0])
    context.setFillColor(UIColor.systemGreen.cgColor)
    context.fillEllipse(
      in: CGRect(
        x: startPoint.x - markerSize / 2,
        y: startPoint.y - markerSize / 2,
        width: markerSize,
        height: markerSize
      ))

    // 終了地点（赤色、開始地点と異なる場合のみ）
    if coordinates.count > 1 {
      let endPoint = snapshot.point(for: coordinates.last!)
      context.setFillColor(UIColor.systemRed.cgColor)
      context.fillEllipse(
        in: CGRect(
          x: endPoint.x - markerSize / 2,
          y: endPoint.y - markerSize / 2,
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
      .backgroundColor: UIColor.systemBackground.withAlphaComponent(0.8),
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

    // マージンを設定
    let baseMargin: CGFloat = 18
    let routeRange = max(latRange, lonRange)
    let marginMultiplier: CGFloat = routeRange > 0.01 ? 1.8 : 1.2

    let margin = baseMargin * marginMultiplier
    let drawableWidth = size.width - (margin * 2)
    let drawableHeight = size.height - (margin * 2)

    // 座標をピクセル座標に変換する関数
    func coordinateToPoint(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
      let x =
        margin + ((coordinate.longitude - minLon) / (lonRange == 0 ? 1 : lonRange)) * drawableWidth
      let y =
        margin + ((maxLat - coordinate.latitude) / (latRange == 0 ? 1 : latRange)) * drawableHeight
      return CGPoint(x: x, y: y)
    }

    // ルートラインを描画
    context.setStrokeColor(UIColor.systemBlue.cgColor)
    context.setLineWidth(2.5)
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
      x: startPoint.x - markerSize / 2,
      y: startPoint.y - markerSize / 2,
      width: markerSize,
      height: markerSize
    )
    context.fillEllipse(in: startMarkerRect)

    // 終了地点（赤色）
    if coordinates.count > 1 {
      let endPoint = coordinateToPoint(coordinates.last!)
      context.setFillColor(UIColor.systemRed.cgColor)
      let endMarkerRect = CGRect(
        x: endPoint.x - markerSize / 2,
        y: endPoint.y - markerSize / 2,
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
    let text = "Map unavailable"
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.secondaryLabel,
      .font: UIFont.systemFont(ofSize: 10, weight: .medium),
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

// MARK: - エラー定義
enum ImageStorageError: Error, LocalizedError {
  case compressionFailed
  case saveFailed
  case loadFailed
  case deleteFailed
  case uploadFailed
  case downloadFailed
  case fileNotFound
  case networkUnavailable
  case authenticationFailed
  case storageLimitExceeded
  case invalidURL

  var errorDescription: String? {
    switch self {
    case .compressionFailed:
      return "Failed to compress image"
    case .saveFailed:
      return "Failed to save image"
    case .loadFailed:
      return "Failed to load image"
    case .deleteFailed:
      return "Failed to delete image"
    case .uploadFailed:
      return "Failed to upload to Firebase Storage"
    case .downloadFailed:
      return "Failed to download from Firebase Storage"
    case .fileNotFound:
      return "File not found"
    case .networkUnavailable:
      return "Network unavailable"
    case .authenticationFailed:
      return "Authentication failed"
    case .storageLimitExceeded:
      return "Storage limit exceeded"
    case .invalidURL:
      return "Invalid URL"
    }
  }
}
