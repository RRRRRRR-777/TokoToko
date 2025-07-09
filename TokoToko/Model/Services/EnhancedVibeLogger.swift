import CoreLocation
import Foundation
import UIKit
import Darwin

// MARK: - TokoToko Specialized Types (Phase 3)

// 位置情報関連の型定義
public struct LocationAnomalyResult {
  let severity: AnomalySeverity
  let anomalyInfo: AnomalyInfo?
  let aiRecommendation: String?
}

public struct LocationAnomalyDetector {
  static func analyze(
    location: CLLocation,
    accuracy: CLLocationAccuracy,
    batteryLevel: Float,
    duration: TimeInterval
  ) -> LocationAnomalyResult {
    var anomalies: [Anomaly] = []
    var severity: AnomalySeverity = .low
    var aiRecommendation: String?

    // GPS精度の異常検知
    if accuracy > 100.0 {
      anomalies.append(
        Anomaly(
          type: .responseTime,
          description: "GPS精度が低下しています",
          value: accuracy,
          threshold: 100.0,
          impact: "位置追跡の精度が低下"
        ))
      severity = .medium
      aiRecommendation = "GPS精度が低下しています。屋外での使用を推奨します。"
    }

    // バッテリー消費の異常検知
    if batteryLevel < 0.2 {
      anomalies.append(
        Anomaly(
          type: .batteryDrain,
          description: "バッテリーレベルが低下しています",
          value: Double(batteryLevel * 100),
          threshold: 20.0,
          impact: "位置追跡の継続が困難"
        ))
      severity = .high
      aiRecommendation = "バッテリーレベルが低下しています。充電を推奨します。"
    }

    // 追跡時間の異常検知
    if duration > 7200 {  // 2時間
      anomalies.append(
        Anomaly(
          type: .responseTime,
          description: "追跡時間が異常に長くなっています",
          value: duration,
          threshold: 7200.0,
          impact: "バッテリー消費の増加"
        ))
      severity = .medium
      aiRecommendation = "長時間の追跡によりバッテリー消費が増加しています。"
    }

    let anomalyInfo =
      !anomalies.isEmpty
      ? AnomalyInfo(
        detectedAnomalies: anomalies,
        severity: severity,
        confidence: 0.85,
        recommendedAction: aiRecommendation ?? "正常",
        detectionMethod: "LocationAnomalyDetector"
      ) : nil

    return LocationAnomalyResult(
      severity: severity,
      anomalyInfo: anomalyInfo,
      aiRecommendation: aiRecommendation
    )
  }
}

// Firebase同期関連の型定義
public struct FirebaseSyncResult {
  let severity: AnomalySeverity
  let anomalyInfo: AnomalyInfo?
  let aiRecommendation: String?
  let healthScore: String
}

public struct FirebaseSyncAnalyzer {
  static func analyze(
    isOnline: Bool,
    pendingWrites: Int,
    lastSync: Date?
  ) -> FirebaseSyncResult {
    var anomalies: [Anomaly] = []
    var severity: AnomalySeverity = .low
    var aiRecommendation: String?
    var healthScore = "良好"

    // オフライン状態の検知
    if !isOnline {
      anomalies.append(
        Anomaly(
          type: .networkTimeout,
          description: "オフライン状態です",
          value: 0.0,
          threshold: 1.0,
          impact: "データ同期が停止"
        ))
      severity = .medium
      aiRecommendation = "ネットワーク接続を確認してください。"
      healthScore = "注意"
    }

    // 未送信データの蓄積
    if pendingWrites > 10 {
      anomalies.append(
        Anomaly(
          type: .errorRate,
          description: "未送信データが蓄積しています",
          value: Double(pendingWrites),
          threshold: 10.0,
          impact: "データ損失のリスク"
        ))
      severity = .high
      aiRecommendation = "未送信データが蓄積しています。オフライン時のデータ損失リスクを評価してください。"
      healthScore = "危険"
    }

    // 最後の同期からの経過時間
    if let lastSync = lastSync {
      let timeSinceLastSync = Date().timeIntervalSince(lastSync)
      if timeSinceLastSync > 3600 {  // 1時間
        anomalies.append(
          Anomaly(
            type: .responseTime,
            description: "最後の同期から時間が経過しています",
            value: timeSinceLastSync,
            threshold: 3600.0,
            impact: "データの整合性リスク"
          ))
        severity = .medium
        aiRecommendation = "長時間同期されていません。ネットワーク接続を確認してください。"
        healthScore = "注意"
      }
    }

    let anomalyInfo =
      !anomalies.isEmpty
      ? AnomalyInfo(
        detectedAnomalies: anomalies,
        severity: severity,
        confidence: 0.9,
        recommendedAction: aiRecommendation ?? "正常",
        detectionMethod: "FirebaseSyncAnalyzer"
      ) : nil

    return FirebaseSyncResult(
      severity: severity,
      anomalyInfo: anomalyInfo,
      aiRecommendation: aiRecommendation,
      healthScore: healthScore
    )
  }
}

// メモリ圧迫度の型定義
public struct MemoryPressure {
  let level: String
  let usage: Int64

  init(usage: Int64) {
    self.usage = usage
    if usage > 1024 * 1024 * 500 {  // 500MB
      self.level = "高"
    } else if usage > 1024 * 1024 * 200 {  // 200MB
      self.level = "中"
    } else {
      self.level = "低"
    }
  }
}

