//
//  APIClient.swift
//  TekuToko
//
//  Created by Claude Code on 2025/12/02.
//

import FirebaseAuth
import Foundation

// MARK: - APIClientError

/// APIクライアントのエラー型
///
/// HTTPステータスコードやネットワークエラーを表現します。
enum APIClientError: Error, Equatable {
  /// リソースが見つからない（404）
  case notFound

  /// 認証が必要（401）
  case authenticationRequired

  /// サーバーエラー（5xx）
  case serverError(statusCode: Int)

  /// ネットワークエラー
  case networkError(Error)

  /// 無効なデータ（デコードエラー）
  case invalidData

  /// 不正なリクエスト（400）
  case badRequest

  /// その他のHTTPエラー
  case httpError(statusCode: Int)

  static func == (lhs: APIClientError, rhs: APIClientError) -> Bool {
    switch (lhs, rhs) {
    case (.notFound, .notFound),
      (.authenticationRequired, .authenticationRequired),
      (.invalidData, .invalidData),
      (.badRequest, .badRequest):
      return true
    case let (.serverError(lhsCode), .serverError(rhsCode)):
      return lhsCode == rhsCode
    case let (.httpError(lhsCode), .httpError(rhsCode)):
      return lhsCode == rhsCode
    case (.networkError, .networkError):
      return true
    default:
      return false
    }
  }
}

// MARK: - URLSessionProtocol

/// URLSessionの抽象化プロトコル（テスト用）
protocol URLSessionProtocol {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - TokenProviderProtocol

/// 認証トークンを提供するプロトコル
protocol TokenProviderProtocol {
  func getIDToken() async throws -> String
}

// MARK: - FirebaseTokenProvider

/// Firebase認証トークンを提供する実装
final class FirebaseTokenProvider: TokenProviderProtocol {
  func getIDToken() async throws -> String {
    guard let currentUser = Auth.auth().currentUser else {
      throw APIClientError.authenticationRequired
    }

    return try await withCheckedThrowingContinuation { continuation in
      currentUser.getIDToken { token, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        guard let token = token else {
          continuation.resume(throwing: APIClientError.authenticationRequired)
          return
        }
        continuation.resume(returning: token)
      }
    }
  }
}

// MARK: - APIClientProtocol

/// APIクライアントのプロトコル
///
/// Go バックエンドとのHTTP通信を抽象化します。
protocol APIClientProtocol {
  /// GETリクエストを送信
  ///
  /// - Parameter path: APIパス（例: "/walks"）
  /// - Returns: デコードされたレスポンス
  func get<T: Decodable>(path: String) async throws -> T

  /// POSTリクエストを送信
  ///
  /// - Parameters:
  ///   - path: APIパス（例: "/walks"）
  ///   - body: リクエストボディ
  /// - Returns: デコードされたレスポンス
  func post<T: Decodable, U: Encodable>(path: String, body: U) async throws -> T

  /// PUTリクエストを送信
  ///
  /// - Parameters:
  ///   - path: APIパス（例: "/walks/123"）
  ///   - body: リクエストボディ
  /// - Returns: デコードされたレスポンス
  func put<T: Decodable, U: Encodable>(path: String, body: U) async throws -> T

  /// DELETEリクエストを送信
  ///
  /// - Parameter path: APIパス（例: "/walks/123"）
  func delete(path: String) async throws
}

// MARK: - URLSessionAPIClient

/// URLSessionを使用したAPIクライアント実装
final class URLSessionAPIClient: APIClientProtocol {

  // MARK: - Properties

  private let baseURL: URL
  private let session: URLSessionProtocol
  private let tokenProvider: TokenProviderProtocol
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  // MARK: - Initialization

  init(
    baseURL: URL,
    session: URLSessionProtocol = URLSession.shared,
    tokenProvider: TokenProviderProtocol = FirebaseTokenProvider()
  ) {
    self.baseURL = baseURL
    self.session = session
    self.tokenProvider = tokenProvider
    self.encoder = JSONEncoder()
    self.decoder = JSONDecoder()

    // ISO8601形式の日付対応
    encoder.dateEncodingStrategy = .iso8601
    decoder.dateDecodingStrategy = .iso8601
  }

  // MARK: - APIClientProtocol

  func get<T: Decodable>(path: String) async throws -> T {
    let request = try await buildRequest(path: path, method: "GET", body: nil as Empty?)
    return try await performRequest(request)
  }

  func post<T: Decodable, U: Encodable>(path: String, body: U) async throws -> T {
    let request = try await buildRequest(path: path, method: "POST", body: body)
    return try await performRequest(request)
  }

  func put<T: Decodable, U: Encodable>(path: String, body: U) async throws -> T {
    let request = try await buildRequest(path: path, method: "PUT", body: body)
    return try await performRequest(request)
  }

  func delete(path: String) async throws {
    let request = try await buildRequest(path: path, method: "DELETE", body: nil as Empty?)
    try await performRequestWithoutResponse(request)
  }

  // MARK: - Private Methods

  private func buildRequest<T: Encodable>(
    path: String, method: String, body: T?
  ) async throws -> URLRequest {
    let url = baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method

    // 認証トークンを取得して設定
    do {
      let token = try await tokenProvider.getIDToken()
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    } catch {
      throw APIClientError.authenticationRequired
    }

    // リクエストボディがある場合はエンコード
    if let body = body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try encoder.encode(body)
    }

    return request
  }

  private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
    let (data, response) = try await executeRequest(request)

    try validateResponse(response)

    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      #if DEBUG
        print("[APIClient] デコードエラー: \(error)")
      #endif
      throw APIClientError.invalidData
    }
  }

  private func performRequestWithoutResponse(_ request: URLRequest) async throws {
    let (_, response) = try await executeRequest(request)
    try validateResponse(response)
  }

  private func executeRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
    #if DEBUG
      let method = request.httpMethod ?? "?"
      let urlString = request.url?.absoluteString ?? ""
      print("[APIClient] Request: \(method) \(urlString)")
    #endif

    do {
      let (data, response) = try await session.data(for: request)

      #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
          print("[APIClient] Response: \(httpResponse.statusCode)")
        }
      #endif

      return (data, response)
    } catch {
      #if DEBUG
        print("[APIClient] ネットワークエラー: \(error)")
      #endif
      throw APIClientError.networkError(error)
    }
  }

  private func validateResponse(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIClientError.networkError(URLError(.badServerResponse))
    }

    let statusCode = httpResponse.statusCode

    switch statusCode {
    case 200...299:
      return
    case 400:
      throw APIClientError.badRequest
    case 401:
      throw APIClientError.authenticationRequired
    case 404:
      throw APIClientError.notFound
    case 500...599:
      throw APIClientError.serverError(statusCode: statusCode)
    default:
      throw APIClientError.httpError(statusCode: statusCode)
    }
  }
}

// MARK: - Empty

/// 空のボディ用の型
private struct Empty: Encodable {}
