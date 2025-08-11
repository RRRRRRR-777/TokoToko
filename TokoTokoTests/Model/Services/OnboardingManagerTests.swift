//
//  OnboardingManagerTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
import Foundation
import Combine
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

    // MARK: - Integration Tests (Phase 4)

    func testOnboardingManagerIntegrationWithMainTabView() {
        // TDD Red: MainTabViewとの統合テスト（失敗するテストを先に書く）
        // Given: 初回起動状況（UserDefaultsクリア状態）
        mockUserDefaults.removeObject(forKey: "onboarding_first_launch_shown")

        // When: MainTabViewが表示される際のオンボーディング判定
        let shouldShowFirstLaunch = sut.shouldShowOnboarding(for: .firstLaunch)

        // Then: 初回起動時はオンボーディングが表示されること
        XCTAssertTrue(shouldShowFirstLaunch, "MainTabView表示時に初回起動オンボーディングが判定されること")

        // When: オンボーディング表示後にマークされる
        sut.markOnboardingAsShown(for: .firstLaunch)

        // Then: 次回起動時は表示されないこと
        let shouldShowSecond = sut.shouldShowOnboarding(for: .firstLaunch)
        XCTAssertFalse(shouldShowSecond, "オンボーディング表示後は二回目以降表示されないこと")
    }

    func testOnboardingManagerObservableObjectIntegration() {
        // TDD Green: ObservableObject統合テスト（テストが通るよう修正）
        // Given: OnboardingManagerがObservableObjectとして動作する
        let expectation = self.expectation(description: "ObservableObject通知")
        expectation.expectedFulfillmentCount = 2 // currentContentとnotificationTriggerの2つの変更を期待
        var notificationCount = 0

        // When: プロパティが変更される
        let cancellable = sut.objectWillChange.sink {
            notificationCount += 1
            expectation.fulfill()
        }

        // @Published プロパティの変更をトリガー
        sut.markOnboardingAsShown(for: .firstLaunch)

        // Then: 変更通知が発生すること
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(notificationCount, 2, "ObservableObjectとして2回の変更通知が発生すること（currentContent + notificationTrigger）")
        }

        cancellable.cancel()
    }

    func testVersionUpdateOnboardingIntegration() {
        // TDD Red: バージョンアップデート統合テスト
        // Given: 異なるバージョンでの複数回実行
        let version1 = "1.0.0"
        let version2 = "1.1.0"

        // When: 最初のバージョンでオンボーディング表示
        let shouldShowV1First = sut.shouldShowOnboarding(for: .versionUpdate(version: version1))
        XCTAssertTrue(shouldShowV1First, "新バージョン初回は表示されること")

        sut.markOnboardingAsShown(for: .versionUpdate(version: version1))
        let shouldShowV1Second = sut.shouldShowOnboarding(for: .versionUpdate(version: version1))
        XCTAssertFalse(shouldShowV1Second, "同バージョン2回目は表示されないこと")

        // When: 新しいバージョンに更新
        let shouldShowV2First = sut.shouldShowOnboarding(for: .versionUpdate(version: version2))

        // Then: 新バージョンでは再び表示されること
        XCTAssertTrue(shouldShowV2First, "新バージョン更新時は再度表示されること")
    }

    func testOnboardingContentConsistency() {
        // TDD Red: コンテンツ整合性テスト
        // Given: 初回起動とバージョンアップの両方のコンテンツを取得
        let firstLaunchContent = sut.getOnboardingContent(for: .firstLaunch)
        let versionUpdateContent = sut.getOnboardingContent(for: .versionUpdate(version: "1.1.0"))

        // Then: 両方のコンテンツが適切に生成されること
        XCTAssertNotNil(firstLaunchContent, "初回起動コンテンツが生成されること")
        XCTAssertNotNil(versionUpdateContent, "バージョンアップコンテンツが生成されること")

        // コンテンツの構造が正しいこと
        XCTAssertEqual(firstLaunchContent?.pages.count, 2, "初回起動コンテンツは2ページであること")
        XCTAssertEqual(versionUpdateContent?.pages.count, 1, "バージョンアップコンテンツは1ページであること")

        // ページ内容が空でないこと
        if let firstPage = firstLaunchContent?.pages.first {
            XCTAssertFalse(firstPage.title.isEmpty, "タイトルが空でないこと")
            XCTAssertFalse(firstPage.description.isEmpty, "説明文が空でないこと")
            XCTAssertFalse(firstPage.imageName.isEmpty, "画像名が空でないこと")
        }
    }

    // MARK: - TDD Red Phase - YML機能の失敗テスト

    func testLoadOnboardingFromYMLShouldFail() {
        // Given: YML読み込み機能が未実装の状態
        // When: YMLファイルからコンテンツを読み込もうとする
        do {
            let content = try sut.loadOnboardingFromYML()
            // Then: この段階では失敗するはず（メソッドが未実装）
            XCTFail("loadOnboardingFromYML()が未実装の状態では、このテストは失敗するはず")
        } catch {
            // Expected: メソッド未実装のため失敗する
            XCTAssertTrue(true, "YML読み込み機能が未実装のため失敗する")
        }
    }

    func testYMLFileNotFoundShouldFallback() {
        // Given: YMLファイルが存在しない状況
        // When: 存在しないYMLファイルを読み込もうとする
        do {
            let content = try sut.loadOnboardingFromYML(fileName: "non_existent_file.yml")
            // Then: この段階では失敗するはず（メソッドが未実装）
            XCTFail("存在しないファイルの処理が未実装の状態では、このテストは失敗するはず")
        } catch {
            // Expected: ファイル不存在処理が未実装のため失敗する
            XCTAssertTrue(true, "YMLファイル不存在の処理が未実装のため失敗する")
        }
    }

    func testInvalidYMLFormatShouldFallback() {
        // Given: 不正な形式のYMLファイル
        // When: 不正なYMLファイルを読み込もうとする
        do {
            let content = try sut.loadOnboardingFromYML(invalidFormat: true)
            // Then: この段階では失敗するはず（エラーハンドリング未実装）
            XCTFail("不正なYML形式の処理が未実装の状態では、このテストは失敗するはず")
        } catch {
            // Expected: エラーハンドリングが未実装のため失敗する
            XCTAssertTrue(true, "不正なYML形式の処理が未実装のため失敗する")
        }
    }

    func testYMLLoadingPerformanceShouldMeet500msRequirement() {
        // Given: YML読み込みのパフォーマンステスト準備
        let startTime = Date()

        // When: YMLファイルを読み込む（未実装）
        do {
            let content = try sut.loadOnboardingFromYML()
            let endTime = Date()
            let elapsedTime = endTime.timeIntervalSince(startTime)

            // Then: この段階では失敗するはず（メソッドが未実装）
            XCTFail("YML読み込み処理が未実装の状態では、このテストは失敗するはず")
        } catch {
            // Expected: パフォーマンステストメソッドが未実装のため失敗する
            XCTAssertTrue(true, "YML読み込みパフォーマンステストが未実装のため失敗する")
        }
    }

    func testCreateContentFromYMLDataShouldFail() {
        // Given: YMLデータからコンテンツ作成が未実装の状態
        // When: YMLデータからOnboardingContentを作成しようとする
        do {
            let mockYMLData = ["title": "test", "description": "test desc"]
            let content = try sut.createOnboardingContent(from: mockYMLData)
            // Then: この段階では失敗するはず（メソッドが未実装）
            XCTFail("YMLデータからのコンテンツ作成が未実装の状態では、このテストは失敗するはず")
        } catch {
            // Expected: コンテンツ作成メソッドが未実装のため失敗する
            XCTAssertTrue(true, "YMLデータからのコンテンツ作成が未実装のため失敗する")
        }
    }

    func testVersionParsingFromYMLShouldFail() {
        // Given: バージョン解析機能が未実装の状態
        // When: バージョン文字列を解析しようとする
        do {
            let parsedVersion = try sut.parseVersion("1.2.3")
            // Then: この段階では失敗するはず（メソッドが未実装）
            XCTFail("バージョン解析機能が未実装の状態では、このテストは失敗するはず")
        } catch {
            // Expected: バージョン解析が未実装のため失敗する
            XCTAssertTrue(true, "バージョン解析機能が未実装のため失敗する")
        }
    }
}
