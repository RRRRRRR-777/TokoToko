//
//  SettingsView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/20.
//

import FirebaseAuth
import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var authManager: AuthManager
  @State private var showingLogoutAlert: Bool
  @State private var isLoading: Bool
  @State private var errorMessage: String?

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
  private var mockUser: User? {
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
  }

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
