//
//  TokoTokoApp.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import SwiftUI

// Firebase認証状態を管理するクラス
class AuthManager: ObservableObject {
  @Published var isLoggedIn = false
  private var authStateHandler: AuthStateDidChangeListenerHandle?

  init() {
    // Firebase認証状態の変更を監視
    authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.isLoggedIn = user != nil
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
  @State private var selectedTab: Tab = .home

  enum Tab {
    case home
    case map
    case settings
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
      }
      .tabItem {
        Label("設定", systemImage: "gear")
      }
      .tag(Tab.settings)
    }
  }
}

// 設定画面（シンプルな実装）
struct SettingsView: View {
  var body: some View {
    List {
      Section(header: Text("アプリ設定")) {
        Text("アカウント")
        Text("通知")
        Text("プライバシー")
      }

      Section(header: Text("位置情報")) {
        Text("位置情報の精度")
        Text("バックグラウンド更新")
      }

      Section(header: Text("その他")) {
        Text("このアプリについて")
        Text("ヘルプ")
      }
    }
    .navigationTitle("設定")
  }
}
