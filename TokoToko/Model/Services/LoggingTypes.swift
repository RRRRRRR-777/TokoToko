import Foundation
import UIKit

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

// MARK: - Date Extensions

extension Date {
  var iso8601: String {
    return ISO8601DateFormatter().string(from: self)
  }
}
