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
    
    private let imageGenerator = WalkImageGenerator.shared
    private let walkRepository = WalkRepository.shared
    
    private init() {}
    
    /// 散歩データを共有します
    ///
    /// - Parameters:
    ///   - walk: 共有する散歩データ
    ///   - presentingViewController: 共有シートを表示するViewController
    /// - Throws: WalkSharingError
    func shareWalk(_ walk: Walk, presentingViewController: UIViewController?) async throws {
        // 画像生成
        let image = try await imageGenerator.generateWalkImage(from: walk)
        
        // 共有画像をFirebase Storageに保存
        try await saveImageToDatabase(image, for: walk)
        
        // 共有テキスト生成
        let shareText = generateShareText(from: walk)
        
        // 共有シート表示
        try await showShareSheet(
            image: image,
            text: shareText,
            presentingViewController: presentingViewController
        )
    }
    
    /// 散歩データから共有用テキストを生成します
    ///
    /// - Parameter walk: テキスト生成対象の散歩データ
    /// - Returns: 生成された共有テキスト
    private func generateShareText(from walk: Walk) -> String {
        let appName = "とことこ-お散歩SNS"
        let title = walk.title
        let distance = walk.distanceString
        let duration = walk.durationString
        let steps = walk.totalSteps
        
        let shareText = """
        \(title)を完了しました！
        
        📍 距離: \(distance)
        ⏱️ 時間: \(duration)
        👣 歩数: \(steps)歩
        
        #\(appName) #散歩 #ウォーキング #健康
        """
        
        return shareText
    }
    
    /// 共有画像をデータベースに保存します
    ///
    /// - Parameters:
    ///   - image: 保存する画像
    ///   - walk: 関連する散歩データ
    /// - Throws: WalkSharingError
    private func saveImageToDatabase(_ image: UIImage, for walk: Walk) async throws {
        try await withCheckedThrowingContinuation { continuation in
            walkRepository.saveSharedImage(image, for: walk) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: WalkSharingError.imageGenerationFailed)
                }
            }
        }
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
        guard let presentingViewController = presentingViewController else {
            throw WalkSharingError.noViewControllerPresent
        }
        
        await MainActor.run {
            let activityItems: [Any] = [image, text]
            let activityViewController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
            
            // iPad対応: ポップオーバー表示設定
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = presentingViewController.view
                popover.sourceRect = CGRect(
                    x: presentingViewController.view.bounds.midX,
                    y: presentingViewController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            
            // 特定のアクティビティを除外（必要に応じて調整）
            activityViewController.excludedActivityTypes = [
                .addToReadingList,
                .assignToContact,
                .openInIBooks
            ]
            
            presentingViewController.present(activityViewController, animated: true)
        }
    }
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
            .sheet(isPresented: $isPresented) {
                ShareWalkSheet(
                    walk: walk,
                    isPresented: $isPresented,
                    isSharing: $isSharing,
                    errorMessage: $errorMessage
                )
            }
    }
}

/// 共有シート用のSwiftUIビュー
private struct ShareWalkSheet: UIViewControllerRepresentable {
    let walk: Walk
    @Binding var isPresented: Bool
    @Binding var isSharing: Bool
    @Binding var errorMessage: String?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented && !isSharing {
            isSharing = true
            
            Task {
                do {
                    try await WalkSharingService.shared.shareWalk(
                        walk,
                        presentingViewController: uiViewController
                    )
                    
                    await MainActor.run {
                        isSharing = false
                        isPresented = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isSharing = false
                        isPresented = false
                    }
                }
            }
        }
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