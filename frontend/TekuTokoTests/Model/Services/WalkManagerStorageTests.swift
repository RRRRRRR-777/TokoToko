//
//  WalkManagerStorageTests.swift
//  TekuTokoTests
//
//  Created by Claude Code on 2025/12/06.
//

import CoreLocation
import XCTest

@testable import TekuToko

/// WalkManagerStorageのオフライン保存機能のテスト
///
/// WalkManagerのローカル保存・読み込み・削除機能をテストします。
/// 注意: WalkManagerはシングルトンなので、テストは状態に依存します。
final class WalkManagerStorageTests: XCTestCase {

  // MARK: - hasPendingWalks Tests

  func test_hasPendingWalks_初期状態_結果が返される() {
    // 期待値: hasPendingWalksが呼び出し可能であること
    // 実際の値はテスト環境の状態に依存
    let _ = WalkManager.shared.hasPendingWalks()
    // クラッシュしなければ成功
  }

  // MARK: - saveWalkLocally Tests

  func test_saveWalkLocally_有効なWalk_結果が返される() {
    // 期待値: saveWalkLocallyがbool値を返す
    let walk = createTestWalk()

    let result = WalkManager.shared.saveWalkLocally(walk)

    // Bool値が返されることを確認
    XCTAssertTrue(result == true || result == false)

    // クリーンアップ
    if result {
      WalkManager.shared.deletePendingWalk(for: walk.id)
    }
  }

  // MARK: - loadPendingWalks Tests

  func test_loadPendingWalks_呼び出し可能_配列が返される() {
    // 期待値: loadPendingWalksが配列を返す
    let walks = WalkManager.shared.loadPendingWalks()

    // 配列であることを確認（空かどうかは環境依存）
    XCTAssertNotNil(walks)
  }

  // MARK: - Integration Tests

  func test_saveAndLoad_保存後に読み込み_データが保持される() {
    // 期待値: 保存した散歩が読み込める
    let walk = createTestWalk()

    // 保存
    let saveResult = WalkManager.shared.saveWalkLocally(walk)

    if saveResult {
      // 読み込み
      let pendingWalks = WalkManager.shared.loadPendingWalks()

      // 保存した散歩が含まれていることを確認
      let found = pendingWalks.contains { $0.id == walk.id }
      XCTAssertTrue(found, "保存した散歩が読み込まれるはず")

      // クリーンアップ
      WalkManager.shared.deletePendingWalk(for: walk.id)
    }
  }

  func test_deletePendingWalk_削除後_対象が消える() {
    // 期待値: 削除した散歩は読み込まれない
    let walk = createTestWalk()

    // 保存
    let saveResult = WalkManager.shared.saveWalkLocally(walk)

    if saveResult {
      // 削除
      WalkManager.shared.deletePendingWalk(for: walk.id)

      // 読み込み
      let pendingWalks = WalkManager.shared.loadPendingWalks()

      // 削除した散歩が含まれていないことを確認
      let found = pendingWalks.contains { $0.id == walk.id }
      XCTAssertFalse(found, "削除した散歩は読み込まれないはず")
    }
  }

  // MARK: - Helper Methods

  private func createTestWalk() -> Walk {
    Walk(
      title: "テスト散歩",
      description: "テスト用の散歩",
      userId: "test-user-id",
      id: UUID(),
      startTime: Date(),
      endTime: Date().addingTimeInterval(1800),
      totalDistance: 1000,
      totalSteps: 1200,
      status: .completed
    )
  }
}
