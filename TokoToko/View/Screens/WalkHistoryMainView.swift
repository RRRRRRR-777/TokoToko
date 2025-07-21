//
//  WalkHistoryMainView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/18.
//

import SwiftUI
import CoreLocation

struct WalkHistoryMainView: View {
  @State private var walks: [Walk] = []
  @State private var isLoading = true
  @State private var hasError = false
  
  private let walkRepository = WalkRepository.shared
  
  var body: some View {
    Group {
      if isLoading {
        LoadingView(message: "散歩履歴を読み込み中...")
      } else if hasError || walks.isEmpty {
        EmptyWalkHistoryView()
      } else {
        WalkHistoryView(walks: walks, initialIndex: 0)
      }
    }
    .onAppear {
      loadWalks()
    }
  }
  
  private func loadWalks() {
    isLoading = true
    hasError = false
    
    walkRepository.fetchWalks { result in
      DispatchQueue.main.async {
        isLoading = false
        switch result {
        case .success(let fetchedWalks):
          // 完了した散歩のみを表示し、作成日時の降順でソート
          let completedWalks = fetchedWalks.filter { $0.isCompleted }
          self.walks = completedWalks.sorted { $0.createdAt > $1.createdAt }
          
        case .failure(let error):
          print("❌ 散歩履歴の読み込みに失敗しました: \(error)")
          self.hasError = true
        }
      }
    }
  }
}

// 空の散歩履歴表示用のビュー
private struct EmptyWalkHistoryView: View {
  var body: some View {
    VStack(spacing: 20) {
      Spacer()
      
      Image(systemName: "figure.walk.circle")
        .font(.system(size: 80))
        .foregroundColor(.gray)
        .accessibilityIdentifier("空の散歩履歴アイコン")
      
      Text("散歩履歴がありません")
        .font(.title)
        .fontWeight(.bold)
        .accessibilityIdentifier("散歩履歴がありません")
      
      Text("散歩を完了すると\nここに履歴が表示されます")
        .font(.body)
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
        .accessibilityIdentifier("散歩を完了すると、ここに履歴が表示されます")
      
      Spacer()
    }
    .navigationTitle("おさんぽ")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview("ローディング状態") {
  NavigationView {
    WalkHistoryMainView()
  }
}

#Preview("散歩履歴あり") {
  NavigationView {
    WalkHistoryView(walks: [
      Walk(
        title: "朝の散歩",
        description: "公園を歩きました",
        id: UUID(),
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 1200,
        totalSteps: 1500,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6812, longitude: 139.7671),
          CLLocation(latitude: 35.6815, longitude: 139.7675),
          CLLocation(latitude: 35.6820, longitude: 139.7680),
          CLLocation(latitude: 35.6825, longitude: 139.7690)
        ]
      ),
      Walk(
        title: "夕方の散歩",
        description: "川沿いを歩きました",
        id: UUID(),
        startTime: Date().addingTimeInterval(-7200),
        endTime: Date().addingTimeInterval(-6600),
        totalDistance: 800,
        totalSteps: 1000,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6700, longitude: 139.7500),
          CLLocation(latitude: 35.6720, longitude: 139.7520),
          CLLocation(latitude: 35.6740, longitude: 139.7540),
          CLLocation(latitude: 35.6760, longitude: 139.7560),
          CLLocation(latitude: 35.6780, longitude: 139.7580)
        ]
      )
    ], initialIndex: 0)
  }
}

#Preview("空の状態") {
  NavigationView {
    EmptyWalkHistoryView()
  }
}
