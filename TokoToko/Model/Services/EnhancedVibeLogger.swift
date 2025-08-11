import Foundation
import Darwin
import CoreLocation

// MARK: - Enhanced Vibe Logger Core Implementation

public class EnhancedVibeLogger {
  public static let shared = EnhancedVibeLogger()

  private let logQueue = DispatchQueue(label: "com.tokotoko.logger", qos: .utility)
  private var logLevel: LogLevel
  private var enableFileOutput: Bool
  private let logDirectoryPath: String
  
  // バッチログ機能
  private var logBuffer: [EnhancedVibeLogEntry] = []
  private var batchTimer: Timer?
  private let batchSize = 50
  private let batchTimeInterval: TimeInterval = 30.0

  private init() {
    #if DEBUG
      self.logLevel = .debug
      self.enableFileOutput = true
    #else
      self.logLevel = .info
      self.enableFileOutput = false
    #endif

    self.logDirectoryPath = NSHomeDirectory() + "/RRRRRRR777/TokoToko/logs"

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
    return logLevel
  }
  
  public func setFileOutput(_ enabled: Bool) {
    enableFileOutput = enabled
  }
  
  public func getFileOutput() -> Bool {
    return enableFileOutput
  }
  
  public func resetToDefaultSettings() {
    logLevel = .debug
    enableFileOutput = true
  }
  
  public func getLogDirectoryPath() -> String {
    return logDirectoryPath
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
  private func log(
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
    guard level.priority >= logLevel.priority else { return }

    logQueue.async { [weak self] in
      guard let self = self else { return }

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

  // MARK: - Output Methods
  private func outputToConsole(_ logEntry: EnhancedVibeLogEntry) {
    let consoleOutput = formatConsoleOutput(logEntry)
    print(consoleOutput)
  }

  private func outputToFile(_ logEntry: EnhancedVibeLogEntry) {
    guard let jsonData = try? JSONEncoder().encode(logEntry),
      let jsonString = String(data: jsonData, encoding: .utf8)
    else {
      return
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateString = dateFormatter.string(from: Date())

    let fileName = "tokotoko_\(dateString).log"
    let filePath = "\(logDirectoryPath)/\(fileName)"

    let logLine = "\(jsonString)\n"

    if FileManager.default.fileExists(atPath: filePath) {
      if let fileHandle = FileHandle(forWritingAtPath: filePath) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(logLine.data(using: .utf8) ?? Data())
        fileHandle.closeFile()
      }
    } else {
      try? logLine.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
  }

  // MARK: - Batch Log Management
  public func startBatchMode(interval: TimeInterval = 30.0) {
    logQueue.async { [weak self] in
      guard let self = self else { return }
      
      self.stopBatchMode()
      
      DispatchQueue.main.async {
        self.batchTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
          self.flushLogBuffer()
        }
      }
    }
  }

  public func stopBatchMode() {
    logQueue.async { [weak self] in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        self.batchTimer?.invalidate()
        self.batchTimer = nil
      }
      
      self.flushLogBuffer()
    }
  }

  private func flushLogBuffer() {
    guard !logBuffer.isEmpty else { return }
    
    let currentBuffer = logBuffer
    logBuffer.removeAll()
    
    for logEntry in currentBuffer {
      outputToFile(logEntry)
    }
  }

  // MARK: - Formatting Methods
  private func formatConsoleOutput(_ logEntry: EnhancedVibeLogEntry) -> String {
    let timestamp = logEntry.timestamp
    let level = logEntry.level
    let operation = logEntry.operation
    let message = logEntry.message
    let source = logEntry.source

    var output = "\(level.emoji) [\(level.rawValue)] \(timestamp) [\(operation)] \(message)"

    if let source = source {
      output += " (\(source.fileName):\(source.lineNumber) \(source.functionName))"
    }

    if !logEntry.context.isEmpty {
      output += " Context: \(logEntry.context)"
    }

    if let humanNote = logEntry.humanNote {
      output += " 📝 Human: \(humanNote)"
    }

    if let aiTodo = logEntry.aiTodo {
      output += " 🤖 AI-TODO: \(aiTodo)"
    }

    return output
  }

  // MARK: - Helper Methods
  private func getStackTrace() -> String {
    let stackTrace = Thread.callStackSymbols
    return stackTrace.joined(separator: "\n")
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

  // MARK: - Performance Measurement
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

  // MARK: - TokoToko Specialized Logging Methods
  public func logLocationBugPrevention(
    location: CLLocation,
    accuracy: CLLocationAccuracy,
    batteryLevel: Float,
    duration: TimeInterval,
    context: [String: String] = [:]
  ) {
    let anomalyResult = LocationAnomalyDetector.analyze(
      location: location,
      accuracy: accuracy,
      batteryLevel: batteryLevel,
      duration: duration
    )

    let level: LogLevel = {
      switch anomalyResult.severity {
      case .low: return .info
      case .medium: return .warning
      case .high: return .error
      case .critical: return .critical
      }
    }()

    log(
      level: level,
      operation: "locationBugPrevention",
      message: anomalyResult.aiRecommendation ?? "位置情報正常",
      context: context,
      anomalyDetection: anomalyResult.anomalyInfo
    )
  }

  public func logWalkStateTransitionBugPrevention(
    walkId: String,
    fromState: String,
    toState: String,
    trigger: String,
    context: [String: String] = [:]
  ) {
    let validation = WalkStateValidator.validate(
      fromState: fromState,
      toState: toState,
      trigger: trigger,
      context: context
    )

    if !validation.isValid {
      log(
        level: .error,
        operation: "walkStateTransitionBugPrevention",
        message: validation.aiRecommendation ?? "不正な状態遷移",
        context: context,
        anomalyDetection: validation.anomalyInfo
      )
    } else {
      log(
        level: .debug,
        operation: "walkStateTransitionBugPrevention",
        message: "正常な状態遷移: \(fromState) -> \(toState)",
        context: context
      )
    }
  }

  public func logPhotoMemoryBugPrevention(
    currentMemoryUsage: Int64,
    photoCount: Int,
    cacheSize: Int64,
    context: [String: String] = [:]
  ) {
    let memoryResult = PhotoMemoryAnalyzer.analyze(
      currentMemoryUsage: currentMemoryUsage,
      photoCount: photoCount,
      cacheSize: cacheSize
    )

    let level: LogLevel = {
      switch memoryResult.severity {
      case .low: return .info
      case .medium: return .warning
      case .high: return .error
      case .critical: return .critical
      }
    }()

    log(
      level: level,
      operation: "photoMemoryBugPrevention",
      message: memoryResult.aiRecommendation ?? "メモリ使用量正常",
      context: context,
      anomalyDetection: memoryResult.anomalyInfo
    )
  }

  public func logFirebaseSyncBugPrevention(
    isOnline: Bool,
    pendingWrites: Int,
    lastSync: Date?,
    context: [String: String] = [:]
  ) {
    let syncResult = FirebaseSyncAnalyzer.analyze(
      isOnline: isOnline,
      pendingWrites: pendingWrites,
      lastSync: lastSync
    )

    let level: LogLevel = {
      switch syncResult.severity {
      case .low: return .info
      case .medium: return .warning
      case .high: return .error
      case .critical: return .critical
      }
    }()

    log(
      level: level,
      operation: "firebaseSyncBugPrevention",
      message: syncResult.aiRecommendation ?? "Firebase同期正常",
      context: context,
      anomalyDetection: syncResult.anomalyInfo
    )
  }

  // MARK: - Memory Management
  private func getCurrentMemoryUsage() -> Int64 {
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