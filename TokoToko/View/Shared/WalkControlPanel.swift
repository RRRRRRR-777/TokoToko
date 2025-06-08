//
//  WalkControlPanel.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import SwiftUI

struct WalkControlPanel: View {
  @ObservedObject var walkManager: WalkManager
  @State private var showingStartAlert = false
  @State private var showingStopAlert = false
  @State private var walkTitle = ""

  var body: some View {
    // コントロールボタン
    HStack(spacing: 16) {
      if walkManager.isWalking {
        // 散歩中のボタン
        Button(action: {
          if walkManager.currentWalk?.status == .paused {
            walkManager.resumeWalk()
          } else {
            walkManager.pauseWalk()
          }
        }) {
          HStack {
            Image(
              systemName: walkManager.currentWalk?.status == .paused ? "play.fill" : "pause.fill")
            Text(walkManager.currentWalk?.status == .paused ? "再開" : "一時停止")
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.orange)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        .accessibilityIdentifier(walkManager.currentWalk?.status == .paused ? "散歩再開" : "散歩一時停止")

        Button(action: {
          showingStopAlert = true
        }) {
          HStack {
            Image(systemName: "stop.fill")
            Text("終了")
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.red)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        .accessibilityIdentifier("散歩終了")
      } else {
        // 散歩開始ボタン - アイコンのみ
        Button(action: {
          showingStartAlert = true
        }) {
          Image(systemName: "figure.walk")
            .font(.title)
            .frame(width: 60, height: 60)
            .background(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color(red: 0 / 255, green: 163 / 255, blue: 129 / 255),
                  Color(red: 0 / 255, green: 143 / 255, blue: 109 / 255),
                ]),
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .foregroundColor(.white)
            .clipShape(Circle())
            .shadow(
              color: Color(red: 0 / 255, green: 163 / 255, blue: 129 / 255).opacity(0.4), radius: 8,
              x: 0, y: 4)
        }
        .accessibilityIdentifier("新しい散歩を開始")
        .scaleEffect(walkManager.isWalking ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: walkManager.isWalking)
      }
    }
    .alert("散歩を開始", isPresented: $showingStartAlert) {
      TextField("散歩のタイトル（任意）", text: $walkTitle)
      Button("開始") {
        let title = walkTitle.isEmpty ? "新しい散歩" : walkTitle
        walkManager.startWalk(title: title)
        walkTitle = ""
      }
      Button("キャンセル", role: .cancel) {
        walkTitle = ""
      }
    } message: {
      Text("散歩を開始しますか？タイトルを入力することもできます。")
    }
    .alert("散歩を終了", isPresented: $showingStopAlert) {
      Button("終了", role: .destructive) {
        walkManager.stopWalk()
      }
      Button("キャンセル", role: .cancel) {}
    } message: {
      Text("散歩を終了しますか？記録が保存されます。")
    }
  }
}

struct WalkInfoDisplay: View {
  let elapsedTime: String
  let totalSteps: Int
  let distance: String

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("経過時間")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(elapsedTime)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }

      Spacer()

      VStack(alignment: .center, spacing: 4) {
        Text("歩数")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(String(totalSteps) + "歩")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        Text("距離")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(distance)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      }
    }
  }
}

#Preview {
  VStack {
    WalkControlPanel(walkManager: WalkManager.shared)
      .padding()

    Divider()

    WalkInfoDisplay(elapsedTime: "12:34", totalSteps: 1234, distance: "1.2 km")
      .padding()
      .background(Color(.systemGray6))
      .cornerRadius(12)
      .padding()
  }
}
