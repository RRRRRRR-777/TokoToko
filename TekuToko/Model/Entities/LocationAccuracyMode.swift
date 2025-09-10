//
//  LocationAccuracyMode.swift
//  TekuToko
//
//  Created by Claude on 2025/08/22.
//

import CoreLocation
import Foundation

/// 位置情報の精度モード
///
/// 散歩記録時の位置情報精度とバッテリー消費のバランスを調整するための設定です。
/// 3つのモードから選択でき、それぞれ異なる精度とバッテリー消費特性を持ちます。
///
/// ## Overview
///
/// - **高精度モード**: 最高精度でルート記録、バッテリー消費大
/// - **バランスモード**: 精度と省電力のバランス、推奨設定
/// - **省電力モード**: 低精度だがバッテリー消費少、長時間散歩向け
///
/// ## Topics
///
/// ### Cases
/// - ``highAccuracy``
/// - ``balanced``
/// - ``batterySaving``
///
/// ### Configuration
/// - ``desiredAccuracy``
/// - ``distanceFilter``
/// - ``displayName``
/// - ``description``
/// - ``rawValue``
///
/// ### UserDefaults Persistence
/// - ``userDefaultsKey``
/// - ``init(rawValue:)``
enum LocationAccuracyMode: String, CaseIterable, Identifiable {
  /// 高精度モード
  ///
  /// GPS最高精度で位置情報を記録します。
  /// 正確なルート記録が必要な短時間散歩に適しています。
  case highAccuracy = "high"

  /// バランスモード（推奨）
  ///
  /// 精度とバッテリー消費のバランスを取った設定です。
  /// 日常的な散歩記録に最適で、デフォルト設定として推奨されます。
  case balanced = "balanced"

  /// 省電力モード
  ///
  /// バッテリー消費を抑えた低精度設定です。
  /// 長時間の散歩やバッテリー残量が少ない場合に適しています。
  case batterySaving = "battery"

  /// Identifiableプロトコル対応のID
  var id: String { rawValue }

  /// CoreLocationの精度設定値
  ///
  /// 各モードに対応するCLLocationAccuracyの値を返します。
  /// LocationManagerの設定に直接使用されます。
  var desiredAccuracy: CLLocationAccuracy {
    switch self {
    case .highAccuracy:
      return kCLLocationAccuracyBest
    case .balanced:
      return kCLLocationAccuracyNearestTenMeters
    case .batterySaving:
      return kCLLocationAccuracyHundredMeters
    }
  }

  /// 位置更新の距離フィルター値（メートル）
  ///
  /// 指定した距離だけ移動した場合にのみ位置情報を更新します。
  /// バッテリー消費の最適化に寄与します。
  var distanceFilter: CLLocationDistance {
    switch self {
    case .highAccuracy:
      return 5.0  // 5メートル移動で更新
    case .balanced:
      return 20.0  // 20メートル移動で更新（デフォルト）
    case .batterySaving:
      return 50.0  // 50メートル移動で更新
    }
  }

  /// 表示用の名称
  ///
  /// ユーザーインターフェースに表示される日本語名称です。
  var displayName: String {
    switch self {
    case .highAccuracy:
      return "高精度"
    case .balanced:
      return "バランス"
    case .batterySaving:
      return "省電力"
    }
  }

  /// 詳細説明
  ///
  /// 各モードの特徴と適用場面を説明するテキストです。
  /// 設定画面での補助情報として使用されます。
  var description: String {
    switch self {
    case .highAccuracy:
      return "最高精度でルートを記録します。バッテリー消費は大きくなります。"
    case .balanced:
      return "精度とバッテリー消費のバランスを取った推奨設定です。"
    case .batterySaving:
      return "バッテリー消費を抑えます。長時間の散歩に適しています。"
    }
  }

  /// UserDefaults保存用のキー
  ///
  /// 設定の永続化に使用するUserDefaultsキーです。
  static let userDefaultsKey = "locationAccuracyMode"
  // MARK: - Default Value

  /// デフォルトの精度モード
  ///
  /// アプリ初回起動時や設定が見つからない場合に使用されるデフォルト値です。
  /// バランスモードを推奨設定として採用しています。
  static let `default`: LocationAccuracyMode = .balanced
}
