//
//  AppConfig.swift
//  TekuToko
//
//  Created by Assistant on 2025/12/01.
//

import Foundation

/// アプリケーション設定を管理する構造体
/// xcconfigで定義された値をInfo.plist経由で取得する
enum AppConfig {

  // MARK: - Environment

  /// アプリケーション環境
  enum Environment: String {
    /// ローカル開発環境（localhost）
    case debug
    /// GKE開発環境
    case development
    /// GKEステージング環境
    case staging
    /// GKE本番環境
    case release
  }

  // MARK: - Private Constants

  private enum Keys {
    static let apiBaseURL = "API_BASE_URL"
    static let appEnv = "APP_ENV"
    static let useGoBackend = "USE_GO_BACKEND"
  }

  // MARK: - Environment

  /// 現在の環境（Info.plistから取得）
  static var currentEnvironment: Environment {
    guard let envString = Bundle.main.object(forInfoDictionaryKey: Keys.appEnv) as? String,
      let env = Environment(rawValue: envString)
    else {
      fatalError("APP_ENV not configured in Info.plist")
    }
    return env
  }

  // MARK: - Base URL

  /// APIベースURL（Info.plistから取得）
  static var baseURL: URL {
    guard let urlString = Bundle.main.object(forInfoDictionaryKey: Keys.apiBaseURL) as? String,
      let url = URL(string: urlString)
    else {
      fatalError("API_BASE_URL not configured in Info.plist")
    }
    return url
  }

  // MARK: - Feature Flags

  /// Goバックエンドを使用するかどうかのフラグ（Info.plistから取得）
  /// - true: Goバックエンド（REST API）を使用
  /// - false: Firebase（Firestore）を使用（デフォルト）
  static var useGoBackend: Bool {
    Bundle.main.object(forInfoDictionaryKey: Keys.useGoBackend) as? String == "YES"
  }
}
