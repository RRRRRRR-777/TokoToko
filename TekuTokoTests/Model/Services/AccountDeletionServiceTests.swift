//
//  AccountDeletionServiceTests.swift
//  TekuTokoTests
//
//  Created by Claude Code on 2025/10/04.
//

import FirebaseFirestore
import FirebaseStorage
import XCTest

@testable import TekuToko

// MARK: - Mocks

/// モックFirebase認証ヘルパー
class MockFirebaseAuthHelper: FirebaseAuthHelperProtocol {
  var userIdToReturn: String?

  func getCurrentUserId() -> String? {
    userIdToReturn
  }
}

/// モックFirebaseユーザー
class MockFirebaseUser: FirebaseUserProtocol {
  var shouldThrowError = false
  var deleteCallCount = 0

  func delete() async throws {
    deleteCallCount += 1
    if shouldThrowError {
      throw NSError(
        domain: "com.test.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "モック削除エラー"])
    }
  }
}

/// モックFirestore
class MockFirestore: FirestoreProtocol {
  func collection(_ collectionPath: String) -> CollectionReference {
    // テスト用のダミー実装
    // 実際には使用されないが、プロトコル準拠のために必要
    return Firestore.firestore().collection(collectionPath)
  }
}

/// モックStorage
class MockStorage: StorageProtocol {
  func reference() -> StorageReference {
    // テスト用のダミー実装
    // 実際には使用されないが、プロトコル準拠のために必要
    return Storage.storage().reference()
  }
}

/// AccountDeletionServiceのテストクラス
///
/// アカウント削除機能の正常系・異常系をテストします。
final class AccountDeletionServiceTests: XCTestCase {

  // MARK: - Properties

  var sut: AccountDeletionService!
  var mockAuthHelper: MockFirebaseAuthHelper!
  var mockUser: MockFirebaseUser!

  // MARK: - Setup & Teardown

  override func setUp() {
    super.setUp()
    mockAuthHelper = MockFirebaseAuthHelper()
    mockUser = MockFirebaseUser()
    // デフォルトでは認証済みユーザーとして設定
    mockAuthHelper.userIdToReturn = "test-user-id"
  }

  override func tearDown() {
    sut = nil
    mockAuthHelper = nil
    mockUser = nil
    super.tearDown()
  }

  // MARK: - Tests

  /// 【正常系】ユーザー認証済みの場合、アカウント削除が成功すること
  func testDeleteAccount_WhenUserAuthenticated_Success() async throws {
    // Given: ユーザーが認証済み
    sut = AccountDeletionService(
      authHelper: mockAuthHelper,
      db: MockFirestore(),
      storage: MockStorage(),
      getCurrentUser: { self.mockUser },
      skipTestEnvironmentCheck: true
    )

    // When: アカウント削除を実行
    let result = await sut.deleteAccount()

    // Then: 削除が成功すること
    switch result {
    case .success:
      XCTAssertEqual(mockUser.deleteCallCount, 1, "ユーザー削除が1回呼ばれるべき")
    case .failure(let error):
      XCTFail("削除が成功すべきだが失敗: \(error)")
    }
  }

  /// 【異常系】ユーザー未認証の場合、エラーが返却されること
  func testDeleteAccount_WhenUserNotAuthenticated_ReturnsError() async throws {
    // Given: ユーザー未認証状態
    mockAuthHelper.userIdToReturn = nil
    sut = AccountDeletionService(
      authHelper: mockAuthHelper,
      db: MockFirestore(),
      storage: MockStorage(),
      getCurrentUser: { self.mockUser },
      skipTestEnvironmentCheck: true
    )

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

  /// 【異常系】Firebase Auth削除処理が失敗した場合、エラーが返却されること
  func testDeleteAccount_WhenFirebaseDeletionFails_ReturnsError() async throws {
    // Given: Firebase Auth削除が失敗する状態
    mockUser.shouldThrowError = true
    sut = AccountDeletionService(
      authHelper: mockAuthHelper,
      db: MockFirestore(),
      storage: MockStorage(),
      getCurrentUser: { self.mockUser },
      skipTestEnvironmentCheck: true
    )

    // When: アカウント削除を実行
    let result = await sut.deleteAccount()

    // Then: 削除エラーが返却されること
    switch result {
    case .success:
      XCTFail("Firebase削除失敗のため全体も失敗すべき")
    case .failure(let error):
      XCTAssertEqual(error, "アカウント削除に失敗しました", "エラーメッセージが正しいこと")
    }
  }
}
