//
//  MockWalkRepository.swift
//  TokoTokoTests
//
//  Created by bokuyamada on 2025/06/27.
//

import Foundation
import CoreLocation
@testable import TokoToko

// テスト用のモックWalkRepository
class MockWalkRepository {
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
  
  func fetchWalk(withID id: UUID, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
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
    if shouldSimulateError {
      completion(.failure(simulatedError))
      return
    }
    
    guard let userId = mockCurrentUserId else {
      completion(.failure(.authenticationRequired))
      return
    }
    
    let newWalk = Walk(title: title, description: description, userId: userId)
    
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
    
    guard let index = mockWalks.firstIndex(where: { $0.id == walk.id && $0.userId == mockCurrentUserId }) else {
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
  func saveWalkToFirestore(_ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    saveWalk(walk, completion: completion)
  }
  
  func fetchWalksFromFirestore(userId: String, completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    setMockCurrentUserId(userId)
    fetchWalks(completion: completion)
  }
  
  func updateWalkInFirestore(_ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    updateWalk(walk, completion: completion)
  }
  
  func deleteWalkFromFirestore(walkId: UUID, userId: String, completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void) {
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