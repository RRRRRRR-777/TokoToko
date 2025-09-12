//
//  EnhancedVibeLoggerPerformance.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/08/30.
//

import Darwin
import Foundation

// MARK: - Performance Measurement Extension

/// EnhancedVibeLoggerのパフォーマンス計測機能拡張
extension EnhancedVibeLogger {

  // MARK: - Performance Measurement

  /// 同期処理のパフォーマンス測定
  ///
  /// 指定されたブロックの実行時間とメモリ使用量を測定し、
  /// 詳細なパフォーマンスメトリクスをログ出力します。
  ///
  /// ## Example
  /// ```swift
  /// let result = logger.measurePerformance(operation: "dataProcessing") {
  ///   return processLargeDataSet()
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - operation: パフォーマンス測定対象の操作名
  ///   - file: 呼び出し元ファイル名（自動取得）
  ///   - function: 呼び出し元関数名（自動取得）
  ///   - line: 呼び出し元行番号（自動取得）
  ///   - block: 測定対象の処理ブロック
  /// - Returns: ブロックの実行結果
  /// - Throws: ブロック内で発生したエラーを再スロー
  public func measurePerformance<T>(
    operation: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    block: () throws -> T
  ) rethrows -> T {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = try block()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

    let performanceMetrics = PerformanceMetrics(
      executionTime: timeElapsed,
      memoryUsage: getCurrentMemoryUsage(),
      threadInfo: ThreadInfo()
    )

    log(
      level: .info,
      operation: operation,
      message: "パフォーマンス測定完了",
      context: ["execution_time": String(timeElapsed)],
      source: SourceInfo(fileName: file, functionName: function, lineNumber: line),
      performanceMetrics: performanceMetrics
    )

    return result
  }

  /// 非同期処理のパフォーマンス測定
  ///
  /// 指定された非同期ブロックの実行時間とメモリ使用量を測定し、
  /// 詳細なパフォーマンスメトリクスをログ出力します。
  ///
  /// ## Example
  /// ```swift
  /// let result = await logger.measurePerformanceAsync(operation: "asyncDataFetch") {
  ///   return await fetchDataFromAPI()
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - operation: パフォーマンス測定対象の操作名
  ///   - file: 呼び出し元ファイル名（自動取得）
  ///   - function: 呼び出し元関数名（自動取得）
  ///   - line: 呼び出し元行番号（自動取得）
  ///   - block: 測定対象の非同期処理ブロック
  /// - Returns: ブロックの実行結果
  /// - Throws: ブロック内で発生したエラーを再スロー
  public func measurePerformanceAsync<T>(
    operation: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    block: () async throws -> T
  ) async rethrows -> T {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = try await block()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

    let performanceMetrics = PerformanceMetrics(
      executionTime: timeElapsed,
      memoryUsage: getCurrentMemoryUsage(),
      threadInfo: ThreadInfo()
    )

    log(
      level: .info,
      operation: operation,
      message: "非同期パフォーマンス測定完了",
      context: ["execution_time": String(timeElapsed)],
      source: SourceInfo(fileName: file, functionName: function, lineNumber: line),
      performanceMetrics: performanceMetrics
    )

    return result
  }

  // MARK: - Memory Management

  /// 現在のメモリ使用量を取得
  ///
  /// Mach APIを使用してアプリケーションの現在のメモリ使用量を取得します。
  /// パフォーマンス測定時のメモリ情報として使用されます。
  ///
  /// - Returns: 現在のメモリ使用量（バイト）。取得に失敗した場合は0
  internal func getCurrentMemoryUsage() -> Int64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }

    if kerr == KERN_SUCCESS {
      return Int64(info.resident_size)
    } else {
      return 0
    }
  }
}
