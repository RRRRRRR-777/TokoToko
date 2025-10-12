//
//  HomeView.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import CoreMotion
import MapKit
import SwiftUI
import UIKit

#if canImport(FoundationModels)
  import FoundationModels
#endif

/// TekuTokoアプリのメイン画面を表示するSwiftUIビュー
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

  /// ルート提案エラー表示用のメッセージ
  @State private var routeSuggestionErrorMessage: String?

  /// Apple Intelligence利用可否フラグ
  ///
  /// 端末がApple Intelligence（Foundation Models）をサポートしているかを示します。
  /// iOS 26.0以降でSystemLanguageModelの利用可否をチェックして設定されます。
  @State private var isAppleIntelligenceAvailable = false

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

  /// アニメーション制御フラグ
  ///
  /// repeatForeverアニメーションのライフサイクル管理用
  /// ビューの表示状態に応じてアニメーションを適切に制御します
  @State private var shouldAnimateRecording = false
  @State private var shouldAnimateUnknownState = false

  /// パフォーマンス最適化用のプロパティ
  ///
  /// 計算コストの高い要素をキャッシュし、不要な再描画を防止します。
  private var optimizedProgressViewStyle: CircularProgressViewStyle {
    CircularProgressViewStyle(tint: Color(red: 0.2, green: 0.7, blue: 0.9))
  }

  /// セーフエリア下端に応じたボトムパディング量を算出
  ///
  /// セーフエリア下端が 0 の場合は物理ホームボタン端末とみなして 90pt、
  /// それ以外はホームインジケータ端末として 60pt を返します。
  private var bottomPadding: CGFloat {
    let bottomInset = getSafeAreaInsets().bottom
    if bottomInset > 0 {
      return 60
    }

    // セーフエリア情報が取得できない初期表示などでは画面高さでフォールバック
    return UIScreen.main.bounds.height > 667 ? 60 : 90
  }

  /// 画面幅に応じた横方向の余白を算出
  ///
  /// 端末サイズごとに見た目のバランスが崩れないよう、画面幅の一定割合と最小値を組み合わせる。
  private var horizontalPadding: CGFloat {
    let base = UIScreen.main.bounds.width * 0.06
    return max(20, base)
  }

  // MARK: - タイミング制御定数

  /// UIアニメーション関連の定数
  private enum AnimationTiming {
    /// 初期状態変更アニメーションの時間
    static let initialStateChange: Double = 0.12
    /// 完了状態アニメーションの時間
    static let completionStateChange: Double = 0.2
    /// UIレンダリング完了保証のための最小遅延
    static let uiRenderingDelay: Double = 0.001
  }

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
          .padding(.horizontal, horizontalPadding)
          .padding(.bottom, bottomPadding)
        }
      }

      // 右下固定の散歩提案ボタン（iOS 26.0以降かつApple Intelligence利用可能な端末のみ表示）
      if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        VStack {
          Spacer()
          HStack {
            Spacer()
            routeSuggestionButton
              .padding(.trailing, 20)
              .padding(.bottom, bottomPadding)
          }
        }
      } else if #available(iOS 26.0, *), isAppleIntelligenceAvailable {
        VStack {
          Spacer()
          HStack {
            Spacer()
            routeSuggestionButton
              .padding(.trailing, 20)
              .padding(.bottom, bottomPadding)
          }
        }
      }
    }
    .accessibilityIdentifier("HomeView")
    .navigationBarHidden(true)
    .ignoresSafeArea(.all, edges: .top)
    .onAppear {
      // Issue #99対応: 位置情報許可状態を事前にチェック（フラッシュ防止）
      #if DEBUG
        print("HomeView onAppear - 位置情報許可状態チェック開始")
      #endif
      checkLocationPermissionStatus()

      // アニメーション制御の初期化
      initializeAnimationStates()

      // Apple Intelligence利用可否チェック
      checkAppleIntelligenceAvailability()

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
    .onDisappear {
      // アニメーション停止でメモリリーク防止
      stopAllAnimations()
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
    .onChange(of: walkManager.isWalking) { isWalking in
      // 散歩状態の変更に応じてアニメーション状態を同期
      updateRecordingAnimationState()

      #if DEBUG
        print("散歩状態変更: \(isWalking)")
        print("  - アニメーション状態: \(shouldAnimateRecording)")
      #endif
    }
    .loadingOverlay(isLoading: isLoading)
    .alert(
      "散歩ルート提案エラー",
      isPresented: Binding(
        get: { routeSuggestionErrorMessage != nil },
        set: { if !$0 { routeSuggestionErrorMessage = nil } }
      ),
      actions: {
        Button("閉じる", role: .cancel) {
          routeSuggestionErrorMessage = nil
        }
      },
      message: {
        Text(routeSuggestionErrorMessage ?? "")
      }
    )
    .overlay(
      // オンボーディングモーダルを背景透明でオーバーレイ表示
      Group {
        if showOnboarding, let content = onboardingManager.currentContent {
          OnboardingModalView(
            content: content,
            isPresented: $showOnboarding
          ) {
            onboardingManager.markOnboardingAsShown(for: .firstLaunch)
          }
          .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        }
      }
    )
  }

  // 散歩提案ボタン
  private var routeSuggestionButton: some View {
    Button(action: {
      handleSuggestionButtonTapped()
    }) {
      Image(systemName: "sparkles")
        .font(.system(size: 24, weight: .medium))
        .foregroundColor(.white)
        .frame(width: 60, height: 60)
        .background(
          LinearGradient(
            gradient: Gradient(colors: [
              Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255),
              Color(red: 138 / 255, green: 55 / 255, blue: 217 / 255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .clipShape(Circle())
        .shadow(color: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255).opacity(0.4), radius: 8, x: 0, y: 4)
    }
    .accessibilityIdentifier("RouteSuggestionButton")
    .accessibilityLabel("散歩ルートを提案")
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
          // 位置情報の許可状態に応じて表示を切り替え（使用頻度順に最適化）
          switch locationManager.authorizationStatus {
          case .authorizedWhenInUse, .authorizedAlways:
            // 最も一般的なケース: 位置情報許可済み
            MapViewComponent(
              region: $region,
              annotations: createMapAnnotations(),
              polylineCoordinates: createPolylineCoordinates()
            )
            .transition(.opacity.animation(.easeInOut(duration: 0.2)))

          case .notDetermined:
            // 初回起動時: 許可要求画面
            requestPermissionView
              .transition(.opacity.animation(.easeInOut(duration: 0.2)))

          case .restricted, .denied:
            // 許可拒否済み: 設定案内画面
            permissionDeniedView
              .transition(.opacity.animation(.easeInOut(duration: 0.2)))

          @unknown default:
            // 未知の状態: エラー表示（将来のiOS対応）
            unknownPermissionStateView
              .transition(.opacity.animation(.easeInOut(duration: 0.2)))
          }
        } else {
          // 許可状態確認中: 改善されたローディング表示（フラッシュ防止）
          loadingPermissionCheckView
            .transition(.opacity.animation(.easeInOut(duration: 0.1)))
        }
      }

      // 散歩中のオーバーレイ
      if walkManager.isWalking {
        VStack {
          Spacer()
          HStack {
            Spacer()
          }
        }
      }
    }
    .background(Color(.systemGray6))
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

      Button("続ける") {
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

  /// 位置情報許可状態確認中のローディング表示
  ///
  /// Issue #99対応: フラッシュ防止のための専用ローディング画面（SplashView表示）
  @ViewBuilder private var loadingPermissionCheckView: some View {
    LoadingView(message: "マップを読み込み中...")
  }

  /// 未知の位置情報許可状態表示
  ///
  /// 将来のiOSバージョンでの新しい許可状態に対応
  @ViewBuilder private var unknownPermissionStateView: some View {
    VStack(spacing: 24) {
      // アニメーション付きエラーアイコン
      Image(systemName: "questionmark.circle.fill")
        .font(.system(size: 60, weight: .medium))
        .foregroundStyle(
          LinearGradient(
            colors: [.orange, .yellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .scaleEffect(shouldAnimateUnknownState ? 0.95 : 1.05)
        .animation(
          shouldAnimateUnknownState
            ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .none,
          value: shouldAnimateUnknownState
        )

      VStack(spacing: 12) {
        Text("位置情報の許可状態が不明です")
          .font(.system(.title2, design: .rounded))
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
          .foregroundColor(.primary)

        Text("アプリを再起動するか、設定で位置情報を確認してください。")
          .font(.system(.body, design: .rounded))
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal, 8)
      }

      // 改善されたボタンデザインとレイアウト
      VStack(spacing: 12) {
        createActionButton(
          title: "設定を開く",
          icon: "gearshape.fill",
          backgroundColor: .orange
        ) {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        }

        createActionButton(
          title: "再試行",
          icon: "arrow.clockwise",
          backgroundColor: .blue
        ) {
          withAnimation(.easeInOut(duration: 0.3)) {
            isLocationPermissionCheckCompleted = false
          }
          // アニメーション状態の同期（競合状態防止）
          updateRecordingAnimationState()
          checkLocationPermissionStatus()
        }
      }
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 24)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    )
    .padding(.horizontal, 24)
    .accessibilityIdentifier("UnknownPermissionStateView")
    .accessibilityLabel("位置情報の許可状態が不明です")
  }

  /// 散歩提案ボタンがタップされた時の処理
  ///
  /// 現在の位置情報、散歩状態、位置情報許可状態などをログ出力します。
  /// 将来的にはFoundation Modelsを使用してルート提案を生成します。
  private func handleSuggestionButtonTapped() {
    #if DEBUG
      print("========================================")
      print("散歩提案ボタンがタップされました")
      print("========================================")

      // 1. 現在の位置情報をログ出力
      if let location = currentLocation {
        print("📍 現在位置:")
        print("  - 緯度: \(location.coordinate.latitude)")
        print("  - 経度: \(location.coordinate.longitude)")
        print("  - 精度: \(location.horizontalAccuracy)m")
        print("  - タイムスタンプ: \(location.timestamp)")
      } else {
        print("📍 現在位置: 取得できていません")
      }

      // 2. 現在の散歩状態をログ出力
      print("\n🚶 散歩状態:")
      print("  - 散歩中: \(walkManager.isWalking)")
      if let currentWalk = walkManager.currentWalk {
        print("  - ステータス: \(currentWalk.status)")
        print("  - 経過時間: \(walkManager.elapsedTimeString)")
        print("  - 距離: \(walkManager.distanceString)")
        print("  - 歩数: \(walkManager.totalSteps)")
        print("  - 記録位置数: \(currentWalk.locations.count)")
      } else {
        print("  - 現在散歩中ではありません")
      }

      // 3. 位置情報許可状態をログ出力
      print("\n🔐 位置情報許可状態:")
      print("  - 許可状態: \(locationManager.authorizationStatus)")
      print("  - チェック完了: \(isLocationPermissionCheckCompleted)")

      // 4. プレースホルダー: 将来的にはここで散歩履歴を取得
      print("\n📊 散歩履歴（将来実装）:")
      print("  - 直近の散歩: [未実装 - Firestoreから取得予定]")
      print("  - 訪問エリア: [未実装]")
      print("  - 平均距離: [未実装]")

      // 5. プレースホルダー: 将来的にはここでユーザーの気分入力を取得
      print("\n💭 ユーザー入力（将来実装）:")
      print("  - 気分: [未実装]")
      print("  - 希望距離: [未実装]")
      print("  - 希望時間: [未実装]")

      print("========================================")
    #endif

    if let forcedMessage = forcedRouteSuggestionErrorMessage() {
      routeSuggestionErrorMessage = forcedMessage
      return
    }

    // 6. RouteSuggestionServiceを使用してルート提案を生成
    if #available(iOS 26.0, *) {
      Task {
        do {
          isLoading = true
          routeSuggestionErrorMessage = nil

          let service = RouteSuggestionService()
          let suggestions = try await service.generateRouteSuggestions()

          isLoading = false

          #if DEBUG
            print("\n🎯 生成されたルート提案:")
            for (index, suggestion) in suggestions.enumerated() {
              print("[\(index + 1)] \(suggestion.title)")
              print("   説明: \(suggestion.description)")
              print("   距離: \(suggestion.estimatedDistance)km")
              print("   所要時間: \(suggestion.estimatedDuration)分")
              print("   理由: \(suggestion.recommendationReason)")
              print("")
            }
            print("========================================")
          #endif

        } catch {
          isLoading = false

          routeSuggestionErrorMessage = makeRouteSuggestionAlertMessage(from: error)

          #if DEBUG
            print("\n❌ ルート提案生成エラー:")
            print("  - エラー: \(error.localizedDescription)")
            print("========================================")
          #endif
        }
      }
    } else {
      routeSuggestionErrorMessage = "ルート提案機能はiOS 26.0以降で利用できます。"
      #if DEBUG
        print("\n⚠️ RouteSuggestionServiceはiOS 26.0以降で利用可能です")
        print("========================================")
      #endif
    }
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

  private func forcedRouteSuggestionErrorMessage() -> String? {
    let arguments = ProcessInfo.processInfo.arguments
    guard arguments.contains("--force-error") else { return nil }

    let type = arguments.firstIndex(of: "--error-type").flatMap { index -> String? in
      guard index + 1 < arguments.count else { return nil }
      return arguments[index + 1]
    }?.lowercased()

    switch type {
    case "network":
      return "ネットワーク接続に問題が発生しました。通信環境を確認して再度お試しください。"
    case "timeout":
      return "サーバーの応答がタイムアウトしました。しばらくしてから再度お試しください。"
    case "unauthorized":
      return "ログイン状態が無効です。再度ログインしてからお試しください。"
    default:
      return "ルート提案の取得中にエラーが発生しました。"
    }
  }

  private func makeRouteSuggestionAlertMessage(from error: Error) -> String {
    if let serviceError = error as? RouteSuggestionServiceError {
      switch serviceError {
      case .foundationModelUnavailable(let detail):
        return "Apple Intelligenceが現在利用できないため、ルート提案を生成できません。設定を確認してから再度お試しください。\n詳細: \(detail)"
      case .generationFailed(let detail):
        return "ルート提案の生成に失敗しました。時間をおいて再度お試しください。\n詳細: \(detail)"
      case .databaseUnavailable(let detail):
        return "散歩履歴の取得に失敗しました。通信環境を確認してから再度お試しください。\n詳細: \(detail)"
      }
    }

    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
      return "ネットワーク接続に問題が発生しました。（コード: \(nsError.code)）通信環境を確認して再度お試しください。"
    }
    return nsError.localizedDescription
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
  private func checkLocationPermissionStatus() {
    // 状態管理を強化
    let initialState = isLocationPermissionCheckCompleted

    // アニメーション付きの状態変更（最適化されたタイミング）
    withAnimation(.easeOut(duration: AnimationTiming.initialStateChange)) {
      isLocationPermissionCheckCompleted = false
    }

    // 許可状態を即座に確認（同期的処理）
    let status = locationManager.checkAuthorizationStatus()

    // 非同期で許可状態更新処理を実行
    performLocationPermissionUpdate(initialState: initialState, status: status)
  }

  /// 位置情報許可状態の更新処理
  ///
  /// 許可状態チェック後の非同期更新処理を分離したメソッドです。
  /// フラッシュ防止のタイミング制御と状態更新を担当します。
  ///
  /// - Parameters:
  ///   - initialState: チェック開始時の状態
  ///   - status: 取得した許可状態
  private func performLocationPermissionUpdate(initialState: Bool, status: CLAuthorizationStatus) {
    // フラッシュ防止のための精密なタイミング制御
    DispatchQueue.main.asyncAfter(deadline: .now() + AnimationTiming.uiRenderingDelay) {
      // スムーズな状態完了アニメーション
      withAnimation(.easeInOut(duration: AnimationTiming.completionStateChange)) {
        self.isLocationPermissionCheckCompleted = true
      }

      // 許可済みの場合の統合処理
      if self.isLocationAuthorized(status) {
        self.setupLocationManager()
      }

      // 統合テスト用の状態ログ
      #if DEBUG
        print("位置情報許可状態チェック完了")
        print("  - 初期状態: \(initialState)")
        print("  - 最終状態: \(self.isLocationPermissionCheckCompleted)")
        print("  - 許可状態: \(status)")
        print("  - 許可判定: \(self.isLocationAuthorized(status))")
      #endif
    }
  }

  /// 位置情報が許可されているかを判定するヘルパーメソッド
  ///
  /// 統合テスト対応とロバスト性向上
  private func isLocationAuthorized(_ status: CLAuthorizationStatus) -> Bool {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      return true
    case .notDetermined, .denied, .restricted:
      return false
    @unknown default:
      // 将来のiOSバージョンでの新しい状態を安全に処理
      #if DEBUG
        print("未知の位置情報許可状態: \(status)")
      #endif
      return false
    }
  }

  /// アクションボタンを生成するヘルパーメソッド
  ///
  /// メモリ効率とパフォーマンスの最適化
  @ViewBuilder
  private func createActionButton(
    title: String,
    icon: String,
    backgroundColor: Color,
    action: @escaping () -> Void
  ) -> some View {
    Button {
      action()
    } label: {
      // パフォーマンス最適化されたHStack
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 16, weight: .medium))
          .symbolRenderingMode(.hierarchical)
        Text(title)
          .font(.system(.body, design: .rounded))
          .fontWeight(.medium)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .padding(.horizontal, 20)
      .background(optimizedButtonBackground(backgroundColor))
      .foregroundColor(.white)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .shadow(color: backgroundColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    .buttonStyle(PlainButtonStyle())
    .scaleEffect(isLoading ? 0.98 : 1.0)
    .animation(.easeInOut(duration: 0.1), value: isLoading)
  }

  /// ボタン背景の最適化されたグラデーション生成
  ///
  /// グラデーションキャッシュとメモリ最適化
  @ViewBuilder
  private func optimizedButtonBackground(_ baseColor: Color) -> some View {
    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: baseColor, location: 0.0),
        .init(color: baseColor.opacity(0.8), location: 1.0),
      ]),
      startPoint: .leading,
      endPoint: .trailing
    )
  }

  // MARK: - アニメーションライフサイクル管理

  /// アニメーション状態の初期化
  ///
  /// ビュー表示時にアニメーション制御フラグを適切に設定します。
  /// メモリリーク防止とパフォーマンス最適化を目的としています。
  private func initializeAnimationStates() {
    DispatchQueue.main.async {
      self.shouldAnimateRecording =
        self.walkManager.isWalking && self.walkManager.currentWalk?.status != .paused
      self.shouldAnimateUnknownState = true

      #if DEBUG
        print("アニメーション初期化:")
        print("  - 記録アニメーション: \(self.shouldAnimateRecording)")
        print("  - 未知状態アニメーション: \(self.shouldAnimateUnknownState)")
      #endif
    }
  }

  /// Apple Intelligence利用可否をチェック
  ///
  /// Foundation ModelsのSystemLanguageModelが利用可能かどうかを確認し、
  /// 端末がApple Intelligence対応かどうかを判定します。
  /// iOS 26.0以降でのみ実行され、結果をisAppleIntelligenceAvailableに設定します。
  private func checkAppleIntelligenceAvailability() {
    if #available(iOS 26.0, *) {
      #if canImport(FoundationModels)
        switch SystemLanguageModel.default.availability {
        case .available:
          isAppleIntelligenceAvailable = true
          #if DEBUG
            print("✅ Apple Intelligence: 利用可能")
          #endif

        case .unavailable(let reason):
          isAppleIntelligenceAvailable = false
          #if DEBUG
            print("⚠️ Apple Intelligence: 利用不可")
            switch reason {
            case .deviceNotEligible:
              print("  理由: 端末が非対応（iPhone 15 Pro以降が必要）")
            case .appleIntelligenceNotEnabled:
              print("  理由: Apple Intelligenceが無効")
            case .modelNotReady:
              print("  理由: モデルが準備中")
            @unknown default:
              print("  理由: 不明 (\(reason))")
            }
          #endif
        }
      #else
        isAppleIntelligenceAvailable = false
        #if DEBUG
          print("⚠️ Apple Intelligence: FoundationModelsフレームワークが利用不可")
        #endif
      #endif
    } else {
      isAppleIntelligenceAvailable = false
      #if DEBUG
        print("⚠️ Apple Intelligence: iOS 26.0以降が必要")
      #endif
    }
  }

  /// すべてのアニメーションを停止
  ///
  /// ビューが非表示になる際にrepeatForeverアニメーションを停止し、
  /// メモリリークと不要なCPU使用を防止します。
  private func stopAllAnimations() {
    DispatchQueue.main.async {
      withAnimation(.none) {
        self.shouldAnimateRecording = false
        self.shouldAnimateUnknownState = false
      }

      #if DEBUG
        print("全アニメーション停止完了")
      #endif
    }
  }

  /// 記録アニメーション状態の更新
  ///
  /// 散歩状態の変更に応じてアニメーション状態を同期します。
  /// 一時停止時や停止時には適切にアニメーションを停止します。
  private func updateRecordingAnimationState() {
    DispatchQueue.main.async {
      let newState = self.walkManager.isWalking && self.walkManager.currentWalk?.status != .paused

      if self.shouldAnimateRecording != newState {
        withAnimation(.easeInOut(duration: 0.3)) {
          self.shouldAnimateRecording = newState
        }
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

// MARK: - テスト用拡張

#if DEBUG
  extension HomeView {
    /// テスト用：位置情報許可状態チェック完了フラグのアクセサー
    ///
    /// HomeViewの内部状態isLocationPermissionCheckCompletedにアクセスするためのテスト専用プロパティです。
    /// 位置情報許可状態の事前チェック完了を確認するテストで使用されます。
    var testIsLocationPermissionCheckCompleted: Bool {
      isLocationPermissionCheckCompleted
    }

    /// テスト用：位置情報許可状態チェックメソッドの呼び出し
    ///
    /// HomeViewのcheckLocationPermissionStatus()メソッドをテストから呼び出すためのラッパーメソッドです。
    /// メソッドの存在確認と動作テストで使用されます。
    func testCheckLocationPermissionStatus() {
      checkLocationPermissionStatus()
    }

    /// テスト用：位置情報許可状態判定ヘルパーのアクセス
    ///
    /// 位置情報許可状態の判定ロジックをテストから呼び出すためのメソッドです。
    /// 各種許可状態での判定動作を検証します。
    func testIsLocationAuthorized(_ status: CLAuthorizationStatus) -> Bool {
      isLocationAuthorized(status)
    }

    /// テスト用：統合テスト用の包括的状態アクセス
    ///
    /// 統合テスト用の状態確認メソッドです。
    /// アプリ起動フロー全体の検証に使用されます。
    func testComprehensiveState() -> (isCheckCompleted: Bool, canAccessLocation: Bool) {
      let isCompleted = isLocationPermissionCheckCompleted
      // 実際の位置情報マネージャーの状態も確認
      let locationManager = LocationManager.shared
      let canAccess =
        locationManager.checkAuthorizationStatus() == .authorizedWhenInUse
        || locationManager.checkAuthorizationStatus() == .authorizedAlways

      return (isCheckCompleted: isCompleted, canAccessLocation: canAccess)
    }
  }
#endif

#Preview {
  HomeView(showOnboarding: .constant(false))
    .environmentObject(OnboardingManager())
}
