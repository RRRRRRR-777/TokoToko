//
//  SettingsView.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/05/20.
//

import FirebaseAuth
import SwiftUI
import UIKit

/// アプリケーション設定とアカウント管理画面
///
/// `SettingsView`はユーザーアカウント情報の表示、ログアウト処理、
/// アプリ設定項目へのアクセスを提供する設定画面です。
/// UIテスト対応機能とFirebase認証との連携機能を統合しています。
///
/// ## Overview
///
/// - **アカウント情報**: メールアドレスとプロフィール画像の表示
/// - **ログアウト機能**: 確認ダイアログ付きのログアウト処理
/// - **設定項目**: 通知、プライバシー、位置情報設定へのナビゲーション
/// - **UIテスト対応**: 各種テストシナリオ用のモックデータ制御
///
/// ## Topics
///
/// ### Properties
/// - ``authManager``
/// - ``showingLogoutAlert``
/// - ``isLoading``
/// - ``errorMessage``
///
/// ### Methods
/// - ``logout()``
struct SettingsView: View {
  /// 認証状態管理オブジェクト
  ///
  /// ログアウト処理と認証状態の参照に使用されるAuthManagerのインスタンスです。
  @EnvironmentObject private var authManager: AuthManager

  /// 位置情報設定管理オブジェクト
  ///
  /// 位置情報精度設定とバックグラウンド更新設定の管理に使用されるLocationSettingsManagerのインスタンスです。
  @EnvironmentObject private var locationSettingsManager: LocationSettingsManager

  /// ログアウト確認ダイアログの表示状態
  ///
  /// ログアウトボタンタップ時に表示される確認ダイアログの表示制御に使用されます。
  @State private var showingLogoutAlert: Bool

  /// ログアウト処理のローディング状態
  ///
  /// ログアウト処理中はtrueになり、ローディングインジケーターを表示します。
  @State private var isLoading: Bool

  /// エラーメッセージ
  ///
  /// ログアウト処理やその他のエラーが発生した場合のメッセージを保持します。
  @State private var errorMessage: String?

  /// アカウント削除確認ダイアログの表示状態
  @State private var showingDeleteAccountAlert = false

  /// アカウント削除処理中のローディング状態
  @State private var isDeletingAccount = false

  /// ポリシー表示モーダルの表示状態
  @State private var showingPolicyView = false

  /// 選択されたポリシータイプ
  @State private var selectedPolicyType: PolicyType = .privacyPolicy

  /// キャッシュされたポリシー
  @State private var cachedPolicy: Policy?

  /// ポリシー読み込み状態
  @State private var isPolicyLoading = false

  // UIテスト用のフラグ
  private var isUITesting: Bool {
    ProcessInfo.processInfo.arguments.contains("--uitesting")
  }

