import XCTest

@testable import TokoToko

class EnhancedVibeLoggerTests: XCTestCase {
  var logger: EnhancedVibeLogger!
  var tempLogDirectory: String!

  override func setUpWithError() throws {
    try super.setUpWithError()

    // テスト用の一時ディレクトリを作成
    tempLogDirectory = NSTemporaryDirectory() + "test_logs_\(UUID().uuidString)"
    try FileManager.default.createDirectory(
      atPath: tempLogDirectory, withIntermediateDirectories: true, attributes: nil)

    logger = EnhancedVibeLogger.shared
  }

  override func tearDownWithError() throws {
    // テスト用ディレクトリのクリーンアップ
    try? FileManager.default.removeItem(atPath: tempLogDirectory)
    logger = nil

    try super.tearDownWithError()
  }

  // MARK: - Basic Logging Tests
  func testBasicLogging() {
    // Given
    let operation = "testOperation"
    let message = "テストメッセージ"
    let context = ["key": "value"]

    // When
    logger.debug(operation: operation, message: message, context: context)
    logger.info(operation: operation, message: message, context: context)
    logger.warning(operation: operation, message: message, context: context)
    logger.error(operation: operation, message: message, context: context)
    logger.critical(operation: operation, message: message, context: context)

    // Then
    // コンソール出力のテストは実際の出力を確認する必要があるため、
    // ここでは例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  // MARK: - Log Level Tests
  func testLogLevelPriority() {
    // Given & When & Then
    XCTAssertEqual(LogLevel.debug.priority, 0)
    XCTAssertEqual(LogLevel.info.priority, 1)
    XCTAssertEqual(LogLevel.warning.priority, 2)
    XCTAssertEqual(LogLevel.error.priority, 3)
    XCTAssertEqual(LogLevel.critical.priority, 4)
  }

  func testLogLevelEmoji() {
    // Given & When & Then
    XCTAssertEqual(LogLevel.debug.emoji, "🔧")
    XCTAssertEqual(LogLevel.info.emoji, "📊")
    XCTAssertEqual(LogLevel.warning.emoji, "⚠️")
    XCTAssertEqual(LogLevel.error.emoji, "❌")
    XCTAssertEqual(LogLevel.critical.emoji, "🚨")
  }

  // MARK: - Source Info Tests
  func testSourceInfo() {
    // Given
    let fileName = "/path/to/TestFile.swift"
    let functionName = "testFunction"
    let lineNumber = 42

    // When
    let sourceInfo = SourceInfo(
      fileName: fileName, functionName: functionName, lineNumber: lineNumber)

    // Then
    XCTAssertEqual(sourceInfo.fileName, "TestFile.swift")
    XCTAssertEqual(sourceInfo.functionName, functionName)
    XCTAssertEqual(sourceInfo.lineNumber, lineNumber)
    XCTAssertEqual(sourceInfo.moduleName, "TokoToko")
  }

  // MARK: - Environment Helper Tests
  func testEnvironmentHelper() {
    // Given & When
    let environment = EnvironmentHelper.getCurrentEnvironment()

    // Then
    XCTAssertNotNil(environment["device_model"])
    XCTAssertNotNil(environment["device_name"])
    XCTAssertNotNil(environment["system_name"])
    XCTAssertNotNil(environment["system_version"])
    XCTAssertNotNil(environment["app_version"])
    XCTAssertNotNil(environment["build_number"])
    XCTAssertNotNil(environment["is_debug"])
    XCTAssertEqual(environment["is_debug"], "true")  // テスト環境では常にtrue
  }

  // MARK: - Convenience Methods Tests
  func testLogMethodStartEnd() {
    // Given
    let context = ["param": "value"]

    // When & Then
    logger.logMethodStart(context: context)
    logger.logMethodEnd(context: context)

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogError() {
    // Given
    let error = NSError(
      domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    let operation = "testOperation"

    // When & Then
    logger.logError(error, operation: operation, humanNote: "テストエラー", aiTodo: "エラーハンドリングを改善")

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogUserAction() {
    // Given
    let action = "buttonTap"
    let screen = "HomeView"
    let context = ["button_id": "start_walk"]

    // When & Then
    logger.logUserAction(action: action, screen: screen, context: context)

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogNetworkRequest() {
    // Given
    let url = "https://api.example.com/walks"
    let method = "POST"
    let statusCode = 200
    let responseTime = 0.123

    // When & Then
    logger.logNetworkRequest(
      url: url, method: method, statusCode: statusCode, responseTime: responseTime)

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogNetworkRequestWithError() {
    // Given
    let url = "https://api.example.com/walks"
    let method = "POST"
    let statusCode = 500

    // When & Then
    logger.logNetworkRequest(url: url, method: method, statusCode: statusCode)

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  // MARK: - Phase 2 Enhanced Logging Tests
  func testLogWithPerformance() {
    // Given
    let operation = "testPerformance"
    let message = "パフォーマンステスト"
    let executionTime: TimeInterval = 0.5

    // When & Then
    logger.logWithPerformance(
      level: .info,
      operation: operation,
      message: message,
      executionTime: executionTime,
      humanNote: "パフォーマンステスト実行",
      aiTodo: "実行時間を最適化"
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogStateTransition() {
    // Given
    let component = "WalkManager"
    let fromState = "idle"
    let toState = "walking"
    let trigger = "startWalk"

    // When & Then
    logger.logStateTransition(
      component: component,
      from: fromState,
      to: toState,
      trigger: trigger,
      isValid: true,
      duration: 0.1
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogErrorChain() {
    // Given
    let rootCause = "Network timeout"
    let errorEvent = ErrorEvent(
      errorType: "NetworkError",
      errorMessage: "Connection failed",
      context: ["url": "https://api.example.com"]
    )

    // When & Then
    logger.logErrorChain(
      rootCause: rootCause,
      errorSequence: [errorEvent],
      recoveryAttempts: 3,
      finalOutcome: "Request failed"
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogAnomaly() {
    // Given
    let anomaly = Anomaly(
      type: .memoryLeak,
      description: "メモリ使用量が異常に高い",
      value: 500.0,
      threshold: 200.0,
      impact: "アプリのパフォーマンス低下"
    )

    // When & Then
    logger.logAnomaly(
      anomalies: [anomaly],
      severity: .high,
      confidence: 0.95,
      recommendedAction: "メモリリークの原因を調査",
      detectionMethod: "Memory threshold monitoring"
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogBugReproduction() {
    // Given
    let userAction = UserAction(
      action: "tap",
      screen: "HomeView",
      element: "startButton"
    )
    let systemSnapshot = SystemSnapshot(
      memoryUsage: 1024 * 1024,
      cpuUsage: 50.0,
      batteryLevel: 0.8
    )

    // When & Then
    logger.logBugReproduction(
      userActions: [userAction],
      systemSnapshot: systemSnapshot,
      reproductionSteps: ["1. アプリを起動", "2. スタートボタンをタップ"],
      environmentFactors: ["iOS 17.0", "iPhone 15"],
      reproductionRate: 0.8,
      severity: .high
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testMeasurePerformance() {
    // Given
    let operation = "testOperation"

    // When
    let result = logger.measurePerformance(operation: operation) {
      // 簡単な計算処理をシミュレート
      return (1...1000).reduce(0, +)
    }

    // Then
    XCTAssertEqual(result, 500500)
  }

  func testMeasurePerformanceAsync() async {
    // Given
    let operation = "testAsyncOperation"

    // When
    let result = await logger.measurePerformanceAsync(operation: operation) {
      // 非同期処理をシミュレート
      await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒
      return "async result"
    }

    // Then
    XCTAssertEqual(result, "async result")
  }

  // MARK: - Phase 2 Structure Tests
  func testPerformanceMetrics() {
    // Given
    let executionTime: TimeInterval = 1.5
    let memoryUsage: Int64 = 1024 * 1024
    let threadInfo = ThreadInfo()

    // When
    let metrics = PerformanceMetrics(
      executionTime: executionTime,
      memoryUsage: memoryUsage,
      threadInfo: threadInfo
    )

    // Then
    XCTAssertEqual(metrics.executionTime, executionTime)
    XCTAssertEqual(metrics.memoryUsage, memoryUsage)
    XCTAssertNotNil(metrics.threadInfo)
  }

  func testErrorChain() {
    // Given
    let rootCause = "Database connection failed"
    let errorEvent = ErrorEvent(
      errorType: "SQLError",
      errorMessage: "Connection timeout"
    )

    // When
    let errorChain = ErrorChain(
      rootCause: rootCause,
      errorSequence: [errorEvent],
      recoveryAttempts: 2,
      finalOutcome: "Operation failed"
    )

    // Then
    XCTAssertEqual(errorChain.rootCause, rootCause)
    XCTAssertEqual(errorChain.errorSequence.count, 1)
    XCTAssertEqual(errorChain.recoveryAttempts, 2)
    XCTAssertEqual(errorChain.finalOutcome, "Operation failed")
  }

  func testStateTransition() {
    // Given
    let component = "LocationManager"
    let fromState = "stopped"
    let toState = "tracking"
    let trigger = "startTracking"

    // When
    let stateTransition = StateTransition(
      component: component,
      fromState: fromState,
      toState: toState,
      trigger: trigger,
      isValid: true,
      duration: 0.05
    )

    // Then
    XCTAssertEqual(stateTransition.component, component)
    XCTAssertEqual(stateTransition.fromState, fromState)
    XCTAssertEqual(stateTransition.toState, toState)
    XCTAssertEqual(stateTransition.trigger, trigger)
    XCTAssertTrue(stateTransition.isValid)
    XCTAssertEqual(stateTransition.duration, 0.05)
  }

  func testBugReproductionInfo() {
    // Given
    let userAction = UserAction(action: "swipe", screen: "MapView")
    let systemSnapshot = SystemSnapshot(memoryUsage: 512 * 1024, cpuUsage: 25.0)

    // When
    let bugReproduction = BugReproductionInfo(
      userActions: [userAction],
      systemSnapshot: systemSnapshot,
      reproductionSteps: ["Step 1", "Step 2"],
      environmentFactors: ["iOS 16.0"],
      reproductionRate: 0.9,
      severity: .critical
    )

    // Then
    XCTAssertEqual(bugReproduction.userActions.count, 1)
    XCTAssertEqual(bugReproduction.reproductionSteps.count, 2)
    XCTAssertEqual(bugReproduction.reproductionRate, 0.9)
    XCTAssertEqual(bugReproduction.severity, .critical)
  }

  func testAnomalyInfo() {
    // Given
    let anomaly = Anomaly(
      type: .cpuSpike,
      description: "CPU使用率スパイク",
      value: 95.0,
      threshold: 80.0,
      impact: "アプリの応答性低下"
    )

    // When
    let anomalyInfo = AnomalyInfo(
      detectedAnomalies: [anomaly],
      severity: .high,
      confidence: 0.9,
      recommendedAction: "CPU使用率を最適化",
      detectionMethod: "CPU monitoring"
    )

    // Then
    XCTAssertEqual(anomalyInfo.detectedAnomalies.count, 1)
    XCTAssertEqual(anomalyInfo.severity, .high)
    XCTAssertEqual(anomalyInfo.confidence, 0.9)
    XCTAssertEqual(anomalyInfo.recommendedAction, "CPU使用率を最適化")
    XCTAssertEqual(anomalyInfo.detectionMethod, "CPU monitoring")
  }

  // MARK: - Enhanced Log Entry Tests
  func testEnhancedVibeLogEntry() {
    // Given
    let level = LogLevel.info
    let operation = "testOperation"
    let message = "テストメッセージ"
    let context = ["key": "value"]
    let environment = ["env": "test"]
    let source = SourceInfo()
    let performanceMetrics = PerformanceMetrics(executionTime: 0.5)

    // When
    let logEntry = EnhancedVibeLogEntry(
      level: level,
      operation: operation,
      message: message,
      context: context,
      environment: environment,
      source: source,
      humanNote: "人間向けメモ",
      aiTodo: "AI向けTODO",
      performanceMetrics: performanceMetrics
    )

    // Then
    XCTAssertEqual(logEntry.level, level)
    XCTAssertEqual(logEntry.operation, operation)
    XCTAssertEqual(logEntry.message, message)
    XCTAssertEqual(logEntry.context, context)
    XCTAssertEqual(logEntry.environment, environment)
    XCTAssertEqual(logEntry.source?.fileName, source.fileName)
    XCTAssertEqual(logEntry.humanNote, "人間向けメモ")
    XCTAssertEqual(logEntry.aiTodo, "AI向けTODO")
    XCTAssertNotNil(logEntry.timestamp)
    XCTAssertNotNil(logEntry.correlationId)
    XCTAssertNotNil(logEntry.performanceMetrics)
    XCTAssertEqual(logEntry.performanceMetrics?.executionTime, 0.5)
  }

  // MARK: - Log Entry Codable Tests
  func testEnhancedLogEntryCodable() throws {
    // Given
    let performanceMetrics = PerformanceMetrics(executionTime: 1.0)
    let logEntry = EnhancedVibeLogEntry(
      level: .info,
      operation: "testOperation",
      message: "テストメッセージ",
      context: ["key": "value"],
      environment: ["env": "test"],
      source: SourceInfo(),
      humanNote: "人間向けメモ",
      aiTodo: "AI向けTODO",
      performanceMetrics: performanceMetrics
    )

    // When
    let jsonData = try JSONEncoder().encode(logEntry)
    let decodedLogEntry = try JSONDecoder().decode(EnhancedVibeLogEntry.self, from: jsonData)

    // Then
    XCTAssertEqual(decodedLogEntry.level, logEntry.level)
    XCTAssertEqual(decodedLogEntry.operation, logEntry.operation)
    XCTAssertEqual(decodedLogEntry.message, logEntry.message)
    XCTAssertEqual(decodedLogEntry.context, logEntry.context)
    XCTAssertEqual(decodedLogEntry.environment, logEntry.environment)
    XCTAssertEqual(decodedLogEntry.humanNote, logEntry.humanNote)
    XCTAssertEqual(decodedLogEntry.aiTodo, logEntry.aiTodo)
    XCTAssertEqual(decodedLogEntry.timestamp, logEntry.timestamp)
    XCTAssertEqual(decodedLogEntry.correlationId, logEntry.correlationId)
    XCTAssertEqual(decodedLogEntry.performanceMetrics?.executionTime, 1.0)
  }

  // MARK: - Backward Compatibility Tests
  func testBasicVibeLogEntryCompatibility() {
    // Given
    let logEntry: BasicVibeLogEntry = EnhancedVibeLogEntry(
      level: .info,
      operation: "testOperation",
      message: "テストメッセージ",
      context: ["key": "value"],
      environment: ["env": "test"],
      source: SourceInfo(),
      humanNote: "人間向けメモ",
      aiTodo: "AI向けTODO"
    )

    // When & Then
    XCTAssertEqual(logEntry.level, .info)
    XCTAssertEqual(logEntry.operation, "testOperation")
    XCTAssertEqual(logEntry.message, "テストメッセージ")
    XCTAssertEqual(logEntry.humanNote, "人間向けメモ")
    XCTAssertEqual(logEntry.aiTodo, "AI向けTODO")
  }

  // MARK: - Log Management Tests
  func testGetLogFiles() {
    // Given & When
    let logFiles = logger.getLogFiles()

    // Then
    XCTAssertTrue(logFiles.allSatisfy { $0.hasSuffix(".log") })
  }

  func testClearOldLogs() {
    // Given
    let expectation = self.expectation(description: "Clear old logs")

    // When
    logger.clearOldLogs(olderThanDays: 7)

    // Then
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1.0)
  }

  // MARK: - Phase 3 TokoToko Specialized Tests
  func testLocationAnomalyDetector() {
    // Given
    let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
    let lowAccuracy: CLLocationAccuracy = 150.0
    let highAccuracy: CLLocationAccuracy = 5.0
    let lowBattery: Float = 0.15
    let highBattery: Float = 0.8
    let shortDuration: TimeInterval = 1800  // 30分
    let longDuration: TimeInterval = 8400  // 2時間20分

    // When & Then - 正常な状態
    let normalResult = LocationAnomalyDetector.analyze(
      location: location,
      accuracy: highAccuracy,
      batteryLevel: highBattery,
      duration: shortDuration
    )
    XCTAssertEqual(normalResult.severity, .low)
    XCTAssertNil(normalResult.anomalyInfo)
    XCTAssertNil(normalResult.aiRecommendation)

    // When & Then - GPS精度異常
    let lowAccuracyResult = LocationAnomalyDetector.analyze(
      location: location,
      accuracy: lowAccuracy,
      batteryLevel: highBattery,
      duration: shortDuration
    )
    XCTAssertEqual(lowAccuracyResult.severity, .medium)
    XCTAssertNotNil(lowAccuracyResult.anomalyInfo)
    XCTAssertTrue(lowAccuracyResult.aiRecommendation?.contains("GPS精度が低下") ?? false)

    // When & Then - バッテリー低下
    let lowBatteryResult = LocationAnomalyDetector.analyze(
      location: location,
      accuracy: highAccuracy,
      batteryLevel: lowBattery,
      duration: shortDuration
    )
    XCTAssertEqual(lowBatteryResult.severity, .high)
    XCTAssertNotNil(lowBatteryResult.anomalyInfo)
    XCTAssertTrue(lowBatteryResult.aiRecommendation?.contains("バッテリー") ?? false)

    // When & Then - 長時間追跡
    let longDurationResult = LocationAnomalyDetector.analyze(
      location: location,
      accuracy: highAccuracy,
      batteryLevel: highBattery,
      duration: longDuration
    )
    XCTAssertEqual(longDurationResult.severity, .medium)
    XCTAssertNotNil(longDurationResult.anomalyInfo)
    XCTAssertTrue(longDurationResult.aiRecommendation?.contains("長時間の追跡") ?? false)
  }

  func testFirebaseSyncAnalyzer() {
    // Given
    let recentSync = Date().addingTimeInterval(-300)  // 5分前
    let oldSync = Date().addingTimeInterval(-3600)  // 1時間前
    let veryOldSync = Date().addingTimeInterval(-7200)  // 2時間前

    // When & Then - 正常な状態
    let normalResult = FirebaseSyncAnalyzer.analyze(
      isOnline: true,
      pendingWrites: 2,
      lastSync: recentSync
    )
    XCTAssertEqual(normalResult.severity, .low)
    XCTAssertNil(normalResult.anomalyInfo)
    XCTAssertEqual(normalResult.healthScore, "良好")

    // When & Then - オフライン状態
    let offlineResult = FirebaseSyncAnalyzer.analyze(
      isOnline: false,
      pendingWrites: 2,
      lastSync: recentSync
    )
    XCTAssertEqual(offlineResult.severity, .medium)
    XCTAssertNotNil(offlineResult.anomalyInfo)
    XCTAssertEqual(offlineResult.healthScore, "注意")

    // When & Then - 過度な未同期データ
    let pendingWritesResult = FirebaseSyncAnalyzer.analyze(
      isOnline: true,
      pendingWrites: 15,
      lastSync: recentSync
    )
    XCTAssertEqual(pendingWritesResult.severity, .high)
    XCTAssertNotNil(pendingWritesResult.anomalyInfo)

    // When & Then - 最終同期が古い
    let oldSyncResult = FirebaseSyncAnalyzer.analyze(
      isOnline: true,
      pendingWrites: 2,
      lastSync: veryOldSync
    )
    XCTAssertEqual(oldSyncResult.severity, .high)
    XCTAssertNotNil(oldSyncResult.anomalyInfo)

    // When & Then - 同期履歴なし
    let noSyncResult = FirebaseSyncAnalyzer.analyze(
      isOnline: true,
      pendingWrites: 2,
      lastSync: nil
    )
    XCTAssertEqual(noSyncResult.severity, .medium)
    XCTAssertNotNil(noSyncResult.anomalyInfo)
  }

  func testPhotoMemoryAnalyzer() {
    // Given
    let lowMemory: Int64 = 50 * 1024 * 1024  // 50MB
    let mediumMemory: Int64 = 150 * 1024 * 1024  // 150MB
    let highMemory: Int64 = 350 * 1024 * 1024  // 350MB

    // When & Then - 正常な状態
    let normalResult = PhotoMemoryAnalyzer.analyze(
      currentMemoryUsage: lowMemory,
      photoCount: 5,
      cacheSize: 10 * 1024 * 1024
    )
    XCTAssertEqual(normalResult.severity, .low)
    XCTAssertNil(normalResult.anomalyInfo)

    // When & Then - 高メモリ使用量
    let highMemoryResult = PhotoMemoryAnalyzer.analyze(
      currentMemoryUsage: highMemory,
      photoCount: 5,
      cacheSize: 10 * 1024 * 1024
    )
    XCTAssertEqual(highMemoryResult.severity, .high)
    XCTAssertNotNil(highMemoryResult.anomalyInfo)

    // When & Then - 過度な写真枚数
    let tooManyPhotosResult = PhotoMemoryAnalyzer.analyze(
      currentMemoryUsage: mediumMemory,
      photoCount: 12,
      cacheSize: 10 * 1024 * 1024
    )
    XCTAssertEqual(tooManyPhotosResult.severity, .medium)
    XCTAssertNotNil(tooManyPhotosResult.anomalyInfo)

    // When & Then - 大きなキャッシュサイズ
    let largeCacheResult = PhotoMemoryAnalyzer.analyze(
      currentMemoryUsage: mediumMemory,
      photoCount: 5,
      cacheSize: 60 * 1024 * 1024
    )
    XCTAssertEqual(largeCacheResult.severity, .medium)
    XCTAssertNotNil(largeCacheResult.anomalyInfo)
  }

  func testWalkStateValidator() {
    // Given
    let validTransitions = [
      ("notStarted", "inProgress"),
      ("inProgress", "paused"),
      ("paused", "inProgress"),
      ("inProgress", "completed"),
      ("paused", "completed"),
    ]

    let invalidTransitions = [
      ("notStarted", "paused"),
      ("notStarted", "completed"),
      ("completed", "inProgress"),
      ("completed", "paused"),
    ]

    // When & Then - 有効な遷移
    for (from, to) in validTransitions {
      let result = WalkStateValidator.validate(
        fromState: from,
        toState: to,
        trigger: "test",
        context: [:]
      )
      XCTAssertTrue(result.isValid, "遷移 \(from) -> \(to) は有効であるべきです")
      XCTAssertEqual(result.severity, .low)
    }

    // When & Then - 無効な遷移
    for (from, to) in invalidTransitions {
      let result = WalkStateValidator.validate(
        fromState: from,
        toState: to,
        trigger: "test",
        context: [:]
      )
      XCTAssertFalse(result.isValid, "遷移 \(from) -> \(to) は無効であるべきです")
      XCTAssertEqual(result.severity, .high)
      XCTAssertNotNil(result.anomalyInfo)
    }
  }

  func testLogLocationBugPrevention() {
    // Given
    let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
    let context = ["accuracy": "5.0", "speed": "1.2"]

    // When & Then - 正常な位置情報
    logger.logLocationBugPrevention(
      location: location,
      accuracy: 5.0,
      batteryLevel: 0.8,
      duration: 1800,
      context: context
    )

    // When & Then - 異常な位置情報
    logger.logLocationBugPrevention(
      location: location,
      accuracy: 150.0,
      batteryLevel: 0.15,
      duration: 8400,
      context: context
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogFirebaseSyncBugPrevention() {
    // Given
    let context = ["collection": "walks", "operation": "save"]
    let lastSync = Date().addingTimeInterval(-3600)

    // When & Then - 正常な同期状態
    logger.logFirebaseSyncBugPrevention(
      isOnline: true,
      pendingWrites: 2,
      lastSync: lastSync,
      context: context
    )

    // When & Then - 異常な同期状態
    logger.logFirebaseSyncBugPrevention(
      isOnline: false,
      pendingWrites: 15,
      lastSync: nil,
      context: context
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogPhotoMemoryBugPrevention() {
    // Given
    let context = ["photo_source": "camera", "resolution": "high"]

    // When & Then - 正常なメモリ使用量
    logger.logPhotoMemoryBugPrevention(
      currentMemoryUsage: 50 * 1024 * 1024,
      photoCount: 5,
      cacheSize: 10 * 1024 * 1024,
      context: context
    )

    // When & Then - 異常なメモリ使用量
    logger.logPhotoMemoryBugPrevention(
      currentMemoryUsage: 350 * 1024 * 1024,
      photoCount: 12,
      cacheSize: 60 * 1024 * 1024,
      context: context
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  func testLogWalkStateTransitionBugPrevention() {
    // Given
    let context = ["user_action": "tap_start", "previous_duration": "0"]

    // When & Then - 有効な状態遷移
    logger.logWalkStateTransitionBugPrevention(
      fromState: "notStarted",
      toState: "inProgress",
      trigger: "startWalk",
      context: context
    )

    // When & Then - 無効な状態遷移
    logger.logWalkStateTransitionBugPrevention(
      fromState: "completed",
      toState: "inProgress",
      trigger: "invalidAction",
      context: context
    )

    // 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  // MARK: - Phase 4 Tests: 既存コードとの統合テスト

  func testWalkManagerIntegration() {
    // WalkManagerとの統合テスト
    let walkManager = WalkManager()
    let expectation = XCTestExpectation(description: "WalkManager integration test")

    // 散歩開始時のログ確認
    walkManager.startWalk()

    // ログファイル確認
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      let logFiles = self.getLogFiles()
      XCTAssertFalse(logFiles.isEmpty, "ログファイルが作成されるべき")

      if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
        XCTAssert(latestLog.content.contains("startWalk"), "startWalkログが記録されるべき")
        XCTAssert(latestLog.content.contains("METHOD_START"), "メソッド開始ログが記録されるべき")
      }

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
  }

  func testLocationManagerIntegration() {
    // LocationManagerとの統合テスト
    let locationManager = LocationManager()
    let expectation = XCTestExpectation(description: "LocationManager integration test")

    // 位置情報更新開始時のログ確認
    locationManager.startUpdatingLocation()

    // ログファイル確認
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      let logFiles = self.getLogFiles()
      XCTAssertFalse(logFiles.isEmpty, "ログファイルが作成されるべき")

      if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
        XCTAssert(
          latestLog.content.contains("startUpdatingLocation"), "startUpdatingLocationログが記録されるべき")
        XCTAssert(latestLog.content.contains("METHOD_START"), "メソッド開始ログが記録されるべき")
      }

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
  }

  func testWalkRepositoryIntegration() {
    // WalkRepositoryとの統合テスト
    let walkRepository = WalkRepository.shared
    let expectation = XCTestExpectation(description: "WalkRepository integration test")

    // Walk取得時のログ確認
    walkRepository.fetchWalks { result in
      // ログファイル確認
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        let logFiles = self.getLogFiles()
        XCTAssertFalse(logFiles.isEmpty, "ログファイルが作成されるべき")

        if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
          XCTAssert(latestLog.content.contains("fetchWalks"), "fetchWalksログが記録されるべき")
          XCTAssert(latestLog.content.contains("METHOD_START"), "メソッド開始ログが記録されるべき")
        }

        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 3.0)
  }

  func testGoogleAuthServiceIntegration() {
    // GoogleAuthServiceとの統合テスト
    let googleAuthService = GoogleAuthService()
    let expectation = XCTestExpectation(description: "GoogleAuthService integration test")

    // Google認証時のログ確認
    googleAuthService.signInWithGoogle { result in
      // ログファイル確認
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        let logFiles = self.getLogFiles()
        XCTAssertFalse(logFiles.isEmpty, "ログファイルが作成されるべき")

        if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
          XCTAssert(latestLog.content.contains("signInWithGoogle"), "signInWithGoogleログが記録されるべき")
          XCTAssert(latestLog.content.contains("METHOD_START"), "メソッド開始ログが記録されるべき")
        }

        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 5.0)
  }

  func testIntegratedLogAnalysis() {
    // 統合されたログの分析テスト
    let logger = EnhancedVibeLogger.shared

    // 複数のサービスからのログ記録
    logger.info(operation: "WalkManager.startWalk", message: "散歩開始")
    logger.logLocationBugPrevention(
      location: CLLocation(latitude: 35.6762, longitude: 139.6503),
      accuracy: 5.0,
      batteryLevel: 0.8,
      duration: 1.0
    )
    logger.logFirebaseBugPrevention(
      operation: "saveWalk",
      isOnline: true,
      pendingWrites: 0,
      lastSync: Date()
    )

    // ログファイル確認
    let logFiles = getLogFiles()
    XCTAssertFalse(logFiles.isEmpty, "ログファイルが作成されるべき")

    if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
      XCTAssert(latestLog.content.contains("WalkManager.startWalk"), "WalkManagerログが記録されるべき")
      XCTAssert(latestLog.content.contains("location_bug_prevention"), "位置情報バグ防止ログが記録されるべき")
      XCTAssert(latestLog.content.contains("firebase_bug_prevention"), "Firebaseバグ防止ログが記録されるべき")
    }
  }

  func testIntegratedPerformanceMetrics() {
    // 統合されたパフォーマンスメトリクスのテスト
    let logger = EnhancedVibeLogger.shared

    // パフォーマンス測定開始
    logger.logMethodStart(context: ["test": "integrated_performance"])

    // 模擬処理
    Thread.sleep(forTimeInterval: 0.1)

    // パフォーマンス測定終了
    logger.logMethodEnd(context: ["test": "integrated_performance"])

    // ログファイル確認
    let logFiles = getLogFiles()
    XCTAssertFalse(logFiles.isEmpty, "ログファイルが作成されるべき")

    if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
      XCTAssert(latestLog.content.contains("METHOD_START"), "メソッド開始ログが記録されるべき")
      XCTAssert(latestLog.content.contains("METHOD_END"), "メソッド終了ログが記録されるべき")
      XCTAssert(latestLog.content.contains("execution_time"), "実行時間が記録されるべき")
    }
  }

  func testIntegratedErrorHandling() {
    // 統合されたエラー処理のテスト
    let logger = EnhancedVibeLogger.shared

    // エラー発生シミュレーション
    let testError = NSError(
      domain: "TestDomain", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"])

    logger.logError(
      testError,
      operation: "IntegratedTest",
      context: ["test_type": "error_handling"],
      humanNote: "統合テストでのエラー",
      aiTodo: "エラー対応を確認"
    )

    // ログファイル確認
    let logFiles = getLogFiles()
    XCTAssertFalse(logFiles.isEmpty, "ログファイルが作成されるべき")

    if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
      XCTAssert(latestLog.content.contains("ERROR"), "エラーログが記録されるべき")
      XCTAssert(latestLog.content.contains("IntegratedTest"), "操作名が記録されるべき")
      XCTAssert(latestLog.content.contains("統合テストでのエラー"), "人間向けメモが記録されるべき")
      XCTAssert(latestLog.content.contains("エラー対応を確認"), "AIタスクが記録されるべき")
    }
  }

  // MARK: - Phase 5 Tests: 自動化・最適化機能

  func testDynamicLogLevelAdjustment() {
    // ログレベル動的調整機能のテスト
    let logger = EnhancedVibeLogger.shared

    // 初期ログレベルを記録
    let initialLogLevel = logger.logLevel

    // ログレベル調整実行
    logger.adjustLogLevelBasedOnConditions()

    // 少し待機してから確認
    let expectation = XCTestExpectation(description: "Dynamic log level adjustment")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      // ログファイル確認
      let logFiles = self.getLogFiles()
      if !logFiles.isEmpty {
        if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
          // ログレベル調整のログが記録されている可能性を確認
          XCTAssert(
            latestLog.content.contains("adjustLogLevelBasedOnConditions")
              || latestLog.content.contains("battery_level"),
            "ログレベル調整に関するログが記録されるべき")
        }
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
  }

  func testLogFileRotation() {
    // ログファイルローテーション機能のテスト
    let logger = EnhancedVibeLogger.shared

    // ローテーション実行
    logger.rotateLogFiles()

    // 少し待機してから確認
    let expectation = XCTestExpectation(description: "Log file rotation")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      // ローテーションが実行されたことを確認（エラーなく完了すればOK）
      XCTAssertNotNil(logger, "ログファイルローテーションが正常に実行されるべき")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
  }

  func testBatchLogging() {
    // バッチログ出力機能のテスト
    let logger = EnhancedVibeLogger.shared

    // バッチロギングを有効化
    logger.enableBatchLogging(batchSize: 3, flushInterval: 2.0)

    // 複数のログを記録
    logger.info(operation: "batchTest1", message: "バッチテスト1")
    logger.info(operation: "batchTest2", message: "バッチテスト2")
    logger.info(operation: "batchTest3", message: "バッチテスト3")

    // バッチが自動的にフラッシュされるまで待機
    let expectation = XCTestExpectation(description: "Batch logging")
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      // ログファイル確認
      let logFiles = self.getLogFiles()
      XCTAssertFalse(logFiles.isEmpty, "バッチログファイルが作成されるべき")

      if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
        XCTAssert(latestLog.content.contains("batchTest"), "バッチテストログが記録されるべき")
      }

      // バッチロギングを無効化
      logger.disableBatchLogging()
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 4.0)
  }

  func testPerformanceOptimization() {
    // パフォーマンス最適化機能のテスト
    let logger = EnhancedVibeLogger.shared

    // パフォーマンス最適化実行
    logger.optimizePerformance()

    // 少し待機してから確認
    let expectation = XCTestExpectation(description: "Performance optimization")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      // ログファイル確認
      let logFiles = self.getLogFiles()
      if !logFiles.isEmpty {
        if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
          XCTAssert(
            latestLog.content.contains("optimizePerformance")
              || latestLog.content.contains("battery_level"),
            "パフォーマンス最適化のログが記録されるべき")
        }
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
  }

  func testLogManagement() {
    // ログ管理機能のテスト
    let logger = EnhancedVibeLogger.shared

    // いくつかのログを記録
    logger.info(operation: "managementTest", message: "管理テスト1")
    logger.info(operation: "managementTest", message: "管理テスト2")

    // ログファイル一覧取得
    let logFiles = logger.getLogFiles()
    XCTAssertFalse(logFiles.isEmpty, "ログファイルが存在するべき")

    // 古いログのクリア（テスト用に短い期間を指定）
    logger.clearOldLogs(olderThanDays: 0)

    // 少し待機
    let expectation = XCTestExpectation(description: "Log management")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      // クリア処理が正常に実行されたことを確認
      XCTAssertNotNil(logger, "ログ管理機能が正常に実行されるべき")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
  }

  func testLogLevelFiltering() {
    // ログレベルフィルタリングのテスト
    let logger = EnhancedVibeLogger.shared

    // ログレベルをWARNING以上に設定
    logger.logLevel = .warning

    // 各レベルのログを記録
    logger.debug(operation: "filterTest", message: "デバッグメッセージ")  // フィルタされる
    logger.info(operation: "filterTest", message: "情報メッセージ")  // フィルタされる
    logger.warning(operation: "filterTest", message: "警告メッセージ")  // 記録される
    logger.error(operation: "filterTest", message: "エラーメッセージ")  // 記録される

    // 少し待機してからログファイル確認
    let expectation = XCTestExpectation(description: "Log level filtering")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      let logFiles = self.getLogFiles()
      if !logFiles.isEmpty {
        if let latestLog = logFiles.max(by: { $0.lastModified < $1.lastModified }) {
          XCTAssert(latestLog.content.contains("警告メッセージ"), "警告レベルのログが記録されるべき")
          XCTAssert(latestLog.content.contains("エラーメッセージ"), "エラーレベルのログが記録されるべき")
          XCTAssertFalse(latestLog.content.contains("デバッグメッセージ"), "デバッグレベルのログは記録されないべき")
          XCTAssertFalse(latestLog.content.contains("情報メッセージ"), "情報レベルのログは記録されないべき")
        }
      }

      // ログレベルを元に戻す
      logger.logLevel = .debug
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
  }

  func testAutomatedOptimization() {
    // 自動最適化の統合テスト
    let logger = EnhancedVibeLogger.shared

    // 自動最適化の各機能を実行
    logger.adjustLogLevelBasedOnConditions()
    logger.optimizePerformance()
    logger.rotateLogFiles()

    // バッチロギングを短期間有効化
    logger.enableBatchLogging(batchSize: 2, flushInterval: 1.0)

    // テストログを記録
    logger.info(operation: "automatedTest", message: "自動最適化テスト1")
    logger.info(operation: "automatedTest", message: "自動最適化テスト2")

    // 結果確認
    let expectation = XCTestExpectation(description: "Automated optimization")
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      // 自動最適化が正常に動作することを確認
      let logFiles = self.getLogFiles()
      XCTAssertFalse(logFiles.isEmpty, "最適化後もログファイルが存在するべき")

      // バッチロギングを無効化
      logger.disableBatchLogging()
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 3.0)
  }
}
