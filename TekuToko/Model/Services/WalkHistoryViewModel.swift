//
//  WalkHistoryViewModel.swift
//  TekuToko
//
//  Created by Claude Code on 2025/07/12.
//

import Combine
import Foundation

/// 散歩履歴表示とナビゲーションを管理するViewModel
///
/// `WalkHistoryViewModel`は散歩履歴一覧の表示、ナビゲーション、
/// UI状態管理を統合するSwiftUI用のObservableObjectです。
/// 複数の散歩データ間の切り替え、詳細表示、削除処理を担当します。
///
/// ## Overview
///
/// 主要な責務：
/// - **散歩ナビゲーション**: 前後の散歩への切り替え
/// - **UI状態管理**: 統計バーの表示/非表示
/// - **データ管理**: 散歩リストの維持と更新
/// - **削除処理**: 散歩データの削除と適切な遷移制御
/// - **バリデーション**: インデックス範囲やデータ整合性の確認
///
/// ## Topics
///
/// ### Properties
/// - ``currentWalk``
/// - ``isStatsBarVisible``
/// - ``walkCount``
///
/// ### Navigation
/// - ``selectNextWalk()``
/// - ``selectPreviousWalk()``
///
/// ### UI State
/// - ``toggleStatsBar()``
///
/// ### Data Management
/// - ``removeWalk(withId:)``
class WalkHistoryViewModel: ObservableObject {

  // MARK: - Published Properties

  /// 現在表示中の散歩データ
  ///
  /// 散歩履歴一覧でユーザーが現在閲覧している散歩のWalkオブジェクトです。
  /// @Publishedにより、値が変更されるとUIに自動反映されます。
  @Published var currentWalk: Walk

  /// 統計バーの表示状態
  ///
  /// 散歩の統計情報（時間、距離、歩数など）を表示するバーの表示/非表示状態。
  /// ユーザーの操作でトグル可能で、デフォルトではtrue（表示）です。
  @Published var isStatsBarVisible: Bool = true

  /// 位置情報読み込み中フラグ
  ///
  /// 散歩の詳細情報（locations）をAPIから読み込み中かどうかを示します。
  /// UIでローディングインジケーター表示の制御に使用します。
  @Published var isLoadingLocations: Bool = false

  // MARK: - Private Properties

  /// 散歩データの配列
  ///
  /// 表示対象となる全ての散歩データを保持します。
  /// 作成日時の降順でソートされた状態で管理されます。
  @Published private var walks: [Walk]

  /// 現在表示中の散歩のインデックス
  ///
  /// walks配列内でのcurrentWalkの位置を示すインデックス値です。
  /// ナビゲーション操作時に更新されます。
  private var currentIndex: Int

  /// 散歩データの永続化層
  ///
  /// 散歩詳細情報（locations含む）の取得に使用するリポジトリです。
  private let walkRepository: WalkRepositoryProtocol

  /// ロガー
  ///
  /// エラーログや操作ログの記録に使用します。
  private let logger = EnhancedVibeLogger.shared

  // MARK: - Error Types

  /// WalkHistoryViewModel初期化時のバリデーションエラー
  ///
  /// ViewModelの初期化時に発生する可能性のあるエラーを定義します。
  /// データの整合性チェックや適切なエラーハンドリングを可能にします。
  ///
  /// ## Topics
  ///
  /// ### Error Cases
  /// - ``emptyWalksArray``
  /// - ``invalidIndex``
  enum ValidationError: Error, Equatable {
    /// 散歩データの配列が空の場合
    ///
    /// ViewModelに渡された散歩データが1件もない場合に発生します。
    /// 散歩履歴が存在しないユーザーやデータ取得エラーの結果です。
    case emptyWalksArray

    /// 初期インデックスが範囲外の値
    ///
    /// 指定された初期インデックスが散歩データ配列の範囲を超えている場合に発生します。
    /// 負の値や配列サイズ以上の値が原因です。
    case invalidIndex
  }

