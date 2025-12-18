//
//  OnboardingConfig.swift
//  TekuToko
//
//  Created by Claude on 2025-08-11.
//

import Foundation

/// YMLファイルからのオンボーディング設定を管理するルートモデル
///
/// `onboarding.yml`ファイルの構造に対応するSwiftデータモデルです。
/// 初回起動時とバージョンアップデート時のオンボーディングコンテンツを管理します。
struct OnboardingConfig: Codable {
  let onboarding: OnboardingData
}

/// オンボーディングデータのメインコンテナ
struct OnboardingData: Codable {
  let firstLaunch: OnboardingSection?
  let versionUpdates: [String: OnboardingSection]

  enum CodingKeys: String, CodingKey {
    case firstLaunch = "first_launch"
    case versionUpdates = "version_updates"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    firstLaunch = try container.decodeIfPresent(OnboardingSection.self, forKey: .firstLaunch)
    versionUpdates =
      try container.decodeIfPresent([String: OnboardingSection].self, forKey: .versionUpdates)
      ?? [:]
  }
}

/// 特定タイプ（初回起動・バージョンアップデート）のオンボーディングセクション
struct OnboardingSection: Codable {
  let pages: [OnboardingPageData]
}

/// オンボーディングページの個別データ
struct OnboardingPageData: Codable {
  let title: String
  let description: String
  let imageName: String

  enum CodingKeys: String, CodingKey {
    case imageName = "image_name"
    case title, description
  }
}
