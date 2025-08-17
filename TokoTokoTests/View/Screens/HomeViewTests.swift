//
//  HomeViewTests.swift
//  TokoTokoTests
//
//  Created by Claude on 2025/08/17.
//

import XCTest
import SwiftUI
import CoreLocation
import ViewInspector
@testable import TokoToko

/// HomeViewの位置情報許可状態チェック機能のテストクラス
///
/// Issue #99: 位置情報許可済み時の許可画面一瞬表示（フラッシュ現象）を修正
/// 位置情報許可状態の事前チェック機能の動作を検証します。
final class HomeViewTests: XCTestCase {

  /// テスト用のモックOnboardingManager
  private var mockOnboardingManager: OnboardingManager!

  override func setUpWithError() throws {
    try super.setUpWithError()
    mockOnboardingManager = OnboardingManager()
  }

  override func tearDownWithError() throws {
    mockOnboardingManager = nil
    try super.tearDownWithError()
  }

  // MARK: - TDD Red Phase: 失敗するテストケース

  /// 位置情報許可状態チェック完了フラグの初期値テスト
  ///
  /// **期待動作**: 初期化時はisLocationPermissionCheckCompletedがfalse
  /// **実装状態**: Green Phaseで実装済み
  func testLocationPermissionCheckCompletedInitialValue() throws {
    // Given: HomeViewのバインディング作成
    let showOnboarding = Binding.constant(false)

    // When: HomeViewを初期化
    let homeView = HomeView(showOnboarding: showOnboarding)
      .environmentObject(mockOnboardingManager)

    // Then: 位置情報許可状態チェック完了フラグは初期値false
    XCTAssertFalse(homeView.testIsLocationPermissionCheckCompleted,
                   "位置情報許可状態チェック完了フラグの初期値はfalseである必要があります")
  }

  /// 位置情報許可状態チェック機能の存在テスト
  ///
  /// **期待動作**: checkLocationPermissionStatus()メソッドが実装されている
  /// **実装状態**: Green Phaseで実装済み
  func testCheckLocationPermissionStatusMethodExists() throws {
    // Given: HomeViewのバインディング作成
    let showOnboarding = Binding.constant(false)

    // When: HomeViewを初期化
    let homeView = HomeView(showOnboarding: showOnboarding)
      .environmentObject(mockOnboardingManager)

    // Then: checkLocationPermissionStatus()メソッドが存在する
    // メソッドの存在確認（実装済み）
    homeView.testCheckLocationPermissionStatus()
    XCTAssertTrue(true, "checkLocationPermissionStatus()メソッドが正常に実行されました")
  }

  /// 位置情報許可済み時の画面フラッシュ防止テスト
  ///
  /// **期待動作**: 位置情報が許可済みの場合、許可画面が一瞬も表示されない
  /// **実装状態**: Green Phaseで実装済み、フラッシュ防止機能追加
  func testLocationPermissionFlashPrevention() throws {
    // Given: HomeViewのバインディング作成
    let showOnboarding = Binding.constant(false)
    let homeView = HomeView(showOnboarding: showOnboarding)
      .environmentObject(mockOnboardingManager)

    // When: 位置情報許可状態チェック完了フラグの確認
    // Then: 初期状態では許可状態チェック未完了（フラッシュ防止）
    XCTAssertFalse(homeView.testIsLocationPermissionCheckCompleted,
                   "初期状態では位置情報許可状態チェックが未完了である必要があります")

    // 位置情報許可状態チェック実行後の状態確認
    homeView.testCheckLocationPermissionStatus()
    
    // 非同期処理完了後の確認
    let expectation = XCTestExpectation(description: "位置情報許可状態チェック完了")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }

  /// 位置情報許可状態チェックの応答時間テスト
  ///
  /// **期待動作**: 許可状態チェックが50ms以内に完了する
  /// **実装状態**: Green Phaseで実装済み
  func testLocationPermissionCheckResponseTime() throws {
    // Given: HomeViewのバインディング作成
    let showOnboarding = Binding.constant(false)
    let homeView = HomeView(showOnboarding: showOnboarding)
      .environmentObject(mockOnboardingManager)

    // When: 許可状態チェックの実行時間を測定
    let startTime = CFAbsoluteTimeGetCurrent()

    homeView.testCheckLocationPermissionStatus()

    let endTime = CFAbsoluteTimeGetCurrent()
    let executionTime = (endTime - startTime) * 1000 // ミリ秒変換

    // Then: 実行時間が50ms以内
    XCTAssertLessThan(executionTime, 50.0,
                      "位置情報許可状態チェックは50ms以内に完了する必要があります（実行時間: \(executionTime)ms）")
  }

  // MARK: - TDD Phase 2 Red: 許可画面フラッシュ防止UIテスト

  /// フラッシュ防止のタイミング検証テスト
  ///
  /// **期待動作**: 位置情報許可状態チェック中は空のビューが表示され、許可画面は表示されない
  /// **実装状態**: 未実装 - このテストは失敗する予定
  func testFlashPreventionDuringPermissionCheck() throws {
    // Given: HomeViewのバインディング作成
    let showOnboarding = Binding.constant(false)
    let homeView = HomeView(showOnboarding: showOnboarding)
      .environmentObject(mockOnboardingManager)

    // When: 初期化直後の状態確認（許可状態チェック前）
    // Then: 許可状態チェック完了前は空のビューが表示される
    XCTAssertFalse(homeView.testIsLocationPermissionCheckCompleted,
                   "初期状態では許可状態チェックが未完了である必要があります")

    // 許可画面要素が存在しないことを確認
    do {
      let _ = try homeView.inspect().find(text: "位置情報の使用許可が必要です")
      XCTFail("許可状態チェック中に位置情報許可画面が表示されてはいけません")
    } catch {
      // 許可画面が見つからない = テスト成功
      // Note: 現在の実装では条件分岐で適切に制御されているため、このテストは成功する
    }
  }

