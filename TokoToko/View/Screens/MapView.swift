//
//  MapView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import MapKit
import SwiftUI
import _MapKit_SwiftUI

struct MapView: View {
  @State private var walks: [Walk] = []
  @State private var isLoading = false
  @State private var showingLocationPermissionAlert = false
  @State private var showingBackgroundPermissionAlert = false
  @State private var region: MKCoordinateRegion

  // 位置情報マネージャー
  private let locationManager = LocationManager.shared
  @State private var currentLocation: CLLocation?
  @State private var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

  // リポジトリ
  private let walkRepository = WalkRepository.shared

  init() {
    // 東京駅をデフォルト位置に
    _region = State(
      initialValue: MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
      ))
  }

  var body: some View {
    VStack {
      // 位置情報の許可状態に応じて表示を切り替え
      switch locationAuthorizationStatus {
      case .notDetermined:
        // まだ許可を求めていない場合
        requestPermissionView

      case .restricted, .denied:
        // 許可が拒否されている場合
        permissionDeniedView

      case .authorizedWhenInUse, .authorizedAlways:
        // 許可されている場合
        MapViewComponent(region: region, annotations: createAnnotationsFromWalks())
          .edgesIgnoringSafeArea(.all)

      @unknown default:
        Text("位置情報の許可状態が不明です")
      }
    }
    .navigationTitle("マップ")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: {
          showingBackgroundPermissionAlert = true
        }) {
          Image(systemName: "location.fill")
        }
        .alert("バックグラウンド位置情報", isPresented: $showingBackgroundPermissionAlert) {
          Button("許可する") {
            locationManager.requestAlwaysAuthorization()
          }
          Button("キャンセル", role: .cancel) {}
        } message: {
          Text("バックグラウンドでも位置情報を取得するために許可が必要です。")
        }
      }
    }
    .onAppear {
      loadWalks()
      setupLocationManager()
    }
    .loadingOverlay(isLoading: isLoading)
  }

  // 記録の読み込み
  private func loadWalks() {
    isLoading = true
    walkRepository.fetchWalks { result in
      isLoading = false
      switch result {
      case .success(let fetchedWalks):
        self.walks = fetchedWalks
      case .failure(let error):
        print("Error loading walks: \(error)")
      // エラー処理をここに追加
      }
    }
  }

  // 位置情報マネージャーの設定
  private func setupLocationManager() {
    // 位置情報の許可状態を確認
    locationAuthorizationStatus = locationManager.checkAuthorizationStatus()
    currentLocation = locationManager.currentLocation

    // 許可されている場合は位置情報の更新を開始
    if locationAuthorizationStatus == .authorizedWhenInUse
      || locationAuthorizationStatus == .authorizedAlways {
      locationManager.startUpdatingLocation()

      // 現在位置が取得できている場合は、その位置にマップを移動
      if let location = locationManager.currentLocation {
        region = locationManager.region(for: location)
      }
    }
  }

  // 記録からマップアノテーションを作成
  private func createAnnotationsFromWalks() -> [MapItem] {
    walks.compactMap { walk -> MapItem? in
      guard let location = walk.location else {
        return nil
      }
      return MapItem(
        coordinate: location,
        title: walk.title,
        imageName: "mappin.circle.fill",
        id: walk.id
      )
    }
  }

  // 位置情報の許可を求めるビュー
  private var requestPermissionView: some View {
    VStack(spacing: 20) {
      Image(systemName: "location.circle")
        .font(.system(size: 100))
        .foregroundColor(.blue)

      Text("位置情報の使用許可が必要です")
        .font(.title)

      Text("このアプリはあなたの現在地を表示するために位置情報を使用します。")
        .multilineTextAlignment(.center)
        .padding()

      Button("位置情報を許可する") {
        locationManager.requestWhenInUseAuthorization()
      }
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(10)
    }
    .padding()
  }

  // 位置情報の許可が拒否された場合のビュー
  private var permissionDeniedView: some View {
    VStack(spacing: 20) {
      Image(systemName: "location.slash")
        .font(.system(size: 100))
        .foregroundColor(.red)

      Text("位置情報へのアクセスが拒否されています")
        .font(.title)

      Text("このアプリを使用するには、設定アプリから位置情報へのアクセスを許可してください。")
        .multilineTextAlignment(.center)
        .padding()

      Button("設定を開く") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(10)
    }
    .padding()
  }
}



#Preview {
  NavigationView {
    MapView()
  }
}