  // MARK: - Initializer

  /// WalkHistoryViewModelを初期化
  ///
  /// 散歩データの配列と初期表示インデックスでViewModelを初期化します。
  /// データの整合性をチェックし、不正な値の場合はエラーをスローします。
  ///
  /// ## Validation
  /// - walks配列が空でないことを確認
  /// - initialIndexがwalk配列の有効な範囲内であることを確認
  ///
  /// ## Note
  /// 初期散歩の位置情報取得は、ViewのonAppearで`loadLocationsForCurrentWalk()`を
  /// 呼び出す必要があります。initで呼び出すとViewがまだObserveを開始しておらず、
  /// @Publishedの変更がUIに反映されません。
  ///
  /// - Parameters:
  ///   - walks: 表示する散歩データの配列（空でないこと）
  ///   - initialIndex: 初期表示する散歩のインデックス（0以上かつwalks.count未満）
  ///   - walkRepository: 散歩詳細取得用のリポジトリ（デフォルト: WalkRepositoryFactory.shared.repository）
  /// - Throws: バリデーションエラー（ValidationError）
  init(
    walks: [Walk],
    initialIndex: Int,
    walkRepository: WalkRepositoryProtocol = WalkRepositoryFactory.shared.repository
  ) throws {
    guard !walks.isEmpty else {
      throw ValidationError.emptyWalksArray
    }

    guard initialIndex >= 0 && initialIndex < walks.count else {
      throw ValidationError.invalidIndex
    }

    self.walks = walks
    self.currentIndex = initialIndex
    self.currentWalk = walks[initialIndex]
    self.walkRepository = walkRepository
  }

  // MARK: - Public Methods

  /// 次の散歩へ遷移
  ///
  /// 現在表示中の散歩の1つ後の散歩へ遷移します。
  /// 最後の散歩の場合は最初の散歩に戻ります（サイクリックナビゲーション）。
  /// 遷移後、新しい散歩の位置情報を非同期で取得します。
  func selectNextWalk() {
    currentIndex = (currentIndex + 1) % walks.count
    currentWalk = walks[currentIndex]
    loadLocationsForCurrentWalk()
  }

  /// 前の散歩へ遷移
  ///
  /// 現在表示中の散歩の1つ前の散歩へ遷移します。
  /// 最初の散歩の場合は最後の散歩に移動します（サイクリックナビゲーション）。
  /// 遷移後、新しい散歩の位置情報を非同期で取得します。
  func selectPreviousWalk() {
    currentIndex = (currentIndex - 1 + walks.count) % walks.count
    currentWalk = walks[currentIndex]
    loadLocationsForCurrentWalk()
  }

  /// 現在の散歩の位置情報を取得
  ///
  /// 詳細APIを呼び出して現在表示中の散歩の位置情報（locations）を取得し、
  /// currentWalkとwalks配列を更新します。
  /// 既に位置情報が読み込まれている場合はAPI呼び出しをスキップします。
  func loadLocationsForCurrentWalk() {
    // 既にlocationsが存在する場合はスキップ
    guard currentWalk.locations.isEmpty else {
      return
    }

    isLoadingLocations = true
    let walkId = currentWalk.id

    walkRepository.fetchWalk(withID: walkId) { [weak self] result in
      Task { @MainActor in
        guard let self = self else { return }
        self.isLoadingLocations = false

        switch result {
        case .success(let detailedWalk):
          // currentWalkのIDが変わっていないことを確認（ユーザーが素早く切り替えた場合の対策）
          guard self.currentWalk.id == walkId else { return }

          // locationsを持つ散歩で更新
          self.currentWalk = detailedWalk

          // walks配列も更新（キャッシュ効果）
          if let index = self.walks.firstIndex(where: { $0.id == walkId }) {
            self.walks[index] = detailedWalk
          }

        case .failure(let error):
          self.logger.logError(
            error,
            operation: "loadLocationsForCurrentWalk",
            humanNote: "位置情報の取得に失敗"
          )
          // エラー時はlocationsなしのまま表示を継続
        }
      }
    }
  }

