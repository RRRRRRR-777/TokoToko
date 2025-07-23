//
//  SplashView.swift
//  TokoToko
//
//  Created by Claude on 2025/06/24.
//

import SwiftUI

/// アプリケーション起動時のスプラッシュ画面
///
/// `SplashView`はアプリ起動時の初期化プロセス中に表示されるローディング画面です。
/// Firebase認証の初期化やアプリの起動準備が完了するまでの間、ユーザーに視覚的な
/// フィードバックを提供します。
///
/// ## Overview
///
/// - **ブランディング**: アプリロゴとタイトルの表示
/// - **視覚的フィードバック**: パルスアニメーションとローディングインジケーター
/// - **初期化状態**: Firebase認証確認中の状態表示
/// - **アクセシビリティ**: スクリーンリーダー対応のラベル設定
///
/// ## Topics
///
/// ### Properties
/// - ``isAnimating``
struct SplashView: View {
  /// ロゴアニメーションの実行状態
  ///
  /// trueの場合、メインロゴがパルス（拡大縮小）アニメーションを実行します。
  /// onAppearで開始され、継続的にアニメーションが繰り返されます。
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
