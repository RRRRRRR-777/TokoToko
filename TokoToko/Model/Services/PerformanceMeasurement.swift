//
//  PerformanceMeasurement.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/28.
//

import Foundation

// パフォーマンス計測ユーティリティ
class PerformanceMeasurement {

  // 計測結果を格納する構造体
  struct MeasurementResult {
    let operationName: String
    let executionTime: TimeInterval
    let startTime: CFAbsoluteTime
    let endTime: CFAbsoluteTime
    let additionalInfo: [String: Any]

    var formattedTime: String {
      if executionTime < 0.001 {
        return String(format: "%.3f μs", executionTime * 1_000_000)
      } else if executionTime < 1.0 {
        return String(format: "%.3f ms", executionTime * 1000)
      } else {
        return String(format: "%.3f s", executionTime)
      }
    }
  }

  // 統計情報を管理するクラス
  class Statistics {
    private var measurements: [String: [TimeInterval]] = [:]

    func addMeasurement(operationName: String, time: TimeInterval) {
      if measurements[operationName] == nil {
        measurements[operationName] = []
      }
      measurements[operationName]?.append(time)
    }

    func getStatistics(for operationName: String) -> (
      count: Int, average: TimeInterval, min: TimeInterval, max: TimeInterval
    )? {
      guard let times = measurements[operationName], !times.isEmpty else {
        return nil
      }

      let count = times.count
      let average = times.reduce(0, +) / Double(count)
      let min = times.min() ?? 0
      let max = times.max() ?? 0

      return (count: count, average: average, min: min, max: max)
    }

    func printAllStatistics() {
      #if DEBUG
        print("📊 ==========  パフォーマンス統計情報  ==========")
        for operationName in measurements.keys.sorted() {
          if let stats = getStatistics(for: operationName) {
            let avgFormatted = formatTime(stats.average)
            let minFormatted = formatTime(stats.min)
            let maxFormatted = formatTime(stats.max)
            print("📊 \(operationName):")
            print("   📈 実行回数: \(stats.count)")
            print("   ⏱️ 平均時間: \(avgFormatted)")
            print("   🟢 最短時間: \(minFormatted)")
            print("   🔴 最長時間: \(maxFormatted)")
          }
        }
        print("📊 =======================================")
      #endif
    }

    private func formatTime(_ time: TimeInterval) -> String {
      if time < 0.001 {
        return String(format: "%.3f μs", time * 1_000_000)
      } else if time < 1.0 {
        return String(format: "%.3f ms", time * 1000)
      } else {
        return String(format: "%.3f s", time)
      }
    }
  }

  // シングルトンインスタンス
  static let shared = PerformanceMeasurement()

  // 統計情報マネージャー
  private let statistics = Statistics()

  // 計測開始時間を保存する辞書
  private var startTimes: [String: CFAbsoluteTime] = [:]

  private init() {}

  // 計測開始
  func startMeasurement(operationName: String, additionalInfo: [String: Any] = [:]) {
    let startTime = CFAbsoluteTimeGetCurrent()
    startTimes[operationName] = startTime

    #if DEBUG
      var infoText = ""
      if !additionalInfo.isEmpty {
        let infoItems = additionalInfo.map { "\($0.key): \($0.value)" }
        infoText = " (\(infoItems.joined(separator: ", ")))"
      }
      print("🚀 計測開始: \(operationName)\(infoText)")
    #endif
  }

  // 計測終了と結果記録
  @discardableResult
  func endMeasurement(operationName: String, additionalInfo: [String: Any] = [:])
    -> MeasurementResult?
  {
    let endTime = CFAbsoluteTimeGetCurrent()

    guard let startTime = startTimes.removeValue(forKey: operationName) else {
      #if DEBUG
        print("⚠️ 計測エラー: \(operationName) の開始時間が見つかりません")
      #endif
      return nil
    }

    let executionTime = endTime - startTime
    let result = MeasurementResult(
      operationName: operationName,
      executionTime: executionTime,
      startTime: startTime,
      endTime: endTime,
      additionalInfo: additionalInfo
    )

    // 統計情報に追加
    statistics.addMeasurement(operationName: operationName, time: executionTime)

    #if DEBUG
      var infoText = ""
      if !additionalInfo.isEmpty {
        let infoItems = additionalInfo.map { "\($0.key): \($0.value)" }
        infoText = " (\(infoItems.joined(separator: ", ")))"
      }

      // 時間に応じて異なる絵文字を使用
      let emoji = getPerformanceEmoji(for: executionTime)
      print("\(emoji) 計測完了: \(operationName) - \(result.formattedTime)\(infoText)")
    #endif

    return result
  }

  // パフォーマンスに応じた絵文字を取得
  private func getPerformanceEmoji(for time: TimeInterval) -> String {
    if time < 0.010 {  // 10ms未満
      return "🟢"
    } else if time < 0.050 {  // 50ms未満
      return "🟡"
    } else if time < 0.100 {  // 100ms未満
      return "🟠"
    } else {  // 100ms以上
      return "🔴"
    }
  }

  // 統計情報の取得
  func getStatistics(for operationName: String) -> (
    count: Int, average: TimeInterval, min: TimeInterval, max: TimeInterval
  )? {
    return statistics.getStatistics(for: operationName)
  }

  // 全統計情報の出力
  func printAllStatistics() {
    statistics.printAllStatistics()
  }

  // ワンライナー計測（クロージャ実行時間を計測）
  @discardableResult
  func measure<T>(
    operationName: String, additionalInfo: [String: Any] = [:], operation: () throws -> T
  ) rethrows -> (result: T, measurementResult: MeasurementResult?) {
    startMeasurement(operationName: operationName, additionalInfo: additionalInfo)
    let result = try operation()
    let measurementResult = endMeasurement(
      operationName: operationName, additionalInfo: additionalInfo)
    return (result: result, measurementResult: measurementResult)
  }

  // 非同期処理の計測（開始のみ、終了は手動）
  func measureAsync(operationName: String, additionalInfo: [String: Any] = [:]) -> () ->
    MeasurementResult?
  {
    startMeasurement(operationName: operationName, additionalInfo: additionalInfo)
    return { [weak self] in
      return self?.endMeasurement(operationName: operationName, additionalInfo: additionalInfo)
    }
  }
}

// 計測用のヘルパー関数
func measurePerformance<T>(
  operationName: String, additionalInfo: [String: Any] = [:], operation: () throws -> T
) rethrows -> T {
  let (result, _) = try PerformanceMeasurement.shared.measure(
    operationName: operationName, additionalInfo: additionalInfo, operation: operation)
  return result
}
