//
//  AppConfigTests.swift
//  TekuTokoTests
//
//  Created by Assistant on 2025/12/01.
//

import XCTest

@testable import TekuToko

final class AppConfigTests: XCTestCase {

  // MARK: - Environment Enum Tests

  /// 期待値: Environment enumが全ての環境を持つ
  func testEnvironmentEnumCases() {
    // 全てのケースが存在することを確認
    XCTAssertNotNil(AppConfig.Environment.debug)
    XCTAssertNotNil(AppConfig.Environment.development)
    XCTAssertNotNil(AppConfig.Environment.staging)
    XCTAssertNotNil(AppConfig.Environment.release)
  }

  /// 期待値: Environment rawValueが正しい文字列
  func testEnvironmentRawValues() {
    XCTAssertEqual(AppConfig.Environment.debug.rawValue, "debug")
    XCTAssertEqual(AppConfig.Environment.development.rawValue, "development")
    XCTAssertEqual(AppConfig.Environment.staging.rawValue, "staging")
    XCTAssertEqual(AppConfig.Environment.release.rawValue, "release")
  }

  /// 期待値: 文字列からEnvironmentを生成できる
  func testEnvironmentInitFromRawValue() {
    XCTAssertEqual(AppConfig.Environment(rawValue: "debug"), .debug)
    XCTAssertEqual(AppConfig.Environment(rawValue: "development"), .development)
    XCTAssertEqual(AppConfig.Environment(rawValue: "staging"), .staging)
    XCTAssertEqual(AppConfig.Environment(rawValue: "release"), .release)
    XCTAssertNil(AppConfig.Environment(rawValue: "invalid"))
  }

  // MARK: - Info.plist Integration Tests
  // 注: これらのテストはDebug configurationでビルドされた場合の値を検証

  /// 期待値: currentEnvironmentがInfo.plistから取得できる
  func testCurrentEnvironmentFromInfoPlist() {
    // Debug configurationでビルドされている場合、debugが返る
    let environment = AppConfig.currentEnvironment
    XCTAssertNotNil(environment)
    // Debug buildの場合
    XCTAssertEqual(environment, .debug)
  }

  /// 期待値: baseURLがInfo.plistのURLコンポーネントから組み立てられる
  func testBaseURLFromInfoPlist() {
    let url = AppConfig.baseURL
    XCTAssertNotNil(url)
    // Debug configurationの場合、localhost:8080
    XCTAssertEqual(url.absoluteString, "http://localhost:8080")
  }

  /// 期待値: useGoBackendがInfo.plistから取得できる
  func testUseGoBackendFromInfoPlist() {
    // Base.xcconfigでUSE_GO_BACKEND = NOに設定
    let useGoBackend = AppConfig.useGoBackend
    XCTAssertFalse(useGoBackend)
  }

  /// 期待値: baseURLが有効なURLである
  func testBaseURLIsValid() {
    let url = AppConfig.baseURL
    XCTAssertNotNil(url.scheme)
    XCTAssertNotNil(url.host)
  }
}
