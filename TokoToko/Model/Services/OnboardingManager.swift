//
//  OnboardingManager.swift
//  TokoToko
//
//  Created by Claude on 2025-08-06.
//

import Foundation

enum OnboardingType: Equatable {
    case firstLaunch
    case versionUpdate(version: String)
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingContent {
    let type: OnboardingType
    let pages: [OnboardingPage]
}

class OnboardingManager {
    private let userDefaults: UserDefaults
    private let firstLaunchKey = "onboarding_first_launch_shown"
    private let versionUpdateKeyPrefix = "onboarding_version_update_"

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    func shouldShowOnboarding(for type: OnboardingType) -> Bool {
        switch type {
        case .firstLaunch:
            return !userDefaults.bool(forKey: firstLaunchKey)
        case .versionUpdate(let version):
            let key = versionUpdateKeyPrefix + version
            return !userDefaults.bool(forKey: key)
        }
    }

    func markOnboardingAsShown(for type: OnboardingType) {
        switch type {
        case .firstLaunch:
            userDefaults.set(true, forKey: firstLaunchKey)
        case .versionUpdate(let version):
            let key = versionUpdateKeyPrefix + version
            userDefaults.set(true, forKey: key)
        }
    }

    func getOnboardingContent(for type: OnboardingType) -> OnboardingContent? {
        switch type {
        case .firstLaunch:
            return createFirstLaunchContent(type: type)
        case .versionUpdate(let version):
            return createVersionUpdateContent(type: type, version: version)
        }
    }

    // MARK: - Private Methods

    private func createFirstLaunchContent(type: OnboardingType) -> OnboardingContent {
        let pages = [
            OnboardingPage(
                title: "TokoTokoへようこそ",
                description: "散歩を記録して、素敵な思い出を作りましょう",
                imageName: "first_launch_1"
            ),
            OnboardingPage(
                title: "簡単操作",
                description: "ボタン一つで散歩の開始・終了ができます",
                imageName: "first_launch_2"
            )
        ]
        return OnboardingContent(type: type, pages: pages)
    }

    private func createVersionUpdateContent(type: OnboardingType, version: String) -> OnboardingContent {
        let pages = [
            OnboardingPage(
                title: "新機能追加",
                description: "バージョン\(version)では新しい機能を追加しました",
                imageName: "version_update_1"
            )
        ]
        return OnboardingContent(type: type, pages: pages)
    }
}
