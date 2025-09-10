//
//  TokoTokoAnalyzersTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/08/02.
//

import XCTest
import CoreLocation
@testable import TekuToko

class TokoTokoAnalyzersTests: XCTestCase {

    // MARK: - LocationAnomalyDetector Tests
    
    func testLocationAnomalyDetector_NormalConditions() {
        // Arrange
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
        let accuracy: CLLocationAccuracy = 5.0
        let batteryLevel: Float = 0.8
        let duration: TimeInterval = 1800 // 30分
        
        // Act
        let result = LocationAnomalyDetector.analyze(
            location: location,
            accuracy: accuracy,
            batteryLevel: batteryLevel,
            duration: duration
        )
        
        // Assert
        XCTAssertEqual(result.severity, .low)
        XCTAssertNil(result.anomalyInfo)
        XCTAssertNil(result.aiRecommendation)
    }
    
    func testLocationAnomalyDetector_PoorGPSAccuracy() {
        // Arrange
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
        let accuracy: CLLocationAccuracy = 150.0
        let batteryLevel: Float = 0.8
        let duration: TimeInterval = 1800
        
        // Act
        let result = LocationAnomalyDetector.analyze(
            location: location,
            accuracy: accuracy,
            batteryLevel: batteryLevel,
            duration: duration
        )
        
        // Assert
        XCTAssertEqual(result.severity, .medium)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertEqual(result.aiRecommendation, "GPS精度が低下しています。屋外での使用を推奨します。")
    }
    
    func testLocationAnomalyDetector_LowBattery() {
        // Arrange
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
        let accuracy: CLLocationAccuracy = 5.0
        let batteryLevel: Float = 0.05
        let duration: TimeInterval = 1800
        
        // Act
        let result = LocationAnomalyDetector.analyze(
            location: location,
            accuracy: accuracy,
            batteryLevel: batteryLevel,
            duration: duration
        )
        
        // Assert
        XCTAssertEqual(result.severity, .medium)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertEqual(result.aiRecommendation, "バッテリーレベルが低下しています。充電を推奨します。")
    }
    
    func testLocationAnomalyDetector_SimulatorBatteryLevel() {
        // Arrange - シミュレーター環境での-1.0バッテリーレベル
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
        let accuracy: CLLocationAccuracy = 5.0
        let batteryLevel: Float = -1.0
        let duration: TimeInterval = 1800
        
        // Act
        let result = LocationAnomalyDetector.analyze(
            location: location,
            accuracy: accuracy,
            batteryLevel: batteryLevel,
            duration: duration
        )
        
        // Assert - シミュレーターではバッテリー異常は検出されない
        XCTAssertEqual(result.severity, .low)
        XCTAssertNil(result.anomalyInfo)
    }
    
    func testLocationAnomalyDetector_LongTrackingDuration() {
        // Arrange
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
        let accuracy: CLLocationAccuracy = 5.0
        let batteryLevel: Float = 0.8
        let duration: TimeInterval = 7300 // 2時間超
        
        // Act
        let result = LocationAnomalyDetector.analyze(
            location: location,
            accuracy: accuracy,
            batteryLevel: batteryLevel,
            duration: duration
        )
        
        // Assert
        XCTAssertEqual(result.severity, .medium)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertEqual(result.aiRecommendation, "長時間の追跡によりバッテリー消費が増加しています。")
    }

    // MARK: - FirebaseSyncAnalyzer Tests
    
    func testFirebaseSyncAnalyzer_NormalConditions() {
        // Arrange
        let isOnline = true
        let pendingWrites = 2
        let lastSync = Date()
        
        // Act
        let result = FirebaseSyncAnalyzer.analyze(
            isOnline: isOnline,
            pendingWrites: pendingWrites,
            lastSync: lastSync
        )
        
        // Assert
        XCTAssertEqual(result.severity, .low)
        XCTAssertNil(result.anomalyInfo)
        XCTAssertEqual(result.healthScore, "良好")
    }
    
