//
//  GoBackendWalkRepositoryTests.swift
//  TekuTokoTests
//
//  Created by Claude Code on 2025/12/02.
//

import CoreLocation
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
      walks: [walkDTO],
      totalCount: 1,
      page: 1,
      limit: 10
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
    // WalkDetailResponseはWalkDTOのtype alias
    mockAPIClient.mockResult = walkDTO

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
    // WalkDetailResponseはWalkDTOのtype alias
    mockAPIClient.mockResult = walkDTO

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

  func test_createWalk_位置情報付き_リクエストに位置情報が含まれる() {
    // 期待値: 位置情報がリクエストに含まれる
    let walkDTO = createTestWalkDTO()
    mockAPIClient.mockResult = walkDTO

    let expectation = expectation(description: "createWalk with location")
    let testLocation = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

    sut.createWalk(title: "テスト散歩", description: "テスト説明", location: testLocation) { _ in
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)

    // 検証: リクエストボディに位置情報が含まれている
    if let body = mockAPIClient.lastBody as? WalkCreateRequest {
      XCTAssertEqual(body.startLatitude, testLocation.latitude)
      XCTAssertEqual(body.startLongitude, testLocation.longitude)
    } else {
      XCTFail("リクエストボディがWalkCreateRequestでない")
    }
  }

  // MARK: - updateWalk Tests

  func test_updateWalk_正常系_散歩を更新できる() {
    // 期待値: 散歩が更新される
    let walkDTO = createTestWalkDTO()
    // WalkDetailResponseはWalkDTOのtype alias
    mockAPIClient.mockResult = walkDTO

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

  // MARK: - LocationDTO Tests

  func test_LocationDTO_toCLLocation_正常に変換できる() {
    // 期待値: LocationDTOからCLLocationに正しく変換される
    let locationDTO = LocationDTO(
      latitude: 35.6812,
      longitude: 139.7671,
      altitude: 10.0,
      timestamp: Date(),
      horizontalAccuracy: 5.0,
      verticalAccuracy: 3.0,
      speed: 1.2,
      course: 90.0,
      sequenceNumber: 0
    )

    // When
    let clLocation = locationDTO.toCLLocation()

    // Then
    XCTAssertEqual(clLocation.coordinate.latitude, 35.6812, accuracy: 0.0001)
    XCTAssertEqual(clLocation.coordinate.longitude, 139.7671, accuracy: 0.0001)
    XCTAssertEqual(clLocation.altitude, 10.0, accuracy: 0.1)
    XCTAssertEqual(clLocation.horizontalAccuracy, 5.0, accuracy: 0.1)
    XCTAssertEqual(clLocation.verticalAccuracy, 3.0, accuracy: 0.1)
    XCTAssertEqual(clLocation.speed, 1.2, accuracy: 0.1)
    XCTAssertEqual(clLocation.course, 90.0, accuracy: 0.1)
  }

  func test_LocationDTO_fromCLLocation_正常に変換できる() {
    // 期待値: CLLocationからLocationDTOに正しく変換される
    let clLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
      altitude: 10.0,
      horizontalAccuracy: 5.0,
      verticalAccuracy: 3.0,
      course: 90.0,
      speed: 1.2,
      timestamp: Date()
    )

    // When
    let locationDTO = LocationDTO.fromCLLocation(clLocation, sequenceNumber: 5)

    // Then
    XCTAssertEqual(locationDTO.latitude, 35.6812, accuracy: 0.0001)
    XCTAssertEqual(locationDTO.longitude, 139.7671, accuracy: 0.0001)
    XCTAssertEqual(locationDTO.altitude!, 10.0, accuracy: 0.1)
    XCTAssertEqual(locationDTO.horizontalAccuracy!, 5.0, accuracy: 0.1)
    XCTAssertEqual(locationDTO.verticalAccuracy!, 3.0, accuracy: 0.1)
    XCTAssertEqual(locationDTO.speed!, 1.2, accuracy: 0.1)
    XCTAssertEqual(locationDTO.course!, 90.0, accuracy: 0.1)
    XCTAssertEqual(locationDTO.sequenceNumber, 5)
  }

  func test_LocationDTO_負のspeedとcourse_nilに変換される() {
    // 期待値: speed/courseが-1（無効値）の場合はnilになる
    let clLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
      altitude: 10.0,
      horizontalAccuracy: 5.0,
      verticalAccuracy: 3.0,
      course: -1,
      speed: -1,
      timestamp: Date()
    )

    // When
    let locationDTO = LocationDTO.fromCLLocation(clLocation, sequenceNumber: 0)

    // Then
    XCTAssertNil(locationDTO.speed)
    XCTAssertNil(locationDTO.course)
  }

  func test_fetchWalk_詳細API_locationsを含む散歩を取得できる() {
    // 期待値: 詳細APIからlocationsを含むWalkが取得される
    let walkDTO = createTestWalkDTO(includeLocations: true)
    mockAPIClient.mockResult = walkDTO

    let expectation = expectation(description: "fetchWalk with locations")
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

    // 検証: locationsが2件取得される
    XCTAssertEqual(walk.locations.count, 2)
    XCTAssertEqual(walk.locations[0].coordinate.latitude, 35.6812, accuracy: 0.0001)
    XCTAssertEqual(walk.locations[1].coordinate.latitude, 35.6815, accuracy: 0.0001)
  }

  func test_WalkDTO_locationsなし_空の配列に変換される() {
    // 期待値: locationsがnilの場合、空の配列に変換される
    let walkDTO = createTestWalkDTO(includeLocations: false)

    // When
    let walk = walkDTO.toWalk()

    // Then
    XCTAssertTrue(walk.locations.isEmpty)
  }

  // MARK: - Helper Methods

  private func createTestWalkDTO(includeLocations: Bool = false) -> WalkDTO {
    let locations: [LocationDTO]? = includeLocations
      ? [
        LocationDTO(
          latitude: 35.6812,
          longitude: 139.7671,
          altitude: 10.0,
          timestamp: Date(),
          horizontalAccuracy: 5.0,
          verticalAccuracy: 3.0,
          speed: 1.2,
          course: 90.0,
          sequenceNumber: 0
        ),
        LocationDTO(
          latitude: 35.6815,
          longitude: 139.7675,
          altitude: 12.0,
          timestamp: Date().addingTimeInterval(60),
          horizontalAccuracy: 5.0,
          verticalAccuracy: 3.0,
          speed: 1.3,
          course: 95.0,
          sequenceNumber: 1
        ),
      ] : nil

    return WalkDTO(
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
      updatedAt: Date(),
      locations: locations
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
