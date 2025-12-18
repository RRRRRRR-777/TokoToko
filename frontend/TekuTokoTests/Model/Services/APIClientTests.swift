//
//  APIClientTests.swift
//  TekuTokoTests
//
//  Created by Claude Code on 2025/12/02.
//

import XCTest

@testable import TekuToko

// MARK: - APIClientTests

final class APIClientTests: XCTestCase {

  // MARK: - Properties

  var sut: URLSessionAPIClient!
  var mockSession: MockURLSession!
  var mockTokenProvider: MockTokenProvider!
  // swiftlint:disable:next force_unwrapping
  let testBaseURL = URL(string: "https://api.example.com")!

  // MARK: - Setup / Teardown

  override func setUp() {
    super.setUp()
    mockSession = MockURLSession()
    mockTokenProvider = MockTokenProvider()
    sut = URLSessionAPIClient(
      baseURL: testBaseURL,
      session: mockSession,
      tokenProvider: mockTokenProvider
    )
  }

  override func tearDown() {
    sut = nil
    mockSession = nil
    mockTokenProvider = nil
    super.tearDown()
  }

  // MARK: - GET Tests

  func test_get_正常系_データを取得できる() async throws {
    // 期待値: JSONレスポンスが正しくデコードされる
    let expectedResponse = TestResponse(id: "123", name: "Test")
    let responseData = try JSONEncoder().encode(expectedResponse)

    mockSession.mockData = responseData
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 200)
    mockTokenProvider.mockToken = "test-token"

    let result: TestResponse = try await sut.get(path: "/test")

    // 検証: レスポンスが期待値と一致
    XCTAssertEqual(result.id, expectedResponse.id)
    XCTAssertEqual(result.name, expectedResponse.name)