    func testFirebaseSyncAnalyzer_OfflineState() {
        // Arrange
        let isOnline = false
        let pendingWrites = 2
        let lastSync = Date()
        
        // Act
        let result = FirebaseSyncAnalyzer.analyze(
            isOnline: isOnline,
            pendingWrites: pendingWrites,
            lastSync: lastSync
        )
        
        // Assert
        XCTAssertEqual(result.severity, .medium)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertEqual(result.healthScore, "注意")
        XCTAssertEqual(result.aiRecommendation, "ネットワーク接続を確認してください。")
    }
    
    func testFirebaseSyncAnalyzer_ManyPendingWrites() {
        // Arrange
        let isOnline = true
        let pendingWrites = 15
        let lastSync = Date()
        
        // Act
        let result = FirebaseSyncAnalyzer.analyze(
            isOnline: isOnline,
            pendingWrites: pendingWrites,
            lastSync: lastSync
        )
        
        // Assert
        XCTAssertEqual(result.severity, .high)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertEqual(result.healthScore, "危険")
        XCTAssertTrue(result.aiRecommendation?.contains("未送信データが蓄積しています") == true)
    }
    
    func testFirebaseSyncAnalyzer_OldLastSync() {
        // Arrange
        let isOnline = true
        let pendingWrites = 2
        let lastSync = Date().addingTimeInterval(-3700) // 1時間以上前
        
        // Act
        let result = FirebaseSyncAnalyzer.analyze(
            isOnline: isOnline,
            pendingWrites: pendingWrites,
            lastSync: lastSync
        )
        
        // Assert
        XCTAssertEqual(result.severity, .medium)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertEqual(result.healthScore, "注意")
        XCTAssertTrue(result.aiRecommendation?.contains("長時間同期されていません") == true)
    }

    // MARK: - PhotoMemoryAnalyzer Tests
    
    func testPhotoMemoryAnalyzer_NormalConditions() {
        // Arrange
        let currentMemoryUsage: Int64 = 100 * 1024 * 1024 // 100MB
        let photoCount = 5
        let cacheSize: Int64 = 20 * 1024 * 1024 // 20MB
        
        // Act
        let result = PhotoMemoryAnalyzer.analyze(
            currentMemoryUsage: currentMemoryUsage,
            photoCount: photoCount,
            cacheSize: cacheSize
        )
        
        // Assert
        XCTAssertEqual(result.severity, .low)
        XCTAssertNil(result.anomalyInfo)
        XCTAssertNil(result.aiRecommendation)
    }
    
    func testPhotoMemoryAnalyzer_HighMemoryUsage() {
        // Arrange
        let currentMemoryUsage: Int64 = 400 * 1024 * 1024 // 400MB
        let photoCount = 5
        let cacheSize: Int64 = 20 * 1024 * 1024
        
        // Act
        let result = PhotoMemoryAnalyzer.analyze(
            currentMemoryUsage: currentMemoryUsage,
            photoCount: photoCount,
            cacheSize: cacheSize
        )
        
        // Assert
        XCTAssertEqual(result.severity, .high)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertTrue(result.aiRecommendation?.contains("メモリ使用量が高くなっています") == true)
    }
    
    func testPhotoMemoryAnalyzer_TooManyPhotos() {
        // Arrange
        let currentMemoryUsage: Int64 = 100 * 1024 * 1024
        let photoCount = 15 // 制限の10枚を超過
        let cacheSize: Int64 = 20 * 1024 * 1024
        
        // Act
        let result = PhotoMemoryAnalyzer.analyze(
            currentMemoryUsage: currentMemoryUsage,
            photoCount: photoCount,
            cacheSize: cacheSize
        )
        
        // Assert
        XCTAssertEqual(result.severity, .medium)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertTrue(result.aiRecommendation?.contains("写真枚数が制限(10枚)を超えています") == true)
    }
    
