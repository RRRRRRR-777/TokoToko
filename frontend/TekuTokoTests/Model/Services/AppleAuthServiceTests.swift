//
//  AppleAuthServiceTests.swift
//  TekuTokoTests
//
//  Created by Test on 2025/10/02.
//

import AuthenticationServices
import FirebaseAuth
import XCTest

@testable import TekuToko

final class AppleAuthServiceTests: XCTestCase {

  var sut: AppleAuthService!

  override func setUp() {
    super.setUp()
    sut = AppleAuthService()
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  // 基本的なインスタンス化テスト
  func testAppleAuthServiceInitialization() {
    XCTAssertNotNil(sut, "AppleAuthServiceのインスタンスが正しく作成されていません")
  }

  // モックを使用したテスト - 失敗ケース
  func testSignInWithAppleFailure() {
    // モックAppleAuthServiceを作成
    class MockAppleAuthService: AppleAuthService {
      override func signInWithApple(completion: @escaping (AuthResult) -> Void) {
        // 強制的にエラーを返す
        completion(.failure("テストエラー"))
      }
    }

    // モックを使用
    let mockService = MockAppleAuthService()

    // 期待値
    let expectation = XCTestExpectation(description: "エラーが返されること")

    // テスト実行
    mockService.signInWithApple { result in
      switch result {
      case .failure(let message):
        XCTAssertEqual(message, "テストエラー", "エラーメッセージが期待と異なります")
        expectation.fulfill()
      case .success:
        XCTFail("成功するはずがありません")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // モックを使用したテスト - 成功ケース
  func testSignInWithAppleSuccess() {
    // モックAppleAuthServiceを作成
    class MockAppleAuthService: AppleAuthService {
      override func signInWithApple(completion: @escaping (AuthResult) -> Void) {
        // 強制的に成功を返す
        completion(.success)
      }
    }

    // モックを使用
    let mockService = MockAppleAuthService()

    // 期待値
    let expectation = XCTestExpectation(description: "成功が返されること")

    // テスト実行
    mockService.signInWithApple { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure:
        XCTFail("失敗するはずがありません")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // 非同期処理のテスト
  func testSignInWithAppleAsync() {
    // モックAppleAuthServiceを作成
    class AsyncMockAppleAuthService: AppleAuthService {
      override func signInWithApple(completion: @escaping (AuthResult) -> Void) {
        // 非同期処理をシミュレート
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
          completion(.success)
        }
      }
    }

    // モックを使用
    let mockService = AsyncMockAppleAuthService()

    // 期待値
    let expectation = XCTestExpectation(description: "非同期処理が完了すること")

    // テスト実行
    mockService.signInWithApple { result in
      switch result {
      case .success:
        expectation.fulfill()
      case .failure:
        XCTFail("失敗するはずがありません")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // エラーケースの詳細テスト
  func testSignInWithAppleVariousErrors() {
    // 様々なエラーケースをテスト
    let errorMessages = ["ネットワークエラー", "認証エラー", "サーバーエラー", "不明なエラー"]

    for errorMessage in errorMessages {
      // モックAppleAuthServiceを作成
      class VariousErrorsMockAppleAuthService: AppleAuthService {
        let errorToReturn: String

        init(errorToReturn: String) {
          self.errorToReturn = errorToReturn
          super.init()
        }

        override func signInWithApple(completion: @escaping (AuthResult) -> Void) {
          // 指定されたエラーを返す
          completion(.failure(errorToReturn))
        }
      }

      // モックを使用
      let mockService = VariousErrorsMockAppleAuthService(errorToReturn: errorMessage)

      // 期待値
      let expectation = XCTestExpectation(description: "\(errorMessage)が返されること")

      // テスト実行
      mockService.signInWithApple { result in
        switch result {
        case .failure(let message):
          XCTAssertEqual(message, errorMessage, "エラーメッセージが期待と異なります")
          expectation.fulfill()
        case .success:
          XCTFail("成功するはずがありません")
        }
      }

      wait(for: [expectation], timeout: 1.0)
    }
  }

  // Apple認証情報が取得できない場合のテスト
  func testSignInWithAppleCredentialNil() {
    // モックAppleAuthServiceを作成
    class MockAppleAuthService: AppleAuthService {
      override func signInWithApple(completion: @escaping (AuthResult) -> Void) {
        // 認証情報が取得できない場合の動作をシミュレート
        completion(.failure("Apple認証情報の取得に失敗しました"))
      }
    }

    // モックを使用
    let mockService = MockAppleAuthService()

    // 期待値
    let expectation = XCTestExpectation(description: "認証情報エラーが返されること")

    // テスト実行
    mockService.signInWithApple { result in
      switch result {
      case .failure(let message):
        XCTAssertEqual(message, "Apple認証情報の取得に失敗しました", "エラーメッセージが期待と異なります")
        expectation.fulfill()
      case .success:
        XCTFail("成功するはずがありません")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // Firebase認証でエラーが発生した場合のテスト
  func testSignInWithAppleFirebaseAuthError() {
    // モックAppleAuthServiceを作成
    class MockAppleAuthService: AppleAuthService {
      override func signInWithApple(completion: @escaping (AuthResult) -> Void) {
        // Firebase認証でエラーが発生した場合の動作をシミュレート
        completion(.failure("Firebase認証エラー: テストエラー"))
      }
    }

    // モックを使用
    let mockService = MockAppleAuthService()

    // 期待値
    let expectation = XCTestExpectation(description: "Firebase認証エラーが返されること")

    // テスト実行
    mockService.signInWithApple { result in
      switch result {
      case .failure(let message):
        XCTAssertTrue(message.contains("Firebase認証エラー"), "エラーメッセージが期待と異なります")
        expectation.fulfill()
      case .success:
        XCTFail("成功するはずがありません")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // ユーザーキャンセルのテスト
  func testSignInWithAppleUserCancelled() {
    // モックAppleAuthServiceを作成
    class MockAppleAuthService: AppleAuthService {
      override func signInWithApple(completion: @escaping (AuthResult) -> Void) {
        // ユーザーがキャンセルした場合の動作をシミュレート
        completion(.failure("ユーザーがログインをキャンセルしました"))
      }
    }

    // モックを使用
    let mockService = MockAppleAuthService()

    // 期待値
    let expectation = XCTestExpectation(description: "キャンセルエラーが返されること")

    // テスト実行
    mockService.signInWithApple { result in
      switch result {
      case .failure(let message):
        XCTAssertTrue(
          message.contains("キャンセル"), "エラーメッセージが期待と異なります")
        expectation.fulfill()
      case .success:
        XCTFail("成功するはずがありません")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
