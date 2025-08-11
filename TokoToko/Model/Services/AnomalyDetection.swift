import Foundation

// MARK: - Anomaly Detection Types

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