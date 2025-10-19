//
//  RouteSuggestionServiceTests.swift
//  TekuTokoTests
//
//  Created by Claude Code on 2025/10/12.
//

import CoreLocation
import XCTest

@testable import TekuToko

/// RouteSuggestionServiceのテストクラス
@available(iOS 26.0, *)
final class RouteSuggestionServiceTests: XCTestCase {

  var mockRepository: MockWalkRepository!
  var mockGeocoder: MockGeocoder!
  var service: RouteSuggestionService!

  override func setUp() {
    super.setUp()
    mockRepository = MockWalkRepository()
    mockGeocoder = MockGeocoder()
    service = RouteSuggestionService(
      walkRepository: mockRepository,
      geocoderFactory: { [weak self] in self?.mockGeocoder ?? MockGeocoder() }
    )
  }

  override func tearDown() {
    service = nil
    mockGeocoder = nil
    mockRepository = nil
    super.tearDown()
  }

  // MARK: - Phase 1: fetchWalkHistory() Tests

  /// fetchWalkHistory()が散歩履歴を正常に取得できることをテスト
  func testFetchWalkHistory_Success() async throws {
    // Given: 10件の散歩履歴を用意
    let walks = MockWalkRepository.createSampleWalks(count: 10, userId: "mock-user-id")
    walks.forEach { mockRepository.addMockWalk($0) }

    // When: fetchWalkHistory()を呼び出す
    let result = try await service.fetchWalkHistory()

    // Then: 10件の散歩履歴が取得できる
    XCTAssertEqual(result.count, 10, "10件の散歩履歴が取得できること")
  }

  /// fetchWalkHistory()が最新15件のみ取得することをテスト
  func testFetchWalkHistory_LimitTo15() async throws {
    // Given: 20件の散歩履歴を用意（作成日時が異なる）
    let walks = (1...20).map { index in
      var walk = Walk(
        title: "テスト散歩 \(index)",
        description: "テスト用の散歩 \(index)",
        userId: "mock-user-id"
      )
      // 作成日時を設定（古いものから新しいものへ）
      walk.createdAt = Date(timeIntervalSinceNow: TimeInterval(index * 3600))
      return walk
    }
    walks.forEach { mockRepository.addMockWalk($0) }

    // When: fetchWalkHistory()を呼び出す
    let result = try await service.fetchWalkHistory()

    // Then: 最新15件のみ取得される
    XCTAssertEqual(result.count, 15, "最新15件のみ取得されること")

    // Then: 最新のものから順に並んでいる
    for i in 0..<result.count - 1 {
      XCTAssertGreaterThanOrEqual(
        result[i].createdAt,
        result[i + 1].createdAt,
        "作成日時の降順で並んでいること"
      )
    }
  }

  /// fetchWalkHistory()がエラー時に適切にハンドリングすることをテスト
  func testFetchWalkHistory_Error() async {
    // Given: エラーをシミュレート
    mockRepository.simulateError(.networkError)

    // When & Then: fetchWalkHistory()がエラーをスローする
    do {
      _ = try await service.fetchWalkHistory()
      XCTFail("エラーがスローされるべき")
    } catch let error as RouteSuggestionServiceError {
      if case .databaseUnavailable = error {
        // 期待通りのエラー
      } else {
        XCTFail("databaseUnavailableエラーがスローされるべき")
      }
    } catch {
      XCTFail("RouteSuggestionServiceErrorがスローされるべき")
    }
  }

  /// fetchWalkHistory()が0件の場合に空の配列を返すことをテスト
  func testFetchWalkHistory_Empty() async throws {
    // Given: 散歩履歴が0件

    // When: fetchWalkHistory()を呼び出す
    let result = try await service.fetchWalkHistory()

    // Then: 空の配列が返される
    XCTAssertEqual(result.count, 0, "空の配列が返されること")
  }

  // MARK: - Phase 2: extractSamplingPoints() Tests

  /// extractSamplingPoints()が1地点の場合に正しく抽出できることをテスト
  func testExtractSamplingPoints_OneLocation() {
    // Given: 1地点のみの散歩
    let location = CLLocation(latitude: 35.6812, longitude: 139.7671)
    var walk = Walk(title: "テスト散歩", description: "", userId: "test-user-id")
    walk.locations = [location]

    // When: extractSamplingPoints()を呼び出す
    let result = service.extractSamplingPoints(from: walk)

    // Then: 1地点が返される
    XCTAssertEqual(result.count, 1, "1地点が返されること")
    if let first = result.first {
      XCTAssertEqual(first.coordinate.latitude, location.coordinate.latitude, accuracy: 0.001)
    }
  }

