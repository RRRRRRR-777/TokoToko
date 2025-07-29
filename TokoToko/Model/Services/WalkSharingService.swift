//
//  WalkSharingService.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/07/25.
//

import SwiftUI
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

// MARK: - SwiftUI Integration

/// SwiftUIで共有機能を使用するためのViewModifier
struct ShareWalkModifier: ViewModifier {
    let walk: Walk
    @Binding var isPresented: Bool
    @State private var isSharing = false
    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        ShareWalkSheet(
                            walk: walk,
                            isPresented: $isPresented,
                            isSharing: $isSharing,
                            errorMessage: $errorMessage
                        )
                    }
                }
            )
    }
}

/// 共有シート用のSwiftUIビュー
private struct ShareWalkSheet: View {
    let walk: Walk
    @Binding var isPresented: Bool
    @Binding var isSharing: Bool
    @Binding var errorMessage: String?

    @State private var loadingMessage = "共有用画像を生成中..."

    var body: some View {
        ZStack {
            backgroundOverlay
            loadingView
            errorView
        }
        .onAppear {
            if shouldStartSharing {
                startSharing()
            }
        }
        .opacity(shouldShowOverlay ? 1 : 0)
    }

    // MARK: - View Components

    private var backgroundOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
    }

@ViewBuilder
    private var loadingView: some View {
        if isSharing {
            LoadingCard(message: loadingMessage)
        }
    }

@ViewBuilder
    private var errorView: some View {
        if let errorMessage = errorMessage {
            ErrorCard(
                message: errorMessage,
                onCancel: { isPresented = false },
                onRetry: { retrySharing() }
            )
        }
    }

    // MARK: - Helper Properties

    private var shouldStartSharing: Bool {
        !isSharing && errorMessage == nil
    }

    private var shouldShowOverlay: Bool {
        isSharing || errorMessage != nil
    }

    // MARK: - Helper Methods

    private func retrySharing() {
        self.errorMessage = nil
        loadingMessage = "共有用画像を生成中..."
        startSharing()
    }

    private func startSharing() {
        let sharingManager = SharingProcessManager(
            walk: walk,
            onProgressUpdate: updateLoadingMessage,
            onError: handleError,
            onCompletion: handleCompletion,
            onShareSheetPresented: handleShareSheetPresented
        )

        isSharing = true
        sharingManager.startSharing()
    }

    private func updateLoadingMessage(_ message: String) {
        Task { @MainActor in
            loadingMessage = message
        }
    }

    private func handleError(_ error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            isSharing = false
        }
    }

    private func handleShareSheetPresented() {
        Task { @MainActor in
            isSharing = false
        }
    }

    private func handleCompletion() {
        Task { @MainActor in
            isPresented = false
            isSharing = false
        }
    }
}

// MARK: - Supporting Views

private struct LoadingCard: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle())

            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 32)
    }
}

private struct ErrorCard: View {
    let message: String
    let onCancel: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("共有に失敗しました")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("キャンセル", action: onCancel)
                    .buttonStyle(.bordered)

                Button("再試行", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - Sharing Process Manager

private class SharingProcessManager {
    private let walk: Walk
    private let onProgressUpdate: (String) -> Void
    private let onError: (Error) -> Void
    private let onCompletion: () -> Void
    private let onShareSheetPresented: () -> Void

    init(
        walk: Walk,
        onProgressUpdate: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void,
        onCompletion: @escaping () -> Void,
        onShareSheetPresented: @escaping () -> Void = {}
    ) {
        self.walk = walk
        self.onProgressUpdate = onProgressUpdate
        self.onError = onError
        self.onCompletion = onCompletion
        self.onShareSheetPresented = onShareSheetPresented
    }

    func startSharing() {
        Task {
            do {
                onProgressUpdate("共有画面を準備中...")
                let image = try await generateImage()
                try await saveToDatabase(image: image)
                let shareText = generateShareText()
                try await presentShareSheet(image: image, text: shareText)
            } catch {
                print("❌ 共有処理でエラー発生: \(error.localizedDescription)")
                onError(error)
            }
        }
    }

    private func generateImage() async throws -> UIImage {
        try await WalkImageGenerator.shared.generateWalkImage(from: walk)
    }

    private func saveToDatabase(image: UIImage) async throws {
        try await WalkSharingService.shared.saveImageToDatabase(image, for: walk)
    }

    private func generateShareText() -> String {
        WalkSharingService.shared.generateShareText(from: walk)
    }

    private func presentShareSheet(image: UIImage, text: String) async throws {
        await MainActor.run {
            guard let viewController = findTopViewController() else {
                onError(WalkSharingService.WalkSharingError.noViewControllerPresent)
                return
            }

            let activityViewController = createActivityViewController(
                image: image,
                text: text,
                sourceView: viewController.view
            )

            setupCompletionHandler(for: activityViewController)

            viewController.present(activityViewController, animated: true) {
                print("✅ UIActivityViewController表示完了")
                self.onShareSheetPresented()
            }
        }
    }

    private func findTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Error: WindowSceneまたはRootViewControllerの取得に失敗")
            return nil
        }

        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        print("✅ TopViewController取得成功: \(type(of: topViewController))")
        return topViewController
    }

    private func createActivityViewController(
        image: UIImage,
        text: String,
        sourceView: UIView
    ) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: [image, text],
            applicationActivities: nil
        )

        configurePopoverForIPad(activityViewController, sourceView: sourceView)
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]

        return activityViewController
    }

    /// 完了ハンドラーを設定します
    private func setupCompletionHandler(for activityViewController: UIActivityViewController) {
        activityViewController.completionWithItemsHandler = { [weak self] _, _, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 共有エラー: \(error.localizedDescription)")
                } else {
                    print("✅ 共有処理完了")
                }
                self?.onCompletion()
            }
        }
    }

    /// iPad対応のポップオーバー設定
    private func configurePopoverForIPad(_ activityViewController: UIActivityViewController, sourceView: UIView) {
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
}

extension View {
    /// 散歩共有機能を追加するViewModifier
    ///
    /// - Parameters:
    ///   - walk: 共有する散歩データ
    ///   - isPresented: 共有シートの表示状態
    /// - Returns: 共有機能が追加されたView
    func shareWalk(_ walk: Walk, isPresented: Binding<Bool>) -> some View {
        modifier(ShareWalkModifier(walk: walk, isPresented: isPresented))
    }
}
