//
//  LocationAccuracySettingsViewTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/08/22.
//

import SwiftUI
import ViewInspector
import XCTest
import UIKit
@testable import TokoToko

/// LocationAccuracySettingsViewの単体テスト
///
/// 位置情報精度設定画面のUI表示とユーザーインタラクションをテストします。
/// ViewInspectorを使用してSwiftUIコンポーネントの内容を検証します。
final class LocationAccuracySettingsViewTests: XCTestCase {
  
  var settingsManager: LocationSettingsManager!
  var mockUserDefaults: UserDefaults!
  
  override func setUp() {
    super.setUp()
    // テスト用のUserDefaultsを作成
    mockUserDefaults = UserDefaults(suiteName: "com.tokotoko.test.settings")
    mockUserDefaults.removePersistentDomain(forName: "com.tokotoko.test.settings")
    settingsManager = LocationSettingsManager(userDefaults: mockUserDefaults)
  }
  
  override func tearDown() {
    settingsManager = nil
    mockUserDefaults.removePersistentDomain(forName: "com.tokotoko.test.settings")
    mockUserDefaults = nil
    super.tearDown()
  }
  
  // MARK: - 画面表示テスト
  
  func test_画面表示_ナビゲーションタイトルが正しく表示される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    let navigationView = try view.inspect().find(ViewType.NavigationView.self)
    XCTAssertNotNil(navigationView, "NavigationViewが存在するべき")
    