    // 検証: リクエストにAuthorizationヘッダーが含まれる
    XCTAssertEqual(
      mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"),
      "Bearer test-token"
    )
  }

  func test_get_401エラー_authenticationRequiredエラーを返す() async {
    // 期待値: 401エラー時にauthenticationRequiredエラーが返される
    mockSession.mockData = Data()
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 401)
    mockTokenProvider.mockToken = "test-token"

    do {
      let _: TestResponse = try await sut.get(path: "/test")
      XCTFail("エラーがスローされるべき")
    } catch let error as APIClientError {
      XCTAssertEqual(error, .authenticationRequired)
    } catch {
      XCTFail("予期しないエラー型: \(error)")
    }
  }

  func test_get_404エラー_notFoundエラーを返す() async {
    // 期待値: 404エラー時にnotFoundエラーが返される
    mockSession.mockData = Data()
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 404)
    mockTokenProvider.mockToken = "test-token"

    do {
      let _: TestResponse = try await sut.get(path: "/test")
      XCTFail("エラーがスローされるべき")
    } catch let error as APIClientError {
      XCTAssertEqual(error, .notFound)
    } catch {
      XCTFail("予期しないエラー型: \(error)")
    }
  }

  func test_get_500エラー_serverErrorを返す() async {
    // 期待値: 500エラー時にserverErrorが返される
    mockSession.mockData = Data()
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 500)
    mockTokenProvider.mockToken = "test-token"

    do {
      let _: TestResponse = try await sut.get(path: "/test")
      XCTFail("エラーがスローされるべき")
    } catch let error as APIClientError {
      XCTAssertEqual(error, .serverError(statusCode: 500))
    } catch {
      XCTFail("予期しないエラー型: \(error)")
    }
  }

  func test_get_トークン取得失敗_authenticationRequiredエラーを返す() async {
    // 期待値: トークン取得に失敗した場合、authenticationRequiredエラー
    mockTokenProvider.shouldFail = true

    do {
      let _: TestResponse = try await sut.get(path: "/test")
      XCTFail("エラーがスローされるべき")
    } catch let error as APIClientError {
      XCTAssertEqual(error, .authenticationRequired)
    } catch {
      XCTFail("予期しないエラー型: \(error)")
    }
  }

  func test_get_ネットワークエラー_networkErrorを返す() async {
    // 期待値: ネットワークエラー時にnetworkErrorが返される
    mockSession.mockError = URLError(.notConnectedToInternet)
    mockTokenProvider.mockToken = "test-token"

    do {
      let _: TestResponse = try await sut.get(path: "/test")
      XCTFail("エラーがスローされるべき")
    } catch let error as APIClientError {
      if case .networkError = error {
        // 成功
      } else {
        XCTFail("networkErrorが期待されるが、\(error)が返された")
      }
    } catch {
      XCTFail("予期しないエラー型: \(error)")
    }
  }

  func test_get_デコードエラー_invalidDataエラーを返す() async {
    // 期待値: 不正なJSONの場合、invalidDataエラーが返される
    mockSession.mockData = Data("invalid json".utf8)
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 200)
    mockTokenProvider.mockToken = "test-token"

    do {
      let _: TestResponse = try await sut.get(path: "/test")
      XCTFail("エラーがスローされるべき")
    } catch let error as APIClientError {
      XCTAssertEqual(error, .invalidData)
    } catch {
      XCTFail("予期しないエラー型: \(error)")
    }
  }

  // MARK: - POST Tests

  func test_post_正常系_データを送信して結果を取得できる() async throws {
    // 期待値: POSTリクエストが正しく送信され、レスポンスがデコードされる
    let requestBody = TestRequest(name: "New Item")
    let expectedResponse = TestResponse(id: "456", name: "New Item")
    let responseData = try JSONEncoder().encode(expectedResponse)

    mockSession.mockData = responseData
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 201)
    mockTokenProvider.mockToken = "test-token"

    let result: TestResponse = try await sut.post(path: "/test", body: requestBody)

    // 検証: レスポンスが期待値と一致
    XCTAssertEqual(result.id, expectedResponse.id)
    XCTAssertEqual(result.name, expectedResponse.name)

    // 検証: HTTPメソッドがPOST
    XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")

    // 検証: Content-Typeヘッダーが設定されている
    XCTAssertEqual(
      mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type"),
      "application/json"
    )
  }

  // MARK: - PUT Tests

  func test_put_正常系_データを更新できる() async throws {
    // 期待値: PUTリクエストが正しく送信される
    let requestBody = TestRequest(name: "Updated Item")
    let expectedResponse = TestResponse(id: "123", name: "Updated Item")
    let responseData = try JSONEncoder().encode(expectedResponse)

    mockSession.mockData = responseData
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 200, path: "/test/123")
    mockTokenProvider.mockToken = "test-token"

    let result: TestResponse = try await sut.put(path: "/test/123", body: requestBody)

    // 検証: レスポンスが期待値と一致
    XCTAssertEqual(result.id, expectedResponse.id)
    XCTAssertEqual(result.name, expectedResponse.name)

    // 検証: HTTPメソッドがPUT
    XCTAssertEqual(mockSession.lastRequest?.httpMethod, "PUT")
  }

  // MARK: - DELETE Tests

  func test_delete_正常系_データを削除できる() async throws {
    // 期待値: DELETEリクエストが正しく送信される
    mockSession.mockData = Data()
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 204, path: "/test/123")
    mockTokenProvider.mockToken = "test-token"

    try await sut.delete(path: "/test/123")

    // 検証: HTTPメソッドがDELETE
    XCTAssertEqual(mockSession.lastRequest?.httpMethod, "DELETE")
  }

  func test_delete_404エラー_notFoundエラーを返す() async {
    // 期待値: 削除対象が存在しない場合、notFoundエラー
    mockSession.mockData = Data()
    mockSession.mockResponse = createHTTPURLResponse(statusCode: 404, path: "/test/123")
    mockTokenProvider.mockToken = "test-token"

    do {
      try await sut.delete(path: "/test/123")
      XCTFail("エラーがスローされるべき")
    } catch let error as APIClientError {
      XCTAssertEqual(error, .notFound)
    } catch {
      XCTFail("予期しないエラー型: \(error)")
    }
  }

  // MARK: - Helper Methods

  private func createHTTPURLResponse(statusCode: Int, path: String = "/test") -> HTTPURLResponse {
    HTTPURLResponse(
      url: testBaseURL.appendingPathComponent(path),
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: nil
      // swiftlint:disable:next force_unwrapping
    )!
  }
}

// MARK: - Test Helpers

private struct TestRequest: Encodable {
  let name: String
}

private struct TestResponse: Codable, Equatable {
  let id: String
  let name: String
}

// MARK: - MockURLSession

class MockURLSession: URLSessionProtocol {
  var mockData: Data?
  var mockResponse: URLResponse?
  var mockError: Error?
  var lastRequest: URLRequest?

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    lastRequest = request

    if let error = mockError {
      throw error
    }

    guard let data = mockData, let response = mockResponse else {
      throw URLError(.unknown)
    }

    return (data, response)
  }
}

// MARK: - MockTokenProvider

class MockTokenProvider: TokenProviderProtocol {
  var mockToken: String?
  var shouldFail = false

  func getIDToken() async throws -> String {
    if shouldFail {
      throw TokenProviderError.tokenRetrievalFailed
    }
    guard let token = mockToken else {
      throw TokenProviderError.tokenRetrievalFailed
    }
    return token
  }
}

enum TokenProviderError: Error {
  case tokenRetrievalFailed
}
