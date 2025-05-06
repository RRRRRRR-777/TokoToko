//
//  TokoTokoApp.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/04.
//

import SwiftUI
import FirebaseCore


 class AppDelegate: NSObject, UIApplicationDelegate {
     func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
          FirebaseApp.configure()

         return true
     }
 }

@main
struct TokoTokoApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(coordinator)
        }
    }
}

// メインのタブビュー
struct MainTabView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house")
            }
            .tag(AppCoordinator.Tab.home)

            NavigationView {
                MapScreen()
            }
            .tabItem {
                Label("マップ", systemImage: "map")
            }
            .tag(AppCoordinator.Tab.map)

            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gear")
            }
            .tag(AppCoordinator.Tab.settings)
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
