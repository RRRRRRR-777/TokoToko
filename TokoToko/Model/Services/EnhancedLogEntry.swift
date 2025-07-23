import Foundation

// MARK: - Enhanced Log Entry Structure

/// 拡張ログエントリの構造体
///
/// `EnhancedVibeLogEntry`はTokoTokoアプリケーション専用に設計された
/// 包括的なログエントリ構造体です。基本的なログ情報に加えて、
/// AI協働、パフォーマンス分析、バグ排除のための詳細情報を含みます。
///
/// ## Overview
///
/// - **基本ログ情報**: タイムスタンプ、レベル、メッセージ、コンテキスト
/// - **AI協働フィールド**: ソース情報、スタックトレース、人間・AIのメモ
/// - **バグ排除フィールド**: パフォーマンス、エラー連鎖、状態遷移、異常検出
/// - **環境情報**: 実行環境の詳細情報とコンテキスト
///
/// ## Topics
///
/// ### Basic Information
/// - ``timestamp``
/// - ``level``
/// - ``correlationId``
/// - ``operation``
/// - ``message``
/// - ``context``
/// - ``environment``
///
/// ### AI Collaboration Fields
/// - ``source``
/// - ``stackTrace``
/// - ``humanNote``
/// - ``aiTodo``
///
/// ### Bug Prevention Fields
/// - ``performanceMetrics``
/// - ``errorChain``
/// - ``stateTransition``
/// - ``bugReproduction``
/// - ``anomalyDetection``
public struct EnhancedVibeLogEntry: Codable {
  // MARK: - 基本ログ情報
  
  /// ログエントリのタイムスタンプ（ISO8601形式）
  let timestamp: String
  
  /// ログレベル（debug, info, warning, error, critical）
  let level: LogLevel
  
  /// ログエントリの相関ID（UUIDベース）
  ///
  /// 関連するログエントリを追跡するためのユニークな識別子です。
  let correlationId: String
  
  /// ログエントリの操作名または機能名
  let operation: String
  
  /// ログメッセージの内容
  let message: String
  
  /// 追加のコンテキスト情報
  ///
  /// ログに関連する付加情報をキー・バリュー形式で保存します。
  let context: [String: String]
  
  /// 実行環境の情報
  ///
  /// アプリケーション実行時の環境詳細をキー・バリュー形式で保存します。
  let environment: [String: String]

  // MARK: - AI協働フィールド
  
  /// ログ発生元のソース情報
  ///
  /// ファイル名、関数名、行番号等のソースコード位置情報です。
  let source: SourceInfo?
  
  /// 実行時のスタックトレース情報
  ///
  /// エラー発生時やデバッグ時のコールスタック情報を保存します。
  let stackTrace: String?
  
  /// 人間（開発者）からのメモやコメント
  ///
  /// 開発者が後で参照するためのメモや分析コメントです。
  let humanNote: String?
  
  /// AI用のTodoやタスク情報
  ///
  /// AIエージェントが処理すべきタスクやアクションアイテムです。
  let aiTodo: String?

  // MARK: - バグ排除強化フィールド
  
  /// パフォーマンス関連のメトリクス情報
  ///
  /// 実行時間、メモリ使用量、スレッド情報等のパフォーマンス指標です。
  let performanceMetrics: PerformanceMetrics?
  
  /// エラーの連鎖情報
  ///
  /// エラーの原因となった他のエラーや関連するエラー情報です。
  let errorChain: ErrorChain?
  
  /// 状態遷移の情報
  ///
  /// アプリケーション状態の変化やデータの状態遷移情報です。
  let stateTransition: StateTransition?
  
  /// バグ再現に必要な情報
  ///
  /// バグの再現手順や再現に必要な条件・データです。
  let bugReproduction: BugReproductionInfo?
  
  /// 異常検出関連の情報
  ///
  /// システムの異常や予期しない動作の検出結果です。
  let anomalyDetection: AnomalyInfo?

  init(
    level: LogLevel,
    correlationId: String = UUID().uuidString,
    operation: String,
    message: String,
    context: [String: String] = [:],
    environment: [String: String] = [:],
    source: SourceInfo? = nil,
    stackTrace: String? = nil,
    humanNote: String? = nil,
    aiTodo: String? = nil,
    performanceMetrics: PerformanceMetrics? = nil,
    errorChain: ErrorChain? = nil,
    stateTransition: StateTransition? = nil,
    bugReproduction: BugReproductionInfo? = nil,
    anomalyDetection: AnomalyInfo? = nil
  ) {
    self.timestamp = ISO8601DateFormatter().string(from: Date())
    self.level = level
    self.correlationId = correlationId
    self.operation = operation
    self.message = message
    self.context = context
    self.environment = environment
    self.source = source
    self.stackTrace = stackTrace
    self.humanNote = humanNote
    self.aiTodo = aiTodo
    self.performanceMetrics = performanceMetrics
    self.errorChain = errorChain
    self.stateTransition = stateTransition
    self.bugReproduction = bugReproduction
    self.anomalyDetection = anomalyDetection
  }
}

// MARK: - Backward Compatibility
public typealias BasicVibeLogEntry = EnhancedVibeLogEntry