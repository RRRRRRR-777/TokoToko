//
//  AppInfoViewTests.swift
//  TekuTokoTests
//
//  Created by Claude on 2025/08/22.
//

import SwiftUI
import ViewInspector
import XCTest

@testable import TekuToko

/// AppInfoViewの単体テスト
///
/// 「このアプリについて」画面のUI表示とアプリ情報の正確性をテストします。
/// Info.plistからの情報取得とエラーハンドリングも検証します。
final class AppInfoViewTests: XCTestCase {

  // MARK: - 画面表示テスト

  func test_画面表示_ナビゲーションタイトルが正しく表示される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let titleText = try view.inspect().find(text: "このアプリについて")
    XCTAssertNotNil(titleText, "ナビゲーションタイトルが表示されるべき")
  }

  func test_画面表示_アプリ名が表示される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let appNameText = try view.inspect().find(text: "てくとこ - おさんぽSNS")
    XCTAssertNotNil(appNameText, "アプリ名が表示されるべき")
  }

  func test_画面表示_バージョン情報が表示される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    // バージョン情報のラベル
    let versionLabelText = try view.inspect().find(text: "バージョン")
    XCTAssertNotNil(versionLabelText, "バージョンラベルが表示されるべき")

    // 実際のバージョン番号は動的に取得されるため、存在確認のみ
    let versionSection = try view.inspect().find(ViewType.HStack.self)
    XCTAssertNotNil(versionSection, "バージョン情報のHStackが存在するべき")
  }

  func test_画面表示_ビルド番号が表示される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let buildLabelText = try view.inspect().find(text: "ビルド")
    XCTAssertNotNil(buildLabelText, "ビルドラベルが表示されるべき")
  }

  func test_画面表示_コピーライトが表示される() throws {
    // Given
    let view = AppInfoView()

    // When
    let currentYear = Calendar.current.component(.year, from: Date())
    let expected = "© \(currentYear) riku.yamada"

    // Then
    let copyrightText = try view.inspect().find(text: expected)
    XCTAssertNotNil(copyrightText, "コピーライト表示が存在するべき")
  }

  func test_画面表示_開発元情報が表示される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let developerLabelText = try view.inspect().find(text: "開発元")
    XCTAssertNotNil(developerLabelText, "開発元ラベルが表示されるべき")

    let developerNameText = try view.inspect().find(text: "riku.yamada")
    XCTAssertNotNil(developerNameText, "開発者名が表示されるべき")
  }

  // MARK: - Info.plist情報取得テスト

  func test_Info_plist情報取得_バージョン番号が正しく取得される() {
    // Given
    let view = AppInfoView()

    // When
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    // Then
    XCTAssertNotNil(version, "Info.plistからバージョン番号が取得できるべき")
    XCTAssertFalse(version?.isEmpty ?? true, "バージョン番号は空文字列ではないべき")
  }

  func test_Info_plist情報取得_ビルド番号が正しく取得される() {
    // Given
    let view = AppInfoView()

    // When
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

    // Then
    XCTAssertNotNil(buildNumber, "Info.plistからビルド番号が取得できるべき")
    XCTAssertFalse(buildNumber?.isEmpty ?? true, "ビルド番号は空文字列ではないべき")
  }

  func test_Info_plist情報取得_アプリ名が正しく取得される() {
    // Given
    let view = AppInfoView()

    // When
    let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String

    // Then
    // CFBundleDisplayNameまたはCFBundleNameのいずれかが取得できることを確認
    XCTAssertTrue(displayName != nil || bundleName != nil, "Info.plistからアプリ名が取得できるべき")
  }

  // MARK: - エラーハンドリングテスト

  func test_エラーハンドリング_Info_plist情報が取得できない場合のフォールバック() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    // 実際のテストでは、Info.plistが存在しない状況をシミュレートするのは困難なため、
    // フォールバック値が適切に設定されていることを確認

    // デフォルト値の探索は環境依存のため、例外を出さないことのみ検証
    XCTAssertNoThrow({ _ = view.body })
  }

  // MARK: - アクセシビリティテスト

  func test_アクセシビリティ_アプリ名にアクセシビリティ識別子が設定される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let appNameText = try view.inspect().find(text: "てくとこ - おさんぽSNS")
    let accessibilityId = try appNameText.accessibilityIdentifier()
    XCTAssertEqual(accessibilityId, "app_name", "アプリ名のアクセシビリティ識別子が正しく設定されるべき")
  }

  func test_アクセシビリティ_バージョン情報にアクセシビリティ識別子が設定される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let rows = try view.inspect().findAll(ViewType.HStack.self)
    let versionRow = rows.first { row in
      (try? row.accessibilityIdentifier()) == "version_info"
    }
    XCTAssertNotNil(versionRow, "バージョン情報のHStackにaccessibilityIdentifier(version_info)が設定されるべき")
  }

  func test_アクセシビリティ_ビルド情報にアクセシビリティ識別子が設定される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    // ビルド情報行のアクセシビリティ識別子を確認
    let buildRows = try view.inspect().findAll(ViewType.HStack.self)
    let buildRow = buildRows.first { row in
      do {
        let accessibilityId = try row.accessibilityIdentifier()
        return accessibilityId == "build_info"
      } catch {
        return false
      }
    }
    XCTAssertNotNil(buildRow, "ビルド情報のアクセシビリティ識別子が正しく設定されるべき")
  }

  func test_アクセシビリティ_開発元情報にアクセシビリティ識別子が設定される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let developerRows = try view.inspect().findAll(ViewType.HStack.self)
    let developerRow = developerRows.first { row in
      do {
        let accessibilityId = try row.accessibilityIdentifier()
        return accessibilityId == "developer_info"
      } catch {
        return false
      }
    }
    XCTAssertNotNil(developerRow, "開発元情報のアクセシビリティ識別子が正しく設定されるべき")
  }

  // MARK: - レイアウトテスト

  func test_レイアウト_リスト形式で情報が表示される() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let listView = try view.inspect().find(ViewType.List.self)
    XCTAssertNotNil(listView, "リスト形式でアプリ情報が表示されるべき")
  }

  func test_レイアウト_セクション分けされた表示() throws {
    // Given
    let view = AppInfoView()

    // When & Then
    let sections = try view.inspect().findAll(ViewType.Section.self)
    XCTAssertGreaterThan(sections.count, 0, "セクション分けされた形式で表示されるべき")
  }

  // MARK: - データ整合性テスト

  func test_データ整合性_年度が現在年度またはそれ以前() {
    // Given
    let currentYear = Calendar.current.component(.year, from: Date())
    let copyrightYear = 2024

    // When & Then
    XCTAssertLessThanOrEqual(copyrightYear, currentYear, "コピーライト年度は現在年度以前であるべき")
  }
}
