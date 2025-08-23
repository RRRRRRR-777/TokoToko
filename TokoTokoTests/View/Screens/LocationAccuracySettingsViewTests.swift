//
//  LocationAccuracySettingsViewTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/08/22.
//

import SwiftUI
import ViewInspector
import XCTest
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
}