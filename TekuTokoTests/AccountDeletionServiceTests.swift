//
//  AccountDeletionServiceTests.swift
//  TekuTokoTests
//
//  Created by Claude Code on 2025/10/04.
//

import XCTest
@testable import TekuToko

/// AccountDeletionServiceのテストクラス
///
/// アカウント削除機能の正常系・異常系をテストします。
final class AccountDeletionServiceTests: XCTestCase {

  // MARK: - Properties

  var sut: AccountDeletionService!

  // MARK: - Setup & Teardown

  override func setUp() {
    super.setUp()
    sut = AccountDeletionService()
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  // MARK: - Tests

  /// 【正常系】ユーザー認証済みの場合、アカウント削除が成功すること
  func testDeleteAccount_WhenUserAuthenticated_Success() async throws {
    // Given: ユーザーが認証済み（モック環境）
    // テスト環境ではFirebaseAuthHelperがモックユーザーIDを返す

    // When: アカウント削除を実行
    let result = await sut.deleteAccount()

    // Then: 削除が成功すること
    switch result {
    case .success:
      XCTAssert(true, "アカウント削除が成功")
    case .failure(let error):
      XCTFail("削除が成功すべきだが失敗: \(error)")
    }
  }

  /// 【異常系】ユーザー未認証の場合、エラーが返却されること
  func testDeleteAccount_WhenUserNotAuthenticated_ReturnsError() async throws {
    // Given: ユーザー未認証状態（実装時にモック化が必要）
    // TODO: モック実装後に追加

    // When: アカウント削除を実行
    let result = await sut.deleteAccount()

    // Then: 未認証エラーが返却されること
    switch result {
    case .success:
      XCTFail("未認証のため削除は失敗すべき")
    case .failure(let error):
      XCTAssertEqual(
        error,
        "ユーザーが認証されていません",
        "未認証エラーメッセージが正しいこと"
      )
    }
  }

  /// 【異常系】Firebase削除処理が失敗した場合、エラーが返却されること
  func testDeleteAccount_WhenFirebaseDeletionFails_ReturnsError() async throws {
    // Given: Firebase削除が失敗する状態（モック化が必要）
    // TODO: モック実装後に追加

    // When: アカウント削除を実行
    let result = await sut.deleteAccount()

    // Then: 削除エラーが返却されること
    switch result {
    case .success:
      XCTFail("Firebase削除失敗のため全体も失敗すべき")
    case .failure:
      XCTAssert(true, "削除エラーが返却された")
    }
  }
}
