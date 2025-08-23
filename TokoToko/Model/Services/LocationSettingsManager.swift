//
//  LocationSettingsManager.swift
//  TokoToko
//
//  Created by Claude on 2025/08/22.
//

import CoreLocation
import Foundation

/// 位置情報設定の管理クラス
///
/// アプリの位置情報精度設定とバックグラウンド更新設定を管理します。
/// UserDefaultsを使用した設定の永続化と、LocationManagerへの設定適用を行います。
///
/// ## Overview
///
/// 主要な機能：
/// - **精度モード管理**: 高精度/バランス/省電力の3モード切り替え
/// - **バックグラウンド更新**: ON/OFF切り替え機能
/// - **永続化**: UserDefaultsを使用した設定保存・復元
/// - **LocationManager連携**: 設定値のLocationManagerへの適用
///
/// ## Topics
///
/// ### Properties
/// - ``currentMode``
/// - ``isBackgroundUpdateEnabled``
///
/// ### Configuration Methods
/// - ``setAccuracyMode(_:)``
/// - ``setBackgroundUpdateEnabled(_:)``
///
/// ### Persistence Methods
/// - ``saveSettings()``
/// - ``loadSettings()``
///
/// ### LocationManager Integration
/// - ``applySettingsToLocationManager(_:)``
class LocationSettingsManager: ObservableObject {

  // MARK: - Singleton

  /// LocationSettingsManagerのシングルトンインスタンス
  ///
  /// アプリ全体で単一の設定管理インスタンスを使用し、
  /// 設定状態の一貫性を保証します。
  static let shared = LocationSettingsManager()

  // MARK: - Properties

  /// 現在の位置情報精度モード
  ///
  /// 現在選択されている精度モードです。
  /// @Publishedにより、値が変更されるとUI側に自動的に反映されます。
  @Published private(set) var currentMode: LocationAccuracyMode

  /// バックグラウンド更新の有効状態
  ///
  /// バックグラウンドでの位置情報更新が有効かどうかを示します。
  /// @Publishedにより、値が変更されるとUI側に自動的に反映されます。
  @Published private(set) var isBackgroundUpdateEnabled: Bool

  /// 設定永続化に使用するUserDefaults
  ///
  /// 通常はUserDefaults.standardを使用しますが、
  /// テスト時は独立したUserDefaultsインスタンスを注入できます。
  private let userDefaults: UserDefaults

  // MARK: - UserDefaults Keys

  /// バックグラウンド更新設定のUserDefaultsキー
  private static let backgroundUpdateEnabledKey = "backgroundUpdateEnabled"

  // MARK: - Initialization

  /// LocationSettingsManagerの初期化
  ///
  /// - Parameter userDefaults: 設定保存に使用するUserDefaults（テスト時にはモック注入可能）
  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults

    // デフォルト値の設定
    self.currentMode = .default
    self.isBackgroundUpdateEnabled = true

    // 保存済み設定を読み込み
    loadSettings()
  }

  // MARK: - Configuration Methods

  /// 位置情報精度モードを設定
  ///
  /// 指定された精度モードに変更し、UIに反映します。
  /// 設定は自動的に保存されませんので、必要に応じて`saveSettings()`を呼び出してください。
  ///
  /// - Parameter mode: 設定する精度モード
  func setAccuracyMode(_ mode: LocationAccuracyMode) {
    currentMode = mode
  }

  /// バックグラウンド更新の有効/無効を設定
  ///
  /// バックグラウンドでの位置情報更新の有効状態を変更します。
  /// 設定は自動的に保存されませんので、必要に応じて`saveSettings()`を呼び出してください。
  ///
  /// - Parameter enabled: true=有効, false=無効
  func setBackgroundUpdateEnabled(_ enabled: Bool) {
    isBackgroundUpdateEnabled = enabled
  }

  // MARK: - Persistence Methods

  /// 現在の設定をUserDefaultsに保存
  ///
  /// 精度モードとバックグラウンド更新設定を永続化します。
  /// アプリ再起動後も設定が保持されます。
  func saveSettings() {
    userDefaults.set(currentMode.rawValue, forKey: LocationAccuracyMode.userDefaultsKey)
    userDefaults.set(isBackgroundUpdateEnabled, forKey: Self.backgroundUpdateEnabledKey)
  }

  /// UserDefaultsから設定を読み込み
  ///
  /// 保存された設定を読み込んで現在の設定として適用します。
  /// 保存された設定がない場合はデフォルト値を使用します。
  func loadSettings() {
    // 精度モードの読み込み
    if let modeString = userDefaults.string(forKey: LocationAccuracyMode.userDefaultsKey),
       let mode = LocationAccuracyMode(rawValue: modeString) {
      currentMode = mode
    } else {
      currentMode = .default
    }

    // バックグラウンド更新設定の読み込み
    // UserDefaultsにキーが存在しない場合はデフォルト値（true）を使用
    if userDefaults.object(forKey: Self.backgroundUpdateEnabledKey) != nil {
      isBackgroundUpdateEnabled = userDefaults.bool(forKey: Self.backgroundUpdateEnabledKey)
    } else {
      isBackgroundUpdateEnabled = true
    }
  }

  // MARK: - LocationManager Integration

  /// 現在の設定をLocationManagerに適用
  ///
  /// 設定されている精度モードとバックグラウンド更新設定を
  /// 指定されたLocationManagerに適用します。
  ///
  /// - Parameter locationManager: 設定を適用するLocationManagerインスタンス
  func applySettingsToLocationManager(_ locationManager: CLLocationManager) {
    // 精度設定の適用
    locationManager.desiredAccuracy = currentMode.desiredAccuracy
    locationManager.distanceFilter = currentMode.distanceFilter

    // バックグラウンド更新設定の適用
    // 注意: allowsBackgroundLocationUpdatesの設定には権限と
    //      Info.plistの設定が必要です
    if #available(iOS 9.0, *) {
      // バックグラウンド更新が無効の場合、またはWhenInUse権限の場合はfalseに設定
      if !isBackgroundUpdateEnabled || locationManager.authorizationStatus != .authorizedAlways {
        locationManager.allowsBackgroundLocationUpdates = false
      } else {
        // Info.plistにlocation背景モードが設定されている場合のみ有効化
        if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String],
           backgroundModes.contains("location") {
          locationManager.allowsBackgroundLocationUpdates = true
        }
      }
    }
  }
}