// 写真メモリ分析関連の型定義
public struct PhotoMemoryResult {
  let severity: AnomalySeverity
  let anomalyInfo: AnomalyInfo?
  let aiRecommendation: String?
}

public struct PhotoMemoryAnalyzer {
  static func analyze(
    currentMemoryUsage: Int64,
    photoCount: Int,
    cacheSize: Int64
  ) -> PhotoMemoryResult {
    var anomalies: [Anomaly] = []
    var severity: AnomalySeverity = .low
    var aiRecommendation: String?

    // メモリ使用量のチェック
    if currentMemoryUsage > 300 * 1024 * 1024 {  // 300MB
      anomalies.append(
        Anomaly(
          type: .memoryLeak,
          description: "メモリ使用量が高くなっています",
          value: Double(currentMemoryUsage),
          threshold: 300 * 1024 * 1024,
          impact: "アプリのパフォーマンス低下"
        ))
      severity = .high
      aiRecommendation = "メモリ使用量が高くなっています。写真の解像度を下げるか、枚数を減らしてください。"
    }

    // 写真枚数の制限チェック
    if photoCount > 10 {
      anomalies.append(
        Anomaly(
          type: .memoryLeak,
          description: "写真枚数が制限を超えています",
          value: Double(photoCount),
          threshold: 10.0,
          impact: "メモリ使用量の増加"
        ))
      severity = .medium
      aiRecommendation = "写真枚数が制限(10枚)を超えています。不要な写真を削除してください。"
    }

    // キャッシュサイズのチェック
    if cacheSize > 50 * 1024 * 1024 {  // 50MB
      anomalies.append(
        Anomaly(
          type: .memoryLeak,
          description: "キャッシュサイズが大きくなっています",
          value: Double(cacheSize),
          threshold: 50 * 1024 * 1024,
          impact: "メモリ使用量の増加"
        ))
      severity = .medium
      aiRecommendation = "キャッシュサイズが大きくなっています。キャッシュをクリアしてください。"
    }

    let anomalyInfo =
      !anomalies.isEmpty
      ? AnomalyInfo(
        detectedAnomalies: anomalies,
        severity: severity,
        confidence: 0.8,
        recommendedAction: aiRecommendation ?? "正常",
        detectionMethod: "PhotoMemoryAnalyzer"
      ) : nil

    return PhotoMemoryResult(
      severity: severity,
      anomalyInfo: anomalyInfo,
      aiRecommendation: aiRecommendation
    )
  }
}

// 散歩状態関連の型定義
public enum WalkState: String, Codable {
  case notStarted = "notStarted"
  case inProgress = "inProgress"
  case paused = "paused"
  case completed = "completed"
  case error = "error"
}

public struct WalkStateTransitionResult {
  let anomalyInfo: AnomalyInfo?
  let healthScore: String
}

public struct WalkStateValidationResult {
  let isValid: Bool
  let severity: AnomalySeverity
  let anomalyInfo: AnomalyInfo?
  let aiRecommendation: String?
}

public struct WalkStateValidator {
  static func validate(
    fromState: String,
    toState: String,
    trigger: String,
    context: [String: String]
  ) -> WalkStateValidationResult {
    let isValid = isValidTransition(from: fromState, to: toState, trigger: trigger)
    var severity: AnomalySeverity = .low
    var anomalyInfo: AnomalyInfo?
    var aiRecommendation: String?

    if !isValid {
      severity = .high
      let anomaly = Anomaly(
        type: .errorRate,
        description: "不正な状態遷移が検出されました",
        value: 1.0,
        threshold: 0.0,
        impact: "散歩データの整合性問題"
      )
      anomalyInfo = AnomalyInfo(
        detectedAnomalies: [anomaly],
        severity: severity,
        confidence: 1.0,
        recommendedAction: "状態遷移ロジックを確認してください",
        detectionMethod: "WalkStateValidator"
      )
      aiRecommendation = "不正な状態遷移: \(fromState) -> \(toState) (trigger: \(trigger))"
    }

    return WalkStateValidationResult(
      isValid: isValid,
      severity: severity,
      anomalyInfo: anomalyInfo,
      aiRecommendation: aiRecommendation
    )
  }

  private static func isValidTransition(from: String, to: String, trigger: String) -> Bool {
    switch (from, to) {
    case ("notStarted", "inProgress"):
      return true
    case ("inProgress", "paused"):
      return true
    case ("paused", "inProgress"):
      return true
    case ("inProgress", "completed"):
      return true
    case ("paused", "completed"):
      return true
    default:
      return false
    }
  }
}

public struct WalkStateTransitionAnalyzer {
  static func analyze(
    walkId: String,
    from: WalkState,
    to: WalkState,
    trigger: String,
    isValid: Bool
  ) -> WalkStateTransitionResult {
    var anomalies: [Anomaly] = []
    var healthScore = "良好"

    if !isValid {
      anomalies.append(
        Anomaly(
          type: .errorRate,
          description: "不正な状態遷移が検出されました",
          value: 1.0,
          threshold: 0.0,
          impact: "散歩データの整合性問題"
        ))
      healthScore = "危険"
    }

    let anomalyInfo =
      !anomalies.isEmpty
      ? AnomalyInfo(
        detectedAnomalies: anomalies,
        severity: .high,
        confidence: 1.0,
        recommendedAction: "状態遷移ロジックを確認してください",
        detectionMethod: "WalkStateTransitionAnalyzer"
      ) : nil

    return WalkStateTransitionResult(
      anomalyInfo: anomalyInfo,
      healthScore: healthScore
    )
  }
}