    func testPhotoMemoryAnalyzer_LargeCacheSize() {
        // Arrange
        let currentMemoryUsage: Int64 = 100 * 1024 * 1024
        let photoCount = 5
        let cacheSize: Int64 = 60 * 1024 * 1024 // 60MB
        
        // Act
        let result = PhotoMemoryAnalyzer.analyze(
            currentMemoryUsage: currentMemoryUsage,
            photoCount: photoCount,
            cacheSize: cacheSize
        )
        
        // Assert
        XCTAssertEqual(result.severity, .medium)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertTrue(result.aiRecommendation?.contains("キャッシュサイズが大きくなっています") == true)
    }

    // MARK: - WalkStateValidator Tests
    
    func testWalkStateValidator_ValidTransitions() {
        // Test valid transitions
        let validTransitions = [
            ("notStarted", "inProgress"),
            ("inProgress", "paused"),
            ("paused", "inProgress"),
            ("inProgress", "completed"),
            ("paused", "completed")
        ]
        
        for (from, to) in validTransitions {
            // Act
            let result = WalkStateValidator.validate(
                fromState: from,
                toState: to,
                trigger: "test",
                context: [:]
            )
            
            // Assert
            XCTAssertTrue(result.isValid, "Transition from \(from) to \(to) should be valid")
            XCTAssertEqual(result.severity, .low)
            XCTAssertNil(result.anomalyInfo)
            XCTAssertNil(result.aiRecommendation)
        }
    }
    
    func testWalkStateValidator_InvalidTransition() {
        // Arrange
        let fromState = "completed"
        let toState = "inProgress"
        let trigger = "restart"
        
        // Act
        let result = WalkStateValidator.validate(
            fromState: fromState,
            toState: toState,
            trigger: trigger,
            context: [:]
        )
        
        // Assert
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.severity, .high)
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertTrue(result.aiRecommendation?.contains("不正な状態遷移") == true)
    }

    // MARK: - WalkStateTransitionAnalyzer Tests
    
    func testWalkStateTransitionAnalyzer_ValidTransition() {
        // Arrange
        let walkId = "test-walk-id"
        let from = WalkState.notStarted
        let to = WalkState.inProgress
        let trigger = "start"
        let isValid = true
        
        // Act
        let result = WalkStateTransitionAnalyzer.analyze(
            walkId: walkId,
            from: from,
            to: to,
            trigger: trigger,
            isValid: isValid
        )
        
        // Assert
        XCTAssertNil(result.anomalyInfo)
        XCTAssertEqual(result.healthScore, "良好")
    }
    
    func testWalkStateTransitionAnalyzer_InvalidTransition() {
        // Arrange
        let walkId = "test-walk-id"
        let from = WalkState.completed
        let to = WalkState.inProgress
        let trigger = "invalid"
        let isValid = false
        
        // Act
        let result = WalkStateTransitionAnalyzer.analyze(
            walkId: walkId,
            from: from,
            to: to,
            trigger: trigger,
            isValid: isValid
        )
        
        // Assert
        XCTAssertNotNil(result.anomalyInfo)
        XCTAssertEqual(result.healthScore, "危険")
        XCTAssertEqual(result.anomalyInfo?.severity, .high)
    }

    // MARK: - MemoryPressure Tests
    
    func testMemoryPressure_LowUsage() {
        // Arrange
        let usage: Int64 = 100 * 1024 * 1024 // 100MB
        
        // Act
        let memoryPressure = MemoryPressure(usage: usage)
        
        // Assert
        XCTAssertEqual(memoryPressure.level, "低")
        XCTAssertEqual(memoryPressure.usage, usage)
    }
    
    func testMemoryPressure_MediumUsage() {
        // Arrange
        let usage: Int64 = 300 * 1024 * 1024 // 300MB
        
        // Act
        let memoryPressure = MemoryPressure(usage: usage)
        
        // Assert
        XCTAssertEqual(memoryPressure.level, "中")
        XCTAssertEqual(memoryPressure.usage, usage)
    }
    
    func testMemoryPressure_HighUsage() {
        // Arrange
        let usage: Int64 = 600 * 1024 * 1024 // 600MB
        
        // Act
        let memoryPressure = MemoryPressure(usage: usage)
        
        // Assert
        XCTAssertEqual(memoryPressure.level, "高")
        XCTAssertEqual(memoryPressure.usage, usage)
    }
}
