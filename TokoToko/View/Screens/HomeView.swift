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

/// TokoTokoアプリのメイン画面を表示するSwiftUIビュー
///
/// `HomeView`は散歩アプリケーションの中核となる画面で、以下の主要機能を提供します：
/// - インタラクティブなマップ表示と現在位置の追跡
/// - 散歩の開始・一時停止・再開・終了のコントロール
/// - リアルタイムの散歩統計情報表示（時間、距離、歩数）
/// - 散歩履歴へのナビゲーション
/// - 設定画面への遷移
///
/// ## Overview
///
/// このビューは全画面マップをベースレイヤーとし、その上にオーバーレイ形式で
/// 各種コントロールと情報表示パネルを配置する構成となっています。
/// 位置情報の取得とマップの表示は`LocationManager`と`WalkManager`により管理されます。
///
/// ## Topics
///
/// ### Properties
/// - ``walkManager``
/// - ``locationManager``
/// - ``isLoading``
/// - ``region``
/// - ``currentLocation``
///
/// ### Initialization
/// - ``init()``
struct HomeView: View {
  /// オンボーディングモーダルの表示状態
  ///
  /// MainTabViewから渡されるバインディングで、オンボーディングの表示/非表示を制御します。
  @Binding var showOnboarding: Bool
  
  /// オンボーディングマネージャー
  ///
  /// オンボーディングコンテンツの管理と表示状態の制御を行います。
  @EnvironmentObject var onboardingManager: OnboardingManager
  
  /// 散歩管理の中央コントローラー
  ///
  /// 散歩の開始・停止、統計情報の管理、位置情報の記録を担当するシングルトンインスタンスです。
  /// @StateObjectにより、このビューのライフサイクル全体で状態が管理されます。
  @StateObject private var walkManager = WalkManager.shared

  /// ローディング状態を管理するフラグ
  ///
  /// 非同期処理（位置情報取得、散歩開始処理等）の実行中に表示するローディングインジケーターの制御に使用されます。
  @State private var isLoading = false

  /// マップ表示領域の座標範囲
  ///
  /// 表示するマップの中心座標とズームレベルを定義します。
  /// 初期値は東京駅周辺に設定され、位置情報取得後は現在位置中心に更新されます。
  @State private var region: MKCoordinateRegion

  /// GPS位置情報の取得と管理を行うマネージャー
  ///
  /// CoreLocationをラップしたカスタムマネージャーで、位置情報の取得、権限管理、
  /// バックグラウンド追跡を統合的に管理します。
  @StateObject private var locationManager = LocationManager.shared

  /// 現在取得している位置情報
  ///
  /// 最新のGPS位置情報を保持し、マップの中心位置調整や散歩開始地点の記録に使用されます。
  @State private var currentLocation: CLLocation?

  /// 位置情報許可状態チェック完了フラグ
  ///
  /// Issue #99対応: 位置情報許可状態の事前チェック完了を示すフラグです。
  /// true: 許可状態チェック完了、適切な画面表示可能
  /// false: 許可状態チェック中、画面表示待機
  @State private var isLocationPermissionCheckCompleted = false