// Date拡張（ISO8601フォーマット用）
extension Date {
  var iso8601: String {
    return ISO8601DateFormatter().string(from: self)
  }
}

// MARK: - Enhanced Log Entry Structure (Phase 2)
public struct EnhancedVibeLogEntry: Codable {
  // 基本情報
  let timestamp: String
  let level: LogLevel
  let correlationId: String
  let operation: String
  let message: String
  let context: [String: String]
  let environment: [String: String]

  // AI協働フィールド
  let source: SourceInfo?
  let stackTrace: String?
  let humanNote: String?
  let aiTodo: String?

  // Phase 2: バグ排除強化フィールド
  let performanceMetrics: PerformanceMetrics?
  let errorChain: ErrorChain?
  let stateTransition: StateTransition?
  let bugReproduction: BugReproductionInfo?
  let anomalyDetection: AnomalyInfo?

  init(
    level: LogLevel,
    correlationId: String = UUID().uuidString,
    operation: String,
    message: String,
    context: [String: String] = [:],
    environment: [String: String] = [:],
    source: SourceInfo? = nil,
    stackTrace: String? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil,
    performanceMetrics: PerformanceMetrics? = nil,
    errorChain: ErrorChain? = nil,
    stateTransition: StateTransition? = nil,
    bugReproduction: BugReproductionInfo? = nil,
    anomalyDetection: AnomalyInfo? = nil
  ) {
    self.timestamp = ISO8601DateFormatter().string(from: Date())
    self.level = level
    self.correlationId = correlationId
    self.operation = operation
    self.message = message
    self.context = context
    self.environment = environment
    self.source = source
    self.stackTrace = stackTrace
    self.humanNote = humanNote
    self.aiTodo = aiTodo
    self.performanceMetrics = performanceMetrics
    self.errorChain = errorChain
    self.stateTransition = stateTransition
    self.bugReproduction = bugReproduction
    self.anomalyDetection = anomalyDetection
  }
}

// MARK: - Backward Compatibility
public typealias BasicVibeLogEntry = EnhancedVibeLogEntry

// MARK: - Log Level Definition
public enum LogLevel: String, Codable, CaseIterable {
  case debug = "DEBUG"
  case info = "INFO"
  case warning = "WARNING"
  case error = "ERROR"
  case critical = "CRITICAL"

  var emoji: String {
    switch self {
    case .debug: return "🔧"
    case .info: return "📊"
    case .warning: return "⚠️"
    case .error: return "❌"
    case .critical: return "🚨"
    }
  }

  var priority: Int {
    switch self {
    case .debug: return 0
    case .info: return 1
    case .warning: return 2
    case .error: return 3
    case .critical: return 4
    }
  }
}

// MARK: - Source Information
public struct SourceInfo: Codable {
  let fileName: String
  let functionName: String
  let lineNumber: Int
  let moduleName: String

  init(
    fileName: String = #file, functionName: String = #function, lineNumber: Int = #line,
    moduleName: String = "TokoToko"
  ) {
    self.fileName = String(fileName.split(separator: "/").last ?? "Unknown")
    self.functionName = functionName
    self.lineNumber = lineNumber
    self.moduleName = moduleName
  }
}

// MARK: - Environment Information Helper
public struct EnvironmentHelper {
  static func getCurrentEnvironment() -> [String: String] {
    let device = UIDevice.current
    let processInfo = ProcessInfo.processInfo

    return [
      "device_model": device.model,
      "device_name": device.name,
      "system_name": device.systemName,
      "system_version": device.systemVersion,
      "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        ?? "Unknown",
      "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
      "process_name": processInfo.processName,
      "memory_pressure": String(processInfo.physicalMemory),
      "is_debug": String(isDebugBuild()),
      "battery_level": String(device.batteryLevel),
      "battery_state": batteryStateString(device.batteryState),
    ]
  }

  private static func isDebugBuild() -> Bool {
    #if DEBUG
      return true
    #else
      return false
    #endif
  }

  private static func batteryStateString(_ state: UIDevice.BatteryState) -> String {
    switch state {
    case .unknown: return "unknown"
    case .unplugged: return "unplugged"
    case .charging: return "charging"
    case .full: return "full"
    @unknown default: return "unknown"
    }
  }
}

// MARK: - Performance Metrics (Phase 2)
public struct PerformanceMetrics: Codable {
  let executionTime: TimeInterval
  let memoryUsage: Int64?
  let cpuUsage: Double?
  let diskIO: DiskIOMetrics?
  let networkLatency: TimeInterval?
  let threadInfo: ThreadInfo?
  let batteryDrain: Double?

  init(
    executionTime: TimeInterval,
    memoryUsage: Int64? = nil,
    cpuUsage: Double? = nil,
    diskIO: DiskIOMetrics? = nil,
    networkLatency: TimeInterval? = nil,
    threadInfo: ThreadInfo? = nil,
    batteryDrain: Double? = nil
  ) {
    self.executionTime = executionTime
    self.memoryUsage = memoryUsage
    self.cpuUsage = cpuUsage
    self.diskIO = diskIO
    self.networkLatency = networkLatency
    self.threadInfo = threadInfo
    self.batteryDrain = batteryDrain
  }
}

