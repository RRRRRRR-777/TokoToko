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
/// メインアイコンのみを表示し、シンプルで視覚的に統一されたブランディングを提供します。
///
/// ## Overview
///
/// - **ブランディング**: メインアプリアイコン (TekuTokoIcon) の表示
/// - **デザイン統一**: アプリ全体で使用される温かみのあるクリーム色背景
/// - **シンプル設計**: 最小限の要素で構成された直感的なUI
/// - **アクセシビリティ**: スクリーンリーダー対応のラベル設定
///
struct SplashView: View {

  var body: some View {
    VStack(spacing: 20) {
      Spacer()

      // メインアイコン
      Image("TekuTokoIcon")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 240, height: 240)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("BackgroundColor"))
    .accessibilityLabel("アプリケーション初期化中")
  }
}

#Preview {
  SplashView()
}
