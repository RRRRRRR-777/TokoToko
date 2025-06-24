//
//  SplashView.swift
//  TokoToko
//
//  Created by Claude on 2025/06/24.
//

import SwiftUI

struct SplashView: View {
  @State private var isAnimating = false

  var body: some View {
    VStack(spacing: 20) {
      Spacer()

      // メインロゴ
      Image(systemName: "mappin.and.ellipse")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 120, height: 120)
        .foregroundColor(.blue)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(
          Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
          value: isAnimating
        )

      // アプリ名
      Text("TokoToko")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.primary)

      Text("とことこ - おさんぽSNS")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Spacer()

      // ローディングインジケーター
      VStack(spacing: 16) {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: .blue))
          .scaleEffect(1.2)

        Text("初期化中...")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
    .onAppear {
      isAnimating = true
    }
    .accessibilityLabel("アプリケーション初期化中")
  }
}

#Preview {
  SplashView()
}