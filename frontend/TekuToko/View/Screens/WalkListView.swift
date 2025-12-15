//
//  WalkListView.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/06/16.
//

import CoreLocation
import SwiftUI
import UIKit

struct WalkListView: View {
  /// 現在選択されているタブのインデックス
  ///
  /// 0: 自分の履歴タブ、1: フレンドの履歴タブ
  /// セグメントコントロールとTabViewの両方で使用されます。
  @State private var selectedTab: Int

  /// 表示する散歩データの配列
  ///
  /// WalkRepositoryから取得した完了済み散歩データを保持します。
  /// 作成日時の降順でソートされています。
  @State private var walks: [Walk] = []

  /// データ読み込み中の状態
  ///
  /// trueの場合、ローディングインジケーターが表示されます。
  @State private var isLoading = false

  /// エラーメッセージ
  ///
  /// データ取得失敗時に表示するエラーメッセージ。nilでない場合、アラートが表示されます。
  @State private var errorMessage: String = ""

  /// エラーアラート表示フラグ
  @State private var showErrorAlert = false

  /// 散歩データリポジトリ
  ///
  /// 散歩データの取得を担当するWalkRepositoryです。
  /// WalkRepositoryFactoryを通じて環境設定に基づいたリポジトリを取得します。
  private let walkRepository: WalkRepositoryProtocol = WalkRepositoryFactory.shared.repository

  /// WalkListViewの初期化メソッド
  ///
  /// 指定されたタブを初期選択状態として設定します。
  ///
  /// - Parameter selectedTab: 初期選択タブのインデックス（デフォルト: 0）
  init(selectedTab: Int = 0) {
    self._selectedTab = State(initialValue: selectedTab)

    // 統一されたナビゲーションバー外観設定を適用
    NavigationBarStyleManager.shared.configureForSwiftUI(customizations: .walkListScreen)
  }

  var body: some View {
    contentView
      .alert("エラー", isPresented: $showErrorAlert) {
        Button("OK") {
          showErrorAlert = false
        }
      } message: {
        Text(errorMessage)
      }
  }

  /// メインコンテンツビュー
  private var contentView: some View {
    VStack(spacing: 0) {
      // セグメントコントロール
      Picker("履歴タブ", selection: $selectedTab) {
        Text("自分の履歴").tag(0)
          .accessibilityIdentifier("自分の履歴")
        Text("フレンドの履歴").tag(1)
          .accessibilityIdentifier("フレンドの履歴")
      }
      .pickerStyle(SegmentedPickerStyle())
      .background(Color("BackgroundColor"))
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
    .accentColor(.black)
    .onAppear {
      // セグメントコントロールの外観設定
      UISegmentedControl.appearance().setTitleTextAttributes(
        [.foregroundColor: UIColor.black], for: .normal)
      UISegmentedControl.appearance().setTitleTextAttributes(
        [.foregroundColor: UIColor.black], for: .selected)
      UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(named: "BackgroundColor")

      // List背景の透明化
      UITableView.appearance().backgroundColor = .clear
      UITableViewCell.appearance().backgroundColor = .clear
      loadMyWalks()
    }
    .refreshable {
      loadMyWalks()
    }
    .background(Color("BackgroundColor").ignoresSafeArea())
  }

  /// 自分の散歩履歴を表示するビュー
  ///
  /// ローディング状態、空の状態、散歩リスト表示を適切に切り替えます。
  private var myWalkHistoryView: some View {
    Group {
      if isLoading {
        VStack {
          Spacer()
          ProgressView("読み込み中...")
            .foregroundColor(.black)
          Spacer()
        }
      } else if walks.isEmpty {
        emptyWalkHistoryView
      } else {
        walkHistoryListView
      }
    }
  }

  /// フレンドの散歩履歴を表示するビュー（近日公開予定）
  ///
  /// 将来実装予定の機能として、友達の散歩履歴を表示する予定です。
  /// 現在は準備中のメッセージとアイコンを表示します。
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
        .foregroundColor(.black)
        .padding(.bottom, 8)

      Text("友達の散歩履歴は近日公開予定です")
        .font(.body)
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Spacer()
    }
  }

  /// 散歩履歴が空の場合の表示ビュー
  ///
  /// 散歩データが存在しない場合に表示されるプレースホルダービューです。
  /// ユーザーに散歩を開始するよう促すメッセージを表示します。
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
        .foregroundColor(.black)
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

  /// 散歩履歴をリスト形式で表示するビュー
  ///
  /// 完了した散歩データを一覧表示し、各項目をタップすると詳細画面に遷移します。
  /// プルトゥリフレッシュによる手動更新にも対応しています。
  private var walkHistoryListView: some View {
    List {
      ForEach(Array(walks.enumerated()), id: \.element.id) { index, walk in
        NavigationLink(
          destination:
            WalkHistoryView(
              walks: walks,
              initialIndex: index,
              onWalkDeleted: handleWalkDeletion
            )
            .navigationBarBackButtonHidden(false)
        ) {
          WalkRow(walk: walk)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color("BackgroundColor"))
        .listRowInsets(EdgeInsets())
      }
    }
    .listStyle(PlainListStyle())
    .background(Color("BackgroundColor"))
    .refreshable {
      loadMyWalks()
    }
  }

  /// WalkRepositoryから自分の散歩データを読み込む
  ///
  /// 散歩データの取得を開始し、取得結果に応じてUI状態を更新します。
  /// 完了した散歩のみを抽出し、作成日時の降順でソートして表示用データを準備します。
  ///
  /// ## Process Flow
  /// 1. ローディング状態をtrueに設定
  /// 2. WalkRepository.fetchWalks()を非同期実行
  /// 3. 取得成功時: 完了した散歩をフィルタ・ソートして保持
  /// 4. 取得失敗時: エラーログを出力し空配列を設定
  /// 5. ローディング状態をfalseに設定
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
          self.errorMessage = "散歩履歴の読み込みに失敗しました。\nサーバーに接続できません。"
          self.showErrorAlert = true
        }
      }
    }
  }

  /// 散歩削除時のコールバック処理
  ///
  /// WalkHistoryViewから散歩が削除された際に呼び出され、
  /// 削除された散歩をローカルの散歩リストから除去します。
  ///
  /// - Parameter walkId: 削除された散歩のID
  private func handleWalkDeletion(_ walkId: UUID) {
    // 削除された散歩をリストから除去
    walks.removeAll { $0.id == walkId }
  }
}

#Preview {
  NavigationView {
    WalkListView()
  }
}
