//
//  ConsentFlowView.swift
//  TokoToko
//
//  Created by Claude on 2025/08/03.
//

import SwiftUI

/// 初回同意フローを管理するビュー
///
/// `ConsentFlowView`は初回起動時の同意取得プロセスを管理し、
/// ユーザーがポリシーを確認して同意するまでの流れを制御します。
/// ConsentManagerと連携してポリシー表示と同意記録を行います。
///
/// ## Overview
///
/// - **同意フロー制御**: ポリシー表示から同意完了までの画面遷移
/// - **エラーハンドリング**: ネットワークエラーや同意失敗の処理
/// - **リトライ機能**: 失敗時の再試行オプション
/// - **アクセシビリティ**: スクリーンリーダー対応
///
/// ## Topics
///
/// ### Properties
/// - ``consentManager``
/// - ``showingPolicyView``
/// - ``selectedPolicyType``
struct ConsentFlowView: View {
    /// 同意状態管理オブジェクト
    @EnvironmentObject var consentManager: ConsentManager
    
    /// ポリシー表示モーダルの表示状態
    @State private var showingPolicyView = false
    
    /// 選択されたポリシータイプ
    @State private var selectedPolicyType: PolicyType = .privacyPolicy
    
    var body: some View {
        VStack(spacing: 32) {
            headerSection
            
            if let policy = consentManager.currentPolicy {
                policySection(policy: policy)
                consentSection
            } else if consentManager.isLoading {
                loadingSection
            } else if let error = consentManager.error {
                errorSection(error: error)
            } else {
                // ポリシーがない場合のデフォルト表示
                emptyPolicySection
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingPolicyView) {
            if let policy = consentManager.currentPolicy {
                NavigationView {
                    PolicyView(policy: policy, policyType: selectedPolicyType)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("閉じる") {
                                    showingPolicyView = false
                                }
                            }
                        }
                }
            }
        }
        .accessibilityLabel("同意画面")
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("TokoTokoへようこそ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("サービスをご利用いただく前に、プライバシーポリシーと利用規約をご確認ください。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }
    
    private func policySection(policy: Policy) -> some View {
        VStack(spacing: 16) {
            policyButton(
                title: "プライバシーポリシー",
                subtitle: "個人情報の取り扱いについて",
                policyType: .privacyPolicy
            )
            
            policyButton(
                title: "利用規約",
                subtitle: "サービス利用のルールについて",
                policyType: .termsOfService
            )
        }
    }
    
    private func policyButton(title: String, subtitle: String, policyType: PolicyType) -> some View {
        Button(action: {
            selectedPolicyType = policyType
            showingPolicyView = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("\(title)ボタン")
        .accessibilityHint("\(title)を表示します")
    }
    
    private var consentSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    do {
                        try await consentManager.recordConsent(.initial)
                    } catch {
                        // エラーハンドリングは ConsentManager で処理
                    }
                }
            }) {
                Text("同意してサービスを開始")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("同意ボタン")
            .accessibilityHint("プライバシーポリシーと利用規約に同意してサービスを開始します")
            
            Text("「同意してサービスを開始」をタップすることで、プライバシーポリシーと利用規約に同意したものとみなされます。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }
    
    private func errorSection(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.orange)
            
            Text("エラーが発生しました")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await consentManager.refreshPolicy()
                }
            }) {
                Text("再試行")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("再試行ボタン")
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("ポリシー情報を読み込み中...")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyPolicySection: some View {
        VStack(spacing: 16) {
            Text("利用規約とプライバシーポリシーの準備中です")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("しばらくお待ちください")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ConsentFlowView()
        .environmentObject(ConsentManager())
}