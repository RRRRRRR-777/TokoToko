//
//  WalkSharingService.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/07/25.
//

import UIKit

/// 散歩記録の共有機能を提供するサービスクラス
///
/// `WalkSharingService`は散歩データから生成された画像を様々なプラットフォームで共有する機能を提供します。
/// UIActivityViewControllerを利用してシステム標準の共有シートを表示し、
/// SNS、メッセージアプリ、メール、写真アプリなどへの共有をサポートします。
///
/// ## Overview
///
/// - **対応プラットフォーム**: Instagram, Twitter, LINE, Facebook, メール, メッセージ, 写真アプリ等
/// - **共有形式**: 画像 + テキストメッセージ
/// - **カスタマイズ**: アプリ固有の共有テキスト生成
///
/// ## Topics
///
/// ### 共有機能
/// - ``shareWalk(_:presentingViewController:)``
/// - ``generateShareText(from:)``
/// - ``showShareSheet(image:text:presentingViewController:)``
///
/// ### エラーハンドリング
/// - ``WalkSharingError``
class WalkSharingService {

    /// 共有機能で発生する可能性があるエラー
    enum WalkSharingError: LocalizedError {
        case imageGenerationFailed
        case noViewControllerPresent
        case sharingNotAvailable

        var errorDescription: String? {
            switch self {
            case .imageGenerationFailed:
                return "共有用画像の生成に失敗しました"
            case .noViewControllerPresent:
                return "共有シートを表示するビューが見つかりません"
            case .sharingNotAvailable:
                return "この端末では共有機能を使用できません"
            }
        }
    }

    static let shared = WalkSharingService()

    let imageGenerator = WalkImageGenerator.shared
    private let walkRepository = WalkRepository.shared

    private init() {}

    /// 散歩データを共有します
    ///
    /// - Parameters:
    ///   - walk: 共有する散歩データ
    ///   - presentingViewController: 共有シートを表示するViewController
    /// - Throws: WalkSharingError
    func shareWalk(_ walk: Walk, presentingViewController: UIViewController?) async throws {
        let image = try await generateImageForSharing(from: walk)
        try await persistSharedImage(image, for: walk)
        let shareText = generateShareText(from: walk)
        try await presentShareSheet(image: image, text: shareText, presentingViewController: presentingViewController)
    }

    /// 散歩データから共有用テキストを生成します
    ///
    /// - Parameter walk: テキスト生成対象の散歩データ
    /// - Returns: 生成された共有テキスト
    func generateShareText(from walk: Walk) -> String {
        let components = ShareTextComponents(
            appName: "とことこ-お散歩SNS",
            title: walk.title,
            distance: walk.distanceString,
            duration: walk.durationString,
            steps: walk.totalSteps
        )

        return buildShareText(from: components)
    }

    /// 共有画像をデータベースに保存します
    ///
    /// - Parameters:
    ///   - image: 保存する画像
    ///   - walk: 関連する散歩データ
    /// - Throws: WalkSharingError
    func saveImageToDatabase(_ image: UIImage, for walk: Walk) async throws {
        try await persistSharedImage(image, for: walk)
    }

    /// 共有シートを表示します
    ///
    /// - Parameters:
    ///   - image: 共有する画像
    ///   - text: 共有するテキスト
    ///   - presentingViewController: 共有シートを表示するViewController
    /// - Throws: WalkSharingError
    private func showShareSheet(
        image: UIImage,
        text: String,
        presentingViewController: UIViewController?
    ) async throws {
        try await presentShareSheet(image: image, text: text, presentingViewController: presentingViewController)
    }

    // MARK: - Private Helper Methods

    /// 画像生成を行います
    private func generateImageForSharing(from walk: Walk) async throws -> UIImage {
        try await imageGenerator.generateWalkImage(from: walk)
    }

    /// 共有画像をデータベースに保存します
    private func persistSharedImage(_ image: UIImage, for walk: Walk) async throws {
        try await withCheckedThrowingContinuation { continuation in
            walkRepository.saveSharedImage(image, for: walk) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure:
                    continuation.resume(throwing: WalkSharingError.imageGenerationFailed)
                }
            }
        }
    }

    /// 共有シートを表示します
    private func presentShareSheet(
        image: UIImage,
        text: String,
        presentingViewController: UIViewController?
    ) async throws {
        guard let presentingViewController = presentingViewController else {
            throw WalkSharingError.noViewControllerPresent
        }

        await MainActor.run {
            let activityViewController = createActivityViewController(image: image, text: text)
            configurePopoverPresentation(for: activityViewController, sourceView: presentingViewController.view)
            presentingViewController.present(activityViewController, animated: true)
        }
    }

    /// UIActivityViewControllerを作成します
    private func createActivityViewController(image: UIImage, text: String) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: [image, text],
            applicationActivities: nil
        )

        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]

        return activityViewController
    }

    /// ポップオーバー表示を設定します（iPad対応）
    private func configurePopoverPresentation(for activityViewController: UIActivityViewController, sourceView: UIView) {
        guard let popover = activityViewController.popoverPresentationController else {
            return
        }

        popover.sourceView = sourceView
        popover.sourceRect = CGRect(
            x: sourceView.bounds.midX,
            y: sourceView.bounds.midY,
            width: 0,
            height: 0
        )
        popover.permittedArrowDirections = []
    }

    /// 共有テキストを構築します
    private func buildShareText(from components: ShareTextComponents) -> String {
        """
        \(components.title)を完了しました！

        📍 距離: \(components.distance)
        ⏱️ 時間: \(components.duration)
        👣 歩数: \(components.steps)歩

        #\(components.appName) #散歩 #ウォーキング #健康
        """
    }
}

// MARK: - Share Text Components

/// 共有テキスト生成に必要な構成要素
private struct ShareTextComponents {
    let appName: String
    let title: String
    let distance: String
    let duration: String
    let steps: Int
}
