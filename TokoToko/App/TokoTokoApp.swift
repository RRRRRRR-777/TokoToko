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
    case friend
    case settings
  }

  init() {
    // UIテストモードの場合
    if testingHelper.isUITesting {
      // ディープリンクがある場合
      if testingHelper.hasDeepLink {
        // ディープリンク先に基づいてタブを設定
        switch testingHelper.deepLinkDestination {
        case "friend":
          _selectedTab = State(initialValue: .friend)
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
    ZStack {
      // メインコンテンツ
      VStack(spacing: 0) {
        // 選択されたタブのビューを表示
        Group {
          switch selectedTab {
          case .home:
            NavigationView {
              HomeView()
            }
          case .friend:
            NavigationView {
              //              FriendView()
            }
          case .settings:
            NavigationView {
              SettingsView()
                .environmentObject(authManager)
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        Spacer()
      }

      // カスタムタブバー
      VStack {
        Spacer()
        CustomTabBar(selectedTab: $selectedTab)
          .padding(.horizontal, 20)
          .padding(.bottom, 20)
      }
    }
    .ignoresSafeArea(.all, edges: .bottom)
  }
}

// カスタムタブバー
struct CustomTabBar: View {
  @Binding var selectedTab: MainTabView.Tab

  var body: some View {
    HStack(spacing: 0) {
      TabBarItem(
        tab: .home,
        icon: "house.fill",
        title: "ホーム",
        selectedTab: $selectedTab
      )

      TabBarItem(
        tab: .friend,
        icon: "person.2.fill",
        title: "フレンド",
        selectedTab: $selectedTab
      )

      TabBarItem(
        tab: .settings,
        icon: "gearshape.fill",
        title: "設定",
        selectedTab: $selectedTab
      )
    }
    .frame(width: 280, height: 70)
    .background(
      RoundedRectangle(cornerRadius: 35)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    )
    .padding(.trailing, 80)
  }
}

// 個別のタブバーアイテム
struct TabBarItem: View {
  let tab: MainTabView.Tab
  let icon: String
  let title: String
  @Binding var selectedTab: MainTabView.Tab

  var isSelected: Bool {
    selectedTab == tab
  }

  var body: some View {
    Button(action: {
      selectedTab = tab
    }) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 20, weight: .medium))
          .foregroundColor(isSelected ? .red : .gray)

        Text(title)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(isSelected ? .red : .gray)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
