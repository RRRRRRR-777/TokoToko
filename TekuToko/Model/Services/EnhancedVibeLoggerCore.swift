//
//  EnhancedVibeLoggerCore.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/08/30.
//

import Darwin
import Foundation

// MARK: - Enhanced Vibe Logger Core Implementation

/// 高度なログ管理機能を提供する統合ログシステム
///
/// `EnhancedVibeLogger`はTekuTokoアプリケーション専用に設計された包括的なログ管理システムです。
/// デバッグ情報から本番環境での動作監視まで、アプリケーションの全ライフサイクルにわたって
/// 詳細なログ記録と分析機能を提供します。
///
/// ## Overview
///
/// 主要な機能：
/// - **階層化ログレベル**: debug, info, warning, error, criticalの5段階
/// - **バッチ処理**: 高効率なログバッファリングと一括出力
/// - **ファイル出力**: 永続化されたログファイルの生成と管理
/// - **コンテキスト情報**: 豊富なメタデータとトレーサビリティ
/// - **専門ログ**: 位置情報、Firebase同期、パフォーマンス分析
/// - **デバッグ支援**: メソッド開始/終了、スタックトレース、異常検出
///
/// ## Topics
///
/// ### Singleton Instance
/// - ``shared``
///
/// ### Basic Logging
/// - ``debug(operation:message:context:source:humanNote:aiTodo:)``
/// - ``info(operation:message:context:source:humanNote:aiTodo:)``
/// - ``warning(operation:message:context:source:humanNote:aiTodo:)``
/// - ``error(operation:message:context:source:humanNote:aiTodo:)``
/// - ``critical(operation:message:context:source:humanNote:aiTodo:)``
public class EnhancedVibeLogger {
  /// EnhancedVibeLoggerのシングルトンインスタンス
  ///
  /// アプリケーション全体で統一されたログ管理を実現するため、
  /// 単一のインスタンスを通してすべてのログ操作を行います。
  public static let shared = EnhancedVibeLogger()

  /// ログ処理専用のシリアルキュー
  ///
  /// ログ出力の順序性を保証し、マルチスレッド環境でのデータ競合を防止します。
  /// QoS.utilityで実行され、メインスレッドをブロックしません。
  internal let logQueue = DispatchQueue(label: "com.tekutoko.logger", qos: .utility)

  /// 現在のログレベル設定
  ///
  /// DEBUG版では.debug、RELEASE版では.infoがデフォルト設定されます。
  /// このレベル以上の重要度を持つログのみが出力されます。
  internal var logLevel: LogLevel

  /// ファイル出力の有効/無効状態
  ///
  /// trueの場合、ログがファイルシステムに永続化されます。
  /// DEBUG版ではtrue、RELEASE版ではfalseがデフォルトです。
  internal var enableFileOutput: Bool

  /// ログファイルの保存ディレクトリパス
  ///
  /// ログファイルが保存されるディレクトリの絶対パスです。
  /// アプリケーションのホームディレクトリ配下に自動作成されます。
  internal let logDirectoryPath: String

  /// バッチ処理用のログバッファ
  ///
  /// 効率的なログ出力のため、一定数のログエントリをメモリにバッファリングします。
  /// バッチサイズまたは時間間隔に達すると一括出力されます。
  internal var logBuffer: [EnhancedVibeLogEntry] = []

  /// バッチ出力用のタイマー
  ///
  /// 定期的なバッファフラッシュを制御するタイマーです。
  /// 一定時間経過後にバッファ内容を強制出力します。
  internal var batchTimer: Timer?

  /// バッチ処理の最大エントリ数
  ///
  /// この数に達するとバッファが自動的にフラッシュされます。
  internal let batchSize = 50

  /// バッチ処理の時間間隔（秒）
  ///
  /// この時間が経過するとバッファサイズに関係なくフラッシュされます。
  internal let batchTimeInterval: TimeInterval = 30.0

