//
//  WalkListView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/16.
//

import SwiftUI
import CoreLocation

struct WalkListView: View {
  @State private var selectedTab: Int
  @State private var walks: [Walk] = []
  @State private var isLoading = false

  private let walkRepository = WalkRepository.shared

  init(selectedTab: Int = 0) {
    self._selectedTab = State(initialValue: selectedTab)
  }

  var body: some View {
    VStack(spacing: 0) {
      // セグメントコントロール
      Picker("履歴タブ", selection: $selectedTab) {
        Text("自分の履歴").tag(0)
          .accessibilityIdentifier("自分の履歴")
        Text("フレンドの履歴").tag(1)
          .accessibilityIdentifier("フレンドの履歴")
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding(.horizontal)
      .padding(.top, 8)
      .accessibilityIdentifier("履歴タブSegmentedControl")

      // タブコンテンツ
      TabView(selection: $selectedTab) {
        // 自分の履歴タブ
        myWalkHistoryView
          .tag(0)

        // フレンドの履歴タブ
        friendWalkHistoryView
          .tag(1)
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    .navigationTitle("おさんぽ")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      loadMyWalks()
    }
    .refreshable {
      loadMyWalks()
    }
  }

  // 自分の散歩履歴ビュー
  private var myWalkHistoryView: some View {
    Group {
      if isLoading {
        VStack {
          Spacer()
          ProgressView("読み込み中...")
            .foregroundColor(.secondary)
          Spacer()
        }
      } else if walks.isEmpty {
        emptyWalkHistoryView
      } else {
        walkHistoryListView
      }
    }
  }

  // フレンドの散歩履歴ビュー（近日公開予定）
  private var friendWalkHistoryView: some View {
    VStack {
      Spacer()

      Image(systemName: "person.2.circle")
        .font(.system(size: 60))
        .foregroundColor(.gray)
        .padding(.bottom, 16)

      Text("フレンドの履歴")
        .font(.title2)
        .fontWeight(.semibold)
        .padding(.bottom, 8)

      Text("友達の散歩履歴は近日公開予定です")
        .font(.body)
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Spacer()
    }
  }

  // 空の履歴表示
  private var emptyWalkHistoryView: some View {
    VStack(spacing: 16) {
      Spacer()

      Image(systemName: "figure.walk.circle")
        .font(.system(size: 60))
        .foregroundColor(.gray)
        .accessibilityIdentifier("空の散歩履歴アイコン")

      Text("散歩履歴がありません")
        .font(.title2)
        .fontWeight(.semibold)
        .accessibilityIdentifier("散歩履歴がありません")

      Text("散歩を完了すると、ここに履歴が表示されます")
        .font(.body)
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .accessibilityIdentifier("散歩を完了すると、ここに履歴が表示されます")

      // デバッグ用：新しい詳細画面のプレビューボタン
      NavigationLink(destination: WalkHistoryView(walks: mockWalksForPreview, initialIndex: 0)) {
        Text("新しい詳細画面をプレビュー")
          .font(.headline)
          .foregroundColor(.white)
          .padding()
          .background(Color.blue)
          .cornerRadius(12)
      }
      .padding(.top, 20)

      Spacer()
    }
  }

  // デバッグ用のモックデータ
  private var mockWalksForPreview: [Walk] {
    [
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
          CLLocation(latitude: 35.6818, longitude: 139.7680)
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
          CLLocation(latitude: 35.6820, longitude: 139.7680),
          CLLocation(latitude: 35.6825, longitude: 139.7685),
          CLLocation(latitude: 35.6828, longitude: 139.7688)
        ]
      ),
      Walk(
        title: "夜の散歩",
        description: "商店街を歩きました",
        id: UUID(),
        startTime: Date().addingTimeInterval(-10800),
        endTime: Date().addingTimeInterval(-9600),
        totalDistance: 1800,
        totalSteps: 2200,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6830, longitude: 139.7690),
          CLLocation(latitude: 35.6835, longitude: 139.7695),
          CLLocation(latitude: 35.6840, longitude: 139.7700)
        ]
      )
    ]
  }

  // 散歩履歴リスト
  private var walkHistoryListView: some View {
    List {
      ForEach(Array(walks.enumerated()), id: \.element.id) { index, walk in
        NavigationLink(destination: WalkHistoryView(walks: walks, initialIndex: index)) {
          WalkRow(walk: walk)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(PlainListStyle())
    .refreshable {
      loadMyWalks()
    }
  }

  // 散歩データの読み込み
  private func loadMyWalks() {
    isLoading = true

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
          self.walks = []
        }
      }
    }
  }
}

#Preview {
  NavigationView {
    WalkListView()
  }
}