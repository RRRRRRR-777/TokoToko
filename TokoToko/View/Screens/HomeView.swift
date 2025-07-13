//
//  HomeView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import CoreMotion
import MapKit
import SwiftUI

struct HomeView: View {
  @StateObject private var walkManager = WalkManager.shared
  @State private var isLoading = false
  @State private var region: MKCoordinateRegion

  // 位置情報マネージャー
  @StateObject private var locationManager = LocationManager.shared
  @State private var currentLocation: CLLocation?

  init() {
    // 東京駅をデフォルト位置に
    _region = State(
      initialValue: MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      ))
  }

  var body: some View {
    ZStack {
      mapSection
        .ignoresSafeArea(.all, edges: .all)

      // 散歩中の情報表示パネル
      if walkManager.isWalking {
        VStack {
          Spacer()
          VStack(spacing: 0) {
            // 散歩中の情報表示
            WalkInfoDisplay(
              elapsedTime: walkManager.elapsedTimeString,
              totalSteps: walkManager.totalSteps,
              distance: walkManager.distanceString,
              stepCountSource: walkManager.currentStepCount
            )
            .padding()
            .background(Color.white.opacity(0.95))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)

            // 一時停止中の再開ボタン
            if walkManager.currentWalk?.status == .paused {
              Button(action: {
                walkManager.resumeWalk()
              }) {
                HStack {
                  Image(systemName: "play.fill")
                    .font(.body)
                  Text("再開")
                    .font(.body)
                    .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255),
                      Color(red: 22 / 255, green: 163 / 255, blue: 74 / 255),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(
                  color: Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255).opacity(0.3),
                  radius: 4, x: 0, y: 2)
              }
              .padding(.top, 8)
              .padding(.horizontal)
              .accessibilityIdentifier("散歩再開ボタン")
            }
          }
          .padding(.bottom, getSafeAreaInsets().bottom + 30)
          .padding(.horizontal, 10)
        }
      }

      // 右下固定のコントロールボタン（常に表示）
      VStack {
        Spacer()
        HStack {
          Spacer()
          VStack(spacing: 16) {
            // 新しい詳細画面テスト用ボタン(削除予定)
            NavigationLink(destination: createTestDetailView()) {
              Text("新UI確認")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(20)
                .shadow(radius: 3)
            }

            WalkControlPanel(walkManager: walkManager, isFloating: true)
          }
          .padding(.trailing, 20)
        }
      }
    }
    .navigationBarHidden(true)
    .ignoresSafeArea(.all, edges: .top)
    .onAppear {
      setupLocationManager()
    }
    .onChange(of: locationManager.authorizationStatus) { status in
      print("位置情報許可状態が変更されました: \(status)")
      setupLocationManager()
    }
    .onChange(of: locationManager.currentLocation) { location in
      if let location = location {
        currentLocation = location
        region = locationManager.region(for: location)
      }
    }
    .loadingOverlay(isLoading: isLoading)
  }

  // テスト用の詳細画面を作成(削除予定)
  private func createTestDetailView() -> some View {
    let testWalks = [
      Walk(
        title: "朝の散歩",
        description: "公園を歩きました",
        id: UUID(),
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 1200,
        totalSteps: 1500,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6812, longitude: 139.7671),
          CLLocation(latitude: 35.6815, longitude: 139.7675),
          CLLocation(latitude: 35.6818, longitude: 139.7680),
        ]
      ),
      Walk(
        title: "夕方の散歩",
        description: "川沿いを歩きました",
        id: UUID(),
        startTime: Date().addingTimeInterval(-7200),
        endTime: Date().addingTimeInterval(-6600),
        totalDistance: 800,
        totalSteps: 1000,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6820, longitude: 139.7680),
          CLLocation(latitude: 35.6825, longitude: 139.7685),
          CLLocation(latitude: 35.6828, longitude: 139.7688),
        ]
      ),
    ]

    return WalkHistoryDetailView(walks: testWalks, initialIndex: 0)
  }

  // マップセクション
  private var mapSection: some View {
    ZStack {
      // 位置情報の許可状態に応じて表示を切り替え
      switch locationManager.authorizationStatus {
      case .notDetermined:
        requestPermissionView

      case .restricted, .denied:
        permissionDeniedView

      case .authorizedWhenInUse, .authorizedAlways:
        MapViewComponent(
          region: $region,
          annotations: createMapAnnotations(),
          polylineCoordinates: createPolylineCoordinates()
        )

      @unknown default:
        Text("位置情報の許可状態が不明です")
          .foregroundColor(.secondary)
      }

      // 散歩中のオーバーレイ
      if walkManager.isWalking {
        VStack {
          Spacer()
          HStack {
            Spacer()
            walkingIndicator
              .padding()
          }
        }
      }
    }
    .background(Color(.systemGray6))
  }

  // 散歩中インジケーター
  private var walkingIndicator: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(walkManager.currentWalk?.status == .paused ? Color.orange : Color.red)
        .frame(width: 8, height: 8)
        .scaleEffect(
          walkManager.currentWalk?.status == .paused ? 1.0 : (walkManager.isWalking ? 1.0 : 0.5)
        )
        .animation(
          walkManager.currentWalk?.status == .paused
            ? .none : .easeInOut(duration: 1.0).repeatForever(),
          value: walkManager.isWalking
        )

      Text(walkManager.currentWalk?.status == .paused ? "一時停止中" : "記録中")
        .font(.caption)
        .fontWeight(.medium)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(Color.white.opacity(0.9))
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
  }

  // 位置情報の許可を求めるビュー
  private var requestPermissionView: some View {
    VStack(spacing: 16) {
      Image(systemName: "location.circle")
        .font(.system(size: 60))
        .foregroundColor(.blue)

      VStack(spacing: 8) {
        Text("位置情報の使用許可が必要です")
          .font(.headline)

        Text("現在地を表示し、散歩ルートを記録するために位置情報を使用します。")
          .font(.caption)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      }

      Button("位置情報を許可する") {
        locationManager.requestWhenInUseAuthorization()
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 8)
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(8)
    }
    .padding()
  }

  // 位置情報の許可が拒否された場合のビュー
  private var permissionDeniedView: some View {
    VStack(spacing: 16) {
      Image(systemName: "location.slash")
        .font(.system(size: 60))
        .foregroundColor(.red)

      VStack(spacing: 8) {
        Text("位置情報へのアクセスが拒否されています")
          .font(.headline)

        Text("設定アプリから位置情報へのアクセスを許可してください。")
          .font(.caption)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      }

      Button("設定を開く") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 8)
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(8)
    }
    .padding()
  }

  // 位置情報マネージャーの設定
  private func setupLocationManager() {
    currentLocation = locationManager.currentLocation

    if locationManager.authorizationStatus == .authorizedWhenInUse
      || locationManager.authorizationStatus == .authorizedAlways
    {
      locationManager.startUpdatingLocation()

      if let location = locationManager.currentLocation {
        region = locationManager.region(for: location)
      }
    }
  }

  // セーフエリアのインセットを取得
  private func getSafeAreaInsets() -> UIEdgeInsets {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    else {
      return UIEdgeInsets()
    }
    return window.safeAreaInsets
  }

  // マップアノテーションを作成（開始・終了ポイントのみ）
  private func createMapAnnotations() -> [MapItem] {
    var annotations: [MapItem] = []

    // 現在の散歩の開始・終了地点のみ表示
    if let currentWalk = walkManager.currentWalk, !currentWalk.locations.isEmpty {
      let locations = currentWalk.locations

      // 開始地点
      if let startLocation = locations.first {
        annotations.append(
          MapItem(
            coordinate: startLocation.coordinate,
            title: "開始地点",
            imageName: "play.circle.fill",
            id: UUID()
          )
        )
      }

      // 終了地点（完了した散歩の場合のみ）
      if let endLocation = locations.last, locations.count > 1, currentWalk.status == .completed {
        annotations.append(
          MapItem(
            coordinate: endLocation.coordinate,
            title: "終了地点",
            imageName: "checkmark.circle.fill",
            id: UUID()
          )
        )
      }
    }

    return annotations
  }

  // ポリライン座標を作成
  private func createPolylineCoordinates() -> [CLLocationCoordinate2D] {
    guard let currentWalk = walkManager.currentWalk, !currentWalk.locations.isEmpty else {
      return []
    }

    return currentWalk.locations.map { $0.coordinate }
  }
}

// 角の丸めを指定するための拡張
extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

#Preview {
  MainTabView()
    .environmentObject(AuthManager())
}
