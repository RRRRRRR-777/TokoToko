//
//  ConsentManager.swift
//  TekuToko
//
//  Created by Claude on 2025/08/03.
//

import FirebaseAuth
import Foundation
import SwiftUI

/// アプリ全体の同意状態を管理するObservableObjectクラス
///
/// `ConsentManager`は初回同意フローと再同意フローを管理し、
/// アプリケーションの適切な画面遷移を制御します。
/// PolicyServiceと連携してポリシーの取得と同意記録を行います。
///
/// ## Overview
///
/// - **同意状態管理**: 初回同意と再同意の必要性を判定
/// - **ポリシー管理**: 最新ポリシーの取得とキャッシュ
/// - **画面遷移制御**: 同意状態に基づく適切な画面表示
/// - **エラーハンドリング**: ネットワークエラーや取得失敗への対応
///
/// ## Topics
///
/// ### Published Properties
/// - ``isLoading``
/// - ``currentPolicy``
/// - ``error``
/// - ``hasValidConsent``
///
/// ### Methods
/// - ``loadInitialState()``
/// - ``needsInitialConsent()``
/// - ``needsReConsent()``
/// - ``recordConsent(_:)``
@MainActor
class ConsentManager: ObservableObject {
  /// ポリシー読み込み中かどうか
  @Published var isLoading = false

  /// 現在のポリシー情報
  @Published var currentPolicy: Policy?

  /// エラー情報
  @Published var error: Error?

  /// 有効な同意があるかどうか
  @Published var hasValidConsent = false

  /// PolicyServiceのインスタンス
  private let policyService = PolicyService()

  /// UIテストヘルパーへの参照
  private let testingHelper = UITestingHelper.shared

  init() {
    Task {
      await loadInitialState()
    }
  }

  /// 定期的な再同意チェック
  ///
  /// アプリがアクティブになった際などに呼び出して、
  /// ポリシーの更新による再同意の必要性をチェックします。
  func checkForReConsentNeeded() async {
    guard !isLoading else {
      return
    }

    // UIテストモードの場合は何もしない
    if testingHelper.isUITesting {
      return
    }

    // 最新ポリシーを取得
    do {
      let latestPolicy = try await policyService.fetchPolicy()

      // 現在のポリシーと比較
      if let currentPolicy = currentPolicy,
        latestPolicy.version != currentPolicy.version
      {
        // バージョンが異なる場合は再同意が必要
        self.currentPolicy = latestPolicy
        hasValidConsent = false
      }
    } catch {
      // エラーは無視（ネットワークエラー等）
    }
  }

  /// 初期状態の読み込み
  ///
  /// アプリ起動時に現在のポリシーと同意状態を確認します。
  /// ネットワークエラーの場合はキャッシュされたポリシーを使用します。
  func loadInitialState() async {
    isLoading = true
    error = nil

    // UIテストモードの場合は即座に同意済み状態にする
    if testingHelper.isUITesting {
      // テスト用のデフォルトポリシーを設定
      currentPolicy = Policy(
        version: "1.0.0",
        privacyPolicy: LocalizedContent(
          ja: "UIテスト用プライバシーポリシー",
          en: "UI Test Privacy Policy"
        ),
        termsOfService: LocalizedContent(
          ja: "UIテスト用利用規約",
          en: "UI Test Terms of Service"
        ),
        updatedAt: Date(),
        effectiveDate: Date()
      )
      hasValidConsent = true
      isLoading = false
      return
    }

    do {
      // 現在のポリシーを取得
      currentPolicy = try await policyService.fetchPolicy()

      // 同意状態を確認
      hasValidConsent = await policyService.hasValidConsent()

    } catch {
      // DEBUGビルドでは、エラーをログに記録するがアプリは継続
      #if DEBUG
        print("ConsentManager: ポリシー取得エラー: \(error)")
        // テスト用のデフォルトポリシーを使用
        currentPolicy = Policy(
          version: "1.0.0",
          privacyPolicy: LocalizedContent(
            ja: "テスト用プライバシーポリシー",
            en: "Test Privacy Policy"
          ),
          termsOfService: LocalizedContent(
            ja: "テスト用利用規約",
            en: "Test Terms of Service"
          ),
          updatedAt: Date(),
          effectiveDate: Date()
        )
        // テスト環境では初回同意を要求しない
        hasValidConsent = true
      #else
        // 本番環境ではエラーを保持
        self.error = error

        // エラーの場合はキャッシュされたポリシーを試行
        if let cachedPolicy = try? await policyService.getCachedPolicy() {
          currentPolicy = cachedPolicy
          hasValidConsent = await policyService.hasValidConsent()
        }
      #endif
    }

    isLoading = false
  }

  /// 初回同意が必要かどうか
  ///
  /// - Returns: 初回同意が必要な場合はtrue
  func needsInitialConsent() async -> Bool {
    !hasValidConsent
  }

  /// 再同意が必要かどうか
  ///
  /// ポリシーのバージョンが更新されている場合に再同意が必要になります。
  /// - Returns: 再同意が必要な場合はtrue
  func needsReConsent() async -> Bool {
    guard let policy = currentPolicy else {
      return false
    }

    let hasConsent = await policyService.hasValidConsent()
    if !hasConsent {
      return false
    }

    // 現在の同意がポリシーバージョンと一致しているかチェック
    return await policyService.needsReConsent(for: policy.version)
  }

  /// 同意を記録する
  ///
  /// - Parameter consentType: 同意の種類（プライバシーポリシーのみ、利用規約のみ、または両方）
  func recordConsent(_ consentType: ConsentType) async throws {
    guard let policy = currentPolicy else {
      throw ConsentError.noPolicyAvailable
    }

    let deviceInfo = DeviceInfo(
      platform: "iOS",
      osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
      appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    )

    #if DEBUG
      // テスト環境では同意を記録
      UserDefaults.standard.set(true, forKey: "test_has_consent")
    #else
      // 本番環境ではFirestoreに記録
      guard let userID = getCurrentUserID() else {
        throw ConsentError.consentRecordingFailed
      }

      try await policyService.recordConsent(
        policyVersion: policy.version,
        userID: userID,
        consentType: consentType,
        deviceInfo: deviceInfo
      )
    #endif

    // 同意状態を更新
    hasValidConsent = await policyService.hasValidConsent()
  }

  /// 現在のユーザーIDを取得
  private func getCurrentUserID() -> String? {
    #if DEBUG
      return "test_user"
    #else
      // 本番環境ではFirebase Authから取得
      return FirebaseAuth.Auth.auth().currentUser?.uid
    #endif
  }

  /// ポリシーを再読み込みする
  ///
  /// 手動でポリシーの最新版を取得したい場合に使用します。
  func refreshPolicy() async {
    await loadInitialState()
  }
}

/// 同意管理に関するエラー
enum ConsentError: LocalizedError {
  case noPolicyAvailable
  case networkError(Error)
  case consentRecordingFailed

  var errorDescription: String? {
    switch self {
    case .noPolicyAvailable:
      return "ポリシー情報が利用できません"
    case .networkError(let error):
      return "ネットワークエラー: \(error.localizedDescription)"
    case .consentRecordingFailed:
      return "同意の記録に失敗しました"
    }
  }
}
