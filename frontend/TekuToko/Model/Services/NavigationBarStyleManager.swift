import UIKit
import SwiftUI

/// Navigation Barの外観を統一管理するスタイルマネージャー
///
/// アプリ全体でのNavigation Barの外観統一を担当するサービスクラスです。
/// ダークモード・ライトモード統一、BackgroundColorの適用、各画面固有の要件への対応を提供します。
///
/// ## 設計思想
/// - グローバル設定と画面固有設定の分離
/// - 再利用可能で拡張性のあるAPI設計
/// - iOS 15/16+での互換性保証
///
/// ## Usage
/// ```swift
/// // 基本設定の適用
/// NavigationBarStyleManager.shared.applyUnifiedStyle()
///
/// // カスタム設定付きの適用
/// NavigationBarStyleManager.shared.applyUnifiedStyle(
///   customizations: .init(shadowHidden: true, titleColor: .white)
/// )
/// ```
final class NavigationBarStyleManager {

  /// シングルトンインスタンス
  static let shared = NavigationBarStyleManager()

  /// 初期化の重複を防ぐプライベート初期化子
  private init() {}

  /// Navigation Bar外観のカスタマイズオプション
  ///
  /// 画面固有の要件に応じて基本設定をオーバーライドできるオプションセットです。
  /// すべてのプロパティはオプショナルで、指定しない場合はデフォルト値が適用されます。
  struct CustomizationOptions {
    /// タイトルの文字色（デフォルト: .black）
    let titleColor: UIColor?

    /// 大きなタイトルの文字色（デフォルト: .black）
    let largeTitleColor: UIColor?

    /// 背景色（デフォルト: BackgroundColor）
    let backgroundColor: UIColor?

    /// シャドウを非表示にするかどうか（デフォルト: false）
    let shadowHidden: Bool

    /// ティントカラー（ボタン等の色）（デフォルト: .black）
    let tintColor: UIColor?

    /// 透明背景を使用するかどうか（デフォルト: false）
    let useTransparentBackground: Bool

    /// デフォルトのカスタマイゼーションオプション
    static let `default` = CustomizationOptions(
      titleColor: nil,
      largeTitleColor: nil,
      backgroundColor: nil,
      shadowHidden: false,
      tintColor: nil,
      useTransparentBackground: false
    )

    /// カスタムオプションの初期化
    ///
    /// - Parameters:
    ///   - titleColor: タイトルの文字色
    ///   - largeTitleColor: 大きなタイトルの文字色
    ///   - backgroundColor: 背景色
    ///   - shadowHidden: シャドウを非表示にするか
    ///   - tintColor: ティントカラー
    ///   - useTransparentBackground: 透明背景を使用するか
    init(
      titleColor: UIColor? = nil,
      largeTitleColor: UIColor? = nil,
      backgroundColor: UIColor? = nil,
      shadowHidden: Bool = false,
      tintColor: UIColor? = nil,
      useTransparentBackground: Bool = false
    ) {
      self.titleColor = titleColor
      self.largeTitleColor = largeTitleColor
      self.backgroundColor = backgroundColor
      self.shadowHidden = shadowHidden
      self.tintColor = tintColor
      self.useTransparentBackground = useTransparentBackground
    }
  }

  // MARK: - Public Methods

  /// 統一されたNavigation Bar外観を適用
  ///
  /// アプリ全体で統一されたNavigation Barスタイルを適用します。
  /// カスタマイズオプションを指定することで、画面固有の要件に対応できます。
  ///
  /// - Parameter customizations: 画面固有のカスタマイズオプション
  func applyUnifiedStyle(customizations: CustomizationOptions = .default) {
    let standardAppearance = createAppearance(
      customizations: customizations,
      isScrollEdge: false
    )

    let scrollEdgeAppearance = createAppearance(
      customizations: customizations,
      isScrollEdge: true
    )

    // グローバルにNavigation Bar外観を設定
    UINavigationBar.appearance().standardAppearance = standardAppearance
    UINavigationBar.appearance().compactAppearance = standardAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance

    // ティントカラーの設定
    if let tintColor = customizations.tintColor {
      UINavigationBar.appearance().tintColor = tintColor
    } else {
      UINavigationBar.appearance().tintColor = UIColor.black
    }
  }

  /// 特定の画面向けの外観設定を取得
  ///
  /// 特定のNavigationViewで使用するために、カスタマイズされた外観設定を取得します。
  /// グローバル設定と併用する場合に使用します。
  ///
  /// - Parameter customizations: カスタマイズオプション
  /// - Returns: 設定済みのUINavigationBarAppearance
  func createCustomAppearance(customizations: CustomizationOptions) -> UINavigationBarAppearance {
    createAppearance(customizations: customizations, isScrollEdge: false)
  }

  // MARK: - Private Methods

  /// UINavigationBarAppearanceを作成
  ///
  /// 指定されたカスタマイズオプションに基づいてNavigation Bar外観を作成します。
  ///
  /// - Parameters:
  ///   - customizations: カスタマイズオプション
  ///   - isScrollEdge: スクロールエッジ用の外観かどうか
  /// - Returns: 設定済みのUINavigationBarAppearance
  private func createAppearance(
    customizations: CustomizationOptions,
    isScrollEdge: Bool
  ) -> UINavigationBarAppearance {
    let appearance = UINavigationBarAppearance()

    // 背景設定
    if customizations.useTransparentBackground {
      appearance.configureWithTransparentBackground()
    } else {
      appearance.configureWithOpaqueBackground()
    }

    // 背景色の設定
    let backgroundColor = customizations.backgroundColor ?? UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    appearance.backgroundColor = backgroundColor

    // テキスト色の設定
    let titleColor = customizations.titleColor ?? UIColor.black
    let largeTitleColor = customizations.largeTitleColor ?? UIColor.black

    appearance.titleTextAttributes = [.foregroundColor: titleColor]
    appearance.largeTitleTextAttributes = [.foregroundColor: largeTitleColor]

    // シャドウの設定
    if customizations.shadowHidden {
      appearance.shadowColor = UIColor.clear
      appearance.shadowImage = UIImage()
    }

    return appearance
  }
}

// MARK: - SwiftUI Extensions

extension NavigationBarStyleManager {

  /// SwiftUI用の便利メソッド
  ///
  /// SwiftUIビューの.onAppear内で簡単に呼び出せる便利メソッドです。
  ///
  /// - Parameter customizations: カスタマイズオプション
  func configureForSwiftUI(customizations: CustomizationOptions = .default) {
    applyUnifiedStyle(customizations: customizations)
  }
}

// MARK: - Predefined Configurations

extension NavigationBarStyleManager.CustomizationOptions {

  /// ポリシー画面用のカスタム設定
  ///
  /// PolicyViewで使用される特殊な要件（シャドウ非表示など）に対応した設定です。
  static let policyScreen = NavigationBarStyleManager.CustomizationOptions(
    shadowHidden: true
  )

  /// 設定画面用のカスタム設定
  ///
  /// SettingsViewで使用される設定です。
  static let settingsScreen = NavigationBarStyleManager.CustomizationOptions()

  /// 散歩リスト画面用のカスタム設定
  ///
  /// WalkListViewで使用される設定です。
  static let walkListScreen = NavigationBarStyleManager.CustomizationOptions()

  /// アプリ情報画面用のカスタム設定
  ///
  /// AppInfoViewで使用される設定です。
  static let appInfoScreen = NavigationBarStyleManager.CustomizationOptions()
}
