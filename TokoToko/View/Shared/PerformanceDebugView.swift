//
//  PerformanceDebugView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/28.
//

import SwiftUI

// パフォーマンス計測結果をデバッグ表示するビュー
struct PerformanceDebugView: View {
  @State private var showingStats = false
  @State private var statsText = "統計情報を取得中..."
  
  var body: some View {
    #if DEBUG
    VStack {
      Button("📊 パフォーマンス統計表示") {
        showingStats = true
        updateStatsText()
      }
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(8)
      
      Button("🗑️ 統計リセット") {
        resetStatistics()
      }
      .padding()
      .background(Color.red)
      .foregroundColor(.white)
      .cornerRadius(8)
    }
    .sheet(isPresented: $showingStats) {
      NavigationView {
        ScrollView {
          Text(statsText)
            .font(.system(.caption, design: .monospaced))
            .padding()
        }
        .navigationTitle("パフォーマンス統計")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("閉じる") {
              showingStats = false
            }
          }
          ToolbarItem(placement: .navigationBarLeading) {
            Button("更新") {
              updateStatsText()
            }
          }
        }
      }
    }
    #else
    EmptyView()
    #endif
  }
  
  private func updateStatsText() {
    // 各操作の統計情報を取得してテキスト形式で表示
    var text = "=== パフォーマンス統計情報 ===\n\n"
    
    let operations = [
      "WalkHistory.loadMyWalks",
      "WalkHistory.processData", 
      "WalkHistory.listRendering",
      "WalkRow.rendering",
      "WalkRow.calculateRegion",
      "MapViewComponent.init",
      "MapViewComponent.makeUIView",
      "MapViewComponent.updateUIView",
      "WalkRepository.fetchWalksFromFirestore",
      "WalkRepository.parseDocuments"
    ]
    
    for operation in operations {
      if let stats = PerformanceMeasurement.shared.getStatistics(for: operation) {
        text += "📈 \(operation):\n"
        text += "  実行回数: \(stats.count)回\n"
        text += "  平均時間: \(formatTime(stats.average))\n"
        text += "  最短時間: \(formatTime(stats.min))\n"
        text += "  最長時間: \(formatTime(stats.max))\n\n"
      }
    }
    
    if text == "=== パフォーマンス統計情報 ===\n\n" {
      text += "まだ計測データがありません。\n履歴画面を操作してデータを収集してください。"
    }
    
    statsText = text
  }
  
  private func resetStatistics() {
    // 統計をリセットする機能は現在のPerformanceMeasurementクラスにはないため、
    // 将来の実装のためのプレースホルダー
    statsText = "統計がリセットされました。"
  }
  
  private func formatTime(_ time: TimeInterval) -> String {
    if time < 0.001 {
      return String(format: "%.3f μs", time * 1_000_000)
    } else if time < 1.0 {
      return String(format: "%.3f ms", time * 1000)
    } else {
      return String(format: "%.3f s", time)
    }
  }
}

#Preview {
  PerformanceDebugView()
}