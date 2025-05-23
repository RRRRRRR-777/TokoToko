//
//  TokoTokoApp.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import SwiftUI

// Firebase認証状態を管理するクラス
class AuthManager: ObservableObject {
  @Published var isLoggedIn = false
  private var authStateHandler: AuthStateDidChangeListenerHandle?

  // UIテストヘルパーへの参照
  private let testingHelper = UITestingHelper.shared

  init() {
    // UIテストモードの場合
    if testingHelper.isUITesting {
      // モックログイン状態を設定
      isLoggedIn = testingHelper.isMockLoggedIn
    } else {
      // 通常の動作: Firebase認証状態の変更を監視
      authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
        self?.isLoggedIn = user != nil
      }
    }
  }

  // ログアウト処理
  func logout() {
    // UIテストモードの場合
    if testingHelper.isUITesting {
      // モックログイン状態を更新
      isLoggedIn = false
    } else {
      // 通常の動作: Firebase認証でログアウト
      try? Auth.auth().signOut()
      // 注: 実際のログアウト状態の更新はauthStateHandlerで行われる
    }
  }

  deinit {
    // リスナーを削除
    if let handler = authStateHandler {
      Auth.auth().removeStateDidChangeListener(handler)
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    return true
  }

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}

@main
struct TokoTokoApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var authManager = AuthManager()

  var body: some Scene {
    WindowGroup {
      NavigationView {
        if authManager.isLoggedIn {
          MainTabView()
            .environmentObject(authManager)
        } else {
          LoginView()
            .environmentObject(authManager)
        }
      }
    }
  }
}

// メインのタブビュー
struct MainTabView: View {
  @EnvironmentObject var authManager: AuthManager
  @State private var selectedTab: Tab

  // UIテストヘルパーへの参照
  private let testingHelper = UITestingHelper.shared

  enum Tab {
    case home
    case map
    case settings
  }

  init() {
    // UIテストモードの場合
    if testingHelper.isUITesting {
      // ディープリンクがある場合
      if testingHelper.hasDeepLink {
        // ディープリンク先に基づいてタブを設定
        switch testingHelper.deepLinkDestination {
        case "map":
          _selectedTab = State(initialValue: .map)
        case "settings":
          _selectedTab = State(initialValue: .settings)
        default:
          _selectedTab = State(initialValue: .home)
        }
      } else {
        // デフォルトはホームタブ
        _selectedTab = State(initialValue: .home)
      }
    } else {
      // 通常の動作
      _selectedTab = State(initialValue: .home)
    }
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationView {
        HomeView()
      }
      .tabItem {
        Label("ホーム", systemImage: "house")
      }
      .tag(Tab.home)

      NavigationView {
        MapView()
      }
      .tabItem {
        Label("マップ", systemImage: "map")
      }
      .tag(Tab.map)

      NavigationView {
        SettingsView()
          .environmentObject(authManager)
      }
      .tabItem {
        Label("設定", systemImage: "gear")
      }
      .tag(Tab.settings)
    }
  }
}
