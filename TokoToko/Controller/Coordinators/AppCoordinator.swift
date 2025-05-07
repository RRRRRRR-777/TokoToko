//
//  AppCoordinator.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI
import CoreLocation
import MapKit

// アプリ全体の画面遷移を管理するコーディネーター
class AppCoordinator: ObservableObject, LocationUpdateDelegate {
    @Published var selectedTab: Tab = .home
    @Published var selectedItem: Item? = nil

    // 位置情報マネージャー
    let locationManager = LocationManager.shared
    @Published var currentLocation: CLLocation?
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    enum Tab {
        case home
        case settings
        case map
    }

    init() {
        // 位置情報マネージャーの設定
        locationManager.delegate = self
        locationAuthorizationStatus = locationManager.checkAuthorizationStatus()

        // 位置情報の使用許可をリクエスト
        requestLocationPermission()
    }

    // 位置情報の使用許可をリクエスト
    func requestLocationPermission() {
        // まずは「アプリ使用中のみ」の許可をリクエスト
        locationManager.requestWhenInUseAuthorization()

        // 現在の許可状態を更新
        locationAuthorizationStatus = locationManager.checkAuthorizationStatus()
    }

    // バックグラウンド位置情報の許可をリクエスト
    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    // 位置情報の更新を開始
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    // 位置情報の更新を停止
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }

    // LocationUpdateDelegateプロトコルの実装
    func didUpdateLocation(_ location: CLLocation) {
        currentLocation = location
    }

    func didFailWithError(_ error: Error) {
        print("位置情報の取得に失敗しました: \(error.localizedDescription)")
    }

    // 画面遷移のメソッドを追加できます
    func navigateToHome() {
        selectedTab = .home
    }

    func navigateToSettings() {
        selectedTab = .settings
    }

    func navigateToMap() {
        selectedTab = .map
    }

    func showDetail(for item: Item) {
        selectedItem = item
    }
}
