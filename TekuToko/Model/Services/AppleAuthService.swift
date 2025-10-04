//
//  AppleAuthService.swift
//  TekuToko
//
//  Created by Claude on 2025/10/02.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation

/// Apple Sign-In認証サービス
///
/// Appleアカウントでのサインインを管理し、Firebase Authenticationと連携します。
/// Sign in with AppleのフローとFirebase認証を統合し、安全なユーザー認証を提供します。
///
/// ## Topics
///
/// ### Authentication Flow
/// - ``signInWithApple(completion:)``
///
/// ### Result Types
/// - ``AuthResult``
class AppleAuthService: NSObject {

  /// ログ出力用のEnhancedVibeLoggerインスタンス
  ///
  /// Apple認証フローの各段階での詳細ログ、エラー情報、デバッグ情報を記録します。
  private let logger = EnhancedVibeLogger.shared

  /// 認証完了コールバック
  ///
  /// Apple Sign-In完了時に呼び出されるクロージャを保持します。
  private var completionHandler: ((AuthResult) -> Void)?

  /// 現在の認証リクエストで使用するnonce値
  ///
  /// リプレイ攻撃を防ぐため、認証リクエストごとに一意のランダム文字列を生成して保持します。
  /// このnonce値のSHA256ハッシュをAppleに送信し、返されたID Tokenに含まれるnonceと照合することで、
  /// トークンの正当性を検証します。
  private var currentNonce: String?

  /// Apple認証処理の結果を表す列挙型
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
    /// Apple Sign-InとFirebase認証の両方が成功し、ユーザーがログイン状態になったことを示します。
    case success

    /// 認証が失敗した場合
    ///
    /// Apple Sign-InまたはFirebase認証でエラーが発生したことを示します。
    /// - Parameter String: ユーザーに表示するエラーメッセージ
    case failure(String)
  }

  /// Appleアカウントでのサインインを実行
  ///
  /// AuthenticationServicesフレームワークを使用してユーザーのAppleアカウント認証を行い、
  /// 取得した認証情報でFirebase Authenticationにサインインします。
  ///
  /// ## Process Flow
  ///
  /// 1. **リクエスト作成**: Apple ID認証リクエストの作成
  /// 2. **認証開始**: ASAuthorizationControllerでApple Sign-In開始
  /// 3. **認証情報取得**: ID Token と Authorization Codeの取得
  /// 4. **Firebase連携**: Firebase認証情報作成とサインイン
  ///
  /// ## Error Handling
  ///
  /// - 認証キャンセル: ユーザーがSign in with Appleをキャンセルした場合
  /// - 認証情報エラー: Apple認証情報の取得に失敗した場合
  /// - Firebase連携エラー: Firebase認証で問題が発生した場合
  ///
  /// ## Security Notes
  ///
  /// - ID Tokenとnonce値の安全な取り扱い
  /// - Firebase認証情報の暗号化された伝送
  /// - ユーザー情報のプライバシー保護（private relay対応）
  ///
  /// - Parameter completion: 認証結果を受け取るコールバック（成功またはエラーメッセージ）
  func signInWithApple(completion: @escaping (AuthResult) -> Void) {
    logger.logMethodStart()

    // コールバックを保持
    self.completionHandler = completion

    // Apple ID認証リクエストを作成
    let request = createAppleIDRequest()

    // 認証コントローラーを作成して開始
    performAppleSignIn(with: request)
  }

  /// Apple ID認証リクエストを作成
  ///
  /// フルネームとメールアドレスのスコープを要求し、リプレイ攻撃防止のためnonceを生成・設定します。
  /// - Returns: 設定済みのASAuthorizationAppleIDRequest
  private func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
    let nonce = randomNonceString()
    currentNonce = nonce

    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)

    logger.info(
      operation: "createAppleIDRequest",
      message: "Apple ID認証リクエスト作成完了",
      context: ["scopes": "fullName, email", "nonce_generated": "true"]
    )

    return request
  }

  /// Apple Sign-Inを実行
  ///
  /// ASAuthorizationControllerを使用してApple認証フローを開始します。
  /// - Parameter request: Apple ID認証リクエスト
  private func performAppleSignIn(with request: ASAuthorizationAppleIDRequest) {
    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    authorizationController.delegate = self
    authorizationController.presentationContextProvider = self
    authorizationController.performRequests()

    logger.info(
      operation: "performAppleSignIn",
      message: "Apple Sign In開始",
      context: ["controller_initialized": "true"]
    )
  }

  /// Firebase認証を実行
  ///
  /// AppleのID TokenとnonceからOAuthCredentialを作成し、Firebaseにサインインします。
  /// - Parameters:
  ///   - idToken: AppleのID Token文字列
  ///   - nonce: 認証リクエストで使用したnonce値
  ///   - displayName: ユーザーの表示名（オプション）
  private func signInWithFirebase(idToken: String, nonce: String, displayName: String?) {
    let credential = OAuthProvider.credential(
      providerID: .apple,
      idToken: idToken,
      rawNonce: nonce
    )

    logger.info(
      operation: "signInWithFirebase",
      message: "Firebase認証開始",
      context: ["credential_type": "apple"]
    )

    Auth.auth().signIn(with: credential) { [weak self] _, error in
      if let error = error {
        self?.logger.logError(
          error,
          operation: "signInWithFirebase",
          humanNote: "Firebase認証でエラー発生",
          aiTodo: "Firebase設定とネットワーク接続を確認"
        )
        self?.completionHandler?(.failure("Firebase認証エラー: \(error.localizedDescription)"))
        return
      }

      self?.logger.info(
        operation: "signInWithFirebase",
        message: "Firebase認証成功",
        context: ["display_name": displayName ?? "unknown"]
      )

      self?.logger.info(
        operation: "signInWithApple",
        message: "Apple認証プロセス完了",
        context: ["result": "success"]
      )

      self?.completionHandler?(.success)
    }
  }
}

