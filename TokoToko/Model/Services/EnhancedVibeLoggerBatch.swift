//
//  EnhancedVibeLoggerBatch.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/08/30.
//

import Foundation

// MARK: - Batch Processing Extension

/// EnhancedVibeLoggerのバッチ処理とファイル出力機能拡張
extension EnhancedVibeLogger {

  // MARK: - Output Methods

  /// コンソールへのログ出力
  internal func outputToConsole(_ logEntry: EnhancedVibeLogEntry) {
    let consoleOutput = formatConsoleOutput(logEntry)
    print(consoleOutput)
  }

  /// ファイルへのログ出力
  internal func outputToFile(_ logEntry: EnhancedVibeLogEntry) {
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

  // MARK: - Batch Log Management

  /// バッチモードを開始
  ///
  /// 指定された間隔でログバッファを自動フラッシュするバッチ処理を開始します。
  /// バッチモードでは、ログエントリは即座にファイル出力されず、
  /// バッファに蓄積されて定期的に一括出力されます。
  ///
  /// - Parameter interval: フラッシュ間隔（秒）。デフォルトは30秒
  public func startBatchMode(interval: TimeInterval = 30.0) {
    logQueue.async { [weak self] in
      guard let self = self else { return }

      self.stopBatchMode()

      DispatchQueue.main.async {
        self.batchTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
          self.flushLogBuffer()
        }
      }
    }
  }

  /// バッチモードを停止
  ///
  /// タイマーを無効化し、残りのログバッファを強制的にフラッシュします。
  /// バッチモード終了後は、ログエントリが即座にファイル出力されます。
  public func stopBatchMode() {
    logQueue.async { [weak self] in
      guard let self = self else { return }

      DispatchQueue.main.async {
        self.batchTimer?.invalidate()
        self.batchTimer = nil
      }

      self.flushLogBuffer()
    }
  }

  /// ログバッファのフラッシュ
  ///
  /// バッファに蓄積されたすべてのログエントリをファイルに出力し、
  /// バッファをクリアします。バッチ処理の核となるメソッドです。
  internal func flushLogBuffer() {
    guard !logBuffer.isEmpty else { return }

    let currentBuffer = logBuffer
    logBuffer.removeAll()

    for logEntry in currentBuffer {
      outputToFile(logEntry)
    }
  }

  // MARK: - Formatting Methods

  /// コンソール出力用のフォーマット
  ///
  /// ログエントリを読みやすいコンソール形式に変換します。
  /// 絵文字、タイムスタンプ、コンテキスト情報、ソース情報を含む
  /// 構造化された出力を生成します。
  ///
  /// - Parameter logEntry: フォーマット対象のログエントリ
  /// - Returns: フォーマット済みの文字列
  internal func formatConsoleOutput(_ logEntry: EnhancedVibeLogEntry) -> String {
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
}
