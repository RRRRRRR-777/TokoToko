//
//  TestingProtocols.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/23.
//

import Foundation

/// UIテスト関連の機能を提供するプロトコル
public protocol UITestingProvider {
  /// UIテストモードかどうか
  var isUITesting: Bool { get }

  /// UIテスト用のモックログイン状態
  var isMockLoggedIn: Bool { get }

  /// ディープリンクが指定されているかどうか
  var hasDeepLink: Bool { get }

  /// ディープリンク先の取得
  var deepLinkDestination: String? { get }
}

/// 本番環境用のUIテストプロバイダー実装
public class ProductionUITestingProvider: UITestingProvider {
  public var isUITesting: Bool { false }
  public var isMockLoggedIn: Bool { false }
  public var hasDeepLink: Bool { false }
  public var deepLinkDestination: String? { nil }

  public init() {}
}

/// UIテスト環境用のUIテストプロバイダー実装
public class UITestUITestingProvider: UITestingProvider {
  public var isUITesting: Bool { true }
  public var isMockLoggedIn: Bool { ProcessInfo.processInfo.arguments.contains("--logged-in") }
  public var hasDeepLink: Bool { ProcessInfo.processInfo.arguments.contains("--deep-link") }

  public var deepLinkDestination: String? {
    let args = ProcessInfo.processInfo.arguments
    if let index = args.firstIndex(of: "--destination"), index + 1 < args.count {
      return args[index + 1]
    }
    return nil
  }

  public init() {}
}
