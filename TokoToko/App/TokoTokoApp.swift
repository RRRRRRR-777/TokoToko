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

/// Firebase認証状態を管理するObservableObjectクラス
///
/// `AuthManager`はアプリケーション全体のユーザー認証状態を一元管理し、
/// ログイン・ログアウト状態の変化をリアルタイムで監視・通知します。
/// UIテストモード時はモックデータを使用してテストの安定性を確保します。
///
/// ## Overview
///
/// - **認証状態監視**: Firebase Authの状態変化をリアルタイムで追跡
/// - **初期化フェーズ**: アプリ起動時の認証確認プロセスを管理
/// - **UIテスト対応**: テスト実行時はモックデータで動作を模擬
/// - **メモリ管理**: 適切なリスナー削除でメモリリークを防止
///
/// ## Topics
///
/// ### Published Properties
/// - ``isLoggedIn``
/// - ``isInitializing``
///
/// ### Methods
/// - ``logout()``
class AuthManager: ObservableObject {
  /// ユーザーのログイン状態
  ///
  /// Firebaseで認証済みのユーザーが存在する場合はtrue、未認証の場合はfalseです。
  /// @Publishedにより、状態変化が自動的にUIに反映されます。
  @Published var isLoggedIn = false

  /// 認証状態の初期化プロセス中かどうか
  ///
  /// アプリ起動時の認証状態確認中はtrue、確認完了後はfalseになります。
  /// スプラッシュ画面の表示制御に使用されます。
  @Published var isInitializing = true

  /// Firebase認証状態変更リスナーのハンドル
  ///
  /// Firebase Authの認証状態変更を監視するリスナーのハンドルです。
  /// deinit時にリスナーを適切に削除するために保持されます。
  private var authStateHandler: AuthStateDidChangeListenerHandle?

  /// UIテストヘルパーへの参照
  ///
  /// UIテストモード時のモックデータ制御に使用されます。
  private let testingHelper = UITestingHelper.shared

  init() {
    // UIテストモードの場合
    if testingHelper.isUITesting {
      // モックログイン状態を設定
      isLoggedIn = testingHelper.isMockLoggedIn
      isInitializing = false
    } else {
      // 通常の動作: Firebase認証状態の変更を監視
      authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
        DispatchQueue.main.async {
          self?.isLoggedIn = user != nil
          self?.isInitializing = false
        }
      }
    }
  }

  /// ユーザーのログアウト処理を実行
  ///
  /// UIテストモード時はモック状態を更新し、通常モード時はFirebase認証から
  /// サインアウトします。実際の状態更新は認証状態リスナーで自動処理されます。
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

/// TokoTokoアプリケーションのUIApplicationDelegate
///
/// Firebase初期化とGoogle Sign-In URLハンドリングを担当するアプリデリゲートです。
/// アプリケーションのライフサイクルイベントに対応した初期化処理を行います。
///
/// ## Topics
///
/// ### UIApplicationDelegate Methods
/// - ``application(_:didFinishLaunchingWithOptions:)``
/// - ``application(_:open:options:)``
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
    GIDSignIn.sharedInstance.handle(url)
  }
}

/// TokoTokoアプリケーションのメインエントリーポイント
///
/// `TokoTokoApp`はSwiftUI Appプロトコルを実装したメインアプリケーション構造体です。
/// 認証状態に基づいて適切な画面（スプラッシュ、ログイン、メインタブ）を表示します。
///
/// ## Overview
///
/// - **認証フロー**: ログイン状態に応じた適切な画面遷移
/// - **依存性注入**: AuthManagerをアプリ全体で共有
/// - **Firebase統合**: AppDelegateを通じたFirebase初期化
/// - **ナビゲーション**: NavigationViewでの画面管理
///
/// ## Topics
///
/// ### Properties
/// - ``delegate``
/// - ``authManager``
@main
struct TokoTokoApp: App {
  /// UIApplicationDelegateアダプター
  ///
  /// SwiftUI AppでUIApplicationDelegateを使用するためのアダプターです。
  /// Firebase初期化とURL処理を担当するAppDelegateを統合します。
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  /// 認証状態管理オブジェクト
  ///
  /// アプリ全体の認証状態を管理するAuthManagerのインスタンスです。
  /// @StateObjectにより、アプリケーションライフサイクル中で単一のインスタンスが維持されます。
  @StateObject private var authManager = AuthManager()