  /// HomeViewの初期化メソッド
  ///
  /// オンボーディング表示状態のバインディングを受け取り、
  /// マップ表示領域の初期値を東京駅周辺に設定します。
  /// 実際のアプリ使用時は、位置情報取得後に現在位置に更新されます。
  ///
  /// - Parameter showOnboarding: オンボーディング表示状態のバインディング
  ///
  /// ## Default Location
  /// - 中心座標: 東京駅（35.6812, 139.7671）
  /// - ズームレベル: 0.01度（約1km四方の表示範囲）
  init(showOnboarding: Binding<Bool>) {
    self._showOnboarding = showOnboarding
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
                      Color(red: 22 / 255, green: 163 / 255, blue: 74 / 255)
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
            WalkControlPanel(walkManager: walkManager, isFloating: true)
          }
          .padding(.trailing, 20)
        }
      }
    }
    .accessibilityIdentifier("HomeView")
    .navigationBarHidden(true)
    .ignoresSafeArea(.all, edges: .top)
    .onAppear {
      // Issue #99対応: 位置情報許可状態を事前にチェック（フラッシュ防止）
      checkLocationPermissionStatus()
      
      // UIテスト時のオンボーディング表示制御
      // testInitialStateWhenLoggedInのようなテストでは--show-onboardingが指定されていない
      if ProcessInfo.processInfo.arguments.contains("--show-onboarding") {
        #if DEBUG
        print("HomeView: --show-onboarding 引数が検出されました")
        #endif
        DispatchQueue.main.async {
          #if DEBUG
          print("HomeView: オンボーディング表示を true に設定")
          #endif
          self.showOnboarding = true
        }
      }
    }
    .onChange(of: locationManager.authorizationStatus) { status in
      #if DEBUG
      print("位置情報許可状態が変更されました: \(status)")
      #endif
      setupLocationManager()
      
      // UIテスト時以外は位置情報許可が決定された後にオンボーディングを表示
      if !ProcessInfo.processInfo.arguments.contains("--uitesting") {
        handleLocationPermissionChange(status)
      }
    }
    .onChange(of: locationManager.currentLocation) { location in
      if let location = location {
        currentLocation = location
        region = locationManager.region(for: location)
      }
    }
    .loadingOverlay(isLoading: isLoading)
    .overlay(
      // オンボーディングモーダルを背景透明でオーバーレイ表示
      Group {
        if showOnboarding, let content = onboardingManager.currentContent {
          OnboardingModalView(
            content: content,
            isPresented: $showOnboarding,
            onDismiss: {
              onboardingManager.markOnboardingAsShown(for: .firstLaunch)
            }
          )
          .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        }
      }
    )
  }

  // マップセクション
  private var mapSection: some View {
    ZStack {
      // UIテスト時は位置情報許可に関係なくマップビューを表示
      if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        MapViewComponent(
          region: $region,
          annotations: createMapAnnotations(),
          polylineCoordinates: createPolylineCoordinates()
        )
        .accessibilityIdentifier("TestMapView")
        .onAppear {
          #if DEBUG
          print("UIテストモード: MapViewComponentを表示しています")
          #endif
        }
      } else {
        // Issue #99対応: 位置情報許可状態チェック完了後に適切な画面表示
        if isLocationPermissionCheckCompleted {
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
        } else {
          // 許可状態確認中は空のビューを表示（フラッシュ防止）
          EmptyView()
        }
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
      || locationManager.authorizationStatus == .authorizedAlways {
      locationManager.startUpdatingLocation()

      if let location = locationManager.currentLocation {
        region = locationManager.region(for: location)
      }
    }
  }

  /// 位置情報許可状態の変更を処理し、オンボーディング表示を制御
  ///
  /// 位置情報の許可または拒否が決定された際に、初回起動時のオンボーディングを表示します。
  /// 許可/拒否どちらの場合でもオンボーディングを表示することで、アプリの使い方を案内します。
  ///
  /// - Parameter status: 変更後の位置情報許可状態
  private func handleLocationPermissionChange(_ status: CLAuthorizationStatus) {
    // 初回起動時のオンボーディングが必要な場合のみ処理
    guard onboardingManager.shouldShowOnboarding(for: .firstLaunch) else {
      return
    }
    
    switch status {
    case .authorizedWhenInUse, .authorizedAlways, .denied, .restricted:
      // 位置情報の許可/拒否が決定されたらオンボーディングを表示
      DispatchQueue.main.async {
        self.showOnboarding = true
      }
    case .notDetermined:
      // まだ決定されていない場合は何もしない
      break
    @unknown default:
      // 新しい許可状態に対しても安全にオンボーディングを表示
      DispatchQueue.main.async {
        self.showOnboarding = true
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

  /// 位置情報許可状態を事前にチェックする
  ///
  /// Issue #99対応: 位置情報許可画面のフラッシュ現象を防止するため、
  /// 画面表示前に許可状態を確認し、適切な表示を行います。
  /// フラッシュ防止のため、処理時間は50ms以内を目標とします。
  private func checkLocationPermissionStatus() {
    // 許可状態を即座に確認（同期的処理）
    let status = locationManager.checkAuthorizationStatus()
    
    // メイン スレッドで状態更新（UIの即座更新）
    DispatchQueue.main.async {
      self.isLocationPermissionCheckCompleted = true
      
      // 許可済みの場合は位置情報マネージャーをセットアップ
      if status == .authorizedWhenInUse || status == .authorizedAlways {
        self.setupLocationManager()
      }
    }
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
  HomeView(showOnboarding: .constant(false))
    .environmentObject(OnboardingManager())
}
