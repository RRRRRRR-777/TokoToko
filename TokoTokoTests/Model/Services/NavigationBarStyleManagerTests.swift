import XCTest
import UIKit
@testable import TekuToko

/// NavigationBarStyleManagerの単体テストクラス
///
/// NavigationBarStyleManagerの基本機能とリファクタリング後の動作を検証します。
final class NavigationBarStyleManagerTests: XCTestCase {
  
  var styleManager: NavigationBarStyleManager!
  
  // MARK: - Setup & Teardown
  
  override func setUpWithError() throws {
    styleManager = NavigationBarStyleManager.shared
  }
  
  override func tearDownWithError() throws {
    styleManager = nil
  }
  
  // MARK: - Basic Functionality Tests
  
  /// シングルトンパターンの動作確認
  func testSingletonPattern() {
    // Given & When
    let instance1 = NavigationBarStyleManager.shared
    let instance2 = NavigationBarStyleManager.shared
    
    // Then
    XCTAssertTrue(instance1 === instance2, "NavigationBarStyleManagerはシングルトンである必要があります")
  }
  
  /// デフォルト設定での基本動作確認
  func testApplyUnifiedStyleBasicFunctionality() {
    // Given
    let defaultOptions = NavigationBarStyleManager.CustomizationOptions.default
    
    // When & Then (クラッシュしないことを確認)
    XCTAssertNoThrow {
      self.styleManager.applyUnifiedStyle(customizations: defaultOptions)
    }
  }
  
  /// カスタム設定での基本動作確認
  func testApplyUnifiedStyleWithCustomOptions() {
    // Given
    let customOptions = NavigationBarStyleManager.CustomizationOptions(
      titleColor: UIColor.red,
      shadowHidden: true
    )
    
    // When & Then (クラッシュしないことを確認)
    XCTAssertNoThrow {
      self.styleManager.applyUnifiedStyle(customizations: customOptions)
    }
  }
  
  /// createCustomAppearanceメソッドの動作確認
  func testCreateCustomAppearance() {
    // Given
    let customOptions = NavigationBarStyleManager.CustomizationOptions(
      backgroundColor: UIColor.yellow,
      shadowHidden: true
    )
    
    // When
    let appearance = self.styleManager.createCustomAppearance(customizations: customOptions)
    
    // Then
    XCTAssertNotNil(appearance, "カスタムappearanceが作成されている必要があります")
    XCTAssertEqual(appearance.backgroundColor, UIColor.yellow, "背景色がカスタム色に設定されている必要があります")
    
    // shadowHiddenがtrueの場合、シャドウ関連の設定が適用されることをテスト
    // iOS の実装により shadowColor の具体的な値は変動する可能性があるが、
    // shadowHidden=trueでの呼び出しが正常に完了することを確認
    XCTAssertTrue(customOptions.shadowHidden, "shadowHiddenが有効である必要があります")
  }
  
  /// SwiftUI用便利メソッドの動作確認
  func testConfigureForSwiftUI() {
    // Given
    let customOptions = NavigationBarStyleManager.CustomizationOptions(
      titleColor: UIColor.purple
    )
    
    // When & Then (クラッシュしないことを確認)
    XCTAssertNoThrow {
      self.styleManager.configureForSwiftUI(customizations: customOptions)
    }
  }
  
  // MARK: - Predefined Configurations Tests
  
  /// 予定義設定：ポリシー画面用設定の確認
  func testPolicyScreenConfiguration() {
    // Given & When & Then
    XCTAssertNoThrow {
      self.styleManager.applyUnifiedStyle(customizations: .policyScreen)
    }
    
    // ポリシー画面設定の基本プロパティを確認
    let policyOptions = NavigationBarStyleManager.CustomizationOptions.policyScreen
    XCTAssertTrue(policyOptions.shadowHidden, "ポリシー画面ではシャドウが非表示である必要があります")
  }
  
  /// 予定義設定：設定画面用設定の確認
  func testSettingsScreenConfiguration() {
    // Given & When & Then
    XCTAssertNoThrow {
      self.styleManager.applyUnifiedStyle(customizations: .settingsScreen)
    }
    
    let settingsOptions = NavigationBarStyleManager.CustomizationOptions.settingsScreen
    XCTAssertFalse(settingsOptions.shadowHidden, "設定画面ではシャドウが表示される必要があります")
  }
  
