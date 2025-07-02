//
//  StepCountManager.swift
//  TokoToko
//
//  Created by Claude on 2025/06/30.
//

import CoreMotion
import Foundation

// MARK: - StepCountSource enum
enum StepCountSource {
  case coremotion(steps: Int)  // CoreMotion実測値
  case estimated(steps: Int)  // 距離・時間ベース推定値
  case unavailable  // 歩数計測不可

  var steps: Int? {
    switch self {
    case .coremotion(let steps), .estimated(let steps):
      return steps
    case .unavailable:
      return nil
    }
  }

  var isRealTime: Bool {
    switch self {
    case .coremotion:
      return true
    case .estimated, .unavailable:
      return false
    }
  }
}

// MARK: - StepCountDelegate protocol
protocol StepCountDelegate: AnyObject {
  func stepCountDidUpdate(_ stepCount: StepCountSource)
  func stepCountDidFailWithError(_ error: Error)
}

// MARK: - StepCountError enum
enum StepCountError: Error, LocalizedError {
  case notAvailable
  case notAuthorized
  case sensorUnavailable
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

// MARK: - StepCountManager class
class StepCountManager: ObservableObject, CustomDebugStringConvertible {

  // MARK: - Properties
  static let shared = StepCountManager()

  weak var delegate: StepCountDelegate?

  @Published var currentStepCount: StepCountSource = .unavailable
  @Published var isTracking: Bool = false

  private lazy var pedometer: CMPedometer = {
    #if DEBUG
      print("📱 CMPedometer初期化")
    #endif
    return CMPedometer()
  }()
  private var startDate: Date?
  private var baselineSteps: Int = 0

  // MARK: - Constants
  private let updateInterval: TimeInterval = 1.0  // 1秒間隔で更新
  private let stepsPerKilometer: Double = 1300  // 1kmあたりの平均歩数

  // MARK: - Initialization
  private init() {
    #if DEBUG
      print("📱 StepCountManager初期化")
    #endif
  }

  deinit {
    stopTracking()
  }

  // MARK: - Public Methods

  /// 歩数計測が利用可能かチェック
  func isStepCountingAvailable() -> Bool {
    do {
      let available = CMPedometer.isStepCountingAvailable()
      #if DEBUG
        print("📱 CMPedometer.isStepCountingAvailable(): \(available)")
      #endif
      return available
    } catch {
      #if DEBUG
        print("❌ CMPedometer.isStepCountingAvailable() エラー: \(error)")
      #endif
      return false
    }
  }

  /// 歩数トラッキング開始
  func startTracking() {
    #if DEBUG
      print("🚀 歩数トラッキング開始")
    #endif

    guard !isTracking else {
      #if DEBUG
        print("⚠️ 既にトラッキング中です")
      #endif
      return
    }

    do {
      let isAvailable = isStepCountingAvailable()
      #if DEBUG
        print("📱 CMPedometer利用可能性: \(isAvailable)")
      #endif

      guard isAvailable else {
        let error = StepCountError.notAvailable
        #if DEBUG
          print("❌ 歩数計測不可: \(error.localizedDescription)")
        #endif
        handleError(error)
        return
      }

      startDate = Date()
      baselineSteps = 0
      isTracking = true

      #if DEBUG
        print("📊 CMPedometer.startUpdates開始")
      #endif

      // CMPedometerでのリアルタイム歩数取得を開始
      guard let startDate = startDate else {
        #if DEBUG
          print("❌ startDateがnilです")
        #endif
        handleError(.sensorUnavailable)
        return
      }

      pedometer.startUpdates(from: startDate) { [weak self] data, error in
        DispatchQueue.main.async {
          #if DEBUG
            if let error = error {
              print("❌ CMPedometer callback エラー: \(error)")
            } else if let data = data {
              print("📊 CMPedometer callback 成功: \(data.numberOfSteps)歩")
            }
          #endif
          self?.handlePedometerUpdate(data: data, error: error)
        }
      }

      #if DEBUG
        print("✅ 歩数トラッキング開始完了")
      #endif
    } catch {
      #if DEBUG
        print("❌ StepCountManager.startTracking() で予期しないエラー: \(error)")
      #endif
      handleError(.sensorUnavailable)
    }
  }

  /// 歩数トラッキング停止
  func stopTracking() {
    guard isTracking else { return }

    #if DEBUG
      print("⏹️ 歩数トラッキング停止")
    #endif

    pedometer.stopUpdates()
    isTracking = false
    startDate = nil
    baselineSteps = 0

    // 停止時は計測不可状態にリセット
    updateStepCount(.unavailable)
  }

  /// フォールバック用の推定歩数計算
  func estimateSteps(distance: Double, duration: TimeInterval) -> StepCountSource {
    // 距離が0でも推定値として0歩を返す（unavailableではなく）
    guard distance >= 0 else {
      #if DEBUG
        print("⚠️ 推定歩数計算: 負の距離値のため unavailable")
      #endif
      return .unavailable
    }

    // 距離ベースの推定（1km = 約1,300歩）
    let distanceInKm = distance / 1000.0
    let estimatedSteps = Int(distanceInKm * stepsPerKilometer)

    #if DEBUG
      print("📊 推定歩数計算: \(String(format: "%.3f", distanceInKm))km → \(estimatedSteps)歩")
    #endif

    return .estimated(steps: max(0, estimatedSteps))
  }

  // MARK: - Private Methods

  private func handlePedometerUpdate(data: CMPedometerData?, error: Error?) {
    if let error = error {
      #if DEBUG
        print("❌ CMPedometerエラー: \(error.localizedDescription)")
      #endif
      handlePedometerError(error)
      return
    }

    guard let data = data else {
      #if DEBUG
        print("⚠️ CMPedometerData がnilです")
      #endif
      return
    }

    let steps = data.numberOfSteps.intValue
    let stepCountSource = StepCountSource.coremotion(steps: steps)

    #if DEBUG
      print("📊 CoreMotion歩数更新: \(steps)歩")
    #endif

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
    #if DEBUG
      print("❌ StepCountError: \(error.localizedDescription)")
    #endif

    updateStepCount(.unavailable)
    delegate?.stepCountDidFailWithError(error)
  }

  private func updateStepCount(_ stepCount: StepCountSource) {
    currentStepCount = stepCount
    delegate?.stepCountDidUpdate(stepCount)
  }

  // MARK: - CustomDebugStringConvertible

  /// デバッグ用の状態情報
  var debugDescription: String {
    return """
      StepCountManager Debug Info:
      - isTracking: \(isTracking)
      - isStepCountingAvailable: \(isStepCountingAvailable())
      - currentStepCount: \(currentStepCount)
      - startDate: \(startDate?.description ?? "nil")
      """
  }
}
