//
//  WalkHistoryViewModel.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/12.
//

import Combine
import Foundation

class WalkHistoryViewModel: ObservableObject {

  // MARK: - Published Properties
  @Published var currentWalk: Walk
  @Published var isStatsBarVisible: Bool = true
  @Published var selectedImageIndex: Int? = nil

  // MARK: - Private Properties
  @Published private var walks: [Walk]
  private var currentIndex: Int

  // MARK: - Error Types
  enum ValidationError: Error, Equatable {
    case emptyWalksArray
    case invalidIndex
  }

  // MARK: - Initializer
  init(walks: [Walk], initialIndex: Int) throws {
    guard !walks.isEmpty else {
      throw ValidationError.emptyWalksArray
    }

    guard initialIndex >= 0 && initialIndex < walks.count else {
      throw ValidationError.invalidIndex
    }

    self.walks = walks
    self.currentIndex = initialIndex
    self.currentWalk = walks[initialIndex]
  }

  // MARK: - Public Methods

  func selectNextWalk() {
    currentIndex = (currentIndex + 1) % walks.count
    currentWalk = walks[currentIndex]
  }

  func selectPreviousWalk() {
    currentIndex = (currentIndex - 1 + walks.count) % walks.count
    currentWalk = walks[currentIndex]
  }

  func toggleStatsBar() {
    isStatsBarVisible.toggle()
  }

  func selectImage(at index: Int) {
    selectedImageIndex = index
  }

  func deselectImage() {
    selectedImageIndex = nil
  }

  /// 散歩を削除し、適切な次の散歩に遷移する
  /// - Parameter walkId: 削除する散歩のID
  /// - Returns: 削除成功時はtrue、散歩が全て削除された場合や失敗時はfalse
  func removeWalk(withId walkId: UUID) -> Bool {
    guard let walkIndex = walks.firstIndex(where: { $0.id == walkId }) else {
      return false // 削除対象が見つからない
    }
    
    // 散歩を配列から削除
    walks.remove(at: walkIndex)
    
    // 削除後に散歩が残っていない場合
    if walks.isEmpty {
      return false // 画面を閉じる必要がある
    }
    
    // 次に表示する散歩のインデックスを決定
    let nextIndex = determineNextIndex(deletedIndex: walkIndex)
    currentIndex = nextIndex
    currentWalk = walks[nextIndex]
    
    return true // 削除成功、他の散歩が存在
  }
  
  /// 削除後に表示する次の散歩のインデックスを決定
  private func determineNextIndex(deletedIndex: Int) -> Int {
    // 削除したインデックスが現在のインデックスより前の場合、
    // 現在のインデックスを調整
    if deletedIndex < currentIndex {
      currentIndex = max(0, currentIndex - 1)
    }
    
    // 現在のインデックスが配列の範囲外になった場合の調整
    if currentIndex >= walks.count {
      currentIndex = walks.count - 1
    }
    
    // 1つ後の履歴を優先（作成日時が後の履歴）
    // 散歩は作成日時の降順でソートされているため、インデックスが小さいほど新しい
    if currentIndex > 0 {
      return currentIndex - 1 // より新しい散歩（1つ後の履歴）
    } else {
      // 1つ後がない場合は現在のインデックス（または1つ前）
      return currentIndex
    }
  }
  
  /// 現在の散歩リストの数を取得
  var walkCount: Int {
    return walks.count
  }
}