  // 単体テスト環境かどうかを判定
  private var isUnitTest: Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
  }

  // UIテスト用のユーザー情報フラグ
  private var hasUserInfo: Bool {
    ProcessInfo.processInfo.arguments.contains("--with-user-info")
  }

  // UIテスト用のメールアドレス
  private var mockEmail: String? {
    let args = ProcessInfo.processInfo.arguments
    if let index = args.firstIndex(of: "--email"), index + 1 < args.count {
      return args[index + 1]
    }
    return "test@example.com"  // デフォルト値
  }

  // UIテスト用のエラー強制表示フラグ
  private var shouldForceError: Bool {
    ProcessInfo.processInfo.arguments.contains("--force-error")
  }

  // UIテスト用のエラータイプ
  private var forcedErrorType: String? {
    let args = ProcessInfo.processInfo.arguments
    if let index = args.firstIndex(of: "--error-type"), index + 1 < args.count {
      return args[index + 1]
    }
    return nil
  }

  init() {
    // 統一されたナビゲーションバー外観設定を適用
    NavigationBarStyleManager.shared.configureForSwiftUI(customizations: .settingsScreen)

    // List背景の完全制御
    UITableView.appearance().backgroundColor = UIColor.clear
    UITableView.appearance().separatorStyle = .none
    UITableViewCell.appearance().backgroundColor = UIColor.clear
    UITableViewHeaderFooterView.appearance().backgroundColor = UIColor.clear

    // UIテストモードの場合
    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
      // ログアウトアラートを強制表示する場合
      if ProcessInfo.processInfo.arguments.contains("--show-logout-alert") {
        _showingLogoutAlert = State(initialValue: true)
      } else {
        _showingLogoutAlert = State(initialValue: false)
      }

      // ローディング状態を強制する場合
      if ProcessInfo.processInfo.arguments.contains("--force-loading-state") {
        _isLoading = State(initialValue: true)
      } else {
        _isLoading = State(initialValue: false)
      }

      // エラー状態を強制する場合
      if ProcessInfo.processInfo.arguments.contains("--force-error") {
        let errorType =
          ProcessInfo.processInfo.arguments.firstIndex(of: "--error-type").flatMap { index in
            index + 1 < ProcessInfo.processInfo.arguments.count
              ? ProcessInfo.processInfo.arguments[index + 1] : nil
          } ?? "テストエラー"

        _errorMessage = State(initialValue: errorType)
      }
    } else {
      // 通常の動作
      _showingLogoutAlert = State(initialValue: false)
      _isLoading = State(initialValue: false)
    }
  }

  // UIテスト用のモックユーザー
  private var mockUser: FirebaseAuth.User? {
    if isUITesting && hasUserInfo {
      // 実際の環境では、FirebaseAuthのテスト用ユーティリティを使用してモックユーザーを作成します
      // このサンプルでは簡易的な実装のみを示しています
      return nil
    }
    return Auth.auth().currentUser
  }

  var body: some View {
    List {
      Section(
        header:
          HStack {
            Text("アカウント")
              .foregroundColor(.gray)
              .font(.footnote)
              .fontWeight(.regular)
              .textCase(.uppercase)
            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 6)
          .background(Color("BackgroundColor"))
          .listRowInsets(EdgeInsets())
      ) {
        // 単体テスト環境の場合はシンプルな表示のみ
        if isUnitTest {
          Button(action: {
            showingDeleteAccountAlert = true
          }) {
            HStack {
              Text("アカウント削除")
                .foregroundColor(.red)
              Spacer()
              if isDeletingAccount {
                ProgressView()
              }
            }
          }
          .disabled(isDeletingAccount)
          .listRowBackground(Color("BackgroundColor").opacity(0.8))
        }
        // UIテストモードの場合はモックユーザー情報を使用
        else if isUITesting && hasUserInfo {
          // メールアドレス表示
          HStack {
            Text("メールアドレス")
              .foregroundColor(.black)
            Spacer()
            Text(mockEmail ?? "test@example.com")
              .foregroundColor(.black)
          }
          .listRowBackground(Color("BackgroundColor").opacity(0.8))

          // プロフィール画像表示（テスト用）
          HStack {
            Text("プロフィール画像")
              .foregroundColor(.black)
            Spacer()
            Circle()
              .fill(Color.gray)
              .frame(width: 40, height: 40)
          }
          .listRowBackground(Color("BackgroundColor").opacity(0.8))

          Button(action: {
            showingLogoutAlert = true
          }) {
            HStack {
              Text("ログアウト")
                .foregroundColor(.red)
              Spacer()
              if isLoading {
                ProgressView()
              }
            }
          }
          .disabled(isLoading)
          .listRowBackground(Color("BackgroundColor").opacity(0.8))
        }
        // 通常モードの場合は実際のユーザー情報を使用（単体テスト環境では表示しない）
        else if !isUITesting && !isUnitTest, let user = Auth.auth().currentUser {
          HStack {
            Text("メールアドレス")
              .foregroundColor(.black)
            Spacer()
            Text(user.email ?? "不明")
              .foregroundColor(.black)
          }
          .listRowBackground(Color("BackgroundColor").opacity(0.8))

          if let photoURL = user.photoURL, let url = URL(string: photoURL.absoluteString) {
            HStack {
              Text("プロフィール画像")
                .foregroundColor(.black)
              Spacer()
              AsyncImage(url: url) { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              } placeholder: {
                ProgressView()
              }
              .frame(width: 40, height: 40)
              .clipShape(Circle())
            }
            .listRowBackground(Color("BackgroundColor").opacity(0.8))
          }

          Button(action: {
            showingLogoutAlert = true
          }) {
            HStack {
              Text("ログアウト")
                .foregroundColor(.red)
              Spacer()
              if isLoading {
                ProgressView()
              }
            }
          }
          .disabled(isLoading)
          .listRowBackground(Color("BackgroundColor").opacity(0.8))

          Button(action: {
            showingDeleteAccountAlert = true
          }) {
            HStack {
              Text("アカウント削除")
                .foregroundColor(.red)
              Spacer()
              if isDeletingAccount {
                ProgressView()
              }
            }
          }
          .disabled(isDeletingAccount)
          .listRowBackground(Color("BackgroundColor").opacity(0.8))
        }
      }

      Section(
        header:
          HStack {
            Text("アプリ設定")
              .foregroundColor(.gray)
              .font(.footnote)
              .fontWeight(.regular)
              .textCase(.uppercase)
            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 6)
          .background(Color("BackgroundColor"))
          .listRowInsets(EdgeInsets())
      ) {
        Button(action: {
          Task {
            await loadCachedPolicy()
          }
          showingPolicyView = true
          selectedPolicyType = .privacyPolicy
        }) {
          Text("プライバシーポリシー")
            .foregroundColor(.black)
        }
        .listRowBackground(Color("BackgroundColor").opacity(0.8))

        Button(action: {
          Task {
            await loadCachedPolicy()
          }
          showingPolicyView = true
          selectedPolicyType = .termsOfService
        }) {
          Text("利用規約")
            .foregroundColor(.black)
        }
        .listRowBackground(Color("BackgroundColor").opacity(0.8))
      }

      Section(
        header:
          HStack {
            Text("位置情報")
              .foregroundColor(.gray)
              .font(.footnote)
              .fontWeight(.regular)
              .textCase(.uppercase)
            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 6)
          .background(Color("BackgroundColor"))
          .listRowInsets(EdgeInsets())
      ) {
        NavigationLink(
          destination: LocationAccuracySettingsView()
            .environmentObject(locationSettingsManager)
        ) {
          HStack {
            Text("位置情報設定")
              .foregroundColor(.black)
            Spacer()
            Text(locationSettingsManager.currentMode.displayName)
              .foregroundColor(.black)
              .font(.caption)
          }
        }
        .listRowBackground(Color("BackgroundColor").opacity(0.8))
      }

      Section(
        header:
          HStack {
            Text("その他")
              .foregroundColor(.gray)
              .font(.footnote)
              .fontWeight(.regular)
              .textCase(.uppercase)
            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 6)
          .background(Color("BackgroundColor"))
          .listRowInsets(EdgeInsets())
      ) {
        NavigationLink(destination: AppInfoView()) {
          Text("このアプリについて")
            .foregroundColor(.black)
        }
        .listRowBackground(Color("BackgroundColor").opacity(0.8))

        NavigationLink(destination: OpenSourceLicensesView()) {
          Text("オープンソースライセンス")
            .foregroundColor(.black)
        }
        .listRowBackground(Color("BackgroundColor").opacity(0.8))
      }

      if let errorMessage = errorMessage {
        Section {
          Text(errorMessage)
            .foregroundColor(.black)
            .font(.caption)
            .listRowBackground(Color("BackgroundColor").opacity(0.8))
        }
      }
    }
    .listStyle(PlainListStyle())
    .modifier(BackgroundColorModifier())
    .background(Color("BackgroundColor").ignoresSafeArea())
    .navigationTitle("設定")
    .navigationBarTitleDisplayMode(.inline)
    .accentColor(.black)
    .alert("ログアウトしますか？", isPresented: $showingLogoutAlert) {
      Button("キャンセル", role: .cancel) {}
      Button("ログアウト", role: .destructive) {
        logout()
      }
    } message: {
      Text("アカウントからログアウトします。再度ログインする必要があります。")
    }
    .alert("アカウントを削除しますか？", isPresented: $showingDeleteAccountAlert) {
      Button("キャンセル", role: .cancel) {}
      Button("削除", role: .destructive) {
        deleteAccount()
      }
    } message: {
      Text("この操作は取り消せません。アカウントと全てのデータが削除されます。")
    }
    .sheet(isPresented: $showingPolicyView) {
      NavigationView {
        if let policy = cachedPolicy {
          PolicyView(policy: policy, policyType: selectedPolicyType)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
              ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") {
                  showingPolicyView = false
                }
              }
            }
        } else if isPolicyLoading {
          VStack {
            ProgressView()
            Text("ポリシー情報を読み込み中...")
              .padding()
          }
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button("閉じる") {
                showingPolicyView = false
              }
            }
          }
        } else {
          VStack {
            Text("ポリシー情報を読み込めませんでした")
              .padding()
              .onAppear {
                print("SettingsView: モーダル表示時にcachedPolicyがnil")
                print("SettingsView: cachedPolicy = \(String(describing: cachedPolicy))")
              }
          }
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button("閉じる") {
                showingPolicyView = false
              }
            }
          }
        }
      }
    }
    .task {
      await loadCachedPolicy()
    }
  }

  /// ユーザーのログアウト処理を実行
  ///
  /// AuthManagerを通じてログアウト処理を実行します。
  /// 処理中はローディング状態を表示し、完了後は自動的にログイン画面に遷移します。
  ///
  /// ## Process Flow
  /// 1. ローディング状態をtrueに設定
  /// 2. エラーメッセージをクリア
  /// 3. AuthManager.logout()を呼び出し
  /// 4. UI状態をリセット
  private func logout() {
    isLoading = true
    errorMessage = nil

    // AuthManagerのlogoutメソッドを使用
    authManager.logout()

    // UIの更新
    DispatchQueue.main.async {
      isLoading = false
    }
  }

  /// アカウント削除処理を実行
  ///
  /// AccountDeletionServiceを通じてアカウント削除処理を実行します。
  /// 処理中はローディング状態を表示し、成功時は自動的にログイン画面に遷移します。
  ///
  /// ## Process Flow
  /// 1. ローディング状態をtrueに設定
  /// 2. エラーメッセージをクリア
  /// 3. AccountDeletionService.deleteAccount()を呼び出し
  /// 4. 結果に応じてUI状態を更新
  /// 5. 再認証が必要な場合はログアウトして再ログインを促す
  private func deleteAccount() {
    Task {
      isDeletingAccount = true
      errorMessage = nil

      // Firebase初期化エラーを回避するため、使用時に初期化
      let service = AccountDeletionService()
      let result = await service.deleteAccount()

      DispatchQueue.main.async {
        isDeletingAccount = false

        switch result {
        case .success:
          // 削除成功時はログアウト状態になるため、AuthManagerを通じて状態をリセット
          authManager.logout()
        case .failure(let message):
          // 再認証が必要な場合はログアウト
          if message.contains("再度ログイン") {
            authManager.logout()
          } else {
            // その他のエラーメッセージを表示
            errorMessage = message
          }
        }
      }
    }
  }

  /// キャッシュされたポリシーを読み込む
  private func loadCachedPolicy() async {
    isPolicyLoading = true
    let policyService = PolicyService()
    do {
      cachedPolicy = try await policyService.fetchPolicy()
      print("SettingsView: ポリシー読み込み成功: \(cachedPolicy?.version ?? "不明")")
    } catch {
      // エラーの場合は無視（ポリシーが表示できない旨のメッセージを表示）
      print("SettingsView: ポリシー読み込みエラー: \(error)")
      print("SettingsView: エラーの詳細: \(error.localizedDescription)")
      if let policyError = error as? PolicyServiceError {
        print("SettingsView: PolicyServiceError: \(policyError.errorDescription ?? "不明なエラー")")
      }
    }
    isPolicyLoading = false
  }
}

/// List背景色変更用のViewModifier
///
/// iOS 16以降では`.scrollContentBackground(.hidden)`を使用し、
/// iOS 15以下では従来の方法で背景色を適用します。
struct BackgroundColorModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 16.0, *) {
      content
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
    } else {
      content
        .background(Color("BackgroundColor"))
    }
  }
}

// プレビュー用
struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(LocationSettingsManager())
    }
  }
}
