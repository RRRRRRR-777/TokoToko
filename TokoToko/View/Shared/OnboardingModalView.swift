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
        VStack(spacing: 24) {
            headerView
            contentView
            Spacer()
            navigationView
        }
        .padding(.top, 20)
        .background(Color(UIColor.systemBackground))
        .accessibilityIdentifier("OnboardingModalView")
    }
    // MARK: - Private Properties

    private var currentPage: OnboardingPage {
        content.pages[currentPageIndex]
    }

    private var headerView: some View {
        HStack {
            Spacer()
            Button("閉じる") {
                onDismiss()
                isPresented = false
            }
            .accessibilityIdentifier("OnboardingCloseButton")
        }
        .padding(.horizontal)
    }

    private var contentView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo")
                .font(.system(size: 120))
                .foregroundColor(.gray)
                .frame(height: 200)

            Text(currentPage.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(currentPage.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
        }
    }

    private var navigationView: some View {
        HStack(spacing: 20) {
            Button { previousPage() } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            .disabled(currentPageIndex == 0)

            HStack(spacing: 8) {
                ForEach(0..<content.pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPageIndex ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            Button { nextPage() } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
            .disabled(currentPageIndex == content.pages.count - 1)
        }
        .padding(.bottom, 40)
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
