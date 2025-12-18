//
//  MockWalkRepository.swift
//  TekuTokoTests
//
//  Created by bokuyamada on 2025/06/27.
//

import CoreLocation
import Foundation
import MapKit

@testable import TekuToko

// MARK: - MockWalkRepository

// テスト用のモックWalkRepository
class MockWalkRepository: WalkRepositoryProtocol {
  // シミュレーション用のストレージ
  private var mockWalks: [Walk] = []
  private var shouldSimulateError = false
  private var simulatedError: WalkRepositoryError = .networkError
  private var mockCurrentUserId: String? = "mock-user-id"

  // MARK: - テスト制御メソッド

  func setMockCurrentUserId(_ userId: String?) {
    mockCurrentUserId = userId
  }

  func simulateError(_ error: WalkRepositoryError) {
    shouldSimulateError = true
    simulatedError = error
  }

  func clearError() {
    shouldSimulateError = false
  }

  func clearMockData() {
    mockWalks.removeAll()
  }

  func addMockWalk(_ walk: Walk) {
    mockWalks.append(walk)
  }

  // MARK: - WalkRepository互換メソッド

  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    if shouldSimulateError {
      completion(.failure(simulatedError))
      return
    }

    guard let userId = mockCurrentUserId else {
      completion(.failure(.authenticationRequired))
      return
    }

    let userWalks = mockWalks.filter { $0.userId == userId }
    completion(.success(userWalks))
  }

  func fetchWalk(withID id: UUID, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void)
  {
    if shouldSimulateError {
      completion(.failure(simulatedError))
      return
    }

    guard let userId = mockCurrentUserId else {
      completion(.failure(.authenticationRequired))
      return
    }

    guard let walk = mockWalks.first(where: { $0.id == id && $0.userId == userId }) else {
      completion(.failure(.notFound))
      return
    }

    completion(.success(walk))
  }

  func addWalk(
    title: String,
    description: String,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    createWalk(title: title, description: description, location: nil, completion: completion)
  }

  func createWalk(
    title: String,
    description: String,
    location: CLLocationCoordinate2D?,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    if shouldSimulateError {
      completion(.failure(simulatedError))
      return
    }

    guard let userId = mockCurrentUserId else {
      completion(.failure(.authenticationRequired))
      return
    }

    var newWalk = Walk(title: title, description: description, userId: userId)

    // 位置情報がある場合は開始地点として追加
    if let location = location {
      let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
      newWalk.addLocation(clLocation)
    }

    mockWalks.append(newWalk)
    completion(.success(newWalk))
  }

  func saveWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    if shouldSimulateError {
      completion(.failure(simulatedError))
      return
    }

    guard mockCurrentUserId != nil else {
      completion(.failure(.authenticationRequired))
      return
    }

    if let index = mockWalks.firstIndex(where: { $0.id == walk.id }) {
      mockWalks[index] = walk
    } else {
      mockWalks.append(walk)
    }

    completion(.success(walk))
  }

  func updateWalk(_ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    if shouldSimulateError {
      completion(.failure(simulatedError))
      return
    }

    guard mockCurrentUserId != nil else {
      completion(.failure(.authenticationRequired))
      return
    }

    guard
      let index = mockWalks.firstIndex(where: { $0.id == walk.id && $0.userId == mockCurrentUserId }
      )
    else {
      completion(.failure(.notFound))
      return
    }

    mockWalks[index] = walk
    completion(.success(walk))
  }

  func deleteWalk(
    withID id: UUID,
    completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    if shouldSimulateError {
      completion(.failure(simulatedError))
      return
    }

    guard let userId = mockCurrentUserId else {
      completion(.failure(.authenticationRequired))
      return
    }

    guard let index = mockWalks.firstIndex(where: { $0.id == id && $0.userId == userId }) else {
      completion(.failure(.notFound))
      return
    }

    mockWalks.remove(at: index)
    completion(.success(true))
  }

  // WalkRepositoryと同じインターフェースのメソッドを追加
  func saveWalkToFirestore(
    _ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    saveWalk(walk, completion: completion)
  }

  func fetchWalksFromFirestore(
    userId: String, completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void
  ) {
    setMockCurrentUserId(userId)
    fetchWalks(completion: completion)
  }

  func updateWalkInFirestore(
    _ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    updateWalk(walk, completion: completion)
  }

  func deleteWalkFromFirestore(
    walkId: UUID, userId: String, completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    setMockCurrentUserId(userId)
    deleteWalk(withID: walkId, completion: completion)
  }
}

// MARK: - テスト用ヘルパー

extension MockWalkRepository {
  // テスト用のサンプルWalkを生成
  static func createSampleWalk(
    title: String = "テスト散歩",
    description: String = "テスト用の散歩",
    userId: String = "test-user-id"
  ) -> Walk {
    return Walk(
      title: title,
      description: description,
      userId: userId
    )
  }

  // 複数のサンプルWalkを生成
  static func createSampleWalks(count: Int, userId: String = "test-user-id") -> [Walk] {
    return (1...count).map { index in
      Walk(
        title: "テスト散歩 \(index)",
        description: "テスト用の散歩 \(index)",
        userId: userId
      )
    }
  }
}

// MARK: - MockGeocoder

/// テスト用のモックGeocoder
class MockGeocoder: GeocoderProtocol {
  var mockLocality: String?
  var mockError: Error?
  var shouldCancel = false
  var reverseGeocodeCallCount = 0

  func reverseGeocodeLocation(
    _ location: CLLocation,
    completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void
  ) {
    reverseGeocodeCallCount += 1

    // キャンセルされた場合
    if shouldCancel {
      let error = NSError(
        domain: kCLErrorDomain,
        code: CLError.geocodeCanceled.rawValue,
        userInfo: nil
      )
      completionHandler(nil, error)
      return
    }

    // エラーをシミュレート
    if let error = mockError {
      completionHandler(nil, error)
      return
    }

    // 正常系：実際のCLPlacemarkを生成
    if let locality = mockLocality {
      // CLPlacemarkを生成するために、座標からジオコーディング結果を作成
      // Note: テスト環境では実際の値を返す必要があるため、
      // MKPlacemarkを使って生成する
      let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
      let addressDict: [String: Any] = [
        "City": locality,
        "Country": "日本",
        "CountryCode": "JP"
      ]

      if let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict) as CLPlacemark? {
        completionHandler([placemark], nil)
      } else {
        completionHandler([], nil)
      }
    } else {
      completionHandler([], nil)
    }
  }

  func cancelGeocode() {
    shouldCancel = true
  }

  // テスト用のヘルパーメソッド
  func setMockPlacemark(locality: String) {
    mockLocality = locality
  }
}
