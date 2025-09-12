//
//  TestingProtocols.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/05/23.
//

import Foundation

/// UIテスト関連の機能を提供するプロトコル
///
/// `UITestingProvider`はUIテスト環境とプロダクション環境で異なる動作を
/// 実現するためのプロトコルです。Strategy パターンを使用して、環境に応じた
/// 適切なモック動作を提供します。
///
/// ## Overview
///
/// - **環境分離**: テスト用とプロダクション用で異なる実装を提供
/// - **モック制御**: ログイン状態、ディープリンク等の制御
/// - **拡張性**: 新しいテスト機能を追加しやすい設計
///
/// ## Topics
///
/// ### Required Properties
/// - ``isUITesting``
/// - ``isMockLoggedIn``
/// - ``hasDeepLink``
/// - ``deepLinkDestination``
public protocol UITestingProvider {
  /// UIテストモードかどうかの判定
  ///
  /// 現在の環境がUIテスト実行中かどうかを示します。
  var isUITesting: Bool { get }

  /// UIテスト用のモックログイン状態
  ///
  /// UIテスト時に使用するログイン状態のモック値です。
  /// テストシナリオに応じてログイン済み状態をシミュレートします。
  var isMockLoggedIn: Bool { get }

  /// ディープリンクの存在判定
  ///
  /// UIテスト時に特定の画面への直接ナビゲーションが
  /// 設定されているかどうかを判定します。
  var hasDeepLink: Bool { get }

  /// ディープリンクの遷移先情報
  ///
  /// UIテスト時の直接ナビゲーション先を示す文字列です。
  /// 設定されていない場合はnilを返します。
  var deepLinkDestination: String? { get }

  /// オンボーディング状態のリセット要求
  ///
  /// UIテスト時にオンボーディング状態をリセットするかの判定です。
  /// プロダクション環境では常にfalseを返します。
  var shouldResetOnboarding: Bool { get }

  /// オンボーディング強制表示要求
  ///
  /// UIテスト時にオンボーディングを強制的に表示するかの判定です。
  /// プロダクション環境では常にfalseを返します。
  var shouldShowOnboarding: Bool { get }
}

/// 本番環境用のUITestingProvider実装
///
/// `ProductionUITestingProvider`は通常のアプリケーション実行時に使用される
/// プロバイダー実装です。すべてのテスト関連フラグをfalse/nilに設定し、
/// モック動作を無効化します。
///
/// ## Overview
///
/// - **テスト機能無効**: すべてのUIテスト機能を無効化
/// - **通常動作**: プロダクション環境での標準動作を保証
/// - **安全性**: テストコードが本番環境で実行されることを防止
///
/// ## Topics
///
/// ### UITestingProvider Conformance
/// - ``isUITesting``
/// - ``isMockLoggedIn``
/// - ``hasDeepLink``
/// - ``deepLinkDestination``
public class ProductionUITestingProvider: UITestingProvider {
  /// 常にfalseを返すUIテストモード判定
  public var isUITesting: Bool { false }

  /// 常にfalseを返すモックログイン状態
  public var isMockLoggedIn: Bool { false }

  /// 常にfalseを返すディープリンク存在判定
  public var hasDeepLink: Bool { false }

  /// 常にnilを返すディープリンク遷移先
  public var deepLinkDestination: String? { nil }

  /// 常にfalseを返すオンボーディング状態リセット要求
  public var shouldResetOnboarding: Bool { false }

  /// 常にfalseを返すオンボーディング強制表示要求
  public var shouldShowOnboarding: Bool { false }

  /// ProductionUITestingProviderの初期化メソッド
  public init() {}
}

/// UIテスト環境用のUITestingProvider実装
///
/// `UITestUITestingProvider`はUIテスト実行時に使用されるプロバイダー実装です。
/// プロセス引数を解析してテストシナリオに応じたモック動作を提供します。
///
/// ## Overview
///
/// - **引数解析**: プロセス引数からテスト設定を動的に取得
/// - **モック制御**: ログイン状態やディープリンクの柔軟な制御
/// - **テストサポート**: 複数の引数形式に対応した堅牢な解析
///
/// ## Supported Arguments
/// - `--logged-in`, `MOCK_LOGGED_IN`: モックログイン状態を有効化
/// - `--deep-link`, `--destination`: ディープリンク機能を有効化
/// - `DEEP_LINK_DESTINATION_*`: 特定の遷移先を設定
///
/// ## Topics
///
/// ### UITestingProvider Conformance
/// - ``isUITesting``
/// - ``isMockLoggedIn``
/// - ``hasDeepLink``
/// - ``deepLinkDestination``
public class UITestUITestingProvider: UITestingProvider {
  /// 常にtrueを返すUIテストモード判定
  public var isUITesting: Bool { true }

  /// プロセス引数に基づくモックログイン状態判定
  ///
  /// `--logged-in` または `MOCK_LOGGED_IN` 引数の存在をチェックして
  /// モックログイン状態を決定します。
  public var isMockLoggedIn: Bool {
    let args = ProcessInfo.processInfo.arguments
    return args.contains("--logged-in") || args.contains("MOCK_LOGGED_IN")
  }

  /// プロセス引数に基づくディープリンク存在判定
  ///
  /// 複数の引数形式をサポートしてディープリンク設定の存在をチェックします。
  /// - `--deep-link`: 基本的なディープリンクフラグ
  /// - `--destination`: 具体的な遷移先指定
  /// - `DEEP_LINK_DESTINATION_*`: プレフィックス形式での遷移先指定
  public var hasDeepLink: Bool {
    let args = ProcessInfo.processInfo.arguments
    return args.contains("--deep-link") || args.contains("--destination")
      || args.contains { $0.hasPrefix("DEEP_LINK_DESTINATION_") }
  }

  /// プロセス引数からディープリンク遷移先を抽出
  ///
  /// 複数の引数形式から遷移先情報を解析して返します。
  /// 優先順位: `--destination` > `DEEP_LINK_DESTINATION_*`
  ///
  /// ## Argument Formats
  /// - `--destination <target>`: 次の引数を遷移先として使用
  /// - `DEEP_LINK_DESTINATION_<target>`: プレフィックス形式で遷移先を指定
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

  /// プロセス引数に基づくオンボーディング状態リセット要求判定
  ///
  /// `--reset-onboarding` 引数の存在をチェックして
  /// オンボーディング状態リセットの必要性を決定します。
  public var shouldResetOnboarding: Bool {
    let args = ProcessInfo.processInfo.arguments
    return args.contains("--reset-onboarding")
  }

  /// プロセス引数に基づくオンボーディング強制表示要求判定
  ///
  /// `--show-onboarding` 引数の存在をチェックして
  /// オンボーディング強制表示の必要性を決定します。
  public var shouldShowOnboarding: Bool {
    let args = ProcessInfo.processInfo.arguments
    return args.contains("--show-onboarding")
  }

  /// UITestUITestingProviderの初期化メソッド
  public init() {}
}
