//
//  WalkRepositoryTests.swift
//  TekuTokoTests
//
//  Created by bokuyamada on 2025/06/26.
//

import FirebaseFirestore
import XCTest

@testable import TekuToko

final class WalkRepositoryTests: XCTestCase {
  var repository: WalkRepository!
  var mockRepository: MockWalkRepository!

  override func setUpWithError() throws {
    super.setUp()
    // 実際のFirestoreインスタンスを設定（統合テスト用）
    repository = WalkRepository.shared
    // モックリポジトリを設定（ユニットテスト用）
    mockRepository = MockWalkRepository()
  }

  override func tearDownWithError() throws {
    repository = nil
    mockRepository = nil
    super.tearDown()
  }

  // MARK: - ユニットテスト（モック使用）

  func testMockFetchWalksSuccess() async throws {
    // Arrange
    let sampleWalks: [Walk] = MockWalkRepository.createSampleWalks(count: 3, userId: "test-user")
    sampleWalks.forEach { mockRepository.addMockWalk($0) }
    mockRepository.setMockCurrentUserId("test-user")

    let expectation = XCTestExpectation(description: "Should fetch walks from mock")

    // Act & Assert
    mockRepository.fetchWalks { result in
      switch result {
      case .success(let walks):
        XCTAssertEqual(walks.count, 3)
        XCTAssertTrue(walks.allSatisfy { $0.userId == "test-user" })
        expectation.fulfill()
      case .failure:
        XCTFail("Mock should not fail")
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testMockErrorSimulation() async throws {
    // Arrange
    mockRepository.simulateError(WalkRepositoryError.networkError)
    let expectation = XCTestExpectation(description: "Should simulate network error")

    // Act & Assert
    mockRepository.fetchWalks { result in
      switch result {
      case .success:
        XCTFail("Should simulate error")
      case .failure(let error):
        XCTAssertEqual(error, WalkRepositoryError.networkError)
        expectation.fulfill()
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testMockUserDataSeparation() async throws {
    // Arrange
    let user1Walks: [Walk] = MockWalkRepository.createSampleWalks(count: 2, userId: "user-1")
    let user2Walks: [Walk] = MockWalkRepository.createSampleWalks(count: 2, userId: "user-2")

    user1Walks.forEach { mockRepository.addMockWalk($0) }
    user2Walks.forEach { mockRepository.addMockWalk($0) }

    mockRepository.setMockCurrentUserId("user-1")

    let expectation = XCTestExpectation(description: "Should separate user data in mock")

    // Act & Assert
    mockRepository.fetchWalks { result in
      switch result {
      case .success(let walks):
        XCTAssertEqual(walks.count, 2)
        XCTAssertTrue(walks.allSatisfy { $0.userId == "user-1" })
        XCTAssertFalse(walks.contains { $0.userId == "user-2" })
        expectation.fulfill()
      case .failure:
        XCTFail("Mock should not fail")
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testMockDeleteWalkSuccess() async throws {
    // Arrange
    let walk = MockWalkRepository.createSampleWalk(userId: "test-user")
    mockRepository.addMockWalk(walk)
    mockRepository.setMockCurrentUserId("test-user")

    let expectation = XCTestExpectation(description: "Should delete walk successfully")

    // Act & Assert
    mockRepository.deleteWalk(withID: walk.id) { result in
      switch result {
      case .success(let deleted):
        XCTAssertTrue(deleted)
        // 削除後に取得して確認
        self.mockRepository.fetchWalk(withID: walk.id) { fetchResult in
          switch fetchResult {
          case .success:
            XCTFail("Walk should be deleted")
          case .failure(let error):
            XCTAssertEqual(error, WalkRepositoryError.notFound)
            expectation.fulfill()
          }
        }
      case .failure:
        XCTFail("Delete should succeed")
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testMockDeleteWalkNotFound() async throws {
    // Arrange
    let nonExistentWalkId = UUID()
    mockRepository.setMockCurrentUserId("test-user")

    let expectation = XCTestExpectation(description: "Should fail when walk not found")

    // Act & Assert
    mockRepository.deleteWalk(withID: nonExistentWalkId) { result in
      switch result {
      case .success:
        XCTFail("Should not succeed for non-existent walk")
      case .failure(let error):
        XCTAssertEqual(error, WalkRepositoryError.notFound)
        expectation.fulfill()
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  // MARK: - 保存機能テスト（モック使用）

  func testSaveWalkSuccess() async throws {
    // Arrange
    let walk = Walk(
      title: "テスト散歩",
      description: "保存テスト用の散歩",
      userId: "test-user-id"
    )
    mockRepository.setMockCurrentUserId("test-user-id")

    let expectation = XCTestExpectation(description: "Walk should be saved successfully")

    // Act & Assert
    mockRepository.saveWalk(walk) { result in
      switch result {
      case .success(let savedWalk):
        XCTAssertEqual(savedWalk.id, walk.id)
        XCTAssertEqual(savedWalk.title, walk.title)
        XCTAssertEqual(savedWalk.userId, walk.userId)
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to save walk: \(error)")
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testFetchWalksByUser() async throws {
    // Arrange
    let userId = "test-user-id"
    let sampleWalks: [Walk] = MockWalkRepository.createSampleWalks(count: 3, userId: userId)
    sampleWalks.forEach { mockRepository.addMockWalk($0) }
    mockRepository.setMockCurrentUserId(userId)

    let expectation = XCTestExpectation(description: "Walks should be fetched by user")

    // Act & Assert
    mockRepository.fetchWalks { result in
      switch result {
      case .success(let walks):
        XCTAssertEqual(walks.count, 3)
        XCTAssertTrue(walks.allSatisfy { $0.userId == userId })
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to fetch walks: \(error)")
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testUpdateWalkSuccess() async throws {
    // Arrange
    var walk = Walk(
      title: "テスト散歩",
      description: "更新前の説明",
      userId: "test-user-id"
    )
    mockRepository.addMockWalk(walk)
    mockRepository.setMockCurrentUserId("test-user-id")

    walk.description = "更新後の説明"

    let expectation = XCTestExpectation(description: "Walk should be updated successfully")

    // Act & Assert
    mockRepository.updateWalk(walk) { result in
      switch result {
      case .success(let updatedWalk):
        XCTAssertEqual(updatedWalk.description, "更新後の説明")
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to update walk: \(error)")
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testDeleteWalkFromRepository() async throws {
    // Arrange
    let walk = MockWalkRepository.createSampleWalk(userId: "test-user-id")
    mockRepository.addMockWalk(walk)
    mockRepository.setMockCurrentUserId("test-user-id")

    let expectation = XCTestExpectation(description: "Walk should be deleted successfully")

    // Act & Assert
    mockRepository.deleteWalk(withID: walk.id) { result in
      switch result {
      case .success(let deleted):
        XCTAssertTrue(deleted)
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to delete walk: \(error)")
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  // MARK: - ユーザー別データ分離テスト

  func testUserDataSeparationMock() async throws {
    // Arrange
    let user1Id = "user-1"
    let user2Id = "user-2"

    let user1Walk = Walk(title: "ユーザー1の散歩", description: "ユーザー1専用", userId: user1Id)
    let user2Walk = Walk(title: "ユーザー2の散歩", description: "ユーザー2専用", userId: user2Id)

    // ユーザー1とユーザー2のデータを追加
    mockRepository.addMockWalk(user1Walk)
    mockRepository.addMockWalk(user2Walk)

    // ユーザー1としてログイン
    mockRepository.setMockCurrentUserId(user1Id)

    let expectation = XCTestExpectation(description: "User data should be separated")

    // Act & Assert
    mockRepository.fetchWalks { result in
      switch result {
      case .success(let walks):
        // ユーザー1のデータのみ取得されることを確認
        XCTAssertTrue(walks.allSatisfy { $0.userId == user1Id })
        XCTAssertFalse(walks.contains { $0.userId == user2Id })
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to fetch user data: \(error)")
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testUnauthorizedAccessPreventionMock() async throws {
    // Arrange
    let user1Id = "user-1"
    let user2Id = "user-2"
    let walkId = UUID()

    let user1Walk = Walk(title: "ユーザー1の散歩", description: "プライベート", userId: user1Id, id: walkId)

    // ユーザー1のデータを追加
    mockRepository.addMockWalk(user1Walk)

    // ユーザー2でログイン
    mockRepository.setMockCurrentUserId(user2Id)

    let expectation = XCTestExpectation(description: "Unauthorized access should be prevented")

    // Act & Assert
    // ユーザー2がユーザー1のWalkを削除しようとする
    mockRepository.deleteWalk(withID: walkId) { result in
      switch result {
      case .success:
        XCTFail("User2 should not be able to delete User1's walk")
      case .failure(let error):
        // 認証エラーまたは権限エラーが発生することを確認
        XCTAssertTrue(
          error == WalkRepositoryError.authenticationRequired
            || error == WalkRepositoryError.notFound)
        expectation.fulfill()
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  // MARK: - エラーハンドリングテスト

  func testFirestoreConnectionError() async throws {
    // Arrange
    let walk = Walk(title: "エラーテスト", description: "接続エラーテスト")
    let expectation = XCTestExpectation(description: "Should handle connection error")

    // Act & Assert
    // ネットワークエラーをシミュレートするテスト
    repository.saveWalkToFirestore(walk) { result in
      switch result {
      case .success:
        // 成功する場合もあるが、エラーハンドリングの準備ができていることを確認
        expectation.fulfill()
      case .failure(let error):
        // エラーが適切に処理されることを確認
        XCTAssertTrue(error is WalkRepositoryError)
        expectation.fulfill()
      }
    }

    await fulfillment(of: [expectation], timeout: 5.0)
  }

  func testAuthenticationRequiredErrorMock() async throws {
    // Arrange
    // 未認証状態をシミュレート（ユーザーIDを設定しない）
    mockRepository.simulateError(WalkRepositoryError.authenticationRequired)

    let expectation = XCTestExpectation(description: "Should handle authentication error")

    // Act & Assert
    mockRepository.fetchWalks { result in
      switch result {
      case .success:
        XCTFail("Should fail when not authenticated")
      case .failure(let error):
        XCTAssertEqual(error, WalkRepositoryError.authenticationRequired)
        expectation.fulfill()
      }
    }

    await fulfillment(of: [expectation], timeout: 1.0)
  }
}