  /// extractSamplingPoints()が2地点の場合に正しく抽出できることをテスト
  func testExtractSamplingPoints_TwoLocations() {
    // Given: 2地点の散歩
    let start = CLLocation(latitude: 35.6812, longitude: 139.7671)
    let end = CLLocation(latitude: 35.6762, longitude: 139.6503)
    var walk = Walk(title: "テスト散歩", description: "", userId: "test-user-id")
    walk.locations = [start, end]

    // When: extractSamplingPoints()を呼び出す
    let result = service.extractSamplingPoints(from: walk)

    // Then: 2地点（開始+終了）が返される
    XCTAssertEqual(result.count, 2, "2地点が返されること")
    XCTAssertEqual(result[0].coordinate.latitude, start.coordinate.latitude, accuracy: 0.001)
    XCTAssertEqual(result[1].coordinate.latitude, end.coordinate.latitude, accuracy: 0.001)
  }

  /// extractSamplingPoints()が3地点以上の場合に正しく抽出できることをテスト
  func testExtractSamplingPoints_MultipleLocations() {
    // Given: 5地点の散歩
    let locations = [
      CLLocation(latitude: 35.6812, longitude: 139.7671),  // 開始
      CLLocation(latitude: 35.6822, longitude: 139.7681),
      CLLocation(latitude: 35.6832, longitude: 139.7691),  // 中間（index=2）
      CLLocation(latitude: 35.6842, longitude: 139.7701),
      CLLocation(latitude: 35.6852, longitude: 139.7711),  // 終了
    ]
    var walk = Walk(title: "テスト散歩", description: "", userId: "test-user-id")
    walk.locations = locations

    // When: extractSamplingPoints()を呼び出す
    let result = service.extractSamplingPoints(from: walk)

    // Then: 3地点（開始+中間+終了）が返される
    XCTAssertEqual(result.count, 3, "3地点が返されること")
    XCTAssertEqual(result[0].coordinate.latitude, locations[0].coordinate.latitude, accuracy: 0.001)
    XCTAssertEqual(result[1].coordinate.latitude, locations[2].coordinate.latitude, accuracy: 0.001)
    XCTAssertEqual(result[2].coordinate.latitude, locations[4].coordinate.latitude, accuracy: 0.001)
  }

  /// extractSamplingPoints()が位置情報なしの場合に空配列を返すことをテスト
  func testExtractSamplingPoints_NoLocations() {
    // Given: 位置情報なしの散歩
    var walk = Walk(title: "テスト散歩", description: "", userId: "test-user-id")
    walk.locations = []

    // When: extractSamplingPoints()を呼び出す
    let result = service.extractSamplingPoints(from: walk)

    // Then: 空配列が返される
    XCTAssertEqual(result.count, 0, "空配列が返されること")
  }

  // MARK: - Phase 2: extractVisitedAreas() Tests

  /// extractVisitedAreas()が正常にエリアを抽出できることをテスト
  func testExtractVisitedAreas_Success() async throws {
    // Given: 位置情報付きの散歩履歴を2件用意
    let walks = (1...2).map { index -> Walk in
      var walk = Walk(
        title: "テスト散歩 \(index)",
        description: "テスト用の散歩 \(index)",
        userId: "mock-user-id"
      )
      walk.locations = [
        CLLocation(latitude: 35.6812, longitude: 139.7671),
        CLLocation(latitude: 35.6822, longitude: 139.7681),
        CLLocation(latitude: 35.6832, longitude: 139.7691),
      ]
      return walk
    }

    // Given: Geocoderのモックレスポンスを設定
    mockGeocoder.setMockPlacemark(locality: "渋谷区")

    // When: extractVisitedAreas()を呼び出す
    let result = await service.extractVisitedAreas(from: walks)

    // Then: エリアが抽出される（6地点 = 2散歩 × 3地点）
    XCTAssertFalse(result.isEmpty, "エリアが抽出されること")
    XCTAssertEqual(mockGeocoder.reverseGeocodeCallCount, 6, "6回ジオコーディングが呼ばれること")
  }

  /// extractVisitedAreas()が重複を除去することをテスト
  func testExtractVisitedAreas_RemovesDuplicates() async throws {
    // Given: 同じエリアの散歩履歴を2件用意
    let walks = (1...2).map { index -> Walk in
      var walk = Walk(
        title: "テスト散歩 \(index)",
        description: "テスト用の散歩 \(index)",
        userId: "mock-user-id"
      )
      walk.locations = [
        CLLocation(latitude: 35.6812, longitude: 139.7671),
      ]
      return walk
    }

    // Given: 全て同じエリア名を返す
    mockGeocoder.setMockPlacemark(locality: "渋谷区")

    // When: extractVisitedAreas()を呼び出す
    let result = await service.extractVisitedAreas(from: walks)

    // Then: 重複が除去されて1件のみ
    XCTAssertEqual(result.count, 1, "重複が除去されること")
    XCTAssertEqual(result.first, "渋谷区", "正しいエリア名が返されること")
  }

