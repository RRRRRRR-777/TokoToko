//
//  EnhancedVibeLoggerSpecialized.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/08/30.
//

import Foundation
import CoreLocation

// MARK: - TekuToko Specialized Logging Extension

/// EnhancedVibeLoggerのTekuToko特殊化ログ機能拡張
extension EnhancedVibeLogger {

  // MARK: - TekuToko Specialized Logging Methods

  /// 位置情報バグ予防ログ
  ///
  /// GPS位置情報の異常を検出し、潜在的なバグを予防するためのログを記録します。
  /// LocationAnomalyDetectorを使用して位置情報の精度、バッテリー状況、
  /// 時間経過を分析し、異常レベルに応じた適切なログレベルで出力します。
  ///
  /// - Parameters:
  ///   - location: 現在のGPS位置情報
  ///   - accuracy: 位置情報の精度
  ///   - batteryLevel: デバイスのバッテリー残量
  ///   - duration: 位置情報取得の継続時間
  ///   - context: 追加のコンテキスト情報
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
      case .low:
        return .info
      case .medium:
        return .warning
      case .high:
        return .error
      case .critical:
        return .critical
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

  /// 散歩状態遷移バグ予防ログ
  ///
  /// 散歩セッションの状態遷移を監視し、不正な遷移パターンを検出して
  /// バグを予防するためのログを記録します。WalkStateValidatorを使用して
  /// 状態遷移の妥当性を検証し、異常な遷移を早期発見します。
  ///
  /// - Parameters:
  ///   - walkId: 散歩セッションID
  ///   - fromState: 遷移前の状態
  ///   - toState: 遷移後の状態
  ///   - trigger: 状態遷移のトリガー
  ///   - context: 追加のコンテキスト情報
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

  /// 写真メモリバグ予防ログ
  ///
  /// 写真機能使用時のメモリ使用量を監視し、メモリ不足による
  /// クラッシュやパフォーマンス問題を予防するためのログを記録します。
  /// PhotoMemoryAnalyzerを使用してメモリ使用パターンを分析します。
  ///
  /// - Parameters:
  ///   - currentMemoryUsage: 現在のメモリ使用量
  ///   - photoCount: 読み込み済み写真枚数
  ///   - cacheSize: 写真キャッシュサイズ
  ///   - context: 追加のコンテキスト情報
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
      case .low:
        return .info
      case .medium:
        return .warning
      case .high:
        return .error
      case .critical:
        return .critical
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

  /// Firebase同期バグ予防ログ
  ///
  /// Firebase Firestoreとの同期状態を監視し、同期エラーや
  /// データ不整合を予防するためのログを記録します。
  /// FirebaseSyncAnalyzerを使用して同期状態を分析します。
  ///
  /// - Parameters:
  ///   - isOnline: ネットワーク接続状態
  ///   - pendingWrites: 未送信の書き込み件数
  ///   - lastSync: 最後の同期時刻
  ///   - context: 追加のコンテキスト情報
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
      case .low:
        return .info
      case .medium:
        return .warning
      case .high:
        return .error
      case .critical:
        return .critical
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
}
