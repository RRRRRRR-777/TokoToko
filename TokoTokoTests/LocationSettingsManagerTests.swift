//
//  LocationSettingsManagerTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/08/22.
//

import CoreLocation
import XCTest
@testable import TokoToko

/// LocationSettingsManagerの単体テスト
///
/// 位置情報精度設定の管理機能をテストします。
/// TDDアプローチにより、テストファーストで実装を進めます。
final class LocationSettingsManagerTests: XCTestCase {
  
  var sut: LocationSettingsManager!
  var mockUserDefaults: UserDefaults!
  
  override func setUp() {
    super.setUp()
    // テスト用のUserDefaultsを作成（実際のUserDefaultsを汚染しない）
    mockUserDefaults = UserDefaults(suiteName: "com.tokotoko.test")
    mockUserDefaults.removePersistentDomain(forName: "com.tokotoko.test")
    sut = LocationSettingsManager(userDefaults: mockUserDefaults)
  }
  
  override func tearDown() {
    sut = nil
    mockUserDefaults.removePersistentDomain(forName: "com.tokotoko.test")
    mockUserDefaults = nil
    super.tearDown()
  }
  
  // MARK: - 初期化テスト
  
  func test_初期化時_デフォルトでバランスモードが設定される() {
    // When
    let initialMode = sut.currentMode
    
    // Then
    XCTAssertEqual(initialMode, .balanced, "初期値はバランスモードであるべき")
  }
  
  func test_初期化時_バックグラウンド更新はデフォルトで有効() {
    // When
    let isEnabled = sut.isBackgroundUpdateEnabled
    
    // Then
    XCTAssertTrue(isEnabled, "バックグラウンド更新はデフォルトで有効であるべき")
  }
  
  // MARK: - モード変更テスト
  
  func test_精度モード変更_高精度モードに変更できる() {
    // When
    sut.setAccuracyMode(.highAccuracy)
    
    // Then
    XCTAssertEqual(sut.currentMode, .highAccuracy, "高精度モードに変更されるべき")
  }
  
  func test_精度モード変更_省電力モードに変更できる() {
    // When
    sut.setAccuracyMode(.batterySaving)
    
    // Then
    XCTAssertEqual(sut.currentMode, .batterySaving, "省電力モードに変更されるべき")
  }
  
  // MARK: - バックグラウンド更新設定テスト
  
  func test_バックグラウンド更新_無効に設定できる() {
    // When
    sut.setBackgroundUpdateEnabled(false)
    
    // Then
    XCTAssertFalse(sut.isBackgroundUpdateEnabled, "バックグラウンド更新が無効になるべき")
  }
  
  func test_バックグラウンド更新_有効に戻せる() {
    // Given
    sut.setBackgroundUpdateEnabled(false)
    
    // When
    sut.setBackgroundUpdateEnabled(true)
    
    // Then
    XCTAssertTrue(sut.isBackgroundUpdateEnabled, "バックグラウンド更新が有効になるべき")
  }
  
  // MARK: - 永続化テスト
  
  func test_設定保存_精度モードがUserDefaultsに保存される() {
    // When
    sut.setAccuracyMode(.highAccuracy)
    sut.saveSettings()
    
    // Then
    let savedMode = mockUserDefaults.string(forKey: "locationAccuracyMode")
    XCTAssertEqual(savedMode, "high", "高精度モードがUserDefaultsに保存されるべき")
  }
  
  func test_設定保存_バックグラウンド更新設定がUserDefaultsに保存される() {
    // When
    sut.setBackgroundUpdateEnabled(false)
    sut.saveSettings()
    
    // Then
    let savedEnabled = mockUserDefaults.bool(forKey: "backgroundUpdateEnabled")
    XCTAssertFalse(savedEnabled, "バックグラウンド更新設定がUserDefaultsに保存されるべき")
  }
  
  func test_設定読み込み_保存された精度モードが復元される() {
    // Given
    mockUserDefaults.set("battery", forKey: "locationAccuracyMode")
    
    // When
    sut.loadSettings()
    
    // Then
    XCTAssertEqual(sut.currentMode, .batterySaving, "保存された省電力モードが復元されるべき")
  }
  
  func test_設定読み込み_保存されたバックグラウンド設定が復元される() {
    // Given
    mockUserDefaults.set(false, forKey: "backgroundUpdateEnabled")
    
    // When
    sut.loadSettings()
    
    // Then
    XCTAssertFalse(sut.isBackgroundUpdateEnabled, "保存されたバックグラウンド設定が復元されるべき")
  }
  
  // MARK: - LocationManager適用テスト
  
  func test_LocationManager適用_高精度モードの設定値が正しい() {
    // Given
    let mockLocationManager = MockCLLocationManager()
    
    // When
    sut.setAccuracyMode(.highAccuracy)
    sut.applySettingsToLocationManager(mockLocationManager)
    
    // Then
    XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyBest)
    XCTAssertEqual(mockLocationManager.distanceFilter, 5.0)
  }
  
  func test_LocationManager適用_バランスモードの設定値が正しい() {
    // Given
    let mockLocationManager = MockCLLocationManager()
    
    // When
    sut.setAccuracyMode(.balanced)
    sut.applySettingsToLocationManager(mockLocationManager)
    
    // Then
    XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyNearestTenMeters)
    XCTAssertEqual(mockLocationManager.distanceFilter, 20.0)
  }
  
  func test_LocationManager適用_省電力モードの設定値が正しい() {
    // Given
    let mockLocationManager = MockCLLocationManager()
    
    // When
    sut.setAccuracyMode(.batterySaving)
    sut.applySettingsToLocationManager(mockLocationManager)
    
    // Then
    XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyHundredMeters)
    XCTAssertEqual(mockLocationManager.distanceFilter, 50.0)
  }
  
  func test_LocationManager適用_バックグラウンド更新設定が適用される() {
    // Given
    let mockLocationManager = MockCLLocationManager()
    
    // When
    sut.setBackgroundUpdateEnabled(false)
    sut.applySettingsToLocationManager(mockLocationManager)
    
    // Then
    XCTAssertFalse(mockLocationManager.allowsBackgroundLocationUpdates)
  }
}

// MARK: - Mock Classes

/// CLLocationManagerのモッククラス
///
/// テストで実際のCLLocationManagerの代わりに使用
class MockCLLocationManager: CLLocationManager {
  var mockDesiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
  var mockDistanceFilter: CLLocationDistance = kCLDistanceFilterNone
  var mockAllowsBackgroundLocationUpdates = true
  
  override var desiredAccuracy: CLLocationAccuracy {
    get { mockDesiredAccuracy }
    set { mockDesiredAccuracy = newValue }
  }
  
  override var distanceFilter: CLLocationDistance {
    get { mockDistanceFilter }
    set { mockDistanceFilter = newValue }
  }
  
  override var allowsBackgroundLocationUpdates: Bool {
    get { mockAllowsBackgroundLocationUpdates }
    set { mockAllowsBackgroundLocationUpdates = newValue }
  }
}