// MARK: - ASAuthorizationControllerDelegate
// swiftlint:disable:next no_grouping_extension
extension AppleAuthService: ASAuthorizationControllerDelegate {

  /// Apple認証が成功した際のデリゲートメソッド
  ///
  /// - Parameter controller: ASAuthorizationController
  /// - Parameter authorization: 認証結果
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
    else {
      logger.warning(
        operation: "authorizationController",
        message: "Apple認証情報の取得に失敗",
        humanNote: "認証情報が不正です",
        aiTodo: "認証フローを確認"
      )
      completionHandler?(.failure("Apple認証情報の取得に失敗しました"))
      return
    }

    guard let idTokenData = appleIDCredential.identityToken,
      let idToken = String(data: idTokenData, encoding: .utf8)
    else {
      logger.warning(
        operation: "authorizationController",
        message: "ID Tokenの取得に失敗",
        humanNote: "ID Tokenが取得できません",
        aiTodo: "Apple認証設定を確認"
      )
      completionHandler?(.failure("ID Tokenの取得に失敗しました"))
      return
    }

    logger.info(
      operation: "authorizationController",
      message: "Apple認証成功",
      context: [
        "has_id_token": "true",
        "user_id": appleIDCredential.user
      ]
    )

    // 表示名の取得（初回ログイン時のみ利用可能）
    var displayName: String?
    if let fullName = appleIDCredential.fullName {
      let nameComponents = [fullName.givenName, fullName.familyName].compactMap { $0 }
      displayName = nameComponents.joined(separator: " ")
    }

    // Nonce検証
    guard let nonce = currentNonce else {
      logger.warning(
        operation: "authorizationController",
        message: "Nonceが見つかりません",
        humanNote: "セキュリティエラー",
        aiTodo: "Nonce生成処理を確認"
      )
      completionHandler?(.failure("認証エラーが発生しました"))
      return
    }

    // Firebase認証を実行
    signInWithFirebase(idToken: idToken, nonce: nonce, displayName: displayName)
  }

  /// Apple認証が失敗した際のデリゲートメソッド
  ///
  /// - Parameter controller: ASAuthorizationController
  /// - Parameter error: エラー情報
  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    logger.logError(
      error,
      operation: "authorizationController",
      humanNote: "Apple Sign Inでエラー発生",
      aiTodo: "エラー詳細を確認"
    )

    // ユーザーキャンセルの判定
    if let authError = error as? ASAuthorizationError, authError.code == .canceled {
      completionHandler?(.failure("ユーザーがログインをキャンセルしました"))
    } else {
      completionHandler?(.failure("Apple認証エラー: \(error.localizedDescription)"))
    }
  }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
// swiftlint:disable:next no_grouping_extension
extension AppleAuthService: ASAuthorizationControllerPresentationContextProviding {

  /// 認証UIを表示するウィンドウを返す
  ///
  /// - Parameter controller: ASAuthorizationController
  /// - Returns: 認証UIを表示するウィンドウ
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    else {
      logger.warning(
        operation: "presentationAnchor",
        message: "ウィンドウの取得に失敗",
        humanNote: "UIの準備ができていません",
        aiTodo: "UI状態を確認してください"
      )
      return ASPresentationAnchor()
    }

    return window
  }
}

// MARK: - Nonce Generation (Security)
// swiftlint:disable:next no_grouping_extension
extension AppleAuthService {

  /// ランダムなnonce文字列を生成
  ///
  /// リプレイ攻撃を防ぐため、認証リクエストごとに一意のランダム文字列を生成します。
  /// SecRandomCopyBytesを使用して暗号学的に安全な乱数を生成し、
  /// 指定された文字セットから文字列を構築します。
  ///
  /// ## Security Notes
  ///
  /// - SecRandomCopyBytesは暗号学的に安全な乱数生成器
  /// - 文字セットは英数字とハイフン、ピリオド、アンダースコアで構成
  /// - デフォルト長は32文字（256ビット相当のエントロピー）
  ///
  /// - Parameter length: 生成する文字列の長さ（デフォルト: 32）
  /// - Returns: ランダムなnonce文字列
  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
      let randoms: [UInt8] = (0..<16).map { _ in
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
          logger.logError(
            NSError(
              domain: "AppleAuthService",
              code: Int(errorCode),
              userInfo: [NSLocalizedDescriptionKey: "Unable to generate nonce"]
            ),
            operation: "randomNonceString",
            humanNote: "乱数生成に失敗しました",
            aiTodo: "SecRandomCopyBytesのエラーを確認"
          )
          fatalError(
            "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        return random
      }

      randoms.forEach { random in
        if remainingLength == 0 {
          return
        }
        if random < charset.count {
          result.append(charset[Int(random)])
          remainingLength -= 1
        }
      }
    }

    return result
  }

  /// 文字列のSHA256ハッシュ値を計算
  ///
  /// CryptoKitのSHA256を使用して、入力文字列のハッシュ値を16進数文字列として返します。
  /// このハッシュ値はAppleに送信され、返されたID Tokenに含まれるnonce値と照合されます。
  ///
  /// ## Security Notes
  ///
  /// - SHA256は暗号学的に安全なハッシュ関数
  /// - 一方向性: ハッシュ値から元の文字列を復元できない
  /// - 衝突耐性: 異なる入力から同じハッシュ値が生成される確率が極めて低い
  ///
  /// - Parameter input: ハッシュ化する文字列
  /// - Returns: SHA256ハッシュ値の16進数表現
  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()

    return hashString
  }
}
