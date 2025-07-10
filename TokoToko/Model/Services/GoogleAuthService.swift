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
import GoogleSignInSwift
import UIKit

/// Google認証に関連する処理を担当するサービスクラス
class GoogleAuthService {

  // ログ
  private let logger = EnhancedVibeLogger.shared

  /// Google認証の結果を表すenum
  enum AuthResult {
    case success
    case failure(String)
  }

  /// Google認証を実行する
  /// - Parameter completion: 認証結果を返すコールバック
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
          "has_access_token": "true",
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
          "credential_type": "google",
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
            "display_name": user.profile?.name ?? "unknown",
          ]
        )

        self?.logger.info(
          operation: "signInWithGoogle",
          message: "Google認証プロセス完了",
          context: [
            "result": "success",
            "firebase_uid": authResult?.user.uid ?? "unknown",
          ]
        )

        completion(.success)
      }
    }
  }
}
