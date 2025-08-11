//
//  UITestingHelper.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/23.
//

import Foundation

/// UIテスト関連のロジックを集約するヘルパークラス
///
/// `UITestingHelper`はUIテストの実行環境を検出し、テストモードに応じた
/// 適切なモック動作を提供するシングルトンクラスです。プロダクション環境と
/// テスト環境で異なる動作を実現するためのプロバイダーパターンを採用しています。
///
/// ## Overview
///
/// - **環境検出**: プロセス引数からUIテストモードを自動検出
/// - **プロバイダー切り替え**: テスト用・本番用プロバイダーの自動選択
/// - **モック機能**: ログイン状態、ディープリンク等のモック制御
/// - **依存性注入**: テスト用の初期化メソッドでプロバイダーを注入可能
///
/// ## Topics
///
/// ### Singleton
/// - ``shared``
///
/// ### Properties
/// - ``isUITesting``
/// - ``isMockLoggedIn``
/// - ``hasDeepLink``
/// - ``deepLinkDestination``
/// - ``shouldResetOnboarding``
///
/// ### Testing Support
/// - ``init(provider:)``
public class UITestingHelper {

  /// UITestingHelperのシングルトンインスタンス
  ///
  /// アプリケーション全体で統一されたUIテスト環境制御を実現するため、
  /// 単一のインスタンスを通してすべてのテスト関連操作を行います。
  public static let shared = UITestingHelper()

  /// UIテスト機能のプロバイダー
  ///
  /// 実際のUIテスト動作を提供するプロバイダーインスタンスです。
  /// テストモードかプロダクションモードかに応じて適切な実装が設定されます。
  private let provider: UITestingProvider

  /// プライベート初期化メソッド（シングルトン用）
  ///
  /// プロセス引数を検査してUIテストモードかどうかを判定し、
  /// 適切なプロバイダー実装を自動選択します。
  ///
  /// ## Detection Logic
  /// - `--uitesting` または `UI_TESTING` 引数の存在をチェック
  /// - テストモード: UITestUITestingProvider を使用
  /// - プロダクションモード: ProductionUITestingProvider を使用
  private init() {
    let args = ProcessInfo.processInfo.arguments
    let isUITesting = args.contains("--uitesting") || args.contains("UI_TESTING")
    provider = isUITesting ? UITestUITestingProvider() : ProductionUITestingProvider()
  }

  /// テスト用の初期化メソッド（依存性注入用）
  ///
  /// ユニットテストで特定のプロバイダーを注入するための初期化メソッドです。
  /// シングルトンパターンを迂回してテスト専用のインスタンスを作成できます。
  ///
  /// - Parameter provider: 注入するUITestingProviderの実装
  init(provider: UITestingProvider) {
    self.provider = provider
  }

  /// UIテストモードかどうかの判定結果
  ///
  /// プロバイダーを通じてUIテスト実行中かどうかを返します。
  /// テストモードでは各種モック動作が有効になります。
  public var isUITesting: Bool {
    provider.isUITesting
  }

  /// UIテスト用のモックログイン状態
  ///
  /// UIテスト時にログイン状態をシミュレートするためのモック値です。
  /// プロダクションモードでは常にfalseを返します。
  public var isMockLoggedIn: Bool {
    provider.isMockLoggedIn
  }

  /// ディープリンクが指定されているかどうかの判定
  ///
  /// UIテスト時に特定の画面に直接ナビゲートするための
  /// ディープリンク設定が存在するかを判定します。
  public var hasDeepLink: Bool {
    provider.hasDeepLink
  }

  /// ディープリンクの遷移先情報
  ///
  /// UIテスト時の直接ナビゲーション先を示す文字列です。
  /// ディープリンクが設定されていない場合はnilを返します。
  public var deepLinkDestination: String? {
    provider.deepLinkDestination
  }

  /// オンボーディング状態のリセットが要求されているかどうか
  ///
  /// UIテスト時にオンボーディング状態をリセットするかの判定です。
  /// プロダクションモードでは常にfalseを返します。
  public var shouldResetOnboarding: Bool {
    provider.shouldResetOnboarding
  }
  
  /// オンボーディングの強制表示が要求されているかどうか
  ///
  /// UIテスト時にオンボーディングを強制的に表示するかの判定です。
  /// プロダクションモードでは常にfalseを返します。
  public var shouldShowOnboarding: Bool {
    provider.shouldShowOnboarding
  }
}