  private init() {
    #if DEBUG
      self.logLevel = .debug
      self.enableFileOutput = true
    #else
      self.logLevel = .info
      self.enableFileOutput = false
    #endif

    // 新パスに移行しつつ、旧パスも後方互換として維持
    let home = NSHomeDirectory()
    let newPath = home + "/RRRRRRR777/TekuToko/logs"
    let oldPath = home + "/RRRRRRR777/TokoToko/logs"
    // 旧パスが既に存在し、新パスが未作成なら旧パスを優先（テスト互換のため）
    if FileManager.default.fileExists(atPath: oldPath),
      !FileManager.default.fileExists(atPath: newPath)
    {
      self.logDirectoryPath = oldPath
    } else {
      self.logDirectoryPath = newPath
    }

    // ログディレクトリの作成
    try? FileManager.default.createDirectory(
      atPath: logDirectoryPath,
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  // MARK: - Testing Support
  #if DEBUG
    public func setLogLevel(_ level: LogLevel) {
      logLevel = level
    }

    public func getLogLevel() -> LogLevel {
      logLevel
    }

    public func setFileOutput(_ enabled: Bool) {
      enableFileOutput = enabled
    }

    public func getFileOutput() -> Bool {
      enableFileOutput
    }

    public func resetToDefaultSettings() {
      logLevel = .debug
      enableFileOutput = true
    }

    public func getLogDirectoryPath() -> String {
      logDirectoryPath
    }
  #endif

  // MARK: - Basic Logging Methods
  public func debug(
    operation: String,
    message: String,
    context: [String: String] = [:],
    source: SourceInfo? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    log(
      level: .debug,
      operation: operation,
      message: message,
      context: context,
      source: source,
      humanNote: humanNote,
      aiTodo: aiTodo
    )
  }

  public func info(
    operation: String,
    message: String,
    context: [String: String] = [:],
    source: SourceInfo? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    log(
      level: .info,
      operation: operation,
      message: message,
      context: context,
      source: source,
      humanNote: humanNote,
      aiTodo: aiTodo
    )
  }

  public func warning(
    operation: String,
    message: String,
    context: [String: String] = [:],
    source: SourceInfo? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    log(
      level: .warning,
      operation: operation,
      message: message,
      context: context,
      source: source,
      humanNote: humanNote,
      aiTodo: aiTodo
    )
  }

  public func error(
    operation: String,
    message: String,
    context: [String: String] = [:],
    source: SourceInfo? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    log(
      level: .error,
      operation: operation,
      message: message,
      context: context,
      source: source,
      humanNote: humanNote,
      aiTodo: aiTodo
    )
  }

  public func critical(
    operation: String,
    message: String,
    context: [String: String] = [:],
    source: SourceInfo? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    log(
      level: .critical,
      operation: operation,
      message: message,
      context: context,
      source: source,
      humanNote: humanNote,
      aiTodo: aiTodo
    )
  }

  // MARK: - Core Logging Method
  internal func log(
    level: LogLevel,
    operation: String,
    message: String,
    context: [String: String] = [:],
    source: SourceInfo? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil,
    performanceMetrics: PerformanceMetrics? = nil,
    errorChain: ErrorChain? = nil,
    stateTransition: StateTransition? = nil,
    bugReproduction: BugReproductionInfo? = nil,
    anomalyDetection: AnomalyInfo? = nil
  ) {
    guard level.priority >= logLevel.priority else {
      return
    }

    logQueue.async { [weak self] in
      guard let self = self else {
        return
      }

      let logEntry = EnhancedVibeLogEntry(
        level: level,
        operation: operation,
        message: message,
        context: context,
        environment: EnvironmentHelper.getCurrentEnvironment(),
        source: source ?? SourceInfo(),
        stackTrace: self.getStackTrace(),
        humanNote: humanNote,
        aiTodo: aiTodo,
        performanceMetrics: performanceMetrics,
        errorChain: errorChain,
        stateTransition: stateTransition,
        bugReproduction: bugReproduction,
        anomalyDetection: anomalyDetection
      )

      self.outputToConsole(logEntry)

      if self.enableFileOutput {
        if self.batchTimer != nil {
          // バッチモード時はバッファに追加
          self.logBuffer.append(logEntry)
          if self.logBuffer.count >= self.batchSize {
            self.flushLogBuffer()
          }
        } else {
          // 通常モード時は即座に出力
          self.outputToFile(logEntry)
        }
      }
    }
  }

  // MARK: - Convenience Methods
  public func logMethodStart(
    _ functionName: String = #function,
    file: String = #file,
    line: Int = #line,
    context: [String: String] = [:]
  ) {
    debug(
      operation: "methodStart",
      message: "メソッド開始: \(functionName)",
      context: context,
      source: SourceInfo(fileName: file, functionName: functionName, lineNumber: line)
    )
  }

  public func logMethodEnd(
    _ functionName: String = #function,
    file: String = #file,
    line: Int = #line,
    context: [String: String] = [:]
  ) {
    debug(
      operation: "methodEnd",
      message: "メソッド終了: \(functionName)",
      context: context,
      source: SourceInfo(fileName: file, functionName: functionName, lineNumber: line)
    )
  }

  public func logError(
    _ error: Error,
    operation: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    self.error(
      operation: operation,
      message: "エラー発生: \(error.localizedDescription)",
      context: [
        "error_type": String(describing: type(of: error)),
        "error_description": error.localizedDescription,
      ],
      source: SourceInfo(fileName: file, functionName: function, lineNumber: line),
      humanNote: humanNote,
      aiTodo: aiTodo
    )
  }

  // MARK: - Helper Methods
  internal func getStackTrace() -> String {
    let stackTrace = Thread.callStackSymbols
    return stackTrace.joined(separator: "\n")
  }
}
