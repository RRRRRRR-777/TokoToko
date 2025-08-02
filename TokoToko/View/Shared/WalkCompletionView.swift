//
//  WalkCompletionView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/07/25.
//

import SwiftUI

/// 散歩完了時に表示される祝福画面と共有機能を提供するビュー
///
/// `WalkCompletionView`は散歩完了直後に表示される画面で、
/// 散歩の成果を祝福し、結果を共有するための機能を提供します。
///
/// ## Overview
///
/// - **成果表示**: 散歩のタイトル、距離、時間、歩数を見やすく表示
/// - **祝福メッセージ**: 散歩完了への励ましのメッセージ
/// - **共有機能**: 生成された画像をSNSやメッセージアプリで共有
/// - **画像プレビュー**: 共有前に生成画像の確認が可能
///
/// ## Topics
///
/// ### Properties
/// - ``walk``
/// - ``isPresented``
/// - ``generatedImage``
/// - ``isGeneratingImage``
/// - ``showingShareSheet``
/// - ``errorMessage``
struct WalkCompletionView: View {
    /// 完了した散歩データ
    let walk: Walk
    
    /// ビューの表示状態
    @Binding var isPresented: Bool
    
    /// 生成された共有用画像
    @State private var generatedImage: UIImage?
    
    /// 画像生成中の状態
    @State private var isGeneratingImage = false
    
    /// 共有シートの表示状態
    @State private var showingShareSheet = false
    
    /// エラーメッセージ
    @State private var errorMessage: String?
    
    private let imageGenerator = WalkImageGenerator.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 祝福ヘッダー
                    congratulationsHeader
                    
                    // 散歩結果サマリー
                    walkSummary
                    
                    // 画像プレビュー（生成後に表示）
                    imagePreviewSection
                    
                    // エラーメッセージ
                    errorSection
                    
                    // アクションボタン
                    actionButtons
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("散歩完了")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            generateShareImage()
        }
        .shareWalk(walk, isPresented: $showingShareSheet)
    }
    
    // MARK: - View Components
    
    /// 祝福ヘッダー
    private var congratulationsHeader: some View {
        VStack(spacing: 16) {
            // 祝福アイコン
            Image(systemName: "party.popper.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
            
            // 祝福メッセージ
            VStack(spacing: 8) {
                Text("おつかれさまでした！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("素晴らしい散歩でした")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    /// 散歩結果サマリー
    private var walkSummary: some View {
        VStack(spacing: 16) {
            // タイトル
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.blue)
                Text(walk.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Divider()
            
            // 統計情報
            HStack(spacing: 0) {
                // 距離
                VStack(spacing: 4) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text(walk.distanceString)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("距離")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // 時間
                VStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text(walk.durationString)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // 歩数
                VStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("\(walk.totalSteps)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("歩数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    /// 画像プレビューセクション
    private var imagePreviewSection: some View {
        VStack(spacing: 12) {
            if isGeneratingImage {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("共有用画像を生成中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemBackground))
                )
            } else if let image = generatedImage {
                VStack(spacing: 8) {
                    Text("共有用画像")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    /// エラーセクション
    private var errorSection: some View {
        Group {
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
    }
    
    /// アクションボタン
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 共有ボタン
            Button(action: {
                if generatedImage != nil {
                    showingShareSheet = true
                } else {
                    generateShareImage()
                }
            }) {
                HStack {
                    if isGeneratingImage {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isGeneratingImage ? "画像生成中..." : "散歩を共有")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isGeneratingImage ? Color.gray : Color.blue)
                )
                .foregroundColor(.white)
            }
            .disabled(isGeneratingImage)
            
            // 再生成ボタン（エラー時のみ表示）
            if errorMessage != nil {
                Button(action: {
                    generateShareImage()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("再生成")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 共有用画像を生成
    private func generateShareImage() {
        isGeneratingImage = true
        errorMessage = nil
        generatedImage = nil
        
        Task {
            do {
                let image = try await imageGenerator.generateWalkImage(from: walk)
                await MainActor.run {
                    self.generatedImage = image
                    self.isGeneratingImage = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "画像生成に失敗しました: \(error.localizedDescription)"
                    self.isGeneratingImage = false
                }
            }
        }
    }
}

#Preview {
    WalkCompletionView(
        walk: Walk.previewWalk,
        isPresented: .constant(true)
    )
}

// MARK: - Preview Extensions

extension Walk {
    static var previewWalk: Walk {
        let startTime = Date().addingTimeInterval(-3600)
        let endTime = Date().addingTimeInterval(-300)
        
        return Walk(
            title: "朝の散歩",
            description: "爽やかな朝の散歩コース",
            startTime: startTime,
            endTime: endTime,
            totalSteps: 1500,
            status: .completed
        )
    }
}