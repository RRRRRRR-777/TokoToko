//
//  FirebaseConfigurator.swift
//  TekuToko
//
//  Created by Assistant on 2025/09/09.
//

import FirebaseCore
import Foundation

enum FirebaseConfigurator {
  /// GoogleService-Info.plist の内容が有効な場合のみ Firebase を初期化する
  /// - Returns: 初期化が実行され有効になった場合は true、そうでなければ false
  @discardableResult
  static func configureIfValid() -> Bool {
    // すでに初期化済みなら何もしない
    if FirebaseApp.app() != nil { return true }

    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path)
    else {
      return false
    }

    // API Key 最低限のバリデーション（FirebaseInstallationsの要件に沿う）
    // apiKey は SDK バージョンにより Optional のことがあるため安全に unwrap
    guard let apiKey = options.apiKey, !apiKey.isEmpty, isValidAPIKey(apiKey) else {
      return false
    }

    FirebaseApp.configure(options: options)
    return true
  }

  /// Firebase API Key の簡易バリデーション
  private static func isValidAPIKey(_ key: String) -> Bool {
    // iOS用API Keyは通常 A で始まり 39文字
    guard key.hasPrefix("A") else { return false }
    return key.count == 39
  }
}
