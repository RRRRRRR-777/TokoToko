//
//  FirebaseStorageConfig.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/28.
//

import Foundation

/// Firebase Storage操作の設定値を管理するクラス
struct FirebaseStorageConfig {

    // MARK: - リトライ設定

    /// URL取得処理の最大リトライ回数
    static let maxRetryCount: Int = 3

    /// リトライ間隔の基準値（秒）
    static let baseRetryDelay: Double = 1.0

    /// リトライ間隔の計算方法: baseRetryDelay * (試行回数)
    static func retryDelay(for attempt: Int) -> Double {
        baseRetryDelay * Double(attempt)
    }

    // MARK: - ファイル制限

    /// サムネイル画像の最大ファイルサイズ（バイト）
    static let thumbnailMaxFileSize: Int = 5 * 1024 * 1024  // 5MB

    /// 共有画像の最大ファイルサイズ（バイト）
    static let sharedImageMaxFileSize: Int = 5 * 1024 * 1024  // 5MB

    /// プロフィール画像の最大ファイルサイズ（バイト）
    static let profileImageMaxFileSize: Int = 2 * 1024 * 1024  // 2MB

    /// 散歩写真の最大ファイルサイズ（バイト）
    static let walkPhotoMaxFileSize: Int = 10 * 1024 * 1024  // 10MB

    // MARK: - 画像品質設定

    /// JPEG圧縮品質（0.0-1.0）
    static let jpegCompressionQuality: CGFloat = 0.8

    // MARK: - パス構造

    /// サムネイル画像のStorage パス
    static func thumbnailPath(userId: String, walkId: String) -> String {
        "walk_thumbnails/\(userId)/\(walkId).jpg"
    }

    /// 共有画像のStorage パス
    static func sharedImagePath(userId: String, walkId: String) -> String {
        "shared_images/\(userId)/\(walkId)/share_image.jpg"
    }

    /// プロフィール画像のStorage パス
    static func profileImagePath(userId: String) -> String {
        "profile_images/\(userId)/profile.jpg"
    }

    /// 散歩写真のStorage パス
    static func walkPhotoPath(userId: String, walkId: String, photoId: String) -> String {
        "walk_photos/\(userId)/\(walkId)/\(photoId).jpg"
    }

    // MARK: - エラーコード

    /// 権限エラーのHTTPステータスコード
    static let permissionDeniedErrorCode: Int = 403

    /// Storage エラードメイン
    static let storageErrorDomain: String = "FIRStorageErrorDomain"

    /// HTTP ステータスエラードメイン
    static let httpStatusErrorDomain: String = "HTTPStatus"

    // MARK: - ヘルパーメソッド

    /// エラーが権限エラーかどうかを判定
    ///
    /// - Parameter error: 判定対象のエラー
    /// - Returns: 権限エラーの場合はtrue
    static func isPermissionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.code == permissionDeniedErrorCode ||
               nsError.domain.contains(httpStatusErrorDomain)
    }

    /// メタデータの共通項目を生成
    ///
    /// - Parameters:
    ///   - walkId: 散歩ID
    ///   - userId: ユーザーID
    /// - Returns: Firebase Storage メタデータの辞書
    static func commonMetadata(walkId: String, userId: String) -> [String: String] {
        [
            "walkId": walkId,
            "userId": userId,
            "uploadTime": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
    }
}
