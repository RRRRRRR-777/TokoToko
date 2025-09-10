//
//  OnboardingManagerTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
import Foundation
import Combine
@testable import TekuToko

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
        // Given: 初回起動コンテンツを取得
        let firstLaunchContent = sut.getOnboardingContent(for: .firstLaunch)

        // Then: 初回起動コンテンツが適切に生成されること
        XCTAssertNotNil(firstLaunchContent, "初回起動コンテンツが生成されること")

        // コンテンツの構造が正しいこと
        XCTAssertEqual(firstLaunchContent?.pages.count, 4, "初回起動コンテンツは4ページであること")

        // ページ内容が空でないこと
        if let firstPage = firstLaunchContent?.pages.first {
            XCTAssertFalse(firstPage.title.isEmpty, "タイトルが空でないこと")
            XCTAssertFalse(firstPage.description.isEmpty, "説明文が空でないこと")
            XCTAssertFalse(firstPage.imageName.isEmpty, "画像名が空でないこと")
        }
    }

    // MARK: - TDD Red Phase - YML機能の失敗テスト（次フェーズで実装）

    func testLoadOnboardingFromYML() {
        // Given: YML読み込み機能が実装された状態
        // When: YMLファイルからコンテンツを読み込む
        do {
            let config = try sut.loadOnboardingFromYML()
            // Then: 正常に読み込まれること
            XCTAssertNotNil(config, "YML設定が読み込まれること")
            XCTAssertNotNil(config?.onboarding, "オンボーディングデータが存在すること")
        } catch {
            XCTFail("YML読み込みが失敗: \(error)")
        }
    }

    func testYMLFileNotFoundShouldFallback() {
        // Given: YMLファイルが存在しない状況
        // When: 存在しないYMLファイルを読み込もうとする
        do {
            let config = try sut.loadOnboardingFromYML(fileName: "non_existent_file.yml")
            XCTFail("存在しないファイルでエラーが発生すべき")
        } catch {
            // Then: エラーが発生すること
            XCTAssertTrue(error is OnboardingError, "適切なエラー型であること")
            if let onboardingError = error as? OnboardingError {
                XCTAssertEqual(onboardingError, OnboardingError.fileNotFound, "ファイル不在エラーであること")
            }
        }
    }

    func testInvalidYMLFormatShouldFallback() {
        // Given: 不正な形式のYMLファイル
        // When: 不正なYMLファイルを読み込もうとする
        do {
            let config = try sut.loadOnboardingFromYML(invalidFormat: true)
            XCTFail("不正な形式でエラーが発生すべき")
        } catch {
            // Then: エラーが発生すること
            XCTAssertTrue(error is OnboardingError, "適切なエラー型であること")
            if let onboardingError = error as? OnboardingError {
                XCTAssertEqual(onboardingError, OnboardingError.invalidFormat, "不正な形式エラーであること")
            }
        }
    }

    func testYMLLoadingPerformanceShouldMeet500msRequirement() {
        // Given: YML読み込みのパフォーマンステスト準備
        let startTime = Date()
        
        // When: YMLファイルを読み込む
        do {
            let config = try sut.loadOnboardingFromYML()
            let endTime = Date()
            let elapsedTime = endTime.timeIntervalSince(startTime) * 1000 // msに変換
            
            // Then: 500ms以内に完了すること
            XCTAssertLessThan(elapsedTime, 500, "YML読み込みは500ms以内に完了すること")
            XCTAssertNotNil(config, "設定が読み込まれること")
        } catch {
            XCTFail("YML読み込みが失敗: \(error)")
        }
    }

    func testCreateContentFromYMLData() {
        // Given: YMLデータからコンテンツ作成（テスト用メソッド）
        // When: YMLデータからOnboardingContentを作成しようとする
        do {
            let mockYMLData = ["title": "test", "description": "test desc"]
            let content = try sut.createOnboardingContent(from: mockYMLData)
            XCTFail("現時点では未実装エラーが発生すべき")
        } catch {
            // Then: 未実装エラーが発生すること（将来実装予定）
            XCTAssertTrue(error is OnboardingError, "適切なエラー型であること")
            if let onboardingError = error as? OnboardingError {
                XCTAssertEqual(onboardingError, OnboardingError.notImplemented, "未実装エラーであること")
            }
        }
    }

    func testVersionParsing() {
        // Given: バージョン解析機能
        
        // When/Then: 正常なバージョン文字列を解析
        do {
            // 1.0形式
            let version1 = try sut.parseVersion("1.0")
            XCTAssertEqual(version1.major, 1)
            XCTAssertEqual(version1.minor, 0)
            XCTAssertNil(version1.patch)
            
            // 1.2形式
            let version2 = try sut.parseVersion("1.2")
            XCTAssertEqual(version2.major, 1)
            XCTAssertEqual(version2.minor, 2)
            XCTAssertNil(version2.patch)
            
            // 1.2.3形式
            let version3 = try sut.parseVersion("1.2.3")
            XCTAssertEqual(version3.major, 1)
            XCTAssertEqual(version3.minor, 2)
            XCTAssertEqual(version3.patch, 3)
        } catch {
            XCTFail("バージョン解析が失敗: \(error)")
        }
        
        // 不正なバージョン形式
        do {
            let _ = try sut.parseVersion("1")
            XCTFail("不正なバージョンでエラーが発生すべき")
        } catch {
            XCTAssertTrue(error is OnboardingError)
            if let onboardingError = error as? OnboardingError {
                XCTAssertEqual(onboardingError, OnboardingError.invalidVersion)
            }
        }
    }

    // MARK: - Version Retrieval Tests
    
    func testGetCurrentAppVersionReturnsValidVersion() {
        // Given/When: getCurrentAppVersionを呼び出し
        let version = sut.getCurrentAppVersion()
        
        // Then: バージョンが取得できること
        XCTAssertNotNil(version, "アプリバージョンが取得できること")
        XCTAssertFalse(version?.isEmpty ?? true, "バージョンが空でないこと")
        
        // バージョンフォーマットの検証（例: "1.0", "1.2.3"）
        if let appVersion = version {
            let components = appVersion.split(separator: ".")
            XCTAssertGreaterThanOrEqual(components.count, 2, "バージョンは少なくともメジャー.マイナー形式であること")
            XCTAssertTrue(components.allSatisfy { Int($0) != nil }, "バージョンの各コンポーネントは数字であること")
        }
    }
    
    // MARK: - Version Update Onboarding Check Tests
    
    func testCheckVersionUpdateOnboardingWhenVersionUpdateNeeded() {
        // Given: 現在のバージョンのオンボーディングがまだ表示されていない
        let currentVersion = sut.getCurrentAppVersion() ?? "1.0"
        
        // When: バージョンアップデートオンボーディングをチェック
        let content = sut.checkVersionUpdateOnboarding()
        
        // Then: オンボーディングコンテンツが返されること
        XCTAssertNotNil(content, "バージョンアップデートオンボーディングが必要な場合はコンテンツが返されること")
        XCTAssertEqual(content?.type, .versionUpdate(version: currentVersion), "正しいバージョンのオンボーディングタイプであること")
        XCTAssertFalse(content?.pages.isEmpty ?? true, "ページが含まれていること")
    }
    
    func testCheckVersionUpdateOnboardingWhenAlreadyShown() {
        // Given: 現在のバージョンのオンボーディングを既に表示済み
        let currentVersion = sut.getCurrentAppVersion() ?? "1.0"
        sut.markOnboardingAsShown(for: .versionUpdate(version: currentVersion))
        
        // When: バージョンアップデートオンボーディングをチェック
        let content = sut.checkVersionUpdateOnboarding()
        
        // Then: nilが返されること（オンボーディング不要）
        XCTAssertNil(content, "既に表示済みの場合はnilが返されること")
    }
    
    func testCheckVersionUpdateOnboardingWithSpecificVersions() {
        // Given: 異なるバージョンでの動作確認
        let version1 = "1.0"
        let version2 = "1.2"
        
        // When/Then: バージョン1.0のオンボーディング
        let content1 = sut.getOnboardingContent(for: .versionUpdate(version: version1))
        XCTAssertNotNil(content1, "1.0バージョンのオンボーディングが取得できること")
        
        let shouldShow1 = sut.shouldShowOnboarding(for: .versionUpdate(version: version1))
        XCTAssertTrue(shouldShow1, "1.0バージョンの初回表示時はtrueであること")
        
        // オンボーディング表示済みマーク
        sut.markOnboardingAsShown(for: .versionUpdate(version: version1))
        let shouldShow1After = sut.shouldShowOnboarding(for: .versionUpdate(version: version1))
        XCTAssertFalse(shouldShow1After, "1.0バージョン表示後はfalseであること")
        
        // When/Then: バージョン1.2のオンボーディング（別バージョンなので表示される）
        let shouldShow2 = sut.shouldShowOnboarding(for: .versionUpdate(version: version2))
        XCTAssertTrue(shouldShow2, "異なるバージョン(1.2)は表示されること")
    }
    
    // MARK: - Initialization Auto-Detection Tests
    
    func testInitializationAutoSetsVersionUpdateOnboardingWhenFirstLaunchCompleted() {
        // Given: 初回起動が完了している状況
        mockUserDefaults.set(true, forKey: "onboarding_first_launch_shown")
        
        // When: OnboardingManagerを新たに初期化
        let newManager = OnboardingManager(userDefaults: mockUserDefaults)
        
        // Then: バージョンアップデートオンボーディングが自動的に設定されること
        let hasContent = newManager.currentContent != nil
        let currentVersion = newManager.getCurrentAppVersion() ?? "1.0"
        let shouldShowVersionUpdate = newManager.shouldShowOnboarding(for: .versionUpdate(version: currentVersion))
        
        if shouldShowVersionUpdate {
            XCTAssertTrue(hasContent, "バージョンアップデートが必要な場合、初期化時にcurrentContentが設定されること")
            XCTAssertEqual(newManager.currentContent?.type, .versionUpdate(version: currentVersion), "正しいバージョンアップデートタイプが設定されること")
        } else {
            XCTAssertFalse(hasContent, "バージョンアップデートが不要な場合、currentContentはnilであること")
        }
    }
    
    func testInitializationPrioritizesFirstLaunchOverVersionUpdate() {
        // Given: 初回起動もバージョンアップデートも未表示の状況
        // (新しいUserDefaultsインスタンスなので何も設定されていない)
        
        // When: OnboardingManagerを初期化
        let newManager = OnboardingManager(userDefaults: mockUserDefaults)
        
        // Then: 初回起動オンボーディングが優先されること
        XCTAssertNotNil(newManager.currentContent, "初回起動時はcurrentContentが設定されること")
        XCTAssertEqual(newManager.currentContent?.type, .firstLaunch, "初回起動が優先されること")
    }
}
