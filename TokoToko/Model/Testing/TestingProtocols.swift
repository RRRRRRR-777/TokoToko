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
  public var isMockLoggedIn: Bool {
    let args = ProcessInfo.processInfo.arguments
    return args.contains("--logged-in") || args.contains("MOCK_LOGGED_IN")
  }
  public var hasDeepLink: Bool {
    let args = ProcessInfo.processInfo.arguments
    return args.contains("--deep-link") || args.contains("--destination")
      || args.contains(where: { $0.hasPrefix("DEEP_LINK_DESTINATION_") })
  }

  public var deepLinkDestination: String? {
    let args = ProcessInfo.processInfo.arguments
    if let index = args.firstIndex(of: "--destination"), index + 1 < args.count {
      return args[index + 1]
    }
    // DEEP_LINK_DESTINATION_walk 形式の引数を探す
    if let deepLinkArg = args.first(where: { $0.hasPrefix("DEEP_LINK_DESTINATION_") }) {
      return String(deepLinkArg.dropFirst("DEEP_LINK_DESTINATION_".count))
    }
    return nil
  }

  public init() {}
}
