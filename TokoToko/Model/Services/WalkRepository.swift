//
//  WalkRepository.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import Foundation

// 結果型を定義
enum Result<T, E: Error> {
  case success(T)
  case failure(E)
}

// エラー型を定義
enum WalkRepositoryError: Error {
  case fetchFailed
  case saveFailed
  case notFound
}

class WalkRepository {
  // シングルトンインスタンス
  static let shared = WalkRepository()

  // 内部データストレージ
  private var walks: [Walk] = []

  private init() {
    // 初期データがあれば読み込む
  }

  // すべてのWalkを取得
  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    // 実際のアプリではデータベースやAPIからデータを取得
    completion(.success(walks))
  }

  // IDでWalkを取得
  func fetchWalk(withID id: UUID, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void)
  {
    if let walk = walks.first(where: { walk in walk.id == id }) {
      completion(.success(walk))
    } else {
      completion(.failure(.notFound))
    }
  }

  // 新しいWalkを追加
  func createWalk(
    title: String, description: String, location: CLLocationCoordinate2D? = nil,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    var newWalk = Walk(title: title, description: description)

    // 位置情報がある場合は開始地点として追加
    if let location = location {
      let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
      newWalk.addLocation(clLocation)
    }

    walks.append(newWalk)
    completion(.success(newWalk))
  }

  // 完全なWalkオブジェクトを追加（WalkManagerから使用）
  func saveWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    if let index = walks.firstIndex(where: { $0.id == walk.id }) {
      walks[index] = walk
    } else {
      walks.append(walk)
    }
    completion(.success(walk))
  }

  // Walkを更新
  func updateWalk(_ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    if let index = walks.firstIndex(where: { $0.id == walk.id }) {
      walks[index] = walk
      completion(.success(walk))
    } else {
      completion(.failure(.notFound))
    }
  }

  // Walkを削除
  func deleteWalk(
    withID id: UUID, completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    if let index = walks.firstIndex(where: { $0.id == id }) {
      walks.remove(at: index)
      completion(.success(true))
    } else {
      completion(.failure(.notFound))
    }
  }

  // 同期バージョンのメソッド（内部使用またはプレビュー用）
  func getAllWalks() -> [Walk] {
    return walks
  }
}