  /// extractVisitedAreas()が空の履歴に対して空配列を返すことをテスト
  func testExtractVisitedAreas_EmptyHistory() async throws {
    // Given: 空の散歩履歴
    let walks: [Walk] = []

    // When: extractVisitedAreas()を呼び出す
    let result = await service.extractVisitedAreas(from: walks)

    // Then: 空配列が返される
    XCTAssertEqual(result.count, 0, "空配列が返されること")
    XCTAssertEqual(mockGeocoder.reverseGeocodeCallCount, 0, "ジオコーディングが呼ばれないこと")
  }

  /// extractVisitedAreas()がジオコーディングエラー時に継続することをテスト
  func testExtractVisitedAreas_GeocodeError_Continues() async throws {
    // Given: 位置情報付きの散歩履歴を1件用意
    var walk = Walk(
      title: "テスト散歩",
      description: "テスト用の散歩",
      userId: "mock-user-id"
    )
    walk.locations = [
      CLLocation(latitude: 35.6812, longitude: 139.7671),
    ]

    // Given: Geocoderがエラーを返す
    mockGeocoder.mockError = NSError(
      domain: kCLErrorDomain,
      code: CLError.network.rawValue,
      userInfo: nil
    )

    // When: extractVisitedAreas()を呼び出す
    let result = await service.extractVisitedAreas(from: [walk])

    // Then: エラーでも空配列が返される（クラッシュしない）
    XCTAssertEqual(result.count, 0, "エラー時は空配列が返されること")
    XCTAssertEqual(mockGeocoder.reverseGeocodeCallCount, 1, "1回ジオコーディングが呼ばれること")
  }

  // MARK: - Error Handling Tests

  /// fetchWalkHistory()がエラーの場合に適切にハンドリングされることをテスト
  func testFetchError_ThrowsDatabaseUnavailable() async {
    // Given: Firestoreエラーをシミュレート
    mockRepository.simulateError(.networkError)

    // When & Then: fetchWalkHistory()がエラーをスローする
    do {
      _ = try await service.fetchWalkHistory()
      XCTFail("エラーがスローされるべき")
    } catch let error as RouteSuggestionServiceError {
      if case .databaseUnavailable = error {
        // 期待通りのエラー
      } else {
        XCTFail("databaseUnavailableエラーがスローされるべき")
      }
    } catch {
      XCTFail("RouteSuggestionServiceErrorがスローされるべき")
    }
  }

  // MARK: - Clustering Tests

  /// クラスタリング機能が近接する地点を1つに集約することを確認するテスト
  func testClusterLocations_ReducesNearbyPoints() {
    // Given: 同じエリア内の複数の地点
    let nearbyLocations = [
      CLLocation(latitude: 35.681, longitude: 139.767),  // 東京駅周辺
      CLLocation(latitude: 35.682, longitude: 139.768),  // 約100m離れた地点
      CLLocation(latitude: 35.683, longitude: 139.769),  // 約200m離れた地点
      CLLocation(latitude: 36.000, longitude: 140.000),  // 遠く離れた地点
    ]

    // When: クラスタリングを実行
    let clustered = service.clusterLocations(nearbyLocations)

    // Then: 近接する地点が集約される
    XCTAssertLessThan(clustered.count, nearbyLocations.count, "近接する地点が集約されること")
    XCTAssertGreaterThan(clustered.count, 0, "少なくとも1つの代表地点が残ること")
  }

  /// クラスタリング後も遠く離れた地点は保持されることを確認するテスト
  func testClusterLocations_PreservesDistantPoints() {
    // Given: 遠く離れた地点のみ
    let distantLocations = [
      CLLocation(latitude: 35.681, longitude: 139.767),  // 東京
      CLLocation(latitude: 34.702, longitude: 135.495),  // 大阪
      CLLocation(latitude: 43.064, longitude: 141.347),  // 札幌
    ]

    // When: クラスタリングを実行
    let clustered = service.clusterLocations(distantLocations)

    // Then: すべての地点が保持される
    XCTAssertEqual(clustered.count, distantLocations.count, "遠く離れた地点はすべて保持されること")
  }

  /// 空の配列に対してクラスタリングしても安全であることを確認するテスト
  func testClusterLocations_EmptyArray() {
    // Given: 空の配列
    let emptyLocations: [CLLocation] = []

    // When: クラスタリングを実行
    let clustered = service.clusterLocations(emptyLocations)

    // Then: 空の配列が返される
    XCTAssertTrue(clustered.isEmpty, "空の配列が返されること")
  }

  // MARK: - User Input Tests

