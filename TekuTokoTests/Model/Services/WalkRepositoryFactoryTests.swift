//
//  WalkRepositoryFactoryTests.swift
//  TekuTokoTests
//
//  Created by Claude Code on 2025/12/03.
//

import CoreLocation
import XCTest

@testable import TekuToko

// MARK: - WalkRepositoryFactoryTests

final class WalkRepositoryFactoryTests: XCTestCase {

  // MARK: - Properties

  var sut: WalkRepositoryFactory!

  // MARK: - Setup / Teardown

  override func setUp() {
    super.setUp()
    sut = WalkRepositoryFactory.shared
  }

  override func tearDown() {
    // デフォルト状態に戻す
    sut.setRepositoryType(.firestore)
    sut = nil
    super.tearDown()
  }

  // MARK: - Repository Type Tests

  func test_setRepositoryType_firestore_Firestoreリポジトリを返す() {
    // 期待値: Firestoreタイプに設定するとFirestoreリポジトリを返す
    sut.setRepositoryType(.firestore)

    XCTAssertEqual(sut.currentType, .firestore)
    // リポジトリが取得できることを確認
    let repository = sut.repository
    XCTAssertNotNil(repository)
  }

  func test_setRepositoryType_goBackend_GoBackendリポジトリを返す() {
    // 期待値: GoBackendタイプに設定するとGoBackendリポジトリを返す
    sut.setRepositoryType(.goBackend)

    XCTAssertEqual(sut.currentType, .goBackend)
    // リポジトリが取得できることを確認
    let repository = sut.repository
    XCTAssertNotNil(repository)
    // GoBackendWalkRepositoryのインスタンスであることを確認
    XCTAssertTrue(repository is GoBackendWalkRepository)
  }

  func test_resetToEnvironmentDefault_AppConfigに基づいてリセットされる() {
    // 期待値: AppConfig.useGoBackendの値に基づいてタイプがリセットされる
    // 現在の設定を変更
    sut.setRepositoryType(.goBackend)

    // リセット
    sut.resetToEnvironmentDefault()

    // AppConfigの設定に応じた結果を確認
    if AppConfig.useGoBackend {
      XCTAssertEqual(sut.currentType, .goBackend)
    } else {
      XCTAssertEqual(sut.currentType, .firestore)
    }
  }

  // MARK: - DI Tests

  func test_injectRepository_モックリポジトリを注入できる() {
    // 期待値: テスト用のモックリポジトリを注入できる
    let mockRepository = MockWalkRepositoryForFactory()
    sut.injectRepository(mockRepository)
    sut.setRepositoryType(.firestore)

    let repository = sut.repository
    XCTAssertTrue(repository is MockWalkRepositoryForFactory)
  }

  // MARK: - Singleton Tests

  func test_shared_シングルトンインスタンスを返す() {
    // 期待値: sharedは常に同じインスタンスを返す
    let instance1 = WalkRepositoryFactory.shared
    let instance2 = WalkRepositoryFactory.shared

    XCTAssertTrue(instance1 === instance2)
  }

  // MARK: - Repository Instance Tests

  func test_repository_Firestoreタイプで同じインスタンスを返す() {
    // 期待値: 同じタイプの場合、同じインスタンスを返す（遅延初期化）
    sut.setRepositoryType(.firestore)

    let repo1 = sut.repository
    let repo2 = sut.repository

    // 同じインスタンスであることを確認（参照比較）
    XCTAssertTrue(repo1 as AnyObject === repo2 as AnyObject)
  }

  func test_repository_GoBackendタイプで同じインスタンスを返す() {
    // 期待値: GoBackendタイプでも同じインスタンスを返す
    sut.setRepositoryType(.goBackend)

    let repo1 = sut.repository
    let repo2 = sut.repository

    XCTAssertTrue(repo1 as AnyObject === repo2 as AnyObject)
  }
}

// MARK: - MockWalkRepositoryForFactory

/// テスト用のモックリポジトリ
class MockWalkRepositoryForFactory: WalkRepositoryProtocol {
  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    completion(.success([]))
  }

  func fetchWalk(
    withID id: UUID,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    completion(.failure(.notFound))
  }

  func createWalk(
    title: String,
    description: String,
    location: CLLocationCoordinate2D?,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    let walk = Walk(title: title, description: description)
    completion(.success(walk))
  }

  func saveWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    completion(.success(walk))
  }

  func updateWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    completion(.success(walk))
  }

  func deleteWalk(
    withID id: UUID,
    completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    completion(.success(true))
  }
}
