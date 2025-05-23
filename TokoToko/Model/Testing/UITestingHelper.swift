//
//  UITestingHelper.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/23.
//

import Foundation

/// UIテスト関連のロジックを集約するヘルパークラス
public class UITestingHelper {

  /// シングルトンインスタンス
  public static let shared = UITestingHelper()

  /// UIテスト機能のプロバイダー
  private let provider: UITestingProvider

  /// 初期化時にUIテストモードかどうかを判定し、適切なプロバイダーを設定
  private init() {
    let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
    provider = isUITesting ? UITestUITestingProvider() : ProductionUITestingProvider()
  }

  /// テスト用の初期化メソッド（依存性注入用）
  init(provider: UITestingProvider) {
    self.provider = provider
  }

  /// UIテストモードかどうか
  public var isUITesting: Bool {
    provider.isUITesting
  }

  /// UIテスト用のモックログイン状態
  public var isMockLoggedIn: Bool {
    provider.isMockLoggedIn
  }

  /// ディープリンクが指定されているかどうか
  public var hasDeepLink: Bool {
    provider.hasDeepLink
  }

  /// ディープリンク先の取得
  public var deepLinkDestination: String? {
    provider.deepLinkDestination
  }
}
