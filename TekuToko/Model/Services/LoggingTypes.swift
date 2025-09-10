import Foundation
import UIKit

// MARK: - Log Level Definition

/// ログレベルの定義と優先度制御
///
/// `LogLevel`は5段階のログレベルを定義し、各レベルに対応する
/// 視覚的な表現（絵文字）と優先度を提供します。
///
/// ## Overview
///
/// - **debug**: 詳細なデバッグ情報（優先度: 0）
/// - **info**: 一般的な情報メッセージ（優先度: 1）  
/// - **warning**: 警告メッセージ（優先度: 2）
/// - **error**: エラー情報（優先度: 3）
/// - **critical**: 重大なエラー（優先度: 4）
///
/// ## Topics
///
/// ### Cases
/// - ``debug``
/// - ``info``
/// - ``warning``
/// - ``error``
/// - ``critical``
///
/// ### Properties
/// - ``emoji``
/// - ``priority``
public enum LogLevel: String, Codable, CaseIterable {
  /// デバッグレベルのログ（最低優先度）
  ///
  /// 詳細なデバッグ情報や開発時の動作確認用ログです。
  case debug = "DEBUG"

  /// 情報レベルのログ
  ///
  /// 一般的な情報メッセージや正常な動作の記録です。
  case info = "INFO"

  /// 警告レベルのログ
  ///
  /// 注意が必要な状況や潜在的な問題の通知です。
  case warning = "WARNING"

  /// エラーレベルのログ
  ///
  /// 処理に失敗したエラー情報や例外の記録です。
  case error = "ERROR"

  /// 重大エラーレベルのログ（最高優先度）
  ///
  /// アプリケーションの継続に重大な影響を与える問題です。
  case critical = "CRITICAL"

  /// ログレベルに対応する絵文字表現
  ///
  /// コンソール出力やUI表示で視覚的な識別を容易にします。
  var emoji: String {
    switch self {
    case .debug:
      return "🔧"
    case .info:
      return "📊"
    case .warning:
      return "⚠️"
    case .error:
      return "❌"
    case .critical:
      return "🚨"
    }
  }

  /// ログレベルの数値優先度
  ///
  /// フィルタリング時の比較に使用される数値です。
  /// 値が大きいほど重要度が高くなります。
  var priority: Int {
    switch self {
    case .debug:
      return 0
    case .info:
      return 1
    case .warning:
      return 2
    case .error:
      return 3
    case .critical:
      return 4
    }
  }
}

// MARK: - Source Information

/// ログ発生元のソースコード情報
///
/// `SourceInfo`はログエントリが生成されたソースコードの位置情報を
/// 保持する構造体です。デバッグ時のトレーサビリティを向上させます。
///
/// ## Overview
///
/// - **位置特定**: ファイル名、関数名、行番号による正確な位置情報
/// - **モジュール識別**: どのモジュールからログが発生したかを記録
/// - **自動取得**: コンパイラマクロによる自動的な位置情報取得
///
/// ## Topics
///
/// ### Properties
/// - ``fileName``
/// - ``functionName``
/// - ``lineNumber``
/// - ``moduleName``
///
/// ### Initialization
/// - ``init(fileName:functionName:lineNumber:moduleName:)``
public struct SourceInfo: Codable {
  /// ソースファイル名（拡張子含む）
  let fileName: String

  /// 関数名またはメソッド名
  let functionName: String

  /// ソースコードの行番号
  let lineNumber: Int

  /// モジュール名
  let moduleName: String

  /// SourceInfoの初期化メソッド
  ///
  /// コンパイラマクロを使用してソースコードの位置情報を自動取得します。
  /// ファイルパスは自動的にファイル名のみに短縮されます。
  ///
  /// - Parameters:
  ///   - fileName: ソースファイルのフルパス（自動取得）
  ///   - functionName: 関数名（自動取得）
  ///   - lineNumber: 行番号（自動取得）
  ///   - moduleName: モジュール名（デフォルト: "TokoToko"）
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

/// 実行環境情報の取得ヘルパー
///
/// `EnvironmentHelper`はアプリケーションの実行環境に関する詳細情報を
/// 収集・整理するユーティリティ構造体です。デバイス情報、システム情報、
/// アプリ情報を統合的に提供します。
///
/// ## Overview
///
/// - **デバイス情報**: モデル、名前、システムバージョン
/// - **アプリ情報**: バージョン、ビルド番号、デバッグビルド判定
/// - **システム状態**: メモリ、バッテリー状態
/// - **プロセス情報**: プロセス名、実行環境
///
/// ## Topics
///
/// ### Methods
/// - ``getCurrentEnvironment()``
public enum EnvironmentHelper {
  /// 現在の実行環境情報を辞書形式で取得
  ///
  /// デバイス、システム、アプリケーション、プロセスに関する包括的な
  /// 環境情報を収集してキー・バリューペアの辞書として返します。
  ///
  /// ## Collected Information
  /// - デバイスモデル、名前、システム名・バージョン
  /// - アプリバージョン、ビルド番号
  /// - プロセス名、物理メモリ情報
  /// - デバッグビルド判定、バッテリー情報
  ///
  /// - Returns: 環境情報のキー・バリュー辞書
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
      "battery_state": batteryStateString(device.batteryState)
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
    case .unknown:
      return "unknown"
    case .unplugged:
      return "unplugged"
    case .charging:
      return "charging"
    case .full:
      return "full"
    @unknown default:
      return "unknown"
    }
  }
}

// MARK: - Date Extensions

/// Date型のISO8601文字列変換拡張
extension Date {
  /// 日付をISO8601形式の文字列に変換
  ///
  /// 標準的なISO8601DateFormatterを使用して、
  /// 日付を国際標準形式の文字列に変換します。
  ///
  /// - Returns: ISO8601形式の日付文字列
  var iso8601: String {
    ISO8601DateFormatter().string(from: self)
  }
}
