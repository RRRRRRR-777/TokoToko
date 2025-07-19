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
  private let walks: [Walk]
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
}
