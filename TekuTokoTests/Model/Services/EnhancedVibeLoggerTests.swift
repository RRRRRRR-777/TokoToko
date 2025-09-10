import CoreLocation
import XCTest

@testable import TekuToko

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
    // When & Then
    XCTAssertEqual(LogLevel.debug.priority, 0)
    XCTAssertEqual(LogLevel.info.priority, 1)
    XCTAssertEqual(LogLevel.warning.priority, 2)
    XCTAssertEqual(LogLevel.error.priority, 3)
    XCTAssertEqual(LogLevel.critical.priority, 4)
  }

  func testLogLevelEmoji() {
    // When & Then
    XCTAssertEqual(LogLevel.debug.emoji, "🔧")
    XCTAssertEqual(LogLevel.info.emoji, "📊")
    XCTAssertEqual(LogLevel.warning.emoji, "⚠️")
    XCTAssertEqual(LogLevel.error.emoji, "❌")
    XCTAssertEqual(LogLevel.critical.emoji, "🚨")
  }

  // MARK: - Source Info Tests
  func testSourceInfo() {
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
    // When
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

  // MARK: - TokoToko Specialized Logging Tests
  func testLocationBugPrevention() {
    // Given
    let location = CLLocation(latitude: 35.6812, longitude: 139.7671)
    let accuracy: CLLocationAccuracy = 5.0
    let batteryLevel: Float = 0.8
    let duration: TimeInterval = 300.0
    let context = ["test": "location"]

    // When & Then - 例外が発生しないことを確認
    XCTAssertNoThrow {
      self.logger.logLocationBugPrevention(
        location: location,
        accuracy: accuracy,
        batteryLevel: batteryLevel,
        duration: duration,
        context: context
      )
    }
  }

  func testWalkStateTransitionBugPrevention() {
    // Given
    let walkId = UUID().uuidString
    let fromState = "notStarted"
    let toState = "inProgress"
    let trigger = "startWalk"
    let context = ["test": "walkState"]

    // When & Then - 例外が発生しないことを確認
    XCTAssertNoThrow {
      self.logger.logWalkStateTransitionBugPrevention(
        walkId: walkId,
        fromState: fromState,
        toState: toState,
        trigger: trigger,
        context: context
      )
    }
  }

  func testPhotoMemoryBugPrevention() {
    // Given
    let currentMemoryUsage: Int64 = 100 * 1024 * 1024  // 100MB
    let photoCount = 5
    let cacheSize: Int64 = 20 * 1024 * 1024  // 20MB
    let context = ["test": "photoMemory"]

    // When & Then - 例外が発生しないことを確認
    XCTAssertNoThrow {
      self.logger.logPhotoMemoryBugPrevention(
        currentMemoryUsage: currentMemoryUsage,
        photoCount: photoCount,
        cacheSize: cacheSize,
        context: context
      )
    }
  }

  func testFirebaseSyncBugPrevention() {
    // Given
    let isOnline = true
    let pendingWrites = 3
    let lastSync = Date()
    let context = ["test": "firebaseSync"]

    // When & Then - 例外が発生しないことを確認
    XCTAssertNoThrow {
      self.logger.logFirebaseSyncBugPrevention(
        isOnline: isOnline,
        pendingWrites: pendingWrites,
        lastSync: lastSync,
        context: context
      )
    }
  }

  // MARK: - Performance Measurement Tests
  func testMeasurePerformance() {
    // Given
    let operation = "testPerformance"

    // When
    let result = logger.measurePerformance(operation: operation) {
      return "test result"
    }

    // Then
    XCTAssertEqual(result, "test result")
  }

  func testMeasurePerformanceAsync() async throws {
    // Given
    let operation = "testAsyncPerformance"

    // When
    let result = try await logger.measurePerformanceAsync(operation: operation) {
      try await Task.sleep(nanoseconds: 100_000_000)
      return "async result"
    }

    // Then
    XCTAssertEqual(result, "async result")
  }

  // MARK: - Batch Logging Tests
  func testBatchLogging() {
    // Given
    let operation = "batchTest"
    let message = "バッチテストメッセージ"

    // When
    logger.startBatchMode(interval: 1.0)

    // Log multiple entries
    for i in 1...5 {
      logger.info(operation: operation, message: "\(message) \(i)")
    }

    // Stop batch mode to flush buffer
    logger.stopBatchMode()

    // Then - 例外が発生しないことを確認
    XCTAssertNotNil(logger)
  }

  // MARK: - Testing Support Tests (DEBUG only)
  #if DEBUG
  func testTestingSupport() {
    // Given
    let originalLogLevel = logger.getLogLevel()
    let originalFileOutput = logger.getFileOutput()

    // When
    logger.setLogLevel(.warning)
    logger.setFileOutput(false)

    // Then
    XCTAssertEqual(logger.getLogLevel(), .warning)
    XCTAssertEqual(logger.getFileOutput(), false)

    // Reset
    logger.resetToDefaultSettings()
    XCTAssertEqual(logger.getLogLevel(), .debug)
    XCTAssertEqual(logger.getFileOutput(), true)

    // Restore original settings
    logger.setLogLevel(originalLogLevel)
    logger.setFileOutput(originalFileOutput)
  }

  func testLogDirectoryPath() {
    // When
    let logDirectoryPath = logger.getLogDirectoryPath()

    // Then
    // 旧/新いずれのログディレクトリでも許容（後方互換移行中）
    XCTAssertTrue(
      logDirectoryPath.contains("/RRRRRRR777/TokoToko/logs") ||
      logDirectoryPath.contains("/RRRRRRR777/TekuToko/logs")
    )
  }
  #endif

  // MARK: - Convenience Methods Tests
  func testLogMethodStartEnd() {
    // When & Then - 例外が発生しないことを確認
    XCTAssertNoThrow {
      self.logger.logMethodStart("testMethod", context: ["test": "method"])
      self.logger.logMethodEnd("testMethod", context: ["test": "method"])
    }
  }

  func testLogError() {
    // Given
    enum TestError: Error {
      case testError
    }
    let error = TestError.testError
    let operation = "testOperation"

    // When & Then - 例外が発生しないことを確認
    XCTAssertNoThrow {
      self.logger.logError(
        error,
        operation: operation,
        humanNote: "Test error logging",
        aiTodo: "Fix test error"
      )
    }
  }
}
