//
//  OnboardingModalViewUITests.swift
//  TokoTokoUITests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
import ViewInspector
@testable import TokoToko

final class OnboardingModalViewUITests: XCTestCase {

    func testOnboardingModalViewInitialState() throws {
        // Given: 初回起動用のオンボーディングコンテンツ
        let content = OnboardingContent(
            type: .firstLaunch,
            pages: [
                OnboardingPage(
                    title: "テストタイトル1",
                    description: "テスト説明1",
                    imageName: "test_image_1"
                ),
                OnboardingPage(
                    title: "テストタイトル2", 
                    description: "テスト説明2",
                    imageName: "test_image_2"
                )
            ]
        )

        // When: OnboardingModalViewを作成
        let onboardingView = OnboardingModalView(
            content: content,
            isPresented: .constant(true),
            onDismiss: {}
        )

        // Then: 初期状態が正しく表示されること
        let body = try onboardingView.inspect().vStack()
        
        // コンテンツ部分のVStackを取得
        let contentVStack = try body.vStack(1)
        
        // 最初のページが表示されていること
        let titleText = try contentVStack.text(1).string()
        XCTAssertEqual(titleText, "テストタイトル1", "最初のページのタイトルが表示されること")
        
        let descriptionText = try contentVStack.text(2).string()
        XCTAssertEqual(descriptionText, "テスト説明1", "最初のページの説明が表示されること")
        
        // ナビゲーション部分のHStackを取得
        let navigationHStack = try body.hStack(3)
        
        // 前ページボタンと次ページボタンが存在すること
        XCTAssertNoThrow(try navigationHStack.button(0), "前ページボタンが存在すること")
        XCTAssertNoThrow(try navigationHStack.button(2), "次ページボタンが存在すること")
        
        // 閉じるボタンが表示されていること
        let headerHStack = try body.hStack(0)
        XCTAssertNoThrow(try headerHStack.button("閉じる"), "閉じるボタンが存在すること")
    }

    func testOnboardingModalViewNavigation() throws {
        // Given: 複数ページのオンボーディングコンテンツ
        let content = OnboardingContent(
            type: .firstLaunch,
            pages: [
                OnboardingPage(
                    title: "ページ1",
                    description: "説明1",
                    imageName: "image1"
                ),
                OnboardingPage(
                    title: "ページ2",
                    description: "説明2", 
                    imageName: "image2"
                )
            ]
        )

        // When: OnboardingModalViewを作成して次ページボタンをタップ
        var onboardingView = OnboardingModalView(
            content: content,
            isPresented: .constant(true),
            onDismiss: {}
        )

        // 次ページボタンをタップ  
        let navigationHStack = try onboardingView.inspect().vStack().hStack(3)
        try navigationHStack.button(2).tap()

        // Then: 2ページ目が表示されること
        let body = try onboardingView.inspect().vStack()
        let contentVStack = try body.vStack(1)
        let titleText = try contentVStack.text(1).string()
        XCTAssertEqual(titleText, "ページ2", "2ページ目のタイトルが表示されること")
    }

    func testOnboardingModalViewDismiss() throws {
        // Given: オンボーディングコンテンツと閉じるコールバック
        let content = OnboardingContent(
            type: .firstLaunch,
            pages: [
                OnboardingPage(
                    title: "テストタイトル",
                    description: "テスト説明",
                    imageName: "test_image"
                )
            ]
        )

        var dismissCalled = false
        let onDismissCallback = {
            dismissCalled = true
        }

        // When: OnboardingModalViewを作成して閉じるボタンをタップ
        let onboardingView = OnboardingModalView(
            content: content,
            isPresented: .constant(true),
            onDismiss: onDismissCallback
        )

        let headerHStack = try onboardingView.inspect().vStack().hStack(0)
        try headerHStack.button("閉じる").tap()

        // Then: onDismissコールバックが呼ばれること
        XCTAssertTrue(dismissCalled, "閉じるボタンタップ時にonDismissが呼ばれること")
    }

    func testOnboardingModalViewVersionUpdate() throws {
        // Given: バージョンアップ用のオンボーディングコンテンツ
        let content = OnboardingContent(
            type: .versionUpdate(version: "1.1.0"),
            pages: [
                OnboardingPage(
                    title: "新機能追加",
                    description: "バージョン1.1.0の新機能",
                    imageName: "version_update"
                )
            ]
        )

        // When: バージョンアップ用OnboardingModalViewを作成
        let onboardingView = OnboardingModalView(
            content: content,
            isPresented: .constant(true),
            onDismiss: {}
        )

        // Then: バージョンアップ用コンテンツが正しく表示されること
        let body = try onboardingView.inspect().vStack()
        let contentVStack = try body.vStack(1)
        let titleText = try contentVStack.text(1).string()
        XCTAssertEqual(titleText, "新機能追加", "バージョンアップ用タイトルが表示されること")
        
        let descriptionText = try contentVStack.text(2).string()
        XCTAssertEqual(descriptionText, "バージョン1.1.0の新機能", "バージョンアップ用説明が表示されること")
    }

    func testOnboardingModalViewAccessibility() throws {
        // Given: オンボーディングコンテンツ
        let content = OnboardingContent(
            type: .firstLaunch,
            pages: [
                OnboardingPage(
                    title: "アクセシビリティテスト",
                    description: "アクセシビリティ説明",
                    imageName: "accessibility_test"
                )
            ]
        )

        // When: OnboardingModalViewを作成
        let onboardingView = OnboardingModalView(
            content: content,
            isPresented: .constant(true),
            onDismiss: {}
        )

        // Then: アクセシビリティ識別子が設定されていること
        let body = try onboardingView.inspect()
        XCTAssertNoThrow(try body.find(ViewType.VStack.self).accessibilityIdentifier("OnboardingModalView"))
        XCTAssertNoThrow(try body.find(ViewType.Button.self).accessibilityIdentifier("OnboardingCloseButton"))
    }
}