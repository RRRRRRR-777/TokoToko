//
//  UITestingExtensions.swift
//  TokoTokoUITests
//
//  Created by bokuyamada on 2025/05/23.
//

import XCTest

/// UIテスト用の拡張機能を提供するクラス
public enum UITestingExtensions {

    /// UIテスト用のタイムアウト設定
    public enum TimeoutSettings {
        /// 標準のタイムアウト時間（要素の存在確認用）
        public static let standard: TimeInterval = 5.0

        /// 長いタイムアウト時間（複雑な画面遷移用）
        public static let long: TimeInterval = 10.0

        /// オンボーディング用のタイムアウト時間（アニメーション込み）
        public static let onboarding: TimeInterval = 15.0

        /// 短いタイムアウト時間（高速な操作用）
        public static let short: TimeInterval = 2.0

        /// CI環境での調整倍率
        public static let ciMultiplier: TimeInterval = {
            if ProcessInfo.processInfo.environment["CI"] == "true" {
                return 2.0  // CI環境では2倍の時間を確保
            }
            return 1.0
        }()

        /// 環境を考慮した標準タイムアウト
        public static var adjustedStandard: TimeInterval {
            standard * ciMultiplier
        }

        /// 環境を考慮した長いタイムアウト
        public static var adjustedLong: TimeInterval {
            long * ciMultiplier
        }

        /// 環境を考慮したオンボーディングタイムアウト
        public static var adjustedOnboarding: TimeInterval {
            onboarding * ciMultiplier
        }

        /// 環境を考慮した短いタイムアウト
        public static var adjustedShort: TimeInterval {
            short * ciMultiplier
        }
    }

    /// UIテスト用のパフォーマンス閾値設定
    public enum PerformanceThresholds {
        /// CI環境でのパフォーマンス閾値（ミリ秒）
        public static let ciEnvironmentThreshold: Double = 1500.0

        /// ローカル環境でのパフォーマンス閾値（ミリ秒）- iOS 17以前
        public static let localEnvironmentThreshold: Double = 800.0

        /// ローカル環境でのパフォーマンス閾値（ミリ秒）- iOS 18以降
        public static let localEnvironmentThresholdIOS18: Double = 2400.0

        /// 環境とOSバージョンを考慮した適切な閾値を返す
        /// - Returns: 適用すべきパフォーマンス閾値（ミリ秒）
        public static var adaptiveThreshold: Double {
            let isCI = ProcessInfo.processInfo.environment["CI"] == "true"
            if isCI {
                return ciEnvironmentThreshold
            }

            let os = ProcessInfo.processInfo.operatingSystemVersion
            return (os.majorVersion >= 18) ? localEnvironmentThresholdIOS18 : localEnvironmentThreshold
        }
    }

    /// アプリを起動する際のオプション
    public struct LaunchOptions {
        /// UIテストモードを有効にする
        public var isUITesting: Bool = true

        /// モックログイン状態
        public var isLoggedIn: Bool = false

        /// ディープリンクを有効にする
        public var useDeepLink: Bool = false

        /// ディープリンク先
        public var destination: String?

        /// オンボーディング状態をリセットする
        public var resetOnboarding: Bool = false

        /// オンボーディングを強制表示する
        public var showOnboarding: Bool = false

        /// LaunchOptionsを初期化します
        /// - Parameters:
        ///   - isUITesting: UIテストモードを有効にするかどうか
        ///   - isLoggedIn: モックログイン状態
        ///   - useDeepLink: ディープリンクを有効にするかどうか
        ///   - destination: ディープリンク先
        ///   - resetOnboarding: オンボーディング状態をリセットするかどうか
        ///   - showOnboarding: オンボーディングを強制表示するかどうか
        public init(isUITesting: Bool = true, isLoggedIn: Bool = false, useDeepLink: Bool = false, destination: String? = nil, resetOnboarding: Bool = false, showOnboarding: Bool = false) {
            self.isUITesting = isUITesting
            self.isLoggedIn = isLoggedIn
            self.useDeepLink = useDeepLink
            self.destination = destination
            self.resetOnboarding = resetOnboarding
            self.showOnboarding = showOnboarding
        }
    }

    /// 指定されたオプションでアプリを起動する
    /// - Parameters:
    ///   - app: XCUIApplicationインスタンス
    ///   - options: 起動オプション
    public static func launchApp(_ app: XCUIApplication, options: LaunchOptions) {
        // 起動引数をクリア
        app.launchArguments = []

        // UIテストモードを設定
        if options.isUITesting {
            app.launchArguments.append("--uitesting")
        }

        // ログイン状態を設定
        if options.isLoggedIn {
            app.launchArguments.append("--logged-in")
        }

        // ディープリンクを設定
        if options.useDeepLink {
            app.launchArguments.append("--deep-link")

            if let destination = options.destination {
                app.launchArguments.append("--destination")
                app.launchArguments.append(destination)
            }
        }

        // オンボーディング状態をリセット
        if options.resetOnboarding {
            app.launchArguments.append("--reset-onboarding")
        }

        // オンボーディングを強制表示
        if options.showOnboarding {
            app.launchArguments.append("--show-onboarding")
        }

        // アプリを起動
        app.launch()
    }

    /// ログイン状態でアプリを起動する
    /// - Parameter app: XCUIApplicationインスタンス
    public static func launchAppLoggedIn(_ app: XCUIApplication) {
        launchApp(app, options: LaunchOptions(isUITesting: true, isLoggedIn: true))
    }

    /// ログアウト状態でアプリを起動する
    /// - Parameter app: XCUIApplicationインスタンス
    public static func launchAppLoggedOut(_ app: XCUIApplication) {
        launchApp(app, options: LaunchOptions(isUITesting: true, isLoggedIn: false))
    }

    /// 特定の画面にディープリンクでアプリを起動する
    /// - Parameters:
    ///   - app: XCUIApplicationインスタンス
    ///   - destination: ディープリンク先（"outing", "walk", "settings"など）
    ///   - isLoggedIn: ログイン状態
    public static func launchAppWithDeepLink(_ app: XCUIApplication, destination: String, isLoggedIn: Bool = true) {
        launchApp(app, options: LaunchOptions(
            isUITesting: true,
            isLoggedIn: isLoggedIn,
            useDeepLink: true,
            destination: destination
        ))
    }

    /// オンボーディング状態をリセットしてアプリを起動する
    /// - Parameters:
    ///   - app: XCUIApplicationインスタンス
    ///   - isLoggedIn: ログイン状態
    public static func launchAppWithResetOnboarding(_ app: XCUIApplication, isLoggedIn: Bool = true) {
        launchApp(app, options: LaunchOptions(
            isUITesting: true,
            isLoggedIn: isLoggedIn,
            resetOnboarding: true,
            showOnboarding: true
        ))
    }
}