  /// 同意状態管理オブジェクト
  ///
  /// アプリ全体の同意状態を管理するConsentManagerのインスタンスです。
  /// 初回同意フローと再同意フローを制御します。
  @StateObject private var consentManager = ConsentManager()

  var body: some Scene {
    WindowGroup {
      NavigationView {
        if authManager.isInitializing || consentManager.isLoading {
          SplashView()
        } else if !authManager.isLoggedIn {
          // ログインしていない場合は、まずログイン画面を表示
          LoginView()
            .environmentObject(authManager)
        } else if !consentManager.hasValidConsent {
          // ログイン済みだが同意がない場合は、同意画面を表示
          ConsentFlowView()
            .environmentObject(consentManager)
        } else {
          // ログイン済みかつ同意済みの場合は、メインタブを表示
          MainTabView()
            .environmentObject(authManager)
            .environmentObject(consentManager)
        }
      }
    }
  }
}

/// メインタブビューとナビゲーション管理
///
/// `MainTabView`はログイン後のメインUI構造を提供するビューコンポーネントです。
/// 3つのタブ（おでかけ、おさんぽ、設定）間のナビゲーションとカスタムタブバーを管理します。
/// UIテスト時はディープリンクに対応した初期タブ選択を行います。
///
/// ## Overview
///
/// - **タブナビゲーション**: 3つのメイン機能間の切り替え
/// - **カスタムUI**: 独自デザインのタブバー実装
/// - **ディープリンク対応**: UIテスト時の特定タブへの直接ナビゲーション
/// - **ZStack配置**: コンテンツ上にフローティングタブバーを配置
///
/// ## Topics
///
/// ### Nested Types
/// - ``Tab``
///
/// ### Properties
/// - ``authManager``
/// - ``selectedTab``
struct MainTabView: View {
  /// 認証管理オブジェクト
  ///
  /// 親ビューから注入されるAuthManagerインスタンスです。
  /// ログアウト処理や認証状態の参照に使用されます。
  @EnvironmentObject var authManager: AuthManager

  /// 同意状態管理オブジェクト
  ///
  /// 親ビューから注入されるConsentManagerインスタンスです。
  /// 再同意チェックなどに使用されます。
  @EnvironmentObject var consentManager: ConsentManager

  /// 現在選択されているタブ
  ///
  /// タブの選択状態を管理し、表示するビューを決定します。
  @State private var selectedTab: Tab

  /// オンボーディングモーダルの表示状態
  ///
  /// オンボーディングモーダルを表示するかどうかを制御します。
  @State private var showOnboardingModal = false

  /// オンボーディングマネージャー
  ///
  /// オンボーディングの表示判定とコンテンツ管理を担当します。
  @StateObject private var onboardingManager = OnboardingManager()

  /// UIテストヘルパーへの参照
  ///
  /// UIテスト実行時のディープリンクやモック状態制御に使用されます。
  private let testingHelper = UITestingHelper.shared

  /// メインアプリケーションのタブ種別
  ///
  /// 3つのメイン機能に対応するタブを定義します。
  enum Tab {
    /// おでかけタブ（HomeView）
    case outing
    /// おさんぽタブ（WalkHistoryMainView）
    case walk
    /// 設定タブ（SettingsView）
    case settings
  }

