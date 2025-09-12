//
//  EnhancedVibeLogger.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/06/03.
//

// MARK: - EnhancedVibeLogger Import Header

/// EnhancedVibeLoggerのメインインポートヘッダーファイル
///
/// このファイルは分割されたEnhancedVibeLoggerの各モジュールを統合し、
/// 単一のインポートポイントとして機能します。
///
/// ## 分割構造
/// - ``EnhancedVibeLoggerCore``: 基本ログ機能とコア実装
/// - ``EnhancedVibeLoggerBatch``: バッチ処理と出力管理
/// - ``EnhancedVibeLoggerPerformance``: パフォーマンス計測機能
/// - ``EnhancedVibeLoggerSpecialized``: TekuToko特殊化ログ機能
///
/// ## 使用方法
/// ```swift
/// let logger = EnhancedVibeLogger.shared
/// logger.info(operation: "example", message: "テストメッセージ")
/// ```
///
/// ## 詳細な機能ドキュメント
/// 各拡張機能の詳細については、対応する分割ファイルのドキュメントを参照してください。

// このファイルは分割されたEnhancedVibeLoggerモジュールの統合ポイントとして機能します
// 実際の実装は以下のファイルに分割されています：
// - EnhancedVibeLoggerCore.swift
// - EnhancedVibeLoggerBatch.swift
// - EnhancedVibeLoggerPerformance.swift
// - EnhancedVibeLoggerSpecialized.swift
