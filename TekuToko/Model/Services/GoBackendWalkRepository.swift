//
//  GoBackendWalkRepository.swift
//  TekuToko
//
//  Created by Claude Code on 2025/12/02.
//

import CoreLocation
import Foundation

// MARK: - API Response Models

/// 散歩一覧APIレスポンス
struct WalksListResponse: Decodable {
  let walks: [WalkDTO]
  let totalCount: Int
  let page: Int
  let limit: Int

  enum CodingKeys: String, CodingKey {
    case walks
    case totalCount = "total_count"
    case page
    case limit
  }
}

/// 散歩詳細APIレスポンス
/// サーバーはWalkDTOを直接返すため、WalkDTOのtype aliasとして定義
typealias WalkDetailResponse = WalkDTO

// MARK: - WalkDTO

/// Go バックエンドとの通信用DTO
///
/// iOSの`Walk`モデルとGoバックエンドのJSONスキーマを変換するためのData Transfer Object
struct WalkDTO: Codable {
  let id: String
  let userId: String
  let title: String
  let description: String?
  let startTime: Date?
  let endTime: Date?
  let totalDistance: Double
  let totalSteps: Int
  let polylineData: String?
  let thumbnailImageUrl: String?
  let status: WalkStatusDTO
  let pausedAt: Date?
  let totalPausedDuration: Double
  let createdAt: Date
  let updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case title
    case description
    case startTime = "start_time"
    case endTime = "end_time"
    case totalDistance = "total_distance"
    case totalSteps = "total_steps"
    case polylineData = "polyline_data"
    case thumbnailImageUrl = "thumbnail_image_url"
    case status
    case pausedAt = "paused_at"
    case totalPausedDuration = "total_paused_duration"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  /// WalkDTOをWalkモデルに変換
  func toWalk() -> Walk {
    Walk(
      title: title,
      description: description ?? "",
      userId: userId,
      id: UUID(uuidString: id) ?? UUID(),
      startTime: startTime,
      endTime: endTime,
      totalDistance: totalDistance,
      totalSteps: totalSteps,
      polylineData: polylineData,
      thumbnailImageUrl: thumbnailImageUrl,
      status: status.toWalkStatus(),
      pausedAt: pausedAt,
      totalPausedDuration: totalPausedDuration,
      locations: [],
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }

  /// WalkモデルからWalkDTOを作成
  static func fromWalk(_ walk: Walk) -> WalkDTO {
    WalkDTO(
      id: walk.id.uuidString,
      userId: walk.userId ?? "",
      title: walk.title,
      description: walk.description,
      startTime: walk.startTime,
      endTime: walk.endTime,
      totalDistance: walk.totalDistance,
      totalSteps: walk.totalSteps,
      polylineData: walk.polylineData,
      thumbnailImageUrl: walk.thumbnailImageUrl,
      status: WalkStatusDTO.fromWalkStatus(walk.status),
      pausedAt: walk.pausedAt,
      totalPausedDuration: walk.totalPausedDuration,
      createdAt: walk.createdAt,
      updatedAt: walk.updatedAt
    )
  }
}

// MARK: - WalkStatusDTO

/// 散歩ステータスのDTO
enum WalkStatusDTO: String, Codable {
  case notStarted = "not_started"
  case inProgress = "in_progress"
  case paused
  case completed

  func toWalkStatus() -> WalkStatus {
    switch self {
    case .notStarted:
      return .notStarted
    case .inProgress:
      return .inProgress
    case .paused:
      return .paused
    case .completed:
      return .completed
    }
  }

  static func fromWalkStatus(_ status: WalkStatus) -> WalkStatusDTO {
    switch status {
    case .notStarted:
      return .notStarted
    case .inProgress:
      return .inProgress
    case .paused:
      return .paused
    case .completed:
      return .completed
    }
  }
}

// MARK: - Request Models

/// 散歩作成リクエスト
struct WalkCreateRequest: Encodable {
  let title: String
  let description: String?
  let startLatitude: Double?
  let startLongitude: Double?

  enum CodingKeys: String, CodingKey {
    case title
    case description
    case startLatitude = "start_latitude"
    case startLongitude = "start_longitude"
  }
}

/// 散歩更新リクエスト（upsert対応）
struct WalkUpdateRequest: Encodable {
  let title: String?
  let description: String?
  let status: WalkStatusDTO?
  let totalSteps: Int?
  let startTime: Date?
  let endTime: Date?
  let totalDistance: Double?
  let polylineData: String?
  let thumbnailImageUrl: String?
  let pausedAt: Date?
  let totalPausedDuration: Double?

