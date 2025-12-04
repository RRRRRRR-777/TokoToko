//
//  WalkHistoryMainView.swift
//  TekuToko
//
//  Created by Claude Code on 2025/07/18.
//

import CoreLocation
import SwiftUI

/// 散歩履歴のメイン画面とデータローディング制御
///
/// `WalkHistoryMainView`は散歩履歴の一覧表示を管理するメインビューです。
/// データの読み込み状態に応じて適切なビュー（ローディング、空の状態、履歴一覧）を
/// 表示し、WalkRepositoryからの散歩データ取得を制御します。
///
/// ## Overview
///
/// - **データ管理**: WalkRepositoryからの散歩データ取得とキャッシュ
/// - **状態管理**: ローディング、エラー、空の状態の適切な表示制御
/// - **フィルタリング**: 完了した散歩のみを表示し、日付降順でソート
/// - **ナビゲーション**: 条件に応じて適切な子ビューへの遷移制御
///
/// ## Topics
///
/// ### Properties
/// - ``walks``
/// - ``isLoading``
/// - ``hasError``
/// - ``walkRepository``
///
/// ### Methods
/// - ``loadWalks()``
struct WalkHistoryMainView: View {
  /// 表示する散歩データの配列
  ///
  /// WalkRepositoryから取得された散歩データを保持します。
  /// 完了した散歩のみがフィルタリングされ、作成日時の降順でソートされます。
  @State private var walks: [Walk] = []

  /// データ読み込み中の状態
  ///
  /// trueの場合、ローディングビューが表示されます。
  /// データ取得開始時にtrueに設定され、取得完了時にfalseになります。
  @State private var isLoading = true

  /// データ読み込みエラーの状態
  ///
  /// trueの場合、エラー状態として空の履歴ビューが表示されます。
  /// WalkRepositoryからのデータ取得に失敗した場合にtrueに設定されます。
  @State private var hasError = false

  /// エラーメッセージ
  ///
  /// データ取得失敗時に表示するエラーメッセージ。
  @State private var errorMessage: String = ""

  /// エラーアラート表示フラグ
  @State private var showErrorAlert = false

  /// 散歩データリポジトリ
  ///
  /// 散歩データの取得・保存を担当するWalkRepositoryです。
  /// WalkRepositoryFactoryを通じて環境設定に基づいたリポジトリを取得します。
  private let walkRepository: WalkRepositoryProtocol = WalkRepositoryFactory.shared.repository

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
    .alert("エラー", isPresented: $showErrorAlert) {
      Button("OK") {
        showErrorAlert = false
      }
    } message: {
      Text(errorMessage)
    }
  }

  /// WalkRepositoryから散歩データを読み込む
  ///
  /// 散歩データの取得を開始し、取得結果に応じてUI状態を更新します。
  /// 完了した散歩のみを抽出し、作成日時の降順でソートして表示用データを準備します。
  ///
  /// ## Process Flow
  /// 1. ローディング状態をtrueに設定
  /// 2. エラー状態をfalseにリセット
  /// 3. WalkRepository.fetchWalks()を非同期実行
  /// 4. 取得成功時: 完了した散歩をフィルタ・ソートして保持
  /// 5. 取得失敗時: エラー状態をtrueに設定
  /// 6. ローディング状態をfalseに設定
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
          self.errorMessage = "散歩履歴の読み込みに失敗しました。\nサーバーに接続できません。"
          self.showErrorAlert = true
        }
      }
    }
  }
}

/// 散歩履歴が空の場合の表示ビュー
///
/// `EmptyWalkHistoryView`は散歩データが存在しない場合やデータ読み込みに
/// 失敗した場合に表示されるビューです。ユーザーに散歩を開始するよう促すメッセージと
/// アイコンを表示します。
///
/// ## Overview
///
/// - **視覚的フィードバック**: 大きなアイコンでシステム状態を表現
/// - **ガイダンス**: 散歩を完了すれば履歴が表示されることを説明
/// - **アクセシビリティ**: スクリーンリーダー用の適切な識別子を設定
/// - **ナビゲーション**: 散歩履歴画面としてのタイトル表示
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
    WalkHistoryView(
      walks: [
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
            CLLocation(latitude: 35.6825, longitude: 139.7690),
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
            CLLocation(latitude: 35.6780, longitude: 139.7580),
          ]
        ),
      ], initialIndex: 0)
  }
}

#Preview("空の状態") {
  NavigationView {
    EmptyWalkHistoryView()
  }
}
