//
//  GoBackendWalkRepositoryTests.swift
//  TekuTokoTests
//
//  Created by Claude Code on 2025/12/02.
//

import XCTest

@testable import TekuToko

// MARK: - GoBackendWalkRepositoryTests

final class GoBackendWalkRepositoryTests: XCTestCase {

  // MARK: - Properties

  var sut: GoBackendWalkRepository!
  var mockAPIClient: MockAPIClient!

  // MARK: - Setup / Teardown

  override func setUp() {
    super.setUp()
    mockAPIClient = MockAPIClient()
    sut = GoBackendWalkRepository(apiClient: mockAPIClient)
  }

  override func tearDown() {
    sut = nil
    mockAPIClient = nil
    super.tearDown()
  }

  // MARK: - fetchWalks Tests

  func test_fetchWalks_正常系_散歩一覧を取得できる() {
    // 期待値: APIから取得したWalkDTOがWalkに変換されて返される
    let walkDTO = createTestWalkDTO()
    let response = WalksListResponse(
      data: [walkDTO],
      meta: createMeta()
    )
    mockAPIClient.mockResult = response

    let expectation = expectation(description: "fetchWalks")
    var result: Result<[Walk], WalkRepositoryError>?

    sut.fetchWalks { fetchResult in
      result = fetchResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    // 検証: 成功し、Walkが1件返される
    guard case .success(let walks) = result else {
      XCTFail("期待される成功結果が返されなかった")
      return
    }
    XCTAssertEqual(walks.count, 1)
    XCTAssertEqual(walks.first?.id.uuidString.lowercased(), walkDTO.id.lowercased())
    XCTAssertEqual(walks.first?.title, walkDTO.title)
  }

  func test_fetchWalks_認証エラー_authenticationRequiredを返す() {
    // 期待値: 401エラー時にauthenticationRequiredが返される
    mockAPIClient.mockError = APIClientError.authenticationRequired

    let expectation = expectation(description: "fetchWalks")
    var result: Result<[Walk], WalkRepositoryError>?

    sut.fetchWalks { fetchResult in
      result = fetchResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    guard case .failure(let error) = result else {
      XCTFail("期待されるエラー結果が返されなかった")
      return
    }
    XCTAssertEqual(error, .authenticationRequired)
  }

  func test_fetchWalks_ネットワークエラー_networkErrorを返す() {
    // 期待値: ネットワークエラー時にnetworkErrorが返される
    mockAPIClient.mockError = APIClientError.networkError(URLError(.notConnectedToInternet))

    let expectation = expectation(description: "fetchWalks")
    var result: Result<[Walk], WalkRepositoryError>?

    sut.fetchWalks { fetchResult in
      result = fetchResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    guard case .failure(let error) = result else {
      XCTFail("期待されるエラー結果が返されなかった")
      return
    }
    XCTAssertEqual(error, .networkError)
  }

  // MARK: - fetchWalk Tests

  func test_fetchWalk_正常系_散歩詳細を取得できる() {
    // 期待値: 指定IDの散歩を取得できる
    let walkDTO = createTestWalkDTO()
    let response = WalkDetailResponse(
      data: walkDTO,
      meta: createMeta()
    )
    mockAPIClient.mockResult = response

    let expectation = expectation(description: "fetchWalk")
    let walkId = UUID(uuidString: walkDTO.id) ?? UUID()
    var result: Result<Walk, WalkRepositoryError>?

    sut.fetchWalk(withID: walkId) { fetchResult in
      result = fetchResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    guard case .success(let walk) = result else {
      XCTFail("期待される成功結果が返されなかった")
      return
    }
    XCTAssertEqual(walk.id.uuidString.lowercased(), walkDTO.id.lowercased())
    XCTAssertEqual(walk.title, walkDTO.title)
  }

  func test_fetchWalk_404エラー_notFoundを返す() {
    // 期待値: 存在しないWalkを取得しようとするとnotFoundエラー
    mockAPIClient.mockError = APIClientError.notFound

    let expectation = expectation(description: "fetchWalk")
    var result: Result<Walk, WalkRepositoryError>?

    sut.fetchWalk(withID: UUID()) { fetchResult in
      result = fetchResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    guard case .failure(let error) = result else {
      XCTFail("期待されるエラー結果が返されなかった")
      return
    }
    XCTAssertEqual(error, .notFound)
  }

  // MARK: - createWalk Tests

  func test_createWalk_正常系_散歩を作成できる() {
    // 期待値: 新しい散歩が作成される
    let walkDTO = createTestWalkDTO()
    let response = WalkDetailResponse(
      data: walkDTO,
      meta: createMeta()
    )
    mockAPIClient.mockResult = response

    let expectation = expectation(description: "createWalk")
    var result: Result<Walk, WalkRepositoryError>?

    sut.createWalk(title: "テスト散歩", description: "テスト説明", location: nil) { createResult in
      result = createResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    guard case .success(let walk) = result else {
      XCTFail("期待される成功結果が返されなかった")
      return
    }
    XCTAssertEqual(walk.title, walkDTO.title)
  }

  // MARK: - updateWalk Tests

  func test_updateWalk_正常系_散歩を更新できる() {
    // 期待値: 散歩が更新される
    let walkDTO = createTestWalkDTO()
    let response = WalkDetailResponse(
      data: walkDTO,
      meta: createMeta()
    )
    mockAPIClient.mockResult = response

    let expectation = expectation(description: "updateWalk")
    let walk = Walk(title: "更新前", description: "説明", id: UUID(uuidString: walkDTO.id) ?? UUID())
    var result: Result<Walk, WalkRepositoryError>?

    sut.updateWalk(walk) { updateResult in
      result = updateResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    guard case .success(let updatedWalk) = result else {
      XCTFail("期待される成功結果が返されなかった")
      return
    }
    XCTAssertEqual(updatedWalk.id.uuidString.lowercased(), walkDTO.id.lowercased())
  }

  // MARK: - deleteWalk Tests

  func test_deleteWalk_正常系_散歩を削除できる() {
    // 期待値: 散歩が削除される
    mockAPIClient.mockDeleteSuccess = true

    let expectation = expectation(description: "deleteWalk")
    var result: Result<Bool, WalkRepositoryError>?

    sut.deleteWalk(withID: UUID()) { deleteResult in
      result = deleteResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    guard case .success(let success) = result else {
      XCTFail("期待される成功結果が返されなかった")
      return
    }
    XCTAssertTrue(success)
  }

  func test_deleteWalk_404エラー_notFoundを返す() {
    // 期待値: 存在しないWalkを削除しようとするとnotFoundエラー
    mockAPIClient.mockError = APIClientError.notFound

    let expectation = expectation(description: "deleteWalk")
    var result: Result<Bool, WalkRepositoryError>?

    sut.deleteWalk(withID: UUID()) { deleteResult in
      result = deleteResult
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    guard case .failure(let error) = result else {
      XCTFail("期待されるエラー結果が返されなかった")
      return
    }
    XCTAssertEqual(error, .notFound)
  }

  // MARK: - Helper Methods

  private func createTestWalkDTO() -> WalkDTO {
    WalkDTO(
      id: "550e8400-e29b-41d4-a716-446655440000",
      userId: "test-user-id",
      title: "テスト散歩",
      description: "テスト説明",
      startTime: nil,
      endTime: nil,
      totalDistance: 0.0,
      totalSteps: 0,
      polylineData: nil,
      thumbnailImageUrl: nil,
      status: .notStarted,
      pausedAt: nil,
      totalPausedDuration: 0.0,
      createdAt: Date(),
      updatedAt: Date()
    )
  }

  private func createMeta() -> APIResponseMeta {
    APIResponseMeta(
      requestId: "test-request-id",
      timestamp: Date()
    )
  }
}

// MARK: - MockAPIClient

class MockAPIClient: APIClientProtocol {
  var mockResult: Any?
  var mockError: APIClientError?
  var mockDeleteSuccess = false
  var lastPath: String?
  var lastBody: Any?

  func get<T: Decodable>(path: String) async throws -> T {
    lastPath = path
    if let error = mockError {
      throw error
    }
    guard let result = mockResult as? T else {
      throw APIClientError.invalidData
    }
    return result
  }

  func post<T: Decodable, U: Encodable>(path: String, body: U) async throws -> T {
    lastPath = path
    lastBody = body
    if let error = mockError {
      throw error
    }
    guard let result = mockResult as? T else {
      throw APIClientError.invalidData
    }
    return result
  }

  func put<T: Decodable, U: Encodable>(path: String, body: U) async throws -> T {
    lastPath = path
    lastBody = body
    if let error = mockError {
      throw error
    }
    guard let result = mockResult as? T else {
      throw APIClientError.invalidData
    }
    return result
  }

  func delete(path: String) async throws {
    lastPath = path
    if let error = mockError {
      throw error
    }
    if !mockDeleteSuccess {
      throw APIClientError.invalidData
    }
  }
}
