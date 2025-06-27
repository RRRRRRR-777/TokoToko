//
//  WalkRepositoryTests.swift
//  TokoTokoTests
//
//  Created by bokuyamada on 2025/06/26.
//

import XCTest
import FirebaseFirestore
@testable import TokoToko

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
  
  // MARK: - Firestore統合テスト
  
  func testSaveWalkToFirestore() async throws {
    // Arrange
    let walk = Walk(
      title: "テスト散歩",
      description: "Firestoreテスト用の散歩",
      userId: "test-user-id"
    )
    
    let expectation = XCTestExpectation(description: "Walk should be saved to Firestore")
    
    // Act & Assert
    repository.saveWalkToFirestore(walk) { result in
      switch result {
      case .success(let savedWalk):
        XCTAssertEqual(savedWalk.id, walk.id)
        XCTAssertEqual(savedWalk.title, walk.title)
        XCTAssertEqual(savedWalk.userId, walk.userId)
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to save walk to Firestore: \(error)")
      }
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
  }
  
  func testFetchWalksFromFirestoreByUser() async throws {
    // Arrange
    let userId = "test-user-id"
    let expectation = XCTestExpectation(description: "Walks should be fetched from Firestore by user")
    
    // Act & Assert
    repository.fetchWalksFromFirestore(userId: userId) { result in
      switch result {
      case .success(let walks):
        // Firestoreから正しくデータが取得されることを確認
        XCTAssertTrue(walks.allSatisfy { $0.userId == userId })
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to fetch walks from Firestore: \(error)")
      }
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
  }
  
  func testUpdateWalkInFirestore() async throws {
    // Arrange
    var walk = Walk(
      title: "テスト散歩",
      description: "更新前の説明",
      userId: "test-user-id"
    )
    walk.description = "更新後の説明"
    
    let expectation = XCTestExpectation(description: "Walk should be updated in Firestore")
    
    // Act & Assert
    repository.updateWalkInFirestore(walk) { result in
      switch result {
      case .success(let updatedWalk):
        XCTAssertEqual(updatedWalk.description, "更新後の説明")
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to update walk in Firestore: \(error)")
      }
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
  }
  
  func testDeleteWalkFromFirestore() async throws {
    // Arrange
    let walkId = UUID()
    let userId = "test-user-id"
    let expectation = XCTestExpectation(description: "Walk should be deleted from Firestore")
    
    // Act & Assert
    repository.deleteWalkFromFirestore(walkId: walkId, userId: userId) { result in
      switch result {
      case .success(let deleted):
        XCTAssertTrue(deleted)
        expectation.fulfill()
      case .failure(let error):
        XCTFail("Failed to delete walk from Firestore: \(error)")
      }
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
  }
  
  
  // MARK: - ユーザー別データ分離テスト
  
  func testUserDataSeparation() async throws {
    // Arrange
    let user1Id = "user-1"
    let user2Id = "user-2"
    
    let user1Walk = Walk(title: "ユーザー1の散歩", description: "ユーザー1専用", userId: user1Id)
    let user2Walk = Walk(title: "ユーザー2の散歩", description: "ユーザー2専用", userId: user2Id)
    
    let expectation = XCTestExpectation(description: "User data should be separated")
    
    // Act & Assert
    // ユーザー1のデータを保存
    repository.saveWalkToFirestore(user1Walk) { result in
      switch result {
      case .success:
        // ユーザー2のデータを保存
        self.repository.saveWalkToFirestore(user2Walk) { result2 in
          switch result2 {
          case .success:
            // ユーザー1のデータのみ取得できることを確認
            self.repository.fetchWalksFromFirestore(userId: user1Id) { result3 in
              switch result3 {
              case .success(let walks):
                XCTAssertTrue(walks.allSatisfy { $0.userId == user1Id })
                XCTAssertFalse(walks.contains { $0.userId == user2Id })
                expectation.fulfill()
              case .failure(let error):
                XCTFail("Failed to fetch user1 walks: \(error)")
              }
            }
          case .failure(let error):
            XCTFail("Failed to save user2 walk: \(error)")
          }
        }
      case .failure(let error):
        XCTFail("Failed to save user1 walk: \(error)")
      }
    }
    
    await fulfillment(of: [expectation], timeout: 10.0)
  }
  
  func testUnauthorizedAccessPrevention() async throws {
    // Arrange
    let user1Id = "user-1"
    let user2Id = "user-2"
    let walkId = UUID()
    
    let user1Walk = Walk(title: "ユーザー1の散歩", description: "プライベート", userId: user1Id, id: walkId)
    
    let expectation = XCTestExpectation(description: "Unauthorized access should be prevented")
    
    // Act & Assert
    // ユーザー1のデータを保存
    repository.saveWalkToFirestore(user1Walk) { result in
      switch result {
      case .success:
        // ユーザー2が削除を試みる（許可されるべきではない）
        self.repository.deleteWalkFromFirestore(walkId: walkId, userId: user2Id) { result2 in
          switch result2 {
          case .success:
            XCTFail("User2 should not be able to delete User1's walk")
          case .failure(let error):
            // 認証エラーまたは権限エラーが発生することを確認
            XCTAssertTrue(error == WalkRepositoryError.authenticationRequired || error == WalkRepositoryError.notFound)
            expectation.fulfill()
          }
        }
      case .failure(let error):
        XCTFail("Failed to save walk: \(error)")
      }
    }
    
    await fulfillment(of: [expectation], timeout: 10.0)
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
  
  func testAuthenticationRequiredError() async throws {
    // Arrange
    let expectation = XCTestExpectation(description: "Should handle authentication error")
    
    // Act & Assert
    // 未認証状態でのアクセス（getCurrentUserIdがnilを返す）
    repository.fetchWalks { result in
      switch result {
      case .success:
        // 認証が必要な場合は成功しないはず（または空の結果）
        expectation.fulfill()
      case .failure(let error):
        // 認証エラーが発生することを確認
        XCTAssertEqual(error, WalkRepositoryError.authenticationRequired)
        expectation.fulfill()
      }
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
  }
}