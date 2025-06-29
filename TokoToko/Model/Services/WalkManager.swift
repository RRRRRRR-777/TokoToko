//
//  WalkManager.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import Combine
import CoreLocation
import FirebaseAuth
import Foundation

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
  
  // サムネイル生成関連
  private let mapThumbnailGenerator = MapThumbnailGenerator()
  private let imageStorageManager = ImageStorageManager.shared

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
  func startWalk(title: String = "", description: String = "") {
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
    }

    currentWalk = newWalk
    elapsedTime = 0
    distance = 0

    // 位置情報の更新を開始
    locationManager.startUpdatingLocation()

    // タイマーを開始
    startTimer()

    print("散歩を開始しました: \(finalTitle)")
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

    // サムネイル画像を生成して保存
    generateAndSaveThumbnail(for: walk)

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

  // デフォルトの散歩タイトルを生成
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
  private func generateAndSaveThumbnail(for walk: Walk) {
    // 🔵 Refactor - 非同期でサムネイル画像を生成
    
    print("📸 サムネイル画像の生成を開始しました")
    
    // 非同期でサムネイル画像を生成
    mapThumbnailGenerator.generateThumbnail(from: walk) { [weak self] thumbnailImage in
      guard let self = self, let thumbnailImage = thumbnailImage else {
        print("⚠️ サムネイル画像の生成に失敗しました")
        return
      }
      
      #if DEBUG
      print("✅ サムネイル画像生成完了: \(thumbnailImage.size)")
      #endif
      
      // ローカルに保存
      let localSaveSuccess = self.imageStorageManager.saveImageLocally(thumbnailImage, for: walk.id)
      if !localSaveSuccess {
        print("⚠️ サムネイル画像のローカル保存に失敗しました")
        return
      }
      
      #if DEBUG
      print("✅ ローカル保存完了")
      #endif
      
      // Firebase Storageにアップロード（非同期）
      self.imageStorageManager.uploadToFirebaseStorage(thumbnailImage, for: walk.id) { result in
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
extension WalkManager: LocationUpdateDelegate {
  func didUpdateLocation(_ location: CLLocation) {
    // 位置情報の更新は$currentLocationの監視で処理
  }

  func didFailWithError(_ error: Error) {
    print("位置情報の取得に失敗しました: \(error.localizedDescription)")
  }
}