  init() {
    // UIテストモードの場合
    if testingHelper.isUITesting {
      // ディープリンクがある場合
      if testingHelper.hasDeepLink {
        // ディープリンク先に基づいてタブを設定
        switch testingHelper.deepLinkDestination {
        case "walk":
          _selectedTab = State(initialValue: .walk)
        case "settings":
          _selectedTab = State(initialValue: .settings)
        default:
          _selectedTab = State(initialValue: .outing)
        }
      } else {
        // デフォルトはおでかけタブ
        _selectedTab = State(initialValue: .outing)
      }
    } else {
      // 通常の動作
      _selectedTab = State(initialValue: .outing)
    }
  }

  var body: some View {
    ZStack {
      // メインコンテンツ
      VStack(spacing: 0) {
        // 選択されたタブのビューを表示
        Group {
          switch selectedTab {
          case .outing:
            NavigationView {
              HomeView(showOnboarding: $showOnboardingModal)
                .environmentObject(onboardingManager)
            }
          case .walk:
            NavigationView {
              WalkHistoryMainView()
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
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
      Task {
        await consentManager.checkForReConsentNeeded()
      }
    }
    .onAppear {
      checkForOnboarding()
    }
    .onChange(of: selectedTab) { newTab in
      if showOnboardingModal && newTab != .outing {
        onboardingManager.markOnboardingAsShown(for: .firstLaunch)
        showOnboardingModal = false
      }
    }
  }

  // MARK: - Private Methods

  /// オンボーディング表示の必要性をチェックし、必要に応じて表示
  ///
  /// 初回起動時やバージョンアップ時にオンボーディングを表示するかどうかを判定し、
  /// 必要な場合はモーダル表示フラグをtrueに設定します。
  private func checkForOnboarding() {
    // 初回起動のオンボーディング判定
    if onboardingManager.shouldShowOnboarding(for: .firstLaunch) {
      showOnboardingModal = true
    }
    // 将来的にはバージョンアップのオンボーディングも判定可能
    // TODO: アプリバージョンが更新された場合のオンボーディング判定を追加
  }
}

/// カスタムデザインのタブバーコンポーネント
///
/// `CustomTabBar`は3つのタブアイテムを横並びに配置したカスタムタブバーです。
/// 角丸とシャドウを持つ白い背景に各タブボタンを配置し、選択状態を視覚的に表現します。
///
/// ## Topics
///
/// ### Properties
/// - ``selectedTab``
struct CustomTabBar: View {
  /// 選択されているタブのバインディング
  ///
  /// 親ビューのタブ選択状態とバインドされ、タブアイテムのタップで更新されます。
  @Binding var selectedTab: MainTabView.Tab

  var body: some View {
    HStack(spacing: 0) {
      TabBarItem(
        tab: .outing,
        icon: "location.fill",
        title: "おでかけ",
        selectedTab: $selectedTab
      )

      TabBarItem(
        tab: .walk,
        icon: "figure.walk",
        title: "おさんぽ",
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
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("MainTabBar")
  }
}

/// 個別のタブバーアイテムコンポーネント
///
/// `TabBarItem`は単一のタブボタンを表現するビューコンポーネントです。
/// アイコン・タイトル・選択状態の表示とアクセシビリティ対応を統合しています。
///
/// ## Topics
///
/// ### Properties
/// - ``tab``
/// - ``icon``
/// - ``title``
/// - ``selectedTab``
/// - ``isSelected``
struct TabBarItem: View {
  /// このタブアイテムが表すタブ種別
  let tab: MainTabView.Tab

  /// タブアイコンのSF Symbols名
  let icon: String

  /// タブのタイトル文字列
  let title: String

  /// 選択されているタブのバインディング
  @Binding var selectedTab: MainTabView.Tab

  /// このタブが現在選択されているかどうか
  ///
  /// 選択状態に応じてアイコンとテキストの色を変更するために使用されます。
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
    .accessibilityIdentifier(title)
    .accessibilityValue(isSelected ? "選択中" : "未選択")
    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    .accessibilityHint("\(title)タブに切り替えます")
  }
}