public struct DiskIOMetrics: Codable {
  let bytesRead: Int64
  let bytesWritten: Int64
  let operationCount: Int

  init(bytesRead: Int64 = 0, bytesWritten: Int64 = 0, operationCount: Int = 0) {
    self.bytesRead = bytesRead
    self.bytesWritten = bytesWritten
    self.operationCount = operationCount
  }
}

public struct ThreadInfo: Codable {
  let threadName: String
  let threadId: String
  let isMainThread: Bool
  let queueLabel: String?

  init(
    threadName: String = Thread.current.name ?? "Unknown",
    threadId: String = String(describing: Thread.current),
    isMainThread: Bool = Thread.isMainThread,
    queueLabel: String? = DispatchQueue.current?.label
  ) {
    self.threadName = threadName
    self.threadId = threadId
    self.isMainThread = isMainThread
    self.queueLabel = queueLabel
  }
}

// MARK: - Error Chain (Phase 2)
public struct ErrorChain: Codable {
  let rootCause: String
  let errorSequence: [ErrorEvent]
  let recoveryAttempts: Int
  let finalOutcome: String
  let preventionStrategy: String?

  init(
    rootCause: String,
    errorSequence: [ErrorEvent] = [],
    recoveryAttempts: Int = 0,
    finalOutcome: String,
    preventionStrategy: String? = nil
  ) {
    self.rootCause = rootCause
    self.errorSequence = errorSequence
    self.recoveryAttempts = recoveryAttempts
    self.finalOutcome = finalOutcome
    self.preventionStrategy = preventionStrategy
  }
}

public struct ErrorEvent: Codable {
  let timestamp: String
  let errorType: String
  let errorMessage: String
  let stackTrace: String?
  let context: [String: String]

  init(
    errorType: String,
    errorMessage: String,
    stackTrace: String? = nil,
    context: [String: String] = [:]
  ) {
    self.timestamp = ISO8601DateFormatter().string(from: Date())
    self.errorType = errorType
    self.errorMessage = errorMessage
    self.stackTrace = stackTrace
    self.context = context
  }
}

// MARK: - State Transition (Phase 2)
public struct StateTransition: Codable {
  let component: String
  let fromState: String
  let toState: String
  let trigger: String
  let isValid: Bool
  let timestamp: String
  let duration: TimeInterval?
  let metadata: [String: String]

  init(
    component: String,
    fromState: String,
    toState: String,
    trigger: String,
    isValid: Bool,
    duration: TimeInterval? = nil,
    metadata: [String: String] = [:]
  ) {
    self.component = component
    self.fromState = fromState
    self.toState = toState
    self.trigger = trigger
    self.isValid = isValid
    self.timestamp = ISO8601DateFormatter().string(from: Date())
    self.duration = duration
    self.metadata = metadata
  }
}

// MARK: - Bug Reproduction Info (Phase 2)
public struct BugReproductionInfo: Codable {
  let userActions: [UserAction]
  let systemSnapshot: SystemSnapshot
  let reproductionSteps: [String]
  let environmentFactors: [String]
  let reproductionRate: Double
  let severity: BugSeverity

  init(
    userActions: [UserAction] = [],
    systemSnapshot: SystemSnapshot,
    reproductionSteps: [String] = [],
    environmentFactors: [String] = [],
    reproductionRate: Double = 0.0,
    severity: BugSeverity = .medium
  ) {
    self.userActions = userActions
    self.systemSnapshot = systemSnapshot
    self.reproductionSteps = reproductionSteps
    self.environmentFactors = environmentFactors
    self.reproductionRate = reproductionRate
    self.severity = severity
  }
}

public struct UserAction: Codable {
  let timestamp: String
  let action: String
  let screen: String
  let element: String?
  let coordinates: CGPoint?
  let duration: TimeInterval?

  init(
    action: String,
    screen: String,
    element: String? = nil,
    coordinates: CGPoint? = nil,
    duration: TimeInterval? = nil
  ) {
    self.timestamp = ISO8601DateFormatter().string(from: Date())
    self.action = action
    self.screen = screen
    self.element = element
    self.coordinates = coordinates
    self.duration = duration
  }
}

public struct SystemSnapshot: Codable {
  let timestamp: String
  let memoryUsage: Int64
  let cpuUsage: Double
  let diskSpace: Int64
  let networkStatus: String
  let batteryLevel: Double
  let orientation: String
  let activeApps: [String]

  init(
    memoryUsage: Int64 = 0,
    cpuUsage: Double = 0.0,
    diskSpace: Int64 = 0,
    networkStatus: String = "unknown",
    batteryLevel: Double = 0.0,
    orientation: String = "unknown",
    activeApps: [String] = []
  ) {
    self.timestamp = ISO8601DateFormatter().string(from: Date())
    self.memoryUsage = memoryUsage
    self.cpuUsage = cpuUsage
    self.diskSpace = diskSpace
    self.networkStatus = networkStatus
    self.batteryLevel = batteryLevel
    self.orientation = orientation
    self.activeApps = activeApps
  }
}

public enum BugSeverity: String, Codable {
  case low = "LOW"
  case medium = "MEDIUM"
  case high = "HIGH"
  case critical = "CRITICAL"
}

// MARK: - Anomaly Detection (Phase 2)
public struct AnomalyInfo: Codable {
  let detectedAnomalies: [Anomaly]
  let severity: AnomalySeverity
  let confidence: Double
  let recommendedAction: String
  let detectionMethod: String
  let timestamp: String

