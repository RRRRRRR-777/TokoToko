import Foundation
import CoreGraphics

// MARK: - Performance Metrics

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
    queueLabel: String? = nil
  ) {
    self.threadName = threadName
    self.threadId = threadId
    self.isMainThread = isMainThread
    self.queueLabel = queueLabel
  }
}

// MARK: - Error Chain

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

// MARK: - State Transition

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

// MARK: - Bug Reproduction Info

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