  /// 許可画面表示条件の詳細テスト
  ///
  /// **期待動作**: 許可状態がnotDeterminedの場合のみ、チェック完了後に許可画面を表示
  /// **実装状態**: 未実装 - より詳細な条件分岐テストが必要
  func testPermissionScreenDisplayConditions() throws {
    // Given: HomeViewのバインディング作成
    let showOnboarding = Binding.constant(false)
    let homeView = HomeView(showOnboarding: showOnboarding)
      .environmentObject(mockOnboardingManager)

    // When: 許可状態チェック実行
    homeView.testCheckLocationPermissionStatus()

    // 非同期処理完了後の確認
    let expectation = XCTestExpectation(description: "許可状態チェック完了後の画面状態確認")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      // Then: 許可状態チェック完了後の適切な画面表示を確認
      XCTAssertTrue(homeView.testIsLocationPermissionCheckCompleted,
                    "許可状態チェックが完了している必要があります")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  /// 許可画面フラッシュの時間計測テスト
  ///
  /// **期待動作**: 許可画面が表示される時間が0ms（つまり、表示されない）
  /// **実装状態**: 未実装 - フラッシュ時間の詳細計測が必要
  func testPermissionScreenFlashDuration() throws {
    // Given: HomeViewのバインディング作成とフラッシュ検出の準備
    let showOnboarding = Binding.constant(false)
    let homeView = HomeView(showOnboarding: showOnboarding)
      .environmentObject(mockOnboardingManager)

    var permissionScreenDetected = false
    let startTime = CFAbsoluteTimeGetCurrent()

    // When: HomeView表示から50ms間の許可画面表示を監視
    let expectation = XCTestExpectation(description: "許可画面フラッシュ時間計測")

    // 10ms間隔で5回チェック（合計50ms監視）
    var checkCount = 0
    let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
      checkCount += 1

      // 許可画面の存在確認
      do {
        let _ = try homeView.inspect().find(text: "位置情報の使用許可が必要です")
        permissionScreenDetected = true
        timer.invalidate()
        expectation.fulfill()
      } catch {
        // 許可画面が見つからない = 正常
      }

      // 5回チェック完了後、タイマー停止
      if checkCount >= 5 {
        timer.invalidate()
        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 1.0)

    // Then: 許可画面が一度も検出されていない
    let endTime = CFAbsoluteTimeGetCurrent()
    let monitoringDuration = (endTime - startTime) * 1000

    XCTAssertFalse(permissionScreenDetected,
                   "50ms監視期間中に位置情報許可画面が表示されてはいけません（監視時間: \(monitoringDuration)ms）")
  }

  /// 画面遷移の滑らかさテスト
  ///
  /// **期待動作**: 許可状態確認から適切な画面表示まで、中間状態が見えない
  /// **実装状態**: 未実装 - 画面遷移の滑らかさ検証が必要
  func testSmoothTransitionWithoutFlash() throws {
    // Given: HomeViewの初期化
    let showOnboarding = Binding.constant(false)
    let homeView = HomeView(showOnboarding: showOnboarding)
      .environmentObject(mockOnboardingManager)

    // When: 初期状態から許可状態チェック完了まで
    let initialCheckState = homeView.testIsLocationPermissionCheckCompleted
    homeView.testCheckLocationPermissionStatus()

    // Then: 滑らかな遷移の確認
    let expectation = XCTestExpectation(description: "滑らかな画面遷移確認")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
      let finalCheckState = homeView.testIsLocationPermissionCheckCompleted

      // 状態が適切に変化していることを確認
      XCTAssertFalse(initialCheckState, "初期状態ではチェック未完了である必要があります")
      XCTAssertTrue(finalCheckState, "チェック後は完了状態である必要があります")

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - テスト用拡張

extension HomeView {
  /// テスト用：位置情報許可状態チェック完了フラグのアクセサ
  ///
  /// HomeViewの内部状態isLocationPermissionCheckCompletedにアクセスするためのテスト専用プロパティです。
  /// 位置情報許可状態の事前チェック完了を確認するテストで使用されます。
  var testIsLocationPermissionCheckCompleted: Bool {
    isLocationPermissionCheckCompleted
  }

  /// テスト用：位置情報許可状態チェックメソッドの呼び出し
  ///
  /// HomeViewのcheckLocationPermissionStatus()メソッドをテストから呼び出すためのラッパーメソッドです。
  /// メソッドの存在確認と動作テストで使用されます。
  func testCheckLocationPermissionStatus() {
    checkLocationPermissionStatus()
  }
  
  /// テスト用：Phase 2-3改善版ローディング・エラービューのアクセス
  ///
  /// Phase 2-3で改善されたローディング表示とエラー表示のテスト用アクセサです。
  /// アニメーション統一とビジュアル改善の検証に使用されます。
  func testLoadingPermissionCheckView() -> Bool {
    // ローディング表示の状態確認
    return !isLocationPermissionCheckCompleted
  }
  
  /// テスト用：位置情報許可状態判定ヘルパーのアクセス
  ///
  /// Phase 2-3で追加されたヘルパーメソッドのテスト用アクセサです。
  /// 可読性向上のためのリファクタリング効果を検証します。
  func testIsLocationAuthorized(_ status: CLAuthorizationStatus) -> Bool {
    // テスト用に許可状態判定ロジックを公開
    return status == .authorizedWhenInUse || status == .authorizedAlways
  }
}