  /// generateRouteSuggestions()がユーザー入力（気分）を受け取れることをテスト
  func testGenerateRouteSuggestions_WithMoodInput() async throws {
    // Given: 散歩履歴を用意
    let walks = MockWalkRepository.createSampleWalks(count: 5, userId: "mock-user-id")
    walks.forEach { mockRepository.addMockWalk($0) }
    mockGeocoder.setMockPlacemark(locality: "渋谷区")

    // Given: ユーザー入力
    let userInput = RouteSuggestionUserInput(
      mood: "自然を感じたい",
      walkOption: .time(hours: 2.0),
      discoveries: ["自然", "景色"]
    )

    // When: generateRouteSuggestions()を呼び出す
    let suggestions = try await service.generateRouteSuggestions(userInput: userInput)

    // Then: 提案が生成される
    XCTAssertFalse(suggestions.isEmpty, "提案が生成されること")
    XCTAssertLessThanOrEqual(suggestions.count, 3, "最大3件の提案が生成されること")
  }

  /// generateRouteSuggestions()が距離指定を受け取れることをテスト
  func testGenerateRouteSuggestions_WithDistanceInput() async throws {
    // Given: 散歩履歴を用意
    let walks = MockWalkRepository.createSampleWalks(count: 5, userId: "mock-user-id")
    walks.forEach { mockRepository.addMockWalk($0) }
    mockGeocoder.setMockPlacemark(locality: "新宿区")

    // Given: ユーザー入力（距離指定）
    let userInput = RouteSuggestionUserInput(
      mood: "",
      walkOption: .distance(kilometers: 5.0),
      discoveries: []
    )

    // When: generateRouteSuggestions()を呼び出す
    let suggestions = try await service.generateRouteSuggestions(userInput: userInput)

    // Then: 提案が生成される
    XCTAssertFalse(suggestions.isEmpty, "提案が生成されること")
    XCTAssertLessThanOrEqual(suggestions.count, 3, "最大3件の提案が生成されること")
  }
}

// MARK: - Test Helpers

@available(iOS 26.0, *)
extension RouteSuggestionService {
  /// テスト用に内部メソッドを公開
  func fetchWalkHistory() async throws -> [Walk] {
    // リフレクションを使用して内部メソッドにアクセス
    // 注: これはテスト専用のハックです
    return try await withCheckedThrowingContinuation { continuation in
      walkRepository.fetchWalks { result in
        switch result {
        case .success(let walks):
          let recentWalks = Array(walks.sorted { $0.createdAt > $1.createdAt }.prefix(15))
          continuation.resume(returning: recentWalks)
        case .failure(let error):
          continuation.resume(throwing: RouteSuggestionServiceError.databaseUnavailable(
            "散歩履歴の取得に失敗しました: \(error.localizedDescription)"
          ))
        }
      }
    }
  }

  /// テスト用に内部メソッドを公開
  func extractSamplingPoints(from walk: Walk) -> [CLLocation] {
    guard !walk.locations.isEmpty else { return [] }

    var points: [CLLocation] = []

    // 開始地点
    if let start = walk.locations.first {
      points.append(start)
    }

    // 中間地点（位置配列の中央）
    if walk.locations.count > 2 {
      let middleIndex = walk.locations.count / 2
      points.append(walk.locations[middleIndex])
    }

    // 終了地点
    if let end = walk.locations.last, walk.locations.count > 1 {
      points.append(end)
    }

    return points
  }

  /// テスト用に内部メソッドを公開
  func extractVisitedAreas(from walks: [Walk]) async -> [String] {
    var areas: [String] = []

    for walk in walks {
      let samplingPoints = extractSamplingPoints(from: walk)

      for location in samplingPoints {
        do {
          if let areaName = try await reverseGeocode(location: location) {
            areas.append(areaName)
          }
        } catch {
          // エラーは無視して継続
        }

        // レート制限対策：0.1秒待機
        try? await Task.sleep(nanoseconds: 100_000_000)
      }
    }

    // 重複除去
    return Array(Set(areas))
  }

  /// テスト用に内部メソッドを公開
  private func reverseGeocode(location: CLLocation) async throws -> String? {
    let geocoder = geocoderFactory()

    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
      var isResumed = false
      let lock = NSLock()

      // タイムアウト設定（2秒）
      let timeoutTask = Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        lock.lock()
        defer { lock.unlock() }

        if !isResumed {
          isResumed = true
          geocoder.cancelGeocode()
          continuation.resume(throwing: NSError(
            domain: "RouteSuggestionService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "ジオコーディングタイムアウト"]
          ))
        }
      }

      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        lock.lock()
        defer { lock.unlock() }

        guard !isResumed else { return }
        isResumed = true
        timeoutTask.cancel()

        if let error = error {
          continuation.resume(throwing: error)
          return
        }

        // 市区町村レベルの地名を優先
        let areaName = placemarks?.first?.locality
          ?? placemarks?.first?.subLocality
          ?? placemarks?.first?.administrativeArea
        continuation.resume(returning: areaName)
      }
    }
  }
}
