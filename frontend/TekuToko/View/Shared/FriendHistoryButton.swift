//
//  FriendHistoryButton.swift
//  TekuToko
//
//  Created by Claude Code on 2025/10/11.
//

import SwiftUI

/// フレンド履歴表示用のフローティングボタン
///
/// `FriendHistoryButton`は散歩履歴画面でフレンドの履歴を表示するための
/// フローティングボタンコンポーネントです。緑色の円形デザインで、
/// 2人のアイコンを表示します。
///
/// ## Overview
///
/// - **ナビゲーション**: WalkListView(selectedTab: 1)へ遷移
/// - **デザイン**: 60x60の円形ボタン、グラデーション背景
/// - **アクセシビリティ**: スクリーンリーダー対応の識別子設定
///
/// ## Topics
///
/// ### Initialization
/// - ``init()``
struct FriendHistoryButton: View {
  var body: some View {
    NavigationLink(
      destination:
        WalkListView(selectedTab: 1)
        .navigationBarBackButtonHidden(false)
    ) {
      buttonIcon
    }
    .accessibilityIdentifier("フレンドの履歴を表示")
  }

  /// フレンド履歴ボタンのアイコンとスタイル
  private var buttonIcon: some View {
    Image(systemName: "person.2.fill")
      .font(.title)
      .frame(width: 60, height: 60)
      .background(buttonGradient)
      .foregroundColor(.white)
      .clipShape(Circle())
      .shadow(
        color: Color(red: 0 / 255, green: 163 / 255, blue: 129 / 255).opacity(0.4),
        radius: 8, x: 0, y: 4
      )
  }

  /// フレンド履歴ボタンのグラデーション背景
  private var buttonGradient: some View {
    LinearGradient(
      gradient: Gradient(colors: [
        Color(red: 0 / 255, green: 163 / 255, blue: 129 / 255),
        Color(red: 0 / 255, green: 143 / 255, blue: 109 / 255)
      ]),
      startPoint: .leading,
      endPoint: .trailing
    )
  }
}

#Preview {
  NavigationView {
    FriendHistoryButton()
      .padding()
  }
}