  init(
    detectedAnomalies: [Anomaly],
    severity: AnomalySeverity,
    confidence: Double,
    recommendedAction: String,
    detectionMethod: String
  ) {
    self.detectedAnomalies = detectedAnomalies
    self.severity = severity
    self.confidence = confidence
    self.recommendedAction = recommendedAction
    self.detectionMethod = detectionMethod
    self.timestamp = ISO8601DateFormatter().string(from: Date())
  }
}

public struct Anomaly: Codable {
  let type: AnomalyType
  let description: String
  let value: Double
  let threshold: Double
  let impact: String

  init(
    type: AnomalyType,
    description: String,
    value: Double,
    threshold: Double,
    impact: String
  ) {
    self.type = type
    self.description = description
    self.value = value
    self.threshold = threshold
    self.impact = impact
  }
}

public enum AnomalyType: String, Codable {
  case memoryLeak = "MEMORY_LEAK"
  case cpuSpike = "CPU_SPIKE"
  case networkTimeout = "NETWORK_TIMEOUT"
  case batteryDrain = "BATTERY_DRAIN"
  case diskUsage = "DISK_USAGE"
  case responseTime = "RESPONSE_TIME"
  case errorRate = "ERROR_RATE"
}

public enum AnomalySeverity: String, Codable {
  case low = "LOW"
  case medium = "MEDIUM"
  case high = "HIGH"
  case critical = "CRITICAL"
}

// MARK: - Enhanced Vibe Logger
public class EnhancedVibeLogger {
  public static let shared = EnhancedVibeLogger()

  private let logQueue = DispatchQueue(label: "com.tokotoko.logger", qos: .utility)
  private let logLevel: LogLevel
  private let enableFileOutput: Bool
  private let logDirectoryPath: String

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

  public func logUserAction(
    action: String,
    screen: String,
    context: [String: String] = [:]
  ) {
    info(
      operation: "userAction",
      message: "ユーザーアクション: \(action)",
      context: ["screen": screen].merging(context, uniquingKeysWith: { _, new in new })
    )
  }

  public func logNetworkRequest(
    url: String,
    method: String,
    statusCode: Int? = nil,
    responseTime: TimeInterval? = nil
  ) {
    var context: [String: String] = [
      "url": url,
      "method": method,
    ]

    if let statusCode = statusCode {
      context["status_code"] = String(statusCode)
    }

    if let responseTime = responseTime {
      context["response_time"] = String(format: "%.3f", responseTime)
    }

    let level: LogLevel = statusCode != nil && statusCode! >= 400 ? .error : .info

    log(
      level: level,
      operation: "networkRequest",
      message: "ネットワークリクエスト: \(method) \(url)",
      context: context
    )
  }

  // MARK: - Enhanced Logging Methods (Phase 2)
  public func logWithPerformance(
    level: LogLevel,
    operation: String,
    message: String,
    executionTime: TimeInterval,
    context: [String: String] = [:],
    source: SourceInfo? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let performanceMetrics = PerformanceMetrics(
      executionTime: executionTime,
      memoryUsage: getCurrentMemoryUsage(),
      threadInfo: ThreadInfo()
    )

    log(
      level: level,
      operation: operation,
      message: message,
      context: context,
      source: source,
      humanNote: humanNote,
      aiTodo: aiTodo,
      performanceMetrics: performanceMetrics
    )
  }

  public func logStateTransition(
    component: String,
    from fromState: String,
    to toState: String,
    trigger: String,
    isValid: Bool,
    duration: TimeInterval? = nil,
    context: [String: String] = [:],
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let stateTransition = StateTransition(
      component: component,
      fromState: fromState,
      toState: toState,
      trigger: trigger,
      isValid: isValid,
      duration: duration,
      metadata: context
    )

    let level: LogLevel = isValid ? .info : .warning
    let message = "状態遷移: \(fromState) → \(toState) (trigger: \(trigger))"

    log(
      level: level,
      operation: "stateTransition",
      message: message,
      context: context,
      humanNote: humanNote,
      aiTodo: aiTodo,
      stateTransition: stateTransition
    )
  }

  public func logErrorChain(
    rootCause: String,
    errorSequence: [ErrorEvent],
    recoveryAttempts: Int,
    finalOutcome: String,
    context: [String: String] = [:],
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let errorChain = ErrorChain(
      rootCause: rootCause,
      errorSequence: errorSequence,
      recoveryAttempts: recoveryAttempts,
      finalOutcome: finalOutcome
    )

    log(
      level: .error,
      operation: "errorChain",
      message: "エラーチェーン: \(rootCause) → \(finalOutcome)",
      context: context,
      humanNote: humanNote,
      aiTodo: aiTodo,
      errorChain: errorChain
    )
  }

  public func logAnomaly(
    anomalies: [Anomaly],
    severity: AnomalySeverity,
    confidence: Double,
    recommendedAction: String,
    detectionMethod: String,
    context: [String: String] = [:],
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let anomalyInfo = AnomalyInfo(
      detectedAnomalies: anomalies,
      severity: severity,
      confidence: confidence,
      recommendedAction: recommendedAction,
      detectionMethod: detectionMethod
    )

    let logLevel: LogLevel = {
      switch severity {
      case .low: return .warning
      case .medium: return .error
      case .high: return .error
      case .critical: return .critical
      }
    }()

    log(
      level: logLevel,
      operation: "anomalyDetection",
      message: "異常検知: \(anomalies.count)件の異常 (信頼度: \(confidence))",
      context: context,
      humanNote: humanNote,
      aiTodo: aiTodo,
      anomalyDetection: anomalyInfo
    )
  }

