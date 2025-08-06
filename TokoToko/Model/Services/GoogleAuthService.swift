//
//  GoogleAuthService.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/20.
//

import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import UIKit

/// Google認証とFirebase Authenticationの統合を管理するサービスクラス
///
/// `GoogleAuthService`はGoogle Sign-In SDKとFirebase Authenticationを組み合わせ、
/// ユーザーのGoogleアカウントでのサインイン機能を提供します。
///
/// ## Overview
///
/// 主要な機能：
/// - **Google Sign-In統合**: Googleアカウントでの認証フロー
/// - **Firebase連携**: Google認証情報でFirebaseにサインイン
/// - **エラーハンドリング**: 包括的なエラー管理とユーザーフィードバック
/// - **セキュリティ**: トークンと認証情報の安全な処理
///
/// ## Authentication Flow
///
/// 1. Firebase設定のClient ID取得
/// 2. Google Sign-In設定とUIプレゼンテーション
/// 3. Googleユーザー認証とトークン取得
/// 4. Firebase認証情報の作成とサインイン
///
/// ## Topics
///
/// ### Authentication
/// - ``signInWithGoogle(completion:)``
///
/// ### Result Types
/// - ``AuthResult``
class GoogleAuthService {

  /// ログ出力用のEnhancedVibeLoggerインスタンス
  ///
  /// Google認証フローの各段階での詳細ログ、エラー情報、デバッグ情報を記録します。
  private let logger = EnhancedVibeLogger.shared

  /// Google認証処理の結果を表す列挙型
  ///
  /// 認証の成功または失敗を表現し、失敗時はユーザー向けエラーメッセージを含みます。
  ///
  /// ## Topics
  ///
  /// ### Cases
  /// - ``success``
  /// - ``failure(_:)``
  enum AuthResult {
    /// 認証が成功した場合
    ///
    /// GoogleサインインとFirebase認証の両方が成功し、ユーザーがログイン状態になったことを示します。
    case success

    /// 認証が失敗した場合
    ///
    /// GoogleサインインまたはFirebase認証でエラーが発生したことを示します。
    /// - Parameter String: ユーザーに表示するエラーメッセージ
    case failure(String)
  }

  /// Googleアカウントでのサインインを実行
  ///
  /// Google Sign-In SDKを使用してユーザーのGoogleアカウント認証を行い、
  /// 取得した認証情報でFirebase Authenticationにサインインします。
  ///
  /// ## Process Flow
  ///
  /// 1. **設定検証**: Firebase Client IDの取得と検証
  /// 2. **UI準備**: 現在のWindowとRootViewControllerの取得
  /// 3. **Google認証**: Google Sign-Inフローの開始
  /// 4. **トークン取得**: IDトークンとアクセストークンの取得
  /// 5. **Firebase連携**: Firebase認証情報作成とサインイン
  ///
  /// ## Error Handling
  ///
  /// - Firebase設定エラー: GoogleService-Info.plistの不備や破損
  /// - UIエラー: WindowシーンやRootViewControllerの取得失敗
  /// - ネットワークエラー: インターネット接続の問題
  /// - 認証エラー: GoogleまたはFirebase認証の失敗
  ///
  /// ## Security Notes
  ///
  /// - IDトークンとアクセストークンの安全な取り扱い
  /// - Firebase認証情報の暗号化された传送
  /// - ユーザー情報のプライバシー保護
  ///
  /// - Parameter completion: 認証結果を受け取るコールバック（成功またはエラーメッセージ）
  func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
    logger.logMethodStart()

    guard let clientID = FirebaseApp.app()?.options.clientID else {
      logger.logError(
        NSError(
          domain: "GoogleAuthService", code: 1001,
          userInfo: [NSLocalizedDescriptionKey: "Firebase設定エラー"]),
        operation: "signInWithGoogle",
        humanNote: "Firebase設定の取得に失敗",
        aiTodo: "GoogleService-Info.plistの設定を確認"
      )
      completion(.failure("Firebase設定エラー"))
      return
    }

    logger.info(
      operation: "signInWithGoogle",
      message: "Google認証開始",
      context: ["client_id_exists": "true"]
    )

    // Google Sign In configuration
    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config

    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let rootViewController = windowScene.windows.first?.rootViewController
    else {
      logger.warning(
        operation: "signInWithGoogle",
        message: "ウィンドウシーンの取得に失敗",
        humanNote: "UIの準備ができていません",
        aiTodo: "UI状態を確認してください"
      )
      completion(.failure("ウィンドウシーンの取得に失敗しました"))
      return
    }

    logger.info(
      operation: "signInWithGoogle",
      message: "Google Sign In開始",
      context: ["has_root_view_controller": "true"]
    )

    // Start the sign in flow
    GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) {
      [weak self] result, error in
      if let error = error {
        self?.logger.logError(
          error,
          operation: "signInWithGoogle:googleSignIn",
          humanNote: "Google Sign Inプロセスでエラー発生",
          aiTodo: "ネットワーク接続とGoogle設定を確認"
        )
        completion(.failure("Googleログインエラー: \(error.localizedDescription)"))
        return
      }

      guard let user = result?.user,
        let idToken = user.idToken?.tokenString
      else {
        self?.logger.warning(
          operation: "signInWithGoogle:googleSignIn",
          message: "ユーザー情報の取得に失敗",
          humanNote: "Google Sign Inの結果が不正",
          aiTodo: "Google Sign Inの設定を確認"
        )
        completion(.failure("ユーザー情報の取得に失敗しました"))
        return
      }

      self?.logger.info(
        operation: "signInWithGoogle:googleSignIn",
        message: "Google Sign In成功",
        context: [
          "user_id": user.userID ?? "unknown",
          "user_email": user.profile?.email ?? "unknown",
          "has_id_token": "true",
          "has_access_token": "true"
        ]
      )

      // Firebaseの認証情報を作成
      let credential = GoogleAuthProvider.credential(
        withIDToken: idToken,
        accessToken: user.accessToken.tokenString)

      self?.logger.info(
        operation: "signInWithGoogle:firebaseAuth",
        message: "Firebase認証開始",
        context: [
          "user_id": user.userID ?? "unknown",
          "credential_type": "google"
        ]
      )

      // Firebaseで認証
      Auth.auth().signIn(with: credential) { [weak self] authResult, error in
        if let error = error {
          self?.logger.logError(
            error,
            operation: "signInWithGoogle:firebaseAuth",
            humanNote: "Firebase認証でエラー発生",
            aiTodo: "Firebase設定とネットワーク接続を確認"
          )
          completion(.failure("Firebase認証エラー: \(error.localizedDescription)"))
          return
        }

        // 認証成功
        self?.logger.info(
          operation: "signInWithGoogle:firebaseAuth",
          message: "Firebase認証成功",
          context: [
            "user_id": user.userID ?? "unknown",
            "firebase_uid": authResult?.user.uid ?? "unknown",
            "user_email": user.profile?.email ?? "unknown",
            "display_name": user.profile?.name ?? "unknown"
          ]
        )

        self?.logger.info(
          operation: "signInWithGoogle",
          message: "Google認証プロセス完了",
          context: [
            "result": "success",
            "firebase_uid": authResult?.user.uid ?? "unknown"
          ]
        )

        completion(.success)
      }
    }
  }
}
