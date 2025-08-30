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

/// 散歩履歴の詳細表示とインタラクティブビュー
///
/// `WalkHistoryView`は個別の散歩データを詳細表示し、ユーザーが散歩履歴を
/// ナビゲートできるインタラクティブな画面です。マップ表示、統計情報、
/// 写真カルーセル、削除機能を統合しています。
///
/// ## Overview
///
/// - **フルスクリーンマップ**: 散歩ルートを背景全体に表示
/// - **ナビゲーション**: 前後の散歩への切り替えとスワイプ対応
/// - **統計表示**: 距離、時間、歩数等の詳細情報
/// - **写真ビューア**: 散歩中の写真をカルーセル形式で表示
/// - **削除機能**: 散歩データの削除と適切な画面遷移制御
///
/// ## Topics
///
/// ### Properties
/// - ``viewModel``
/// - ``onWalkDeleted``
/// - ``presentationMode``
///
/// ### Initialization
/// - ``init(walks:initialIndex:onWalkDeleted:)``
///
/// ### Methods
/// - ``handleWalkDeletion(walkId:)``
struct WalkHistoryView: View {
  /// 散歩履歴の状態管理とナビゲーション制御を担当するViewModel
  ///
  /// 散歩データの管理、画面遷移、UI状態の制御を行います。
  @StateObject private var viewModel: WalkHistoryViewModel

  /// 散歩削除時のコールバック関数
  ///
  /// 散歩が削除された際に親ビューに通知するためのオプショナルコールバックです。
  let onWalkDeleted: ((UUID) -> Void)?

  /// プレゼンテーション制御用の環境変数
  ///
  /// 散歩が全て削除された場合の画面閉じる処理に使用されます。
  @Environment(\.presentationMode)
  var presentationMode

  /// カラースキーム環境変数
  ///
  /// ライトモード・ダークモードの判定に使用されます。
  @Environment(\.colorScheme)
  var colorScheme

  /// 共有シートの表示状態
  @State private var showingShareSheet = false

  /// 外観モードに応じた背景グラデーション色
  ///
  /// ライトモードでは既存のBackgroundColor、ダークモードではグレーを返します。
  private var backgroundGradientColor: Color {
    colorScheme == .dark ? Color(red: 120 / 255, green: 120 / 255, blue: 120 / 255) : Color("BackgroundColor")
  }

  /// WalkHistoryViewの初期化メソッド
  ///
  /// 散歩データ配列と初期インデックスでビューを初期化します。
  /// 不正な値に対する安全性処理とフォールバック機能を内蔵しています。
  ///
  /// ## Safety Features
  /// - 空の配列に対するフォールバック処理
  /// - インデックス範囲外値の自動補正
  /// - ViewModel初期化失敗時の多段フォールバック
  ///
  /// - Parameters:
  ///   - walks: 表示する散歩データの配列
  ///   - initialIndex: 初期表示する散歩のインデックス
  ///   - onWalkDeleted: 散歩削除時のコールバック（オプション）
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
      friendHistoryButton
    }
    .navigationBarHidden(true)
    .animation(.easeInOut(duration: 0.3), value: viewModel.isStatsBarVisible)
    .shareWalk(viewModel.currentWalk, isPresented: $showingShareSheet)
  }

  // MARK: - View Components

  /// 背景として表示されるフルスクリーンマップビュー
  ///
  /// 現在の散歩のルートを画面全体に表示します。
  /// 散歩が変更されるたびにViewを再作成してデータの整合性を保証します。
  private var backgroundMapView: some View {
    FullScreenMapView(walk: viewModel.currentWalk)
      .id(viewModel.currentWalk.id)  // 散歩が変更されたら確実にViewを再作成
  }

  /// ストーリー形式のナビゲーションオーバーレイ
  ///
  /// 画面下部に配置されるカルーセル形式のナビゲーション要素です。
  /// 前後の散歩への移動と写真の表示・選択機能を提供します。
  private var storyNavigationOverlay: some View {
    VStack {
      Spacer()
      StoryCarouselView(
        onPreviousTap: {
          viewModel.selectPreviousWalk()
        },
        onNextTap: {
          viewModel.selectNextWalk()
        }
      )
      .padding(.bottom, 50)
    }
  }

  /// メインコンテンツエリア
  ///
  /// ヘッダー情報と統計バーを配置するメインのコンテンツエリアです。
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

      // 共有ボタンとユーザー情報表示
      HStack(spacing: 12) {
        // 共有ボタン
        Button(action: {
          showingShareSheet = true
        }) {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(Color(red: 68 / 255, green: 136 / 255, blue: 77 / 255))
            .frame(width: 60, height: 60)
        }

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
    }
    .padding()
    .background(
      LinearGradient(
        colors: [
          backgroundGradientColor.opacity(0.8),
          backgroundGradientColor.opacity(0.7),
          backgroundGradientColor.opacity(0.6),
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
          handleWalkDeletion(walkId: walkId)
        }
      )
      .transition(.move(edge: .leading).combined(with: .opacity))
    }
    .padding(.leading, 10)
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

  // MARK: - Private Methods
  /// 散歩削除処理とナビゲーション制御
  ///
  /// 指定された散歩の削除処理を実行し、適切な画面遷移を制御します。
  /// 散歩が全て削除された場合は自動的に画面を閉じます。
  ///
  /// ## Process Flow
  /// 1. ViewModelで削除処理と次の散歩への遷移実行
  /// 2. 親ビューのコールバックでデータベースからも削除
  /// 3. 散歩が全て削除された場合は画面を閉じる
  ///
  /// - Parameter walkId: 削除する散歩のID
  private func handleWalkDeletion(walkId: UUID) {
    // ViewModelで削除処理を実行し、適切な次の散歩に遷移
    let hasRemainingWalks = viewModel.removeWalk(withId: walkId)

    // 上位のコールバックを呼び出してDBからも削除
    onWalkDeleted?(walkId)

    // 散歩が全て削除された場合は画面を閉じる
    if !hasRemainingWalks {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        presentationMode.wrappedValue.dismiss()
      }
    }
  }
}

/// 配列の安全なアクセス用拡張
///
/// インデックスが範囲外の場合にクラッシュを防ぐためのセーフアクセス機能を提供します。
/// 範囲外アクセスの場合はnilを返します。
extension Array {
  /// インデックスが有効な範囲内の場合のみ要素を返すセーフアクセサ
  ///
  /// - Parameter index: アクセスしたいインデックス
  /// - Returns: 有効なインデックスの場合は要素、範囲外の場合はnil
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
