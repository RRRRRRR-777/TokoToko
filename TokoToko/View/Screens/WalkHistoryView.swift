//
//  WalkHistoryView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/16.
//

import SwiftUI

struct WalkHistoryView: View {
  @State private var selectedTab = 0
  @State private var walks: [Walk] = []
  @State private var isLoading = false

  private let walkRepository = WalkRepository.shared

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

      Spacer()
    }
  }

  // 散歩履歴リスト
  private var walkHistoryListView: some View {
    List {
      ForEach(walks) { walk in
        NavigationLink(destination: DetailView(walk: walk)) {
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
    WalkHistoryView()
  }
}
