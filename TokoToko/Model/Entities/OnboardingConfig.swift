//
//  OnboardingConfig.swift
//  TokoToko
//
//  Created by Claude on 2025-08-11.
//

import Foundation

/// YMLファイルからのオンボーディング設定を管理するルートモデル
struct OnboardingConfig: Codable {
  let onboarding: OnboardingData
}

/// オンボーディングデータのメインコンテナ
struct OnboardingData: Codable {
  let firstLaunch: OnboardingSection?
  let versionUpdates: [String: OnboardingSection]?
  
  enum CodingKeys: String, CodingKey {
    case firstLaunch = "first_launch"
    case versionUpdates = "version_updates"
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