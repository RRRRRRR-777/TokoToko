//
//  OnboardingModalView.swift
//  TokoToko
//
//  Created by Claude on 2025-08-06.
//

import SwiftUI

struct OnboardingModalView: View {
    let content: OnboardingContent
    @Binding var isPresented: Bool
    let onDismiss: () -> Void

    @State private var currentPageIndex = 0
    var body: some View {
        ZStack {
            // 背景オーバーレイ
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                    isPresented = false
                }

            // カード型モーダル
            VStack(spacing: 24) {
                headerView
                contentView
                navigationView
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .accessibilityElement(children: .contain)
        }
    }
    // MARK: - Private Properties

    private var currentPage: OnboardingPage {
        content.pages[currentPageIndex]
    }

    private var headerView: some View {
        HStack {
            Spacer()
            Button {
                onDismiss()
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
            }
            .accessibilityIdentifier("OnboardingCloseButton")
        }
    }

    private var contentView: some View {
        VStack(spacing: 16) {
            // 画像プレースホルダーをカードスタイルに変更
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 160, height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                )

            Text(currentPage.title)
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text(currentPage.description)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineSpacing(2)
                .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        // 右スワイプ: 前のページ
                        previousPage()
                    } else if value.translation.width < -50 {
                        // 左スワイプ: 次のページ
                        nextPage()
                    }
                }
        )
    }

    private var navigationView: some View {
        HStack(spacing: 20) {
            Button { previousPage() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(currentPageIndex == 0 ? .gray.opacity(0.3) : .blue)
            }
            .disabled(currentPageIndex == 0)
            .accessibilityIdentifier("OnboardingPrevButton")

            HStack(spacing: 8) {
                ForEach(0..<content.pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPageIndex ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityIdentifier("OnboardingPageIndicator")
            .accessibilityValue("page \(currentPageIndex + 1) of \(content.pages.count)")

            Button { nextPage() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(currentPageIndex == content.pages.count - 1 ? .gray.opacity(0.3) : .blue)
            }
            .disabled(currentPageIndex == content.pages.count - 1)
            .accessibilityIdentifier("OnboardingNextButton")
        }
        .padding(.top, 16)
    }

    // MARK: - Private Methods

    private func nextPage() {
        if currentPageIndex < content.pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPageIndex += 1
            }
        }
    }

    private func previousPage() {
        if currentPageIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPageIndex -= 1
            }
        }
    }
}

// MARK: - Preview

struct OnboardingModalView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingModalView(
            content: OnboardingContent(
                type: .firstLaunch,
                pages: [
                    OnboardingPage(
                        title: "TokoTokoへようこそ",
                        description: "散歩を記録して、素敵な思い出を作りましょう",
                        imageName: "first_launch_1"
                    ),
                    OnboardingPage(
                        title: "簡単操作",
                        description: "ボタン一つで散歩の開始・終了ができます",
                        imageName: "first_launch_2"
                    )
                ]
            ),
            isPresented: .constant(true)
        ) {}
        .previewLayout(.sizeThatFits)
    }
}
