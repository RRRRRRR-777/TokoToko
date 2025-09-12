//
//  OnboardingConfigTests.swift
//  TekuTokoTests
//
//  Created by Claude on 2025-08-11.
//

import XCTest
import Yams

@testable import TekuToko

final class OnboardingConfigTests: XCTestCase {

  // MARK: - TDD Red Phase - 失敗するテストケース

  func testOnboardingConfigShouldDecodeFromYML() {
    // Given: YMLファイルからのデコード
    let ymlString = """
      onboarding:
        first_launch:
          pages:
            - title: "テストタイトル"
              description: "テスト説明"
              image_name: "test_image"
      """

    // When: YMLをデコードしようとする
    do {
      let config = try YAMLDecoder().decode(OnboardingConfig.self, from: ymlString)
      // Then: TDD Green Phase - 正常にデコードできること
      XCTAssertNotNil(config, "OnboardingConfigが正常にデコードできること")
      XCTAssertNotNil(config.onboarding.firstLaunch, "firstLaunchセクションが存在すること")
      XCTAssertEqual(config.onboarding.firstLaunch?.pages.count, 1, "1つのページが含まれること")
      XCTAssertEqual(
        config.onboarding.firstLaunch?.pages.first?.title, "テストタイトル", "タイトルが正しくデコードされること")
    } catch {
      XCTFail("OnboardingConfigが実装済みの場合、デコードは成功するべき: \(error)")
    }
  }

  func testOnboardingDataShouldDecodeFirstLaunchSection() {
    // Given: first_launchセクションを含むYMLデータ
    let ymlString = """
      onboarding:
        first_launch:
          pages:
            - title: "ようこそ"
              description: "説明文"
              image_name: "image1"
            - title: "使い方"
              description: "使い方の説明"
              image_name: "image2"
      """

    // When: OnboardingDataをデコードしようとする
    do {
      let config = try YAMLDecoder().decode(OnboardingConfig.self, from: ymlString)
      // Then: TDD Green Phase - 正常にデコードできること
      XCTAssertNotNil(config.onboarding.firstLaunch, "firstLaunchセクションが存在すること")
      XCTAssertEqual(config.onboarding.firstLaunch?.pages.count, 2, "2つのページが含まれること")
      XCTAssertEqual(config.onboarding.firstLaunch?.pages[0].title, "ようこそ", "1つ目のページタイトルが正しいこと")
      XCTAssertEqual(config.onboarding.firstLaunch?.pages[1].title, "使い方", "2つ目のページタイトルが正しいこと")
    } catch {
      XCTFail("OnboardingDataが実装済みの場合、デコードは成功するべき: \(error)")
    }
  }

  func testOnboardingSectionShouldDecodePages() {
    // Given: pagesを含むセクションデータ
    let ymlString = """
      pages:
        - title: "タイトル1"
          description: "説明1"
          image_name: "画像1"
        - title: "タイトル2"
          description: "説明2"
          image_name: "画像2"
      """

    // When: OnboardingSectionをデコードしようとする
    do {
      let section = try YAMLDecoder().decode(OnboardingSection.self, from: ymlString)
      // Then: TDD Green Phase - 正常にデコードできること
      XCTAssertEqual(section.pages.count, 2, "2つのページが含まれること")
      XCTAssertEqual(section.pages[0].title, "タイトル1", "1つ目のページタイトルが正しいこと")
      XCTAssertEqual(section.pages[1].title, "タイトル2", "2つ目のページタイトルが正しいこと")
    } catch {
      XCTFail("OnboardingSectionが実装済みの場合、デコードは成功するべき: \(error)")
    }
  }

  func testOnboardingPageDataShouldDecodeWithCodingKeys() {
    // Given: snake_case形式のYMLデータ
    let ymlString = """
      title: "ページタイトル"
      description: "ページ説明"
      image_name: "page_image"
      """

    // When: OnboardingPageDataをデコードしようとする
    do {
      let page = try YAMLDecoder().decode(OnboardingPageData.self, from: ymlString)
      // Then: TDD Green Phase - 正常にデコードでき、CodingKeysが動作すること
      XCTAssertEqual(page.title, "ページタイトル", "タイトルが正しくデコードされること")
      XCTAssertEqual(page.description, "ページ説明", "説明が正しくデコードされること")
      XCTAssertEqual(
        page.imageName, "page_image", "snake_caseのimage_nameがcamelCaseのimageNameに変換されること")
    } catch {
      XCTFail("OnboardingPageDataが実装済みの場合、デコードは成功するべき: \(error)")
    }
  }

  func testVersionUpdatesShouldDecodeMultipleVersions() {
    // Given: 複数バージョンのversion_updatesデータ
    let ymlString = """
      onboarding:
        version_updates:
          "1.0":
            pages:
              - title: "バージョン1.0"
                description: "新機能追加"
                image_name: "v1_image"
          "2.0":
            pages:
              - title: "バージョン2.0"
                description: "大幅改善"
                image_name: "v2_image"
      """

    // When: version_updatesをデコードしようとする
    do {
      let config = try YAMLDecoder().decode(OnboardingConfig.self, from: ymlString)
      // Then: TDD Green Phase - version_updatesが正常にデコードできること
      XCTAssertNotNil(config.onboarding.versionUpdates, "version_updatesセクションが存在すること")
      XCTAssertEqual(config.onboarding.versionUpdates.count, 2, "2つのバージョンが含まれること")
      XCTAssertNotNil(config.onboarding.versionUpdates["1.0"], "バージョン1.0のセクションが存在すること")
      XCTAssertNotNil(config.onboarding.versionUpdates["2.0"], "バージョン2.0のセクションが存在すること")
      XCTAssertEqual(
        config.onboarding.versionUpdates["1.0"]?.pages.first?.title, "バージョン1.0",
        "バージョン1.0のタイトルが正しいこと")
    } catch {
      XCTFail("version_updatesが実装済みの場合、デコードは成功するべき: \(error)")
    }
  }

  func testInvalidYMLFormatShouldFail() {
    // Given: 不正な形式のYMLデータ
    let invalidYmlString = """
      invalid_structure:
        missing_required_fields: true
      """

    // When: 不正なYMLをデコードしようとする
    do {
      let config = try YAMLDecoder().decode(OnboardingConfig.self, from: invalidYmlString)
      // Then: 不正な形式なので失敗する
      XCTFail("不正なYML形式は失敗するべき")
    } catch {
      // Expected: 不正な形式は必ず失敗する
      XCTAssertTrue(true, "不正なYML形式の処理は失敗する")
    }
  }

  func testMissingRequiredFieldsShouldFail() {
    // Given: 必須フィールドが欠けているYMLデータ
    let incompleteYmlString = """
      onboarding:
        first_launch:
          pages:
            - title: "タイトルのみ"
              # description と image_name が欠けている
      """

    // When: 不完全なデータをデコードしようとする
    do {
      let config = try YAMLDecoder().decode(OnboardingConfig.self, from: incompleteYmlString)
      // Then: 必須フィールドが不足しているので失敗する
      XCTFail("必須フィールドが不足している場合は失敗するべき")
    } catch {
      // Expected: 必須フィールドの不足は失敗する
      XCTAssertTrue(true, "必須フィールドが不足した場合の処理は失敗する")
    }
  }
}