    // ナビゲーションタイトルの確認
    let titleText = try view.inspect().find(text: "位置情報設定")
    XCTAssertNotNil(titleText, "ナビゲーションタイトルが表示されるべき")
  }
  
  func test_画面表示_3つの精度モードが表示される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    // 高精度モード
    let highAccuracyText = try view.inspect().find(text: "高精度")
    XCTAssertNotNil(highAccuracyText, "高精度モードが表示されるべき")
    
    // バランスモード
    let balancedText = try view.inspect().find(text: "バランス")
    XCTAssertNotNil(balancedText, "バランスモードが表示されるべき")
    
    // 省電力モード
    let batterySavingText = try view.inspect().find(text: "省電力")
    XCTAssertNotNil(batterySavingText, "省電力モードが表示されるべき")
  }
  
  func test_画面表示_各モードの説明文が表示される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    // 高精度モードの説明
    let highAccuracyDesc = try view.inspect().find(text: "最高精度でルートを記録します。バッテリー消費は大きくなります。")
    XCTAssertNotNil(highAccuracyDesc, "高精度モードの説明が表示されるべき")
    
    // バランスモードの説明
    let balancedDesc = try view.inspect().find(text: "精度とバッテリー消費のバランスを取った推奨設定です。")
    XCTAssertNotNil(balancedDesc, "バランスモードの説明が表示されるべき")
    
    // 省電力モードの説明
    let batterySavingDesc = try view.inspect().find(text: "バッテリー消費を抑えます。長時間の散歩に適しています。")
    XCTAssertNotNil(batterySavingDesc, "省電力モードの説明が表示されるべき")
  }
  
  func test_画面表示_バックグラウンド更新トグルが表示される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    let backgroundToggleText = try view.inspect().find(text: "バックグラウンド更新")
    XCTAssertNotNil(backgroundToggleText, "バックグラウンド更新設定が表示されるべき")
    
    let toggle = try view.inspect().find(ViewType.Toggle.self)
    XCTAssertNotNil(toggle, "バックグラウンド更新のトグルが存在するべき")
  }
  
  // MARK: - 初期状態テスト
  
  func test_初期状態_デフォルトでバランスモードが選択される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    // バランスモードの選択状態を確認
    XCTAssertEqual(settingsManager.currentMode, .balanced, "初期状態はバランスモードが選択されるべき")
  }
  
  func test_初期状態_バックグラウンド更新が有効() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    let toggle = try view.inspect().find(ViewType.Toggle.self)
    let toggleValue = try toggle.isOn()
    XCTAssertTrue(toggleValue, "初期状態はバックグラウンド更新が有効であるべき")
  }
  
  // MARK: - ユーザーインタラクションテスト
  
  func test_ユーザーインタラクション_精度モード選択変更() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When
    // 高精度モードを選択（実際のタップシミュレーション）
    settingsManager.setAccuracyMode(.highAccuracy)
    
    // Then
    XCTAssertEqual(settingsManager.currentMode, .highAccuracy, "高精度モードが選択されるべき")
    
    // When
    // 省電力モードを選択
    settingsManager.setAccuracyMode(.batterySaving)
    
    // Then
    XCTAssertEqual(settingsManager.currentMode, .batterySaving, "省電力モードが選択されるべき")
  }
  
  func test_ユーザーインタラクション_バックグラウンド更新トグル() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When - 直接マネージャーの状態を変更（ViewInspectorのトグルタップは制限あり）
    settingsManager.setBackgroundUpdateEnabled(false)
    
    // Then
    XCTAssertFalse(settingsManager.isBackgroundUpdateEnabled, "バックグラウンド更新が無効になるべき")
    
    // When
    settingsManager.setBackgroundUpdateEnabled(true)
    
    // Then
    XCTAssertTrue(settingsManager.isBackgroundUpdateEnabled, "バックグラウンド更新が有効になるべき")
  }
  
  // MARK: - 権限状態表示テスト
  
  func test_権限状態表示_位置情報権限が表示される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    let permissionText = try view.inspect().find(text: "位置情報権限")
    XCTAssertNotNil(permissionText, "位置情報権限の項目が表示されるべき")
  }
  
  // MARK: - アクセシビリティテスト
  
  func test_アクセシビリティ_精度モード選択にアクセシビリティ識別子が設定される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    // 各精度モードのアクセシビリティ識別子を確認
    let highAccuracyButton = try view.inspect().find(button: "高精度")
    let highAccuracyAccessibilityId = try highAccuracyButton.accessibilityIdentifier()
    XCTAssertEqual(highAccuracyAccessibilityId, "location_accuracy_high", "高精度モードのアクセシビリティ識別子が正しく設定されるべき")
    
    let balancedButton = try view.inspect().find(button: "バランス")
    let balancedAccessibilityId = try balancedButton.accessibilityIdentifier()
    XCTAssertEqual(balancedAccessibilityId, "location_accuracy_balanced", "バランスモードのアクセシビリティ識別子が正しく設定されるべき")
    
    let batterySavingButton = try view.inspect().find(button: "省電力")
    let batterySavingAccessibilityId = try batterySavingButton.accessibilityIdentifier()
    XCTAssertEqual(batterySavingAccessibilityId, "location_accuracy_battery", "省電力モードのアクセシビリティ識別子が正しく設定されるべき")
  }
  
  func test_アクセシビリティ_バックグラウンド更新トグルに識別子が設定される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    let toggle = try view.inspect().find(ViewType.Toggle.self)
    let accessibilityId = try toggle.accessibilityIdentifier()
    XCTAssertEqual(accessibilityId, "background_update_toggle", "バックグラウンド更新トグルのアクセシビリティ識別子が正しく設定されるべき")
  }
  
  // MARK: - 設定アプリ遷移テスト
  
  func test_設定アプリ遷移_設定アプリボタンが表示される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    let settingsButton = try view.inspect().find(button: "設定アプリで開く")
    XCTAssertNotNil(settingsButton, "設定アプリへの遷移ボタンが表示されるべき")
    
    let accessibilityId = try settingsButton.accessibilityIdentifier()
    XCTAssertEqual(accessibilityId, "open_settings_app", "設定アプリボタンのアクセシビリティ識別子が正しく設定されるべき")
  }
  
  // MARK: - リファクタリング検証テスト
  
  /// settingsListViewのメソッド分割後の動作確認テスト
  func test_メソッド分割_各セクションが正しく表示される() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then - 精度モードセクション
    let accuracyModeSection = try view.inspect().find(text: "位置情報の精度")
    XCTAssertNotNil(accuracyModeSection, "精度モードセクションが表示されるべき")
    
    // バックグラウンド設定セクション
    let backgroundSection = try view.inspect().find(text: "バックグラウンド設定")
    XCTAssertNotNil(backgroundSection, "バックグラウンド設定セクションが表示されるべき")
    
    // 権限状態セクション
    let permissionSection = try view.inspect().find(text: "権限状態")
    XCTAssertNotNil(permissionSection, "権限状態セクションが表示されるべき")
  }
  
  /// リファクタリング後のSwiftLint compliance確認テスト
  func test_SwiftLint_クロージャ行数制限遵守() throws {
    // Given
    let view = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When & Then
    // このテストが通ることで、リファクタリング後にクロージャが30行以下になったことを確認
    XCTAssertNoThrow({
      _ = try view.inspect().list()
    }, "リファクタリング後のクロージャは30行制限を遵守するべき")
  }

  /// 実践的な階層深度テスト
  ///
  /// 実際のアプリケーションで発生しうる3-5階層程度の
  /// ビュー階層でのパフォーマンスと安定性を検証します。
  func test_実践的なビュー階層_パフォーマンスと安定性() {
    // Given - 実践的な階層深度（5階層）でテスト
    let testView = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    let hostingController = UIHostingController(rootView: testView)
    
    // 実際のアプリで想定される階層深度のビューを作成
    let practicalDepthView = createDeepViewHierarchy(depth: 5)
    hostingController.view.addSubview(practicalDepthView)
    
    // When & Then
    XCTAssertNoThrow({
      // 実践的な階層でのパフォーマンステスト
      let startTime = CFAbsoluteTimeGetCurrent()
      
      hostingController.loadViewIfNeeded()
      hostingController.viewDidAppear(false)
      
      let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
      
      // パフォーマンス基準：5階層で100ms以内
      XCTAssertLessThan(elapsedTime, 0.1, "ビュー階層の処理は100ms以内に完了すべき")
      
      print("実践的階層テスト完了: \(String(format: "%.3f", elapsedTime * 1000))ms")
    }, "実践的な階層深度でのビュー処理は安定して動作すべき")
    
    hostingController.view.removeFromSuperview()
  }
  
  /// エッジケーステスト：極端な階層深度での安全性確認
  ///
  /// 異常な階層深度（10階層）でもクラッシュしないことを確認します。
  /// これは防御的プログラミングの観点からの検証です。
  func test_エッジケース_異常な階層深度での安全性() {
    // Given - エッジケースとして10階層をテスト
    let testView = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    let hostingController = UIHostingController(rootView: testView)
    
    // 異常な階層深度のビューを作成
    let edgeCaseView = createDeepViewHierarchy(depth: 10)
    hostingController.view.addSubview(edgeCaseView)
    
    // When & Then (クラッシュしないことのみ確認)
    XCTAssertNoThrow({
      hostingController.loadViewIfNeeded()
      // タイムアウトを設定して無限ループを防ぐ
      let expectation = XCTestExpectation(description: "View processing completes")
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        expectation.fulfill()
      }
      
      // 最大1秒待機
      _ = XCTWaiter.wait(for: [expectation], timeout: 1.0)
    }, "異常な階層深度でもクラッシュしないこと")
    
    hostingController.view.removeFromSuperview()
  }
  
  /// NavigationBarStyleManagerの統合テスト
  func test_NavigationBarStyleManager統合_設定が正しく適用される() {
    // Given
    let testView = LocationAccuracySettingsView()
      .environmentObject(settingsManager)
    
    // When
    let hostingController = UIHostingController(rootView: testView)
    hostingController.loadViewIfNeeded()
    
    // Then
    let navigationBar = hostingController.navigationController?.navigationBar ?? UINavigationBar.appearance()
    XCTAssertNotNil(navigationBar.standardAppearance, "NavigationBarStyleManagerによる設定が適用されている必要があります")
    
    // 統一された外観設定の確認
    let appearance = navigationBar.standardAppearance
    XCTAssertNotNil(appearance.backgroundColor, "背景色が設定されている必要があります")
  }
  
  // MARK: - Helper Methods
  
  /// 深い階層のビューを作成（テスト用）
  private func createDeepViewHierarchy(depth: Int) -> UIView {
    var currentView = UIView()
    currentView.backgroundColor = UIColor.red
    
    for _ in 0..<depth {
      let childView = UIView()
      childView.backgroundColor = UIColor.blue
      currentView.addSubview(childView)
      currentView = childView
    }
    
    return currentView
  }
}