  public func logBugReproduction(
    userActions: [UserAction],
    systemSnapshot: SystemSnapshot,
    reproductionSteps: [String],
    environmentFactors: [String],
    reproductionRate: Double,
    severity: BugSeverity,
    context: [String: String] = [:],
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let bugReproduction = BugReproductionInfo(
      userActions: userActions,
      systemSnapshot: systemSnapshot,
      reproductionSteps: reproductionSteps,
      environmentFactors: environmentFactors,
      reproductionRate: reproductionRate,
      severity: severity
    )

    let logLevel: LogLevel = {
      switch severity {
      case .low: return .warning
      case .medium: return .error
      case .high: return .error
      case .critical: return .critical
      }
    }()

    log(
      level: logLevel,
      operation: "bugReproduction",
      message: "バグ再現情報: 再現率\(reproductionRate * 100)%",
      context: context,
      humanNote: humanNote,
      aiTodo: aiTodo,
      bugReproduction: bugReproduction
    )
  }

  // MARK: - Performance Measurement Utilities
  public func measurePerformance<T>(
    operation: String,
    execute: () throws -> T
  ) rethrows -> T {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = try execute()
    let executionTime = CFAbsoluteTimeGetCurrent() - startTime

    logWithPerformance(
      level: .info,
      operation: operation,
      message: "パフォーマンス測定完了",
      executionTime: executionTime,
      aiTodo: executionTime > 1.0 ? "実行時間が長すぎます。最適化を検討してください。" : nil
    )

    return result
  }

  public func measurePerformanceAsync<T>(
    operation: String,
    execute: @escaping () async throws -> T
  ) async rethrows -> T {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = try await execute()
    let executionTime = CFAbsoluteTimeGetCurrent() - startTime

    logWithPerformance(
      level: .info,
      operation: operation,
      message: "非同期パフォーマンス測定完了",
      executionTime: executionTime,
      aiTodo: executionTime > 2.0 ? "非同期処理の実行時間が長すぎます。最適化を検討してください。" : nil
    )

    return result
  }

