//
//  StepCountManager.swift
//  TokoToko
//
//  Created by Claude on 2025/06/30.
//

import CoreMotion
import Foundation

// MARK: - StepCountSource enum

/// 歩数データのソースと値を表現する列挙型
///
/// 歩数情報の取得方法と信頼性を区別し、適切な表示とロジック制御を可能にします。
/// CoreMotionからのリアルタイム値、推定値、計測不可状態を表現します。
///
/// ## Topics
///
/// ### Cases
/// - ``coremotion(steps:)``
/// - ``estimated(steps:)``
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

  /// 距離・時間情報から推定された歩数値
  ///
  /// CoreMotionが利用できない場合の代替手段として、
  /// 移動距離と時間から統計的に推定された歩数です。
  /// - Parameter steps: 推定された歩数
  case estimated(steps: Int)

  /// 歩数計測が利用不可能な状態
  ///
  /// センサーが利用できない、権限が拒否された、
  /// またはその他の理由で歩数が取得できない状態を表します。
  case unavailable

  /// 歩数値を取得（計測不可の場合はnil）
  ///
  /// - Returns: 計測または推定された歩数、計測不可の場合はnil
  var steps: Int? {
    switch self {
    case .coremotion(let steps), .estimated(let steps):
      return steps
    case .unavailable:
      return nil
    }
  }

  /// リアルタイム計測データかどうか
  ///
  /// CoreMotionからの実測値の場合にtrueを返します。
  /// 推定値や計測不可の場合はfalseです。
  ///
  /// - Returns: リアルタイム計測の場合true、それ以外はfalse
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
  /// CoreMotionからの新しい歩数データや推定値が利用可能になった時に呼び出されます。
  /// メインスレッドで呼び出されるため、安全にUI更新を行うことができます。
  /// - Parameter stepCount: 更新された歩数データ
  func stepCountDidUpdate(_ stepCount: StepCountSource)

  /// 歩数計測でエラーが発生した時に呼び出される
  ///
  /// センサーの利用不可、権限拒否、またはその他のエラーが発生した時に呼び出されます。
  /// エラー情報をユーザーに表示したり、代替手段への切り替え処理を行ってください。
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

// MARK: - StepCountManager class

/// 歩数計測と管理を統合するシングルトンクラス
///
/// `StepCountManager`はCoreMotionを使用した歩数計測機能を提供します。
/// リアルタイムの歩数取得、推定値計算、エラーハンドリングを統合管理します。
///
/// ## Overview
///
/// 主要な機能：
/// - **CoreMotion連携**: CMPedometerを使用した高精度歩数計測
/// - **フォールバック推定**: センサー不可時の距離ベース推定
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
///     // 推定値を使用
///     let estimated = stepManager.estimateSteps(distance: 1000, duration: 600)
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
/// - ``estimateSteps(distance:duration:)``
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

  /// 歩数のリアルタイムトラッキングを開始
  ///
  /// CoreMotionのCMPedometerを使用して歩数の継続的な計測を開始します。
  /// 計測開始前に利用可能性と権限の確認を行い、
  /// 必要に応じてエラーハンドリングを実行します。
  ///
  /// ## Process Flow
  /// 1. 既にトラッキング中かどうかを確認
  /// 2. CMPedometerの利用可能性をチェック
  /// 3. トラッキング状態と開始時刻を設定
  /// 4. CMPedometer.startUpdates()で計測開始
  /// 5. コールバックでデータとエラーを処理
  ///
  /// ## Error Handling
  /// - センサー利用不可: StepCountError.notAvailable
  /// - 権限拒否: StepCountError.notAuthorized
  /// - システムエラー: StepCountError.sensorUnavailable
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

  /// 歩数のリアルタイムトラッキングを停止
  ///
  /// 現在実行中の歩数トラッキングを安全に停止し、
  /// 関連する状態をリセットします。
  ///
  /// ## Cleanup Process
  /// 1. トラッキング状態を確認（停止済みの場合は早期リターン）
  /// 2. CMPedometer.stopUpdates()でセンサーアップデート停止
  /// 3. トラッキング状態をfalseに設定
  /// 4. 開始時刻とベースラインをリセット
  /// 5. 歩数データをunavailable状態に設定
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

  /// 距離情報から歩数を推定計算
  ///
  /// CoreMotionが利用できない場合のフォールバック手段として、
  /// 移動距離と経過時間から統計的に歩数を推定します。
  ///
  /// ## Estimation Method
  /// - 基準: 1キロメートあたり約1,300歩（一般的な歩幅を基準）
  /// - 計算: `(距離[m] / 1000) * 1300`
  /// - 結果: 0未満の値は0に調整
  ///
  /// ## Input Validation
  /// - 負の距離値の場合は.unavailableを返す
  /// - 距離が0の場合は0歩として.estimated(steps: 0)を返す
  ///
  /// - Parameters:
  ///   - distance: 移動距離（メートル単位）
  ///   - duration: 経過時間（秒単位）※現在は未使用
  /// - Returns: 推定された歩数または計測不可状態
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
    """
      StepCountManager Debug Info:
      - isTracking: \(isTracking)
      - isStepCountingAvailable: \(isStepCountingAvailable())
      - currentStepCount: \(currentStepCount)
      - startDate: \(startDate?.description ?? "nil")
      """
  }
}
