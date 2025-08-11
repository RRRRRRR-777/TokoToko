//
//  FirebaseAuthHelper.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/28.
//

import FirebaseAuth
import Foundation

/// Firebase認証処理の共通ヘルパークラス
///
/// WalkManagerとWalkRepositoryで重複していた認証チェック処理を統合し、
/// 一貫性のある認証処理を提供します。
class FirebaseAuthHelper {

    /// 認証エラーの種類
    enum AuthError: LocalizedError {
        case userNotAuthenticated
        case tokenRetrievalFailed(Error)
        case tokenInvalid

        var errorDescription: String? {
            switch self {
            case .userNotAuthenticated:
                return "ユーザーが認証されていません"
            case .tokenRetrievalFailed(let error):
                return "認証トークンの取得に失敗しました: \(error.localizedDescription)"
            case .tokenInvalid:
                return "認証トークンが無効です"
            }
        }
    }

    /// 現在の認証済みユーザーIDを取得
    ///
    /// - Returns: ユーザーID、または未認証の場合はnil
    static func getCurrentUserId() -> String? {
        Auth.auth().currentUser?.uid
    }

    /// 認証状態と有効な認証トークンを確認
    ///
    /// - Parameter completion: 認証結果のコールバック（ユーザーIDまたはエラー）
    static func validateAuthenticationWithToken(completion: @escaping (Result<String, AuthError>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            #if DEBUG
                print("❌ Firebase認証: currentUser が nil")
            #endif
            completion(.failure(.userNotAuthenticated))
            return
        }

        let userId = currentUser.uid

        // 認証トークンの有効性確認
        currentUser.getIDTokenResult { tokenResult, error in
            if let error = error {
                #if DEBUG
                    print("❌ Firebase認証: 認証トークン取得エラー - \(error.localizedDescription)")
                #endif
                completion(.failure(.tokenRetrievalFailed(error)))
                return
            }

            guard let token = tokenResult else {
                #if DEBUG
                    print("❌ Firebase認証: 認証トークンが無効")
                #endif
                completion(.failure(.tokenInvalid))
                return
            }

            #if DEBUG
                print("✅ Firebase認証: トークン確認済み")
                print("   有効期限: \(token.expirationDate)")
            #endif

            completion(.success(userId))
        }
    }

    /// 認証状態のシンプルチェック（トークン検証なし）
    ///
    /// - Returns: 認証済みの場合はユーザーID、未認証の場合はエラー
    static func requireAuthentication() -> Result<String, AuthError> {
        guard let userId = getCurrentUserId() else {
            return .failure(.userNotAuthenticated)
        }
        return .success(userId)
    }
}
