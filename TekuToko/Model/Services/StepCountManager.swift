//
//  StepCountManager.swift
//  TokoToko
//
//  Created by Claude on 2025/06/30.
//

import CoreMotion
import Foundation

// MARK: - StepCountManager class

/// 歩数計測と管理を統合するシングルトンクラス
///
/// `StepCountManager`はCoreMotionを使用した歩数計測機能を提供します。
/// リアルタイムの歩数取得とエラーハンドリングを管理します。
///
/// ## Overview
///
/// 主要な機能：
/// - **CoreMotion連携**: CMPedometerを使用した高精度歩数計測
/// - **リアルタイム更新**: 1秒間隔での歩数データ更新
/// - **エラーハンドリング**: 権限、センサー状態の統合管理
/// - **デバッグサポート**: 詳細なログ出力と状態表示
///
/// ## Usage Example
///
/// ```swift
/// let stepManager = StepCountManager.shared
/// stepManager.delegate = self
///
/// if stepManager.isStepCountingAvailable() {
///     stepManager.startTracking()
/// } else {
///     // 歩数が利用できない場合は計測不可状態になります
/// }
/// ```
///
/// ## Topics
///
/// ### Singleton Instance
/// - ``shared``
///
/// ### Delegate
/// - ``delegate``
///
/// ### Published Properties
/// - ``currentStepCount``
/// - ``isTracking``
///
/// ### Step Counting
/// - ``isStepCountingAvailable()``
/// - ``startTracking()``
/// - ``stopTracking()``
class StepCountManager: ObservableObject, CustomDebugStringConvertible {

  // MARK: - Properties

  /// StepCountManagerのシングルトンインスタンス
  ///
  /// アプリ全体で単一の歩数管理インスタンスを使用し、
  /// 状態の一貫性とリソースの効率的管理を実現します。
  static let shared = StepCountManager()

  /// 歩数更新通知を受け取るデリゲート
  ///
  /// 歩数データの更新やエラー発生時の通知を受け取ります。
  /// weak参照で保持し、循環参照を防止します。
  weak var delegate: StepCountDelegate?

  /// 現在の歩数データ
  ///
  /// 最新の歩数情報とそのソースを保持します。
  /// @Publishedにより、値が変更されるとUIに自動反映されます。
  @Published var currentStepCount: StepCountSource = .unavailable

  /// 歩数トラッキングの状態
  ///
  /// CoreMotionによる歩数計測がアクティブかどうかを表します。
  /// @Publishedにより、UIが状態変化を自動的に反映できます。
  @Published var isTracking: Bool = false

  private lazy var pedometer: CMPedometer = {
    CMPedometer()
  }()
  private var startDate: Date?
  private var baselineSteps: Int = -1  // -1は未設定を示す

  /// テスト用: CoreMotion可用性のオーバーライド
  ///
  /// CI/Simulatorなど環境依存を排除するため、
  /// isStepCountingAvailable() の戻り値を任意に固定できるテスト用フラグ。
  /// 通常は `nil`（オーバーライド無効）。
  private var pedometerAvailabilityOverride: Bool?

  // MARK: - Constants
  private let updateInterval: TimeInterval = 1.0  // 1秒間隔で更新

  // MARK: - Initialization
  private init() {}

  deinit {
    stopTracking(finalStop: true)
  }

  // MARK: - Public Methods

  /// デバイスで歩数計測が利用可能かどうかを確認
  ///
  /// CMPedometerのCoreMotionフレームワークを使用して、
  /// 現在のデバイスで歩数計測機能が利用可能かどうかを確認します。
  ///
  /// ## Behavior
  /// - デバイスにモーションセンサーが搭載されているかをチェック
  /// - システムレベルで歩数計測が有効かどうかを確認
  /// - エラーが発生した場合はfalseを返す
  ///
  /// - Returns: 歩数計測が利用可能な場合true、利用不可の場合false
  func isStepCountingAvailable() -> Bool {
    if let override = pedometerAvailabilityOverride { return override }
    return CMPedometer.isStepCountingAvailable()
  }

