import Foundation
import CoreLocation
import UIKit

// MARK: - TokoToko Specialized Analyzers

// MARK: - Location Anomaly Detection

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

// MARK: - Firebase Sync Analysis

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

// MARK: - Memory Pressure Analysis

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

// MARK: - Photo Memory Analysis

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

// MARK: - Walk State Analysis

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