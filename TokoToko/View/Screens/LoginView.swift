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

/// Google Sign-Inを使用したログイン画面
///
/// `LoginView`はユーザー認証のためのログイン画面を提供します。
/// Google Sign-Inボタンとエラーハンドリング、UIテスト対応機能を統合しています。
/// 認証成功後はAuthManagerが自動的に状態更新を行います。
///
/// ## Overview
///
/// - **Google認証**: Google Sign-In SDKを使用したワンタップログイン
/// - **状態管理**: ローディング状態とエラーメッセージの表示制御
/// - **UIテスト対応**: 各種テストシナリオ用のモックデータ制御
/// - **エラーハンドリング**: 認証失敗時の適切なユーザーフィードバック
///
/// ## Topics
///
/// ### Properties
/// - ``authManager``
/// - ``isLoading``
/// - ``errorMessage``
/// - ``authService``
///
/// ### Methods
/// - ``signInWithGoogle()``
struct LoginView: View {
  /// 認証状態管理オブジェクト
  ///
  /// アプリ全体の認証状態を管理するAuthManagerのインスタンスです。
  /// 認証成功時にログイン状態が自動更新されます。
  @EnvironmentObject private var authManager: AuthManager
  
  /// ログイン処理のローディング状態
  ///
  /// Google Sign-In処理中はtrueになり、ローディングインジケーターを表示します。
  @State private var isLoading: Bool
  
  /// 認証エラーメッセージ
  ///
  /// 認証に失敗した場合のエラーメッセージを保持し、ユーザーに表示します。
  @State private var errorMessage: String?

  /// Google認証サービス
  ///
  /// Google Sign-In処理を担当するサービスクラスのインスタンスです。
  private let authService = GoogleAuthService()

  /// UIテスト実行中かどうかを判定
  ///
  /// プロセス引数から`--uitesting`フラグを検出してUIテストモードかどうかを判定します。
  private var isUITesting: Bool {
    ProcessInfo.processInfo.arguments.contains("--uitesting")
  }

  /// UIテスト用のエラー状態強制表示フラグ
  ///
  /// UIテスト実行時に認証エラー状態を強制的に表示するかどうかを判定します。
  private var shouldForceError: Bool {
    ProcessInfo.processInfo.arguments.contains("--force-error")
  }

  /// UIテスト用の強制エラータイプ
  ///
  /// UIテスト実行時に表示する特定のエラーメッセージタイプを取得します。
  private var forcedErrorType: String? {
    let args = ProcessInfo.processInfo.arguments
    if let index = args.firstIndex(of: "--error-type"), index + 1 < args.count {
      return args[index + 1]
    }
    return nil
  }

  /// UIテスト用のローディング状態強制表示フラグ
  ///
  /// UIテスト実行時にローディング状態を強制的に表示するかどうかを判定します。
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

  /// Google Sign-Inによる認証処理を実行
  ///
  /// GoogleAuthServiceを使用してGoogle Sign-In認証を開始します。
  /// 認証中はローディング状態を表示し、結果に応じて成功またはエラーを処理します。
  ///
  /// ## Process Flow
  /// 1. ローディング状態をtrueに設定
  /// 2. エラーメッセージをクリア
  /// 3. GoogleAuthService.signInWithGoogle()を呼び出し
  /// 4. 結果に応じてUI状態を更新
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
