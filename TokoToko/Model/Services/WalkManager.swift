//
//  WalkManager.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import Combine
import CoreLocation
import Foundation
import FirebaseAuth

class WalkManager: NSObject, ObservableObject {
  // シングルトンインスタンス
  static let shared = WalkManager()

  // 現在の散歩
  @Published var currentWalk: Walk?
  @Published var elapsedTime: TimeInterval = 0
  @Published var distance: Double = 0
  @Published var currentLocation: CLLocation?

  // 散歩中かどうか（一時停止中も含む）
  var isWalking: Bool {
    currentWalk?.status == .inProgress || currentWalk?.status == .paused
  }

  // 実際に記録中かどうか（一時停止中は含まない）
  var isRecording: Bool {
    currentWalk?.status == .inProgress
  }

  // 散歩開始待機中のパラメータ（権限要求中に使用）
  private var pendingWalkTitle: String?
  private var pendingWalkDescription: String?

  // 位置情報マネージャー
  private let locationManager = LocationManager.shared
  private let walkRepository = WalkRepository.shared

  // タイマー
  private var timer: Timer?
  private var cancellables = Set<AnyCancellable>()

  override private init() {
    super.init()
    setupLocationManager()
  }

  deinit {
    cancellables.removeAll()
    timer?.invalidate()
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

  // 散歩を開始
  func startWalk(title: String = "新しい散歩", description: String = "") {
    guard !isWalking else { return }

    // 認証されたユーザーIDを取得
    guard let userId = Auth.auth().currentUser?.uid else {
      print("エラー: ユーザーが認証されていません")
      return
    }

    // バックグラウンドでの位置情報追跡のため、常時権限を要求
    let authStatus = locationManager.checkAuthorizationStatus()
    if authStatus != .authorizedAlways {
      print("バックグラウンド位置情報のため常時権限を要求します")
      // 散歩開始パラメータを保存
      pendingWalkTitle = title
      pendingWalkDescription = description
      locationManager.requestAlwaysAuthorization()
      return  // 権限が許可されてから再度呼び出される
    }

    // 新しい散歩を作成
    var newWalk = Walk(
      title: title,
      description: description,
      userId: userId,
      status: .inProgress
    )
    newWalk.start()

    // 現在位置を開始地点として追加
    if let location = currentLocation {
      newWalk.addLocation(location)
    }

    currentWalk = newWalk
    elapsedTime = 0
    distance = 0

    // 位置情報の更新を開始
    locationManager.startUpdatingLocation()

    // タイマーを開始
    startTimer()

    print("散歩を開始しました: \(title)")
  }

  // 散歩を一時停止
  func pauseWalk() {
    guard isRecording, var walk = currentWalk else { return }

    walk.pause()
    currentWalk = walk

    // タイマーを停止
    stopTimer()

    // 位置情報の更新を停止
    locationManager.stopUpdatingLocation()

    print("散歩を一時停止しました")
  }

  // 散歩を再開
  func resumeWalk() {
    guard !isRecording, var walk = currentWalk, walk.status == .paused else { return }

    walk.resume()
    currentWalk = walk

    // 位置情報の更新を再開
    locationManager.startUpdatingLocation()

    // タイマーを再開
    startTimer()

    print("散歩を再開しました")
  }

  // 散歩を終了
  func stopWalk() {
    guard var walk = currentWalk else { return }

    walk.complete()
    currentWalk = walk

    // タイマーを停止
    stopTimer()

    // 位置情報の更新を停止
    locationManager.stopUpdatingLocation()

    // 散歩をリポジトリに保存
    saveCurrentWalk()

    print("散歩を終了しました。距離: \(walk.distanceString), 時間: \(walk.durationString)")
  }

  // 散歩をキャンセル
  func cancelWalk() {
    currentWalk = nil
    elapsedTime = 0
    distance = 0

    // タイマーを停止
    stopTimer()

    // 位置情報の更新を停止
    locationManager.stopUpdatingLocation()

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
  }

  // 経過時間を文字列で取得
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

  // 歩数の取得
  var totalSteps: Int {

    // 仮の実装。実際には歩数計APIやセンサーから取得する必要があります。
    Int(elapsedTime / 2)  // 1秒あたり0.5歩と仮定
  }

  // 距離を文字列で取得
  var distanceString: String {
    if distance >= 1000 {
      return String(format: "%.2f km", distance / 1000)
    } else {
      return String(format: "%.0f m", distance)
    }
  }

  // 位置情報権限の変更を処理
  private func handleAuthorizationStatusChange(_ status: CLAuthorizationStatus) {
    switch status {
    case .authorizedAlways:
      // 常時権限が許可された場合、待機中の散歩があれば開始
      if let title = pendingWalkTitle, let description = pendingWalkDescription {
        print("常時権限が許可されました。散歩を開始します。")
        pendingWalkTitle = nil
        pendingWalkDescription = nil
        startWalk(title: title, description: description)
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
}

// MARK: - LocationUpdateDelegate
extension WalkManager: LocationUpdateDelegate {
  func didUpdateLocation(_ location: CLLocation) {
    // 位置情報の更新は$currentLocationの監視で処理
  }

  func didFailWithError(_ error: Error) {
    print("位置情報の取得に失敗しました: \(error.localizedDescription)")
  }
}
