//
//  AppInfoView.swift
//  TokoToko
//
//  Created by Claude on 2025/08/22.
//

import SwiftUI

/// アプリ情報表示画面
///
/// 「このアプリについて」画面として、アプリのバージョン情報、
/// 開発元情報、コピーライトなどを表示します。
/// Info.plistから動的に情報を取得し、透明性とユーザーの信頼を向上させます。
///
/// ## Overview
///
/// 表示される情報：
/// - **アプリ名**: TokoToko - おさんぽSNS
/// - **バージョン情報**: CFBundleShortVersionString
/// - **ビルド番号**: CFBundleVersion
/// - **開発元**: 個人開発者情報
/// - **コピーライト**: © 2024 個人名
///
/// ## Topics
///
/// ### UI Components
/// - ``InfoRow``
/// - ``AppInfoSection``
/// - ``DeveloperSection``
///
/// ### Data Sources
/// - Info.plist bundle information
/// - Static developer information
struct AppInfoView: View {

  /// Info.plistから取得するアプリバージョン
  private var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "不明"
  }

  /// Info.plistから取得するビルド番号
  private var buildNumber: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "不明"
  }

  /// Info.plistから取得するアプリ名
  private var appName: String {
    let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
    return displayName ?? bundleName ?? "TokoToko"
  }

  /// 現在の年を取得
  private var currentYear: Int {
    Calendar.current.component(.year, from: Date())
  }

  var body: some View {
    NavigationView {
      appInfoListView
        .navigationTitle("このアプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }
    .accentColor(.black)
    .onAppear {
      // iOS 15対応: ナビゲーションバーの外観設定
      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
      UINavigationBar.appearance().standardAppearance = appearance
      UINavigationBar.appearance().compactAppearance = appearance
    }
  }
  
  /// アプリ情報リストビューの共通実装
  private var appInfoListView: some View {
    List {
      // アプリ基本情報セクション
      Section(header: Text("アプリ情報")) {
        // アプリ名
        VStack(alignment: .center, spacing: 8) {
          Text("とことこ - おさんぽSNS")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier("app_name")

          Text("日常の散歩を記録・共有するSNSアプリ")
            .font(.caption)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowBackground(Color("BackgroundColor"))
      }

      // バージョン情報セクション
      Section(header: Text("バージョン情報")) {
        InfoRow(
          title: "バージョン",
          value: appVersion,
          accessibilityId: "version_info"
        )
        .foregroundColor(.black)
        .listRowBackground(Color("BackgroundColor"))

        InfoRow(
          title: "ビルド",
          value: buildNumber,
          accessibilityId: "build_info"
        )
        .foregroundColor(.black)
        .listRowBackground(Color("BackgroundColor"))
      }
      .foregroundColor(.black)

      // 開発元情報セクション
      Section(header: Text("開発元")) {
        InfoRow(
          title: "開発元",
          value: "riku.yamada",
          accessibilityId: "developer_info"
        )
        .listRowBackground(Color("BackgroundColor"))

        InfoRow(
          title: "コピーライト",
          value: "© \(currentYear) riku.yamada",
          accessibilityId: "copyright_info"
        )
        .listRowBackground(Color("BackgroundColor"))
      }
      .foregroundColor(.black)

      // 技術情報セクション
      Section(header: Text("技術情報")) {
        InfoRow(
          title: "フレームワーク",
          value: "SwiftUI",
          accessibilityId: "framework_info"
        )
        .listRowBackground(Color("BackgroundColor"))

        InfoRow(
          title: "最小対応バージョン",
          value: "iOS 15.0",
          accessibilityId: "min_version_info"
        )
        .listRowBackground(Color("BackgroundColor"))
      }
      .foregroundColor(.black)

      // アプリの説明セクション
      Section(header: Text("このアプリについて")) {
        VStack(alignment: .leading, spacing: 12) {
          Text("とことこは、日常の散歩を記録し、友人や家族と散歩体験を共有できるiOSアプリです。")
            .font(.body)

          Text("主な機能：")
            .font(.headline)
            .padding(.top, 8)

          VStack(alignment: .leading, spacing: 4) {
            FeatureRow(text: "GPS追跡による散歩ルート記録")
            FeatureRow(text: "SNS・メール・LINEでの共有")
            FeatureRow(text: "散歩履歴の管理と振り返り")
          }
        }
        .padding(.vertical, 4)
        .foregroundColor(.black)
        .listRowBackground(Color("BackgroundColor"))
      }
    }
    .listStyle(PlainListStyle())
    .foregroundColor(.black)
    .background(Color("BackgroundColor"))
    .modifier(ScrollContentBackgroundModifier())
  }
}

// MARK: - View Modifiers

/// iOS版に応じたスクロール背景の制御
private struct ScrollContentBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 16.0, *) {
      content
        .scrollContentBackground(.hidden)
    } else {
      content
    }
  }
}

// MARK: - Supporting Views

/// 情報表示行
///
/// タイトルと値を表示するシンプルな行コンポーネントです。
private struct InfoRow: View {
  let title: String
  let value: String
  let accessibilityId: String

  var body: some View {
    HStack {
      Text(title)
        .foregroundColor(.black)

      Spacer()

      Text(value)
        .foregroundColor(.black)
        .font(.caption)
    }
    .accessibilityIdentifier(accessibilityId)
  }
}

/// 機能説明行
///
/// アプリの機能を箇条書きで表示するコンポーネントです。
private struct FeatureRow: View {
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Text("•")
        .foregroundColor(.black)

      Text(text)
        .font(.body)
        .foregroundColor(.black)

      Spacer()
    }
  }
}

// MARK: - Preview

struct AppInfoView_Previews: PreviewProvider {
  static var previews: some View {
    AppInfoView()
  }
}
