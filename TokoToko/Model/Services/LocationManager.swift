//
//  LocationManager.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import Foundation
import CoreLocation
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

    // 初期化
    private override init() {
        super.init()
        setupLocationManager()
    }

    // 位置情報マネージャーの設定
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10メートル移動したら更新
        locationManager.pausesLocationUpdatesAutomatically = false // 自動停止を無効化
        // バックグラウンド更新の設定は権限取得後に行う
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
        locationManager.startUpdatingLocation()
    }

    // 位置情報の更新を停止
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // 位置情報の許可状態を確認
    func checkAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    // 指定された座標を中心とするマップ領域を作成
    func region(for location: CLLocation, latitudinalMeters: CLLocationDistance = 1000, longitudinalMeters: CLLocationDistance = 1000) -> MKCoordinateRegion {
        return MKCoordinateRegion(
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
        delegate?.didUpdateLocation(location)
    }

    // エラー発生時に呼ばれる
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置情報の取得に失敗しました: \(error.localizedDescription)")
        delegate?.didFailWithError(error)
    }

    // 位置情報の許可状態が変更された時に呼ばれる
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            // 使用中のみ許可された場合は位置情報の更新を開始
            startUpdatingLocation()
            // バックグラウンド更新は無効
            locationManager.allowsBackgroundLocationUpdates = false
        case .authorizedAlways:
            // 常に許可された場合は位置情報の更新を開始し、バックグラウンド更新を有効化
            startUpdatingLocation()
            locationManager.allowsBackgroundLocationUpdates = true
        case .denied, .restricted:
            // 拒否された場合はエラーメッセージを表示
            print("位置情報の使用が拒否されました。設定アプリから許可してください。")
        case .notDetermined:
            // まだ決定されていない場合は何もしない
            break
        @unknown default:
            break
        }
    }
}
