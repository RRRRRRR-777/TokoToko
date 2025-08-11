import Foundation

// MARK: - Enhanced Log Entry Structure

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