  // MARK: - System Metrics Helpers
  private func getCurrentMemoryUsage() -> Int64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let result = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }

    return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
  }

  // MARK: - TokoToko Specialized Bug Prevention Methods (Phase 3)

  // 🚶‍♂️ 位置情報バグ対策
  public func logLocationBugPrevention(
    location: CLLocation,
    accuracy: CLLocationAccuracy,
    batteryLevel: Float,
    duration: TimeInterval,
    context: [String: String] = [:],
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let locationAnomalies = LocationAnomalyDetector.analyze(
      location: location,
      accuracy: accuracy,
      batteryLevel: batteryLevel,
      duration: duration
    )

    let performanceMetrics = PerformanceMetrics(
      executionTime: duration,
      memoryUsage: getCurrentMemoryUsage(),
      threadInfo: ThreadInfo()
    )

    var enhancedContext = context
    enhancedContext["latitude"] = String(location.coordinate.latitude)
    enhancedContext["longitude"] = String(location.coordinate.longitude)
    enhancedContext["accuracy"] = String(accuracy)
    enhancedContext["altitude"] = String(location.altitude)
    enhancedContext["speed"] = String(location.speed)
    enhancedContext["course"] = String(location.course)
    enhancedContext["battery_level"] = String(batteryLevel)
    enhancedContext["tracking_duration"] = String(duration)

    let level: LogLevel = locationAnomalies.severity == .low ? .info : .warning
    let message = "位置情報追跡の最適化分析: 精度\(accuracy)m, バッテリー\(Int(batteryLevel * 100))%"

    log(
      level: level,
      operation: "locationBugPrevention",
      message: message,
      context: enhancedContext,
      humanNote: humanNote,
      aiTodo: aiTodo ?? locationAnomalies.aiRecommendation,
      performanceMetrics: performanceMetrics,
      anomalyDetection: locationAnomalies.anomalyInfo
    )
  }

  // 🔄 Firebase同期バグ対策
  public func logFirebaseSyncBugPrevention(
    isOnline: Bool,
    pendingWrites: Int,
    lastSync: Date?,
    context: [String: String] = [:],
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let syncHealth = FirebaseSyncAnalyzer.analyze(
      isOnline: isOnline,
      pendingWrites: pendingWrites,
      lastSync: lastSync
    )

    var enhancedContext = context
    enhancedContext["is_online"] = String(isOnline)
    enhancedContext["pending_writes"] = String(pendingWrites)
    enhancedContext["last_sync"] = lastSync?.iso8601 ?? "never"
    enhancedContext["sync_health"] = syncHealth.healthScore

    let level: LogLevel = syncHealth.severity == .low ? .info : .error
    let message = "Firebase同期状態の分析: オンライン=\(isOnline), 未送信=\(pendingWrites)件"

    log(
      level: level,
      operation: "firebaseSyncBugPrevention",
      message: message,
      context: enhancedContext,
      humanNote: humanNote,
      aiTodo: aiTodo ?? syncHealth.aiRecommendation,
      anomalyDetection: syncHealth.anomalyInfo
    )
  }

  // 📸 写真・メモリバグ対策
  public func logPhotoMemoryBugPrevention(
    currentMemoryUsage: Int64,
    photoCount: Int,
    cacheSize: Int64,
    context: [String: String] = [:],
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let memoryHealth = PhotoMemoryAnalyzer.analyze(
      currentMemoryUsage: currentMemoryUsage,
      photoCount: photoCount,
      cacheSize: cacheSize
    )

    let performanceMetrics = PerformanceMetrics(
      executionTime: 0.0,
      memoryUsage: currentMemoryUsage,
      threadInfo: ThreadInfo()
    )

    var enhancedContext = context
    enhancedContext["photo_count"] = String(photoCount)
    enhancedContext["memory_usage"] = String(currentMemoryUsage)
    enhancedContext["cache_size"] = String(cacheSize)
    enhancedContext["max_photo_limit"] = "10"

    let level: LogLevel = memoryHealth.severity == .low ? .info : .warning
    let message = "写真管理のメモリ分析: \(photoCount)枚, メモリ使用量=\(currentMemoryUsage)bytes"

    log(
      level: level,
      operation: "photoMemoryBugPrevention",
      message: message,
      context: enhancedContext,
      humanNote: humanNote,
      aiTodo: aiTodo ?? memoryHealth.aiRecommendation,
      performanceMetrics: performanceMetrics,
      anomalyDetection: memoryHealth.anomalyInfo
    )
  }

  // 🔄 散歩状態遷移バグ対策
  public func logWalkStateTransitionBugPrevention(
    fromState: String,
    toState: String,
    trigger: String,
    context: [String: String] = [:],
    humanNote: String? = nil,
    aiTodo: String? = nil
  ) {
    let validationResult = WalkStateValidator.validate(
      fromState: fromState,
      toState: toState,
      trigger: trigger,
      context: context
    )

    let stateTransition = StateTransition(
      component: "WalkManager",
      fromState: fromState,
      toState: toState,
      trigger: trigger,
      isValid: validationResult.isValid
    )

    var enhancedContext = context
    enhancedContext["is_valid_transition"] = String(validationResult.isValid)

    let level: LogLevel = validationResult.isValid ? .info : .error
    let message = "散歩状態遷移: \(fromState) → \(toState) (\(trigger))"

    log(
      level: level,
      operation: "walkStateTransitionBugPrevention",
      message: message,
      context: enhancedContext,
      humanNote: humanNote,
      aiTodo: aiTodo ?? validationResult.aiRecommendation,
      stateTransition: stateTransition,
      anomalyDetection: validationResult.anomalyInfo
    )
  }

  // MARK: - Phase 5: 自動化・最適化機能
  
  // ログレベル動的調整機能
  public func adjustLogLevelBasedOnConditions() {
    logQueue.async { [weak self] in
      guard let self = self else { return }
      
      let currentBattery = UIDevice.current.batteryLevel
      let memoryPressure = self.getMemoryPressureLevel()
      let errorFrequency = self.getRecentErrorFrequency()
      
      var newLogLevel: LogLevel = .info
      
      // バッテリー残量による調整
      if currentBattery < 0.20 {
        newLogLevel = .warning  // 低バッテリー時は警告以上のみ
      } else if currentBattery < 0.50 {
        newLogLevel = .info      // 中バッテリー時は情報以上
      } else {
        newLogLevel = .debug     // 高バッテリー時は全て
      }
      
      // メモリ圧迫時の調整
      if memoryPressure > 0.8 {
        newLogLevel = LogLevel(rawValue: max(newLogLevel.rawValue, LogLevel.warning.rawValue)) ?? .warning
      }
      
      // エラー頻度による調整
      if errorFrequency > 5 {
        newLogLevel = .debug  // エラー多発時は詳細ログ
      }
      
      if newLogLevel != self.logLevel {
        let oldLevel = self.logLevel
        self.logLevel = newLogLevel
        
        self.log(
          level: .info,
          operation: "adjustLogLevelBasedOnConditions",
          message: "ログレベルを自動調整しました",
          context: [
            "old_level": oldLevel.rawValue,
            "new_level": newLogLevel.rawValue,
            "battery_level": String(format: "%.2f", currentBattery),
            "memory_pressure": String(format: "%.2f", memoryPressure),
            "error_frequency": String(errorFrequency)
          ],
          humanNote: "システム状態に基づいてログレベルを最適化",
          aiTodo: "ログレベル変更の効果を監視"
        )
      }
    }
  }
  
  // メモリ圧迫レベルの取得
  private func getMemoryPressureLevel() -> Double {
    let info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    
    if kerr == KERN_SUCCESS {
      let usedMemory = Double(info.resident_size)
      let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
      return usedMemory / totalMemory
    }
    
    return 0.0
  }
  
  // 最近のエラー頻度の取得
  private func getRecentErrorFrequency() -> Int {
    let recentTimeInterval: TimeInterval = 300  // 5分間
    let cutoffDate = Date().addingTimeInterval(-recentTimeInterval)
    
    // 簡易的な実装（実際はログファイルを解析）
    return 0
  }
  
  // ログファイル自動ローテーション
  public func rotateLogFiles() {
    logQueue.async { [weak self] in
      guard let self = self else { return }
      
      let fileManager = FileManager.default
      let maxFileSize: Int64 = 10 * 1024 * 1024  // 10MB
      let maxFiles = 5
      
      do {
        let files = try fileManager.contentsOfDirectory(atPath: self.logDirectoryPath)
        let logFiles = files.filter { $0.hasSuffix(".log") }.sorted()
        
        for file in logFiles {
          let filePath = "\(self.logDirectoryPath)/\(file)"
          let attributes = try fileManager.attributesOfItem(atPath: filePath)
          
          if let fileSize = attributes[.size] as? Int64, fileSize > maxFileSize {
            // ファイルサイズが上限を超えた場合、ローテーション
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let rotatedFileName = file.replacingOccurrences(of: ".log", with: "_\(timestamp).log")
            let rotatedFilePath = "\(self.logDirectoryPath)/\(rotatedFileName)"
            
            try fileManager.moveItem(atPath: filePath, toPath: rotatedFilePath)
            
            self.log(
              level: .info,
              operation: "rotateLogFiles",
              message: "ログファイルをローテーションしました",
              context: [
                "original_file": file,
                "rotated_file": rotatedFileName,
                "file_size": String(fileSize)
              ]
            )
          }
        }
        
        // 古いローテーションファイルを削除
        let allFiles = try fileManager.contentsOfDirectory(atPath: self.logDirectoryPath)
        let rotatedFiles = allFiles.filter { $0.contains("_") && $0.hasSuffix(".log") }.sorted()
        
        if rotatedFiles.count > maxFiles {
          let filesToDelete = rotatedFiles.prefix(rotatedFiles.count - maxFiles)
          for file in filesToDelete {
            let filePath = "\(self.logDirectoryPath)/\(file)"
            try fileManager.removeItem(atPath: filePath)
          }
        }
      } catch {
        print("ログファイルローテーションエラー: \(error)")
      }
    }
  }
  
  // バッチログ出力機能
  private var logBuffer: [EnhancedVibeLogEntry] = []
  private var batchSize = 10
  private var batchTimer: Timer?
  
  public func enableBatchLogging(batchSize: Int = 10, flushInterval: TimeInterval = 5.0) {
    self.batchSize = batchSize
    
    batchTimer?.invalidate()
    batchTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
      self?.flushLogBuffer()
    }
  }
  
  public func disableBatchLogging() {
    batchTimer?.invalidate()
    batchTimer = nil
    flushLogBuffer()
  }
  
  private func flushLogBuffer() {
    logQueue.async { [weak self] in
      guard let self = self, !self.logBuffer.isEmpty else { return }
      
      let logsToFlush = self.logBuffer
      self.logBuffer.removeAll()
      
      for logEntry in logsToFlush {
        self.outputToFile(logEntry)
      }
      
      if logsToFlush.count > 0 {
        self.log(
          level: .debug,
          operation: "flushLogBuffer",
          message: "バッチログを出力しました",
          context: [
            "batch_size": String(logsToFlush.count),
            "buffer_cleared": "true"
          ]
        )
      }
    }
  }
  
  // パフォーマンス最適化設定
  public func optimizePerformance() {
    logQueue.async { [weak self] in
      guard let self = self else { return }
      
      let currentBattery = UIDevice.current.batteryLevel
      let memoryPressure = self.getMemoryPressureLevel()
      
      // バッテリー残量に基づく最適化
      if currentBattery < 0.20 {
        self.enableFileOutput = false
        self.adjustLogLevelBasedOnConditions()
        self.enableBatchLogging(batchSize: 20, flushInterval: 10.0)
      } else if currentBattery < 0.50 {
        self.enableFileOutput = true
        self.enableBatchLogging(batchSize: 15, flushInterval: 7.0)
      } else {
        self.enableFileOutput = true
        self.enableBatchLogging(batchSize: 10, flushInterval: 5.0)
      }
      
      // メモリ圧迫時の最適化
      if memoryPressure > 0.8 {
        self.clearOldLogs(olderThanDays: 3)
        self.rotateLogFiles()
      }
      
      self.log(
        level: .info,
        operation: "optimizePerformance",
        message: "パフォーマンス最適化を実行しました",
        context: [
          "battery_level": String(format: "%.2f", currentBattery),
          "memory_pressure": String(format: "%.2f", memoryPressure),
          "file_output": String(self.enableFileOutput),
          "batch_logging": self.batchTimer != nil ? "enabled" : "disabled"
        ],
        humanNote: "システムリソースに基づいて最適化",
        aiTodo: "最適化効果を監視"
      )
    }
  }

  // MARK: - Log Management Methods
  public func clearOldLogs(olderThanDays days: Int = 7) {
    logQueue.async { [weak self] in
      guard let self = self else { return }

      let fileManager = FileManager.default
      let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))

      do {
        let files = try fileManager.contentsOfDirectory(atPath: self.logDirectoryPath)

        for file in files {
          let filePath = "\(self.logDirectoryPath)/\(file)"
          let attributes = try fileManager.attributesOfItem(atPath: filePath)

          if let modificationDate = attributes[.modificationDate] as? Date,
            modificationDate < cutoffDate
          {
            try fileManager.removeItem(atPath: filePath)
          }
        }
      } catch {
        print("Failed to clear old logs: \(error)")
      }
    }
  }

  public func getLogFiles() -> [String] {
    do {
      let files = try FileManager.default.contentsOfDirectory(atPath: logDirectoryPath)
      return files.filter { $0.hasSuffix(".log") }
    } catch {
      return []
    }
  }
}