  /// 歩数のリアルタイムトラッキングを開始
  ///
  /// CoreMotionのCMPedometerを使用して歩数の継続的な計測を開始します。
  /// 計測開始前に利用可能性と権限の確認を行い、
  /// 必要に応じてエラーハンドリングを実行します。
  /// 一時停止からの再開時はCMPedometerの再開始を避け、状態のみ更新します。
  ///
  /// ## Process Flow
  /// 1. 既にトラッキング中かどうかを確認
  /// 2. CMPedometerの利用可能性をチェック
  /// 3. トラッキング状態と開始時刻を設定
  /// 4. 必要時のみCMPedometer.startUpdates()で計測開始
  /// 5. コールバックでデータとエラーを処理
  ///
  /// ## Error Handling
  /// - センサー利用不可: StepCountError.notAvailable
  /// - 権限拒否: StepCountError.notAuthorized
  /// - システムエラー: StepCountError.sensorUnavailable
  func startTracking(newWalk: Bool = false) {
    guard !isTracking else {
      return
    }

    guard isStepCountingAvailable() else {
      handleError(.notAvailable)
      return
    }

    if newWalk || baselineSteps < 0 {
      startDate = Date()
      baselineSteps = -1

      currentStepCount = .coremotion(steps: 0)
      delegate?.stepCountDidUpdate(currentStepCount)

      guard let startDate = startDate else {
        handleError(.sensorUnavailable)
        return
      }

      pedometer.startUpdates(from: startDate) { [weak self] data, error in
        DispatchQueue.main.async {
          self?.handlePedometerUpdate(data: data, error: error)
        }
      }
    }

    isTracking = true
  }

  /// 歩数のリアルタイムトラッキングを停止
  ///
  /// 現在実行中の歩数トラッキングを安全に停止し、
  /// 関連する状態をリセットします。散歩完全終了時のみCMPedometerを停止し、
  /// 一時停止時はCMPedometerを継続させて短時間での再開始問題を回避します。
  ///
  /// ## Cleanup Process
  /// 1. トラッキング状態を確認（停止済みの場合は早期リターン）
  /// 2. CMPedometer.stopUpdates()でセンサーアップデート停止
  /// 3. トラッキング状態をfalseに設定
  /// 4. 開始時刻とベースラインをリセット
  /// 5. 歩数データをunavailableにリセット（散歩完全終了時のみ）
  func stopTracking(finalStop: Bool = true) {
    guard isTracking else {
      return
    }

    if finalStop {
      pedometer.stopUpdates()
      isTracking = false
      startDate = nil
      baselineSteps = -1
      currentStepCount = .unavailable
    } else {
      isTracking = false
    }
  }

  // MARK: - Private Methods

  private func handlePedometerUpdate(data: CMPedometerData?, error: Error?) {
    if let error = error {
      handlePedometerError(error)
      return
    }

    guard let data = data else {
      return
    }

    let rawSteps = data.numberOfSteps.intValue

    if baselineSteps < 0 {
      baselineSteps = rawSteps
    }

    let steps = max(0, rawSteps - baselineSteps)
    let stepCountSource = StepCountSource.coremotion(steps: steps)

    updateStepCount(stepCountSource)
  }

  private func handlePedometerError(_ error: Error) {
    let stepCountError: StepCountError

    let nsError = error as NSError
    if nsError.domain == CMErrorDomain {
      switch nsError.code {
      case Int(CMErrorMotionActivityNotAuthorized.rawValue):
        stepCountError = .notAuthorized
      case Int(CMErrorMotionActivityNotAvailable.rawValue):
        stepCountError = .notAvailable
      default:
        stepCountError = .sensorUnavailable
      }
    } else {
      stepCountError = .sensorUnavailable
    }

    handleError(stepCountError)
  }

  private func handleError(_ error: StepCountError) {
    updateStepCount(.unavailable)
    delegate?.stepCountDidFailWithError(error)
  }

  private func updateStepCount(_ stepCount: StepCountSource) {
    currentStepCount = stepCount
    delegate?.stepCountDidUpdate(stepCount)
  }

  // MARK: - Testing Helpers

  /// テスト用: CoreMotion可用性のオーバーライドを設定/解除
  /// - Parameter value: true/falseで固定、nilで解除
  func setAvailabilityOverrideForTesting(_ value: Bool?) {
    pedometerAvailabilityOverride = value
  }

  // MARK: - CustomDebugStringConvertible

  /// デバッグ用の状態情報
  var debugDescription: String {
    """
      StepCountManager Debug Info:
      - isTracking: \(isTracking)
      - isStepCountingAvailable: \(isStepCountingAvailable())
      - currentStepCount: \(currentStepCount)
      - startDate: \(startDate?.description ?? "nil")
      """
  }
}
