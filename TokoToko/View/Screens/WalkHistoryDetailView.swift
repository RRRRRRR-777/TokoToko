//
//  WalkHistoryDetailView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/12.
//

import CoreLocation
import FirebaseAuth
import Foundation
import SwiftUI

struct WalkHistoryDetailView: View {
  @StateObject private var viewModel: WalkHistoryDetailViewModel

  init(walks: [Walk], initialIndex: Int) {
    // ViewModelの初期化を安全に行う
    let viewModel: WalkHistoryDetailViewModel

    if walks.isEmpty {
      // 空の場合はフォールバック
      let fallbackWalk = Walk(title: "エラー", description: "データが見つかりません")
      // swiftlint:disable:next force_try
      viewModel = try! WalkHistoryDetailViewModel(walks: [fallbackWalk], initialIndex: 0)
    } else if initialIndex >= 0 && initialIndex < walks.count {
      // 正常な範囲の場合
      // swiftlint:disable:next force_try
      viewModel = try! WalkHistoryDetailViewModel(walks: walks, initialIndex: initialIndex)
    } else {
      // インデックスが範囲外の場合はゼロに修正
      // swiftlint:disable:next force_try
      viewModel = try! WalkHistoryDetailViewModel(walks: walks, initialIndex: 0)
    }

    self._viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    ZStack {
      backgroundMapView
      mainContentView
      storyNavigationOverlay
      imagePopupView
    }
    .navigationBarHidden(true)
    .animation(.easeInOut(duration: 0.3), value: viewModel.isStatsBarVisible)
    .animation(.easeInOut(duration: 0.2), value: viewModel.selectedImageIndex)
  }

  // MARK: - View Components

  private var backgroundMapView: some View {
    FullScreenMapView(walk: viewModel.currentWalk)
      .id(viewModel.currentWalk.id)  // 散歩が変更されたら確実にViewを再作成
  }

  private var storyNavigationOverlay: some View {
    VStack {
      Spacer()
      StoryCarouselView(
        onPreviousTap: {
          viewModel.selectPreviousWalk()
        },
        onNextTap: {
          viewModel.selectNextWalk()
        },
        photoURLs: mockPhotoURLs,
        onImageTap: { index in
          viewModel.selectImage(at: index)
        }
      )
      .padding(.bottom, 50)
    }
  }

  private var mainContentView: some View {
    VStack {
      headerView

      Spacer()

      HStack {
        // 左側の統計情報バー
        leftStatsBarView

        Spacer()
      }

      Spacer()
    }
  }

  private var headerView: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(viewModel.currentWalk.title)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.black)

        if let startTime = viewModel.currentWalk.startTime {
          Text(startTime.formatted(date: .abbreviated, time: .shortened))
            .font(.caption)
            .foregroundColor(.black)
        }
      }

      Spacer()

      // ユーザー情報表示
      VStack(alignment: .trailing, spacing: 4) {
        // ユーザーアイコン
        if let user = Auth.auth().currentUser,
          let photoURL = user.photoURL
        {
          AsyncImage(url: photoURL) { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } placeholder: {
            Image(systemName: "person.crop.circle.fill")
              .foregroundColor(.gray)
          }
          .frame(width: 40, height: 40)
          .clipShape(Circle())
        } else {
          Image(systemName: "person.crop.circle.fill")
            .foregroundColor(.gray)
            .frame(width: 40, height: 40)
        }

        // ユーザー名（コメントアウト - ユーザー名登録機能未実装のため）
        // Text(user.displayName ?? "ユーザー")
        //   .font(.caption)
        //   .fontWeight(.medium)
        //   .foregroundColor(.black)
      }
    }
    .padding()
    .background(
      LinearGradient(
        colors: [
          Color.white.opacity(0.8),
          Color.white.opacity(0.7),
          Color.white.opacity(0.6),
          Color.clear,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }

  private var leftStatsBarView: some View {
    VStack {
      StatsBarView(
        walk: viewModel.currentWalk,
        isExpanded: Binding(
          get: { viewModel.isStatsBarVisible },
          set: { _ in }
        ),
        onToggle: {
          viewModel.toggleStatsBar()
        }
      )
      .transition(.move(edge: .leading).combined(with: .opacity))
    }
    .padding(.leading, 10)
  }

  @ViewBuilder private var imagePopupView: some View {
    if let selectedIndex = viewModel.selectedImageIndex {
      ImagePopupView(
        imageURL: mockPhotoURLs[safe: selectedIndex] ?? ""
      ) {
        viewModel.deselectImage()
      }
      .transition(.opacity)
    }
  }

  // MARK: - Mock Data (将来的にはWalkデータから取得)
  private var mockPhotoURLs: [String] {
    [
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
      "https://picsum.photos/600/400",
    ]
  }
}

// 安全な配列アクセス用の拡張
extension Array {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

#Preview {
  WalkHistoryDetailView(
    walks: [
      Walk(
        title: "朝の散歩",
        description: "公園を歩きました",
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3000),
        totalDistance: 1200,
        totalSteps: 1500,
        status: .completed,
        locations: [
          CLLocation(latitude: 35.6812, longitude: 139.7671),
          CLLocation(latitude: 35.6815, longitude: 139.7675),
          CLLocation(latitude: 35.6820, longitude: 139.7680),
          CLLocation(latitude: 35.6825, longitude: 139.7690),
        ]
      ),
      Walk(
        title: "夕方の散歩",
        description: "川沿いを歩きました",
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
          CLLocation(latitude: 35.6780, longitude: 139.7580),
        ]
      ),
    ],
    initialIndex: 0
  )
}
