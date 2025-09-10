//
//  StepCountTypes.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/08/30.
//

import Foundation

// MARK: - StepCountSource enum

/// 歩数データのソースと値を表現する列挙型
///
/// 歩数情報の取得方法と信頼性を区別し、適切な表示とロジック制御を可能にします。
/// CoreMotionからのリアルタイム値と計測不可状態を表現します。
///
/// ## Topics
///
/// ### Cases
/// - ``coremotion(steps:)``
/// - ``unavailable``
///
/// ### Properties
/// - ``steps``
/// - ``isRealTime``
enum StepCountSource {
  /// CoreMotionセンサーからの実測歩数値
  ///
  /// デバイスのモーションセンサーから取得した正確な歩数データです。
  /// 最も信頼性が高く、リアルタイムで更新されます。
  /// - Parameter steps: 計測された歩数
  case coremotion(steps: Int)

  /// 歩数計測が利用不可能な状態
  ///
  /// センサーが利用できない、権限が拒否された、
  /// またはその他の理由で歩数が取得できない状態を表します。
  case unavailable

  /// 歩数値を取得（計測不可の場合はnil）
  ///
  /// - Returns: 計測された歩数、計測不可の場合はnil
  var steps: Int? {
    switch self {
    case .coremotion(let steps):
      return steps
    case .unavailable:
      return nil
    }
  }

  /// リアルタイム計測データかどうか
  ///
  /// CoreMotionからの実測値の場合にtrueを返します。
  /// 計測不可の場合はfalseです。
  ///
  /// - Returns: リアルタイム計測の場合true、それ以外はfalse
  var isRealTime: Bool {
    switch self {
    case .coremotion:
      return true
    case .unavailable:
      return false
    }
  }
}

// MARK: - StepCountDelegate protocol

/// 歩数計測の更新とエラーを通知するデリゲートプロトコル
///
/// `StepCountManager`からの歩数データ更新やエラー通知を受け取るためのプロトコルです。
/// リアルタイムの歩数更新や計測エラーに対して適切なUI更新やエラーハンドリングを実装できます。
///
/// ## Topics
///
/// ### Delegate Methods
/// - ``stepCountDidUpdate(_:)``
/// - ``stepCountDidFailWithError(_:)``
protocol StepCountDelegate: AnyObject {
  /// 歩数データが更新された時に呼び出される
  ///
  /// CoreMotionからの新しい歩数データが利用可能になった時に呼び出されます。
  /// メインスレッドで呼び出されるため、安全にUI更新を行うことができます。
  /// - Parameter stepCount: 更新された歩数データ
  func stepCountDidUpdate(_ stepCount: StepCountSource)

  /// 歩数計測でエラーが発生した時に呼び出される
  ///
  /// センサーの利用不可、権限拒否、またはその他のエラーが発生した時に呼び出されます。
  /// エラー情報をユーザーに表示し、計測不可状態であることを通知してください。
  /// - Parameter error: 発生したエラー
  func stepCountDidFailWithError(_ error: Error)
}

// MARK: - StepCountError enum

/// 歩数計測で発生するエラータイプ
///
/// 歩数計測機能で発生する各種エラーを表現します。
/// ユーザーに適切なエラーメッセージを表示し、適切な代替手段を提供できるように設計されています。
///
/// ## Topics
///
/// ### Error Cases
/// - ``notAvailable``
/// - ``notAuthorized``
/// - ``sensorUnavailable``
/// - ``backgroundRestricted``
enum StepCountError: Error, LocalizedError {
  /// デバイスで歩数計測が利用できない
  ///
  /// デバイスにモーションセンサーが搭載されていない、
  /// またはセンサーが物理的に利用できない状態です。
  case notAvailable

  /// 歩数計測の権限が拒否されている
  ///
  /// ユーザーがアプリのモーションアクティビティアクセス権限を拒否した状態です。
  case notAuthorized

  /// 歩数センサーが一時的に利用不可
  ///
  /// センサーの一時的な障害やシステムリソースの制約で、
  /// 歩数計測が一時的に利用できない状態です。
  case sensorUnavailable

  /// バックグラウンドでの歩数計測が制限されている
  ///
  /// アプリがバックグラウンドでのモーションデータアクセスを制限されている状態です。
  case backgroundRestricted

  var errorDescription: String? {
    switch self {
    case .notAvailable:
      return "歩数計測がこのデバイスでは利用できません"
    case .notAuthorized:
      return "歩数計測の権限が拒否されました"
    case .sensorUnavailable:
      return "歩数センサーが一時的に利用できません"
    case .backgroundRestricted:
      return "バックグラウンドでの歩数計測が制限されています"
    }
  }
}
