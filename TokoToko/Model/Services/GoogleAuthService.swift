//
//  GoogleAuthService.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/20.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore
import UIKit

/// Google認証に関連する処理を担当するサービスクラス
class GoogleAuthService {

    /// Google認証の結果を表すenum
    enum AuthResult {
        case success
        case failure(String)
    }

    /// Google認証を実行する
    /// - Parameter completion: 認証結果を返すコールバック
    func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure("Firebase設定エラー"))
            return
        }

        // Google Sign In configuration
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(.failure("ウィンドウシーンの取得に失敗しました"))
            return
        }

        // Start the sign in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                completion(.failure("Googleログインエラー: \(error.localizedDescription)"))
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure("ユーザー情報の取得に失敗しました"))
                return
            }

            // Firebaseの認証情報を作成
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            // Firebaseで認証
            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    completion(.failure("Firebase認証エラー: \(error.localizedDescription)"))
                    return
                }

                // 認証成功
                completion(.success)
            }
        }
    }
}