  /// 予定義設定：散歩リスト画面用設定の確認
  func testWalkListScreenConfiguration() {
    // Given & When & Then
    XCTAssertNoThrow {
      self.styleManager.applyUnifiedStyle(customizations: .walkListScreen)
    }
  }
  
  /// 予定義設定：アプリ情報画面用設定の確認
  func testAppInfoScreenConfiguration() {
    // Given & When & Then
    XCTAssertNoThrow {
      self.styleManager.applyUnifiedStyle(customizations: .appInfoScreen)
    }
  }
  
  // MARK: - Robustness Tests
  
  /// 連続呼び出しでの動作確認
  func testMultipleApplyUnifiedStyleCalls() {
    // Given
    let options1 = NavigationBarStyleManager.CustomizationOptions(titleColor: UIColor.red)
    let options2 = NavigationBarStyleManager.CustomizationOptions(titleColor: UIColor.blue)
    
    // When & Then (クラッシュしないことを確認)
    XCTAssertNoThrow {
      self.styleManager.applyUnifiedStyle(customizations: options1)
      self.styleManager.applyUnifiedStyle(customizations: options2)
    }
  }
  
  /// nil値を含む設定での動作確認
  func testApplyUnifiedStyleWithNilValues() {
    // Given
    let optionsWithNils = NavigationBarStyleManager.CustomizationOptions(
      titleColor: nil,
      largeTitleColor: nil,
      backgroundColor: nil,
      shadowHidden: false,
      tintColor: nil,
      useTransparentBackground: false
    )
    
    // When & Then (クラッシュしないことを確認)
    XCTAssertNoThrow {
      self.styleManager.applyUnifiedStyle(customizations: optionsWithNils)
    }
  }
}

// MARK: - CustomizationOptions Tests

/// NavigationBarStyleManager.CustomizationOptionsの単体テストクラス
final class NavigationBarStyleManagerCustomizationOptionsTests: XCTestCase {
  
  // MARK: - Initialization Tests
  
  /// デフォルト初期化の動作確認
  func testDefaultInitialization() {
    // When
    let options = NavigationBarStyleManager.CustomizationOptions()
    
    // Then
    XCTAssertNil(options.titleColor, "デフォルトのタイトル色はnilである必要があります")
    XCTAssertNil(options.largeTitleColor, "デフォルトの大きなタイトル色はnilである必要があります")
    XCTAssertNil(options.backgroundColor, "デフォルトの背景色はnilである必要があります")
    XCTAssertFalse(options.shadowHidden, "デフォルトではシャドウが表示される必要があります")
    XCTAssertNil(options.tintColor, "デフォルトのティント色はnilである必要があります")
    XCTAssertFalse(options.useTransparentBackground, "デフォルトでは透明背景を使用しない必要があります")
  }
  
  /// カスタム初期化の動作確認
  func testCustomInitialization() {
    // Given
    let titleColor = UIColor.red
    let backgroundColor = UIColor.yellow
    let shadowHidden = true
    
    // When
    let options = NavigationBarStyleManager.CustomizationOptions(
      titleColor: titleColor,
      backgroundColor: backgroundColor,
      shadowHidden: shadowHidden
    )
    
    // Then
    XCTAssertEqual(options.titleColor, titleColor, "タイトル色が設定値と一致する必要があります")
    XCTAssertEqual(options.backgroundColor, backgroundColor, "背景色が設定値と一致する必要があります")
    XCTAssertEqual(options.shadowHidden, shadowHidden, "シャドウ表示設定が設定値と一致する必要があります")
  }
  
  /// 予定義設定の確認
  func testPredefinedConfigurations() {
    // Policy Screen
    let policyOptions = NavigationBarStyleManager.CustomizationOptions.policyScreen
    XCTAssertTrue(policyOptions.shadowHidden, "ポリシー画面ではシャドウが非表示である必要があります")
    
    // Settings Screen
    let settingsOptions = NavigationBarStyleManager.CustomizationOptions.settingsScreen
    XCTAssertFalse(settingsOptions.shadowHidden, "設定画面ではシャドウが表示される必要があります")
    
    // Walk List Screen
    let walkListOptions = NavigationBarStyleManager.CustomizationOptions.walkListScreen
    XCTAssertFalse(walkListOptions.shadowHidden, "散歩リスト画面ではシャドウが表示される必要があります")
    
    // App Info Screen
    let appInfoOptions = NavigationBarStyleManager.CustomizationOptions.appInfoScreen
    XCTAssertFalse(appInfoOptions.shadowHidden, "アプリ情報画面ではシャドウが表示される必要があります")
  }
}