  /// 統計バーの表示/非表示をトグル
  ///
  /// 散歩の統計情報を表示するバーの表示状態を切り替えます。
  /// ユーザーがマップに集中したい時の非表示や、統計確認のための表示に使用します。
  func toggleStatsBar() {
    isStatsBarVisible.toggle()
  }

  /// 散歩を削除し、適切な次の散歩に遷移する
  ///
  /// 指定されたIDの散歩をリストから削除し、削除後の表示を適切に調整します。
  /// 削除後に残った散歩がある場合は適切な次の散歩に自動遷移します。
  ///
  /// ## Behavior
  /// 1. 削除対象の散歩をIDで検索
  /// 2. 散歩を配列から削除
  /// 3. 削除後の散歩リストが空でない場合は次の散歩を決定
  /// 4. currentWalkとcurrentIndexを更新
  ///
  /// - Parameter walkId: 削除する散歩のID
  /// - Returns: 削除成功時はtrue、散歩が全て削除された場合や失敗時はfalse
  func removeWalk(withId walkId: UUID) -> Bool {
    guard let walkIndex = walks.firstIndex(where: { $0.id == walkId }) else {
      return false  // 削除対象が見つからない
    }

    // 散歩を配列から削除
    walks.remove(at: walkIndex)

    // 削除後に散歩が残っていない場合
    if walks.isEmpty {
      return false  // 画面を閉じる必要がある
    }

    // 次に表示する散歩のインデックスを決定
    let nextIndex = determineNextIndex(deletedIndex: walkIndex)
    currentIndex = nextIndex
    currentWalk = walks[nextIndex]

    // 次の散歩の位置情報を取得
    loadLocationsForCurrentWalk()

    return true  // 削除成功、他の散歩が存在
  }

  /// 削除後に表示する次の散歩のインデックスを決定
  ///
  /// 散歩が削除された後に表示すべき次の散歩のインデックスを決定します。
  /// ユーザーの閲覧コンテキストを保持するため、現在位置に最も近い散歩を選択します。
  ///
  /// ## Algorithm
  /// 1. 削除されたインデックスが現在のインデックスより前：現在のインデックスを1つ前にシフト
  /// 2. 削除されたインデックスが現在のインデックスと同じ：次のアイテムを選択（範囲チェック付き）
  /// 3. 削除されたインデックスが現在のインデックスより後：現在のインデックスを維持
  ///
  /// - Parameter deletedIndex: 削除された散歩のインデックス
  /// - Returns: 次に表示すべき散歩のインデックス
  private func determineNextIndex(deletedIndex: Int) -> Int {
    if deletedIndex < currentIndex {
      // 削除されたインデックスが現在より前の場合、現在のインデックスを1つ前にシフト
      return currentIndex - 1
    } else if deletedIndex == currentIndex {
      // 現在の散歩が削除された場合、より新しい散歩を優先
      // インデックスが小さいほど新しい散歩
      if currentIndex > 0 {
        return currentIndex - 1  // より新しい散歩
      } else if currentIndex < walks.count {
        return currentIndex  // 次のアイテム（削除により1つシフトされた）
      } else {
        return walks.count - 1  // 最後のアイテム
      }
    } else {
      // 削除されたインデックスが現在より後の場合、現在のインデックスを維持
      return currentIndex
    }
  }

  /// 現在の散歩リストの数を取得
  ///
  /// ViewModelが管理している散歩データの総数を返します。
  /// UI表示での散歩リストの件数表示やページング制御に使用されます。
  ///
  /// - Returns: 散歩データの総数
  var walkCount: Int {
    walks.count
  }
}
