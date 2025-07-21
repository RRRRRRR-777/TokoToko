//
//  WalkHistoryView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/07/19.
//

import CoreLocation
import FirebaseAuth
import Foundation
import SwiftUI

struct WalkHistoryView: View {
  @StateObject private var viewModel: WalkHistoryViewModel
  let onWalkDeleted: ((UUID) -> Void)?

  init(walks: [Walk], initialIndex: Int, onWalkDeleted: ((UUID) -> Void)? = nil) {
    // 入力値を安全にサニタイズしてViewModelを初期化
    let safeWalks = walks.isEmpty ? [Walk(title: "エラー", description: "データが見つかりません")] : walks
    let safeIndex = max(0, min(initialIndex, safeWalks.count - 1))

    // サニタイズ後は必ず成功するためdo-catchで処理
    let viewModel: WalkHistoryViewModel
    do {
      viewModel = try WalkHistoryViewModel(walks: safeWalks, initialIndex: safeIndex)
    } catch {
      // フォールバック処理（理論上は到達しないが安全のため）
      let fallbackWalk = Walk(title: "システムエラー", description: "ViewModelの初期化に失敗しました")
      do {
        viewModel = try WalkHistoryViewModel(walks: [fallbackWalk], initialIndex: 0)
      } catch {
        // 最終的なフォールバック（この時点では絶対成功するはず）
        fatalError("致命的エラー: WalkHistoryViewModelの初期化に失敗しました")
      }
    }

    self._viewModel = StateObject(wrappedValue: viewModel)
    self.onWalkDeleted = onWalkDeleted
  }

  var body: some View {
    ZStack {
      backgroundMapView
      mainContentView
      storyNavigationOverlay
      imagePopupView
      friendHistoryButton
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
        photoURLs: mockPhotoURLs
      ) { index in
        viewModel.selectImage(at: index)
      }
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
           let photoURL = user.photoURL {
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
          Color.clear
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
        },
        onWalkDeleted: { walkId in
          onWalkDeleted?(walkId)
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


  private var friendHistoryButton: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        NavigationLink(destination: 
          WalkListView(selectedTab: 1)
            .navigationBarBackButtonHidden(false)
        ) {
          Image(systemName: "person.2.fill")
            .font(.title)
            .frame(width: 60, height: 60)
            .background(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color(red: 0 / 255, green: 163 / 255, blue: 129 / 255),
                  Color(red: 0 / 255, green: 143 / 255, blue: 109 / 255)
                ]),
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .foregroundColor(.white)
            .clipShape(Circle())
            .shadow(
              color: Color(red: 0 / 255, green: 163 / 255, blue: 129 / 255).opacity(0.4),
              radius: 8, x: 0, y: 4
            )
        }
        .accessibilityIdentifier("フレンドの履歴を表示")
        .padding(.trailing, 20)
      }
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
      "https://picsum.photos/600/400"
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
  WalkHistoryView(
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
          CLLocation(latitude: 35.6825, longitude: 139.7690)
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
          CLLocation(latitude: 35.6780, longitude: 139.7580)
        ]
      )
    ],
    initialIndex: 0
  )
}
