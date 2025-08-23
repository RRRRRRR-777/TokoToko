//
//  SettingsView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/20.
//

import FirebaseAuth
import SwiftUI

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
      Section(header: Text("アカウント")) {
        // UIテストモードの場合はモックユーザー情報を使用
        if isUITesting && hasUserInfo {
          // メールアドレス表示
          HStack {
            Text("メールアドレス")
            Spacer()
            Text(mockEmail ?? "test@example.com")
              .foregroundColor(.secondary)
          }

          // プロフィール画像表示（テスト用）
          HStack {
            Text("プロフィール画像")
            Spacer()
            Circle()
              .fill(Color.gray)
              .frame(width: 40, height: 40)
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
        }
        // 通常モードの場合は実際のユーザー情報を使用
        else if let user = Auth.auth().currentUser {
          HStack {
            Text("メールアドレス")
            Spacer()
            Text(user.email ?? "不明")
              .foregroundColor(.secondary)
          }

          if let photoURL = user.photoURL, let url = URL(string: photoURL.absoluteString) {
            HStack {
              Text("プロフィール画像")
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
        }
      }

      Section(header: Text("アプリ設定")) {
        Button(action: {
          Task {
            await loadCachedPolicy()
          }
          showingPolicyView = true
          selectedPolicyType = .privacyPolicy
        }) {
          Text("プライバシーポリシー")
            .foregroundColor(.primary)
        }

        Button(action: {
          Task {
            await loadCachedPolicy()
          }
          showingPolicyView = true
          selectedPolicyType = .termsOfService
        }) {
          Text("利用規約")
            .foregroundColor(.primary)
        }
      }

      Section(header: Text("位置情報")) {
        NavigationLink(destination: LocationAccuracySettingsView()
          .environmentObject(LocationSettingsManager.shared)) {
          HStack {
            Text("位置情報設定")
            Spacer()
            Text(LocationSettingsManager.shared.currentMode.displayName)
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
      }

      Section(header: Text("その他")) {
        NavigationLink(destination: AppInfoView()) {
          Text("このアプリについて")
        }
      }

      if let errorMessage = errorMessage {
        Section {
          Text(errorMessage)
            .foregroundColor(.red)
            .font(.caption)
        }
      }
    }
    .navigationTitle("設定")
    .alert("ログアウトしますか？", isPresented: $showingLogoutAlert) {
      Button("キャンセル", role: .cancel) {}
      Button("ログアウト", role: .destructive) {
        logout()
      }
    } message: {
      Text("アカウントからログアウトします。再度ログインする必要があります。")
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

// プレビュー用
struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SettingsView()
        .environmentObject(AuthManager())
    }
  }
}