  enum CodingKeys: String, CodingKey {
    case title
    case description
    case status
    case totalSteps = "total_steps"
    case startTime = "start_time"
    case endTime = "end_time"
    case totalDistance = "total_distance"
    case polylineData = "polyline_data"
    case thumbnailImageUrl = "thumbnail_image_url"
    case pausedAt = "paused_at"
    case totalPausedDuration = "total_paused_duration"
  }
}

// MARK: - GoBackendWalkRepository

/// Go バックエンドと通信するWalkRepository実装
///
/// `WalkRepositoryProtocol` に準拠し、Firestoreの代わりにGo バックエンドのREST APIを使用します。
final class GoBackendWalkRepository: WalkRepositoryProtocol {

  // MARK: - Properties

  private let apiClient: APIClientProtocol

  // MARK: - Initialization

  init(apiClient: APIClientProtocol) {
    self.apiClient = apiClient
  }

  /// AppConfigのbaseURLを使用してAPIClientを自動生成
  convenience init() {
    let client = URLSessionAPIClient(baseURL: AppConfig.baseURL)
    self.init(apiClient: client)
  }

  // MARK: - WalkRepositoryProtocol

  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    Task {
      do {
        let response: WalksListResponse = try await apiClient.get(path: "/v1/walks")
        let walks = response.walks.map { $0.toWalk() }
        await MainActor.run {
          completion(.success(walks))
        }
      } catch {
        await MainActor.run {
          completion(.failure(error.toWalkRepositoryError()))
        }
      }
    }
  }

  func fetchWalk(
    withID id: UUID,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    Task {
      do {
        let response: WalkDetailResponse = try await apiClient.get(path: "/v1/walks/\(id.uuidString)")
        let walk = response.toWalk()
        await MainActor.run {
          completion(.success(walk))
        }
      } catch {
        await MainActor.run {
          completion(.failure(error.toWalkRepositoryError()))
        }
      }
    }
  }

  func createWalk(
    title: String,
    description: String,
    location: CLLocationCoordinate2D?,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    Task {
      do {
        let request = WalkCreateRequest(
          title: title,
          description: description,
          startLatitude: location?.latitude,
          startLongitude: location?.longitude
        )
        let response: WalkDetailResponse = try await apiClient.post(path: "/v1/walks", body: request)
        let walk = response.toWalk()
        await MainActor.run {
          completion(.success(walk))
        }
      } catch {
        await MainActor.run {
          completion(.failure(error.toWalkRepositoryError()))
        }
      }
    }
  }

  func saveWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    // saveWalkはupdateWalkと同じ動作
    updateWalk(walk, completion: completion)
  }

  func updateWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    Task {
      do {
        let request = WalkUpdateRequest(
          title: walk.title,
          description: walk.description,
          status: WalkStatusDTO.fromWalkStatus(walk.status),
          totalSteps: walk.totalSteps,
          startTime: walk.startTime,
          endTime: walk.endTime,
          totalDistance: walk.totalDistance,
          polylineData: walk.polylineData,
          thumbnailImageUrl: walk.thumbnailImageUrl,
          pausedAt: walk.pausedAt,
          totalPausedDuration: walk.totalPausedDuration
        )
        let response: WalkDetailResponse = try await apiClient.put(
          path: "/v1/walks/\(walk.id.uuidString)",
          body: request
        )
        let updatedWalk = response.toWalk()
        await MainActor.run {
          completion(.success(updatedWalk))
        }
      } catch {
        await MainActor.run {
          completion(.failure(error.toWalkRepositoryError()))
        }
      }
    }
  }

  func deleteWalk(
    withID id: UUID,
    completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    Task {
      do {
        try await apiClient.delete(path: "/v1/walks/\(id.uuidString)")
        await MainActor.run {
          completion(.success(true))
        }
      } catch {
        await MainActor.run {
          completion(.failure(error.toWalkRepositoryError()))
        }
      }
    }
  }
}

// MARK: - Error Conversion

extension Error {
  /// ErrorをWalkRepositoryErrorに変換
  func toWalkRepositoryError() -> WalkRepositoryError {
    if let apiError = self as? APIClientError {
      switch apiError {
      case .notFound:
        return .notFound
      case .authenticationRequired:
        return .authenticationRequired
      case .networkError:
        return .networkError
      case .invalidData:
        return .invalidData
      case .serverError, .badRequest, .httpError:
        return .networkError
      }
    }
    return .networkError
  }
}
