//
//  LoginView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/20.
//

import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct LoginView: View {
  @EnvironmentObject private var authManager: AuthManager
  @State private var isLoading: Bool
  @State private var errorMessage: String?

  private let authService = GoogleAuthService()

  // UIテスト用のフラグ
  private var isUITesting: Bool {
    ProcessInfo.processInfo.arguments.contains("--uitesting")
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

  // UIテスト用のローディング状態強制表示フラグ
  private var shouldForceLoading: Bool {
    ProcessInfo.processInfo.arguments.contains("--force-loading-state")
  }

  init() {
    // UIテストモードの場合
    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
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
      _isLoading = State(initialValue: false)
    }
  }

  var body: some View {
    VStack(spacing: 20) {
      Spacer()

      Image(systemName: "mappin.and.ellipse")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 100, height: 100)
        .foregroundColor(.blue)

      Text("TokoTokoへようこそ")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("位置情報を共有して、友達と繋がりましょう")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Spacer()

      if isLoading {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(1.5)
      } else {
        GoogleSignInButton(style: .wide, action: signInWithGoogle)
          .padding(.horizontal)
      }

      if let errorMessage = errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
      }

      Spacer()
    }
    .padding()
    // アプリレベルでログイン状態を管理するため、onAppearでの処理は不要
  }

  private func signInWithGoogle() {
    isLoading = true
    errorMessage = nil

    authService.signInWithGoogle { result in
      DispatchQueue.main.async {
        self.isLoading = false

        switch result {
        case .success:
          // 認証成功 - AuthManagerのリスナーが自動的にログイン状態を更新する
          break
        case .failure(let message):
          self.errorMessage = message
        }
      }
    }
  }
}

#Preview {
  LoginView()
    .environmentObject(AuthManager())
}
