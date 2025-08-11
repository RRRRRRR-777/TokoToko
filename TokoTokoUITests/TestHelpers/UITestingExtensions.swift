//
//  UITestingExtensions.swift
//  TokoTokoUITests
//
//  Created by bokuyamada on 2025/05/23.
//

import XCTest

/// UIテスト用の拡張機能を提供するクラス
public class UITestingExtensions {

    /// アプリを起動する際のオプション
    public struct LaunchOptions {
        /// UIテストモードを有効にする
        public var isUITesting: Bool = true

        /// モックログイン状態
        public var isLoggedIn: Bool = false

        /// ディープリンクを有効にする
        public var useDeepLink: Bool = false

        /// ディープリンク先
        public var destination: String? = nil

        /// オンボーディング状態をリセットする
        public var resetOnboarding: Bool = false
        
        /// オンボーディングを強制表示する
        public var showOnboarding: Bool = false

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
