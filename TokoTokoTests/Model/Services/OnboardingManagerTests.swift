//
//  OnboardingManagerTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
import Foundation
@testable import TokoToko

final class OnboardingManagerTests: XCTestCase {

    var sut: OnboardingManager!
    var mockUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // テスト用のUserDefaultsインスタンスを作成
        mockUserDefaults = UserDefaults(suiteName: "OnboardingManagerTests")
        sut = OnboardingManager(userDefaults: mockUserDefaults)
    }

    override func tearDown() {
        // テストデータをクリーンアップ
        mockUserDefaults.removePersistentDomain(forName: "OnboardingManagerTests")
        mockUserDefaults = nil
        sut = nil
        super.tearDown()
    }

    func testOnboardingManagerInitialization() {
        // Given/When: OnboardingManagerが初期化される

        // Then: インスタンスが作成されることを確認
        XCTAssertNotNil(sut, "OnboardingManagerが正常に初期化されること")
    }

    func testShouldShowOnboardingForFirstLaunch() {
        // Given: 初回起動の状況
        // (UserDefaultsに何も保存されていない状態)

        // When: 初回起動のオンボーディング表示判定を行う
        let shouldShow = sut.shouldShowOnboarding(for: .firstLaunch)

        // Then: 初回起動時はtrueを返すこと
        XCTAssertTrue(shouldShow, "初回起動時はオンボーディングを表示すること")
    }

    func testShouldNotShowOnboardingAfterFirstLaunch() {
        // Given: 初回起動のオンボーディングを既に表示した状況
        sut.markOnboardingAsShown(for: .firstLaunch)

        // When: 再度初回起動のオンボーディング表示判定を行う
        let shouldShow = sut.shouldShowOnboarding(for: .firstLaunch)

        // Then: 2回目以降はfalseを返すこと
        XCTAssertFalse(shouldShow, "初回起動のオンボーディングは1回のみ表示されること")
    }

    func testShouldShowOnboardingForVersionUpdate() {
        // Given: アプリのバージョンアップがあった状況
        let currentVersion = "1.1.0"

        // When: バージョンアップのオンボーディング表示判定を行う
        let shouldShow = sut.shouldShowOnboarding(for: .versionUpdate(version: currentVersion))

        // Then: バージョンアップ時はtrueを返すこと
        XCTAssertTrue(shouldShow, "バージョンアップ時はオンボーディングを表示すること")
    }

    func testShouldNotShowOnboardingForSameVersion() {
        // Given: 特定バージョンのオンボーディングを既に表示した状況
        let version = "1.1.0"
        sut.markOnboardingAsShown(for: .versionUpdate(version: version))

        // When: 同じバージョンで再度オンボーディング表示判定を行う
        let shouldShow = sut.shouldShowOnboarding(for: .versionUpdate(version: version))

        // Then: 同じバージョンでは2回目以降はfalseを返すこと
        XCTAssertFalse(shouldShow, "同じバージョンのオンボーディングは1回のみ表示されること")
    }

    func testGetOnboardingContentForFirstLaunch() {
        // Given/When: 初回起動用のオンボーディングコンテンツを取得する
        let content = sut.getOnboardingContent(for: .firstLaunch)

        // Then: コンテンツが返されること
        XCTAssertNotNil(content, "初回起動用のオンボーディングコンテンツが取得できること")
        XCTAssertEqual(content?.type, .firstLaunch, "コンテンツタイプが正しいこと")
        XCTAssertFalse(content?.pages.isEmpty ?? true, "ページが含まれていること")
    }

    func testGetOnboardingContentForVersionUpdate() {
        // Given: バージョンアップの状況
        let version = "1.1.0"

        // When: バージョンアップ用のオンボーディングコンテンツを取得する
        let content = sut.getOnboardingContent(for: .versionUpdate(version: version))

        // Then: コンテンツが返されること
        XCTAssertNotNil(content, "バージョンアップ用のオンボーディングコンテンツが取得できること")
        XCTAssertEqual(content?.type, .versionUpdate(version: version), "コンテンツタイプが正しいこと")
        XCTAssertFalse(content?.pages.isEmpty ?? true, "ページが含まれていること")
    }
}
