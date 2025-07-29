//
//  WalkSharingView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/07/25.
//

import SwiftUI

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