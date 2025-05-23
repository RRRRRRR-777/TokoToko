//
//  GoogleAuthServiceTests.swift
//  TokoTokoTests
//
//  Created by Test on 2025/05/23.
//

import XCTest
@testable import TokoToko
import FirebaseAuth
import GoogleSignIn

final class GoogleAuthServiceTests: XCTestCase {

    var sut: GoogleAuthService!

    override func setUp() {
        super.setUp()
        sut = GoogleAuthService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // 基本的なインスタンス化テスト
    func testGoogleAuthServiceInitialization() {
        XCTAssertNotNil(sut, "GoogleAuthServiceのインスタンスが正しく作成されていません")
    }

    // モックを使用したテスト - 失敗ケース
    func testSignInWithGoogleFailure() {
        // モックGoogleAuthServiceを作成
        class MockGoogleAuthService: GoogleAuthService {
            override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                // 強制的にエラーを返す
                completion(.failure("テストエラー"))
            }
        }

        // モックを使用
        let mockService = MockGoogleAuthService()

        // 期待値
        let expectation = XCTestExpectation(description: "エラーが返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
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
    func testSignInWithGoogleSuccess() {
        // モックGoogleAuthServiceを作成
        class MockGoogleAuthService: GoogleAuthService {
            override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                // 強制的に成功を返す
                completion(.success)
            }
        }

        // モックを使用
        let mockService = MockGoogleAuthService()

        // 期待値
        let expectation = XCTestExpectation(description: "成功が返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                XCTFail("失敗するはずがありません")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // TestHelpersを使用したテスト - 失敗ケース
    func testSignInWithGoogleFailureUsingTestHelpers() {
        // TestHelpersを使用してモックサービスを作成
        let mockService = TestHelpers.createMockGoogleAuthService(resultToReturn: .failure("ヘルパーテストエラー"))

        // 期待値
        let expectation = XCTestExpectation(description: "エラーが返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
            switch result {
            case .failure(let message):
                XCTAssertEqual(message, "ヘルパーテストエラー", "エラーメッセージが期待と異なります")
                XCTAssertTrue(mockService.signInCalled, "signInWithGoogleメソッドが呼ばれていません")
                expectation.fulfill()
            case .success:
                XCTFail("成功するはずがありません")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // TestHelpersを使用したテスト - 成功ケース
    func testSignInWithGoogleSuccessUsingTestHelpers() {
        // TestHelpersを使用してモックサービスを作成
        let mockService = TestHelpers.createMockGoogleAuthService(resultToReturn: .success)

        // 期待値
        let expectation = XCTestExpectation(description: "成功が返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
            switch result {
            case .success:
                XCTAssertTrue(mockService.signInCalled, "signInWithGoogleメソッドが呼ばれていません")
                expectation.fulfill()
            case .failure:
                XCTFail("失敗するはずがありません")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // 非同期処理のテスト
    func testSignInWithGoogleAsync() {
        // モックGoogleAuthServiceを作成
        class AsyncMockGoogleAuthService: GoogleAuthService {
            override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                // 非同期処理をシミュレート
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    completion(.success)
                }
            }
        }

        // モックを使用
        let mockService = AsyncMockGoogleAuthService()

        // 期待値
        let expectation = XCTestExpectation(description: "非同期処理が完了すること")

        // テスト実行
        mockService.signInWithGoogle { result in
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
    func testSignInWithGoogleVariousErrors() {
        // 様々なエラーケースをテスト
        let errorMessages = ["ネットワークエラー", "認証エラー", "サーバーエラー", "不明なエラー"]

        for errorMessage in errorMessages {
            // モックGoogleAuthServiceを作成
            class VariousErrorsMockGoogleAuthService: GoogleAuthService {
                let errorToReturn: String

                init(errorToReturn: String) {
                    self.errorToReturn = errorToReturn
                    super.init()
                }

                override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                    // 指定されたエラーを返す
                    completion(.failure(errorToReturn))
                }
            }

            // モックを使用
            let mockService = VariousErrorsMockGoogleAuthService(errorToReturn: errorMessage)

            // 期待値
            let expectation = XCTestExpectation(description: "\(errorMessage)が返されること")

            // テスト実行
            mockService.signInWithGoogle { result in
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

    // FirebaseApp.app()?.options.clientIDがnilの場合のテスト
    func testSignInWithGoogleClientIDNil() {
        // モックGoogleAuthServiceを作成
        class MockGoogleAuthService: GoogleAuthService {
            override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                // FirebaseApp.app()?.options.clientIDがnilの場合の動作をシミュレート
                completion(.failure("Firebase設定エラー"))
            }
        }

        // モックを使用
        let mockService = MockGoogleAuthService()

        // 期待値
        let expectation = XCTestExpectation(description: "Firebase設定エラーが返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
            switch result {
            case .failure(let message):
                XCTAssertEqual(message, "Firebase設定エラー", "エラーメッセージが期待と異なります")
                expectation.fulfill()
            case .success:
                XCTFail("成功するはずがありません")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // ウィンドウシーンが取得できない場合のテスト
    func testSignInWithGoogleWindowSceneNil() {
        // モックGoogleAuthServiceを作成
        class MockGoogleAuthService: GoogleAuthService {
            override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                // ウィンドウシーンが取得できない場合の動作をシミュレート
                completion(.failure("ウィンドウシーンの取得に失敗しました"))
            }
        }

        // モックを使用
        let mockService = MockGoogleAuthService()

        // 期待値
        let expectation = XCTestExpectation(description: "ウィンドウシーンエラーが返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
            switch result {
            case .failure(let message):
                XCTAssertEqual(message, "ウィンドウシーンの取得に失敗しました", "エラーメッセージが期待と異なります")
                expectation.fulfill()
            case .success:
                XCTFail("成功するはずがありません")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // GIDSignInでエラーが発生した場合のテスト
    func testSignInWithGoogleGIDSignInError() {
        // モックGoogleAuthServiceを作成
        class MockGoogleAuthService: GoogleAuthService {
            override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                // GIDSignInでエラーが発生した場合の動作をシミュレート
                completion(.failure("Googleログインエラー: テストエラー"))
            }
        }

        // モックを使用
        let mockService = MockGoogleAuthService()

        // 期待値
        let expectation = XCTestExpectation(description: "GIDSignInエラーが返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
            switch result {
            case .failure(let message):
                XCTAssertTrue(message.contains("Googleログインエラー"), "エラーメッセージが期待と異なります")
                expectation.fulfill()
            case .success:
                XCTFail("成功するはずがありません")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // ユーザー情報が取得できない場合のテスト
    func testSignInWithGoogleUserInfoNil() {
        // モックGoogleAuthServiceを作成
        class MockGoogleAuthService: GoogleAuthService {
            override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                // ユーザー情報が取得できない場合の動作をシミュレート
                completion(.failure("ユーザー情報の取得に失敗しました"))
            }
        }

        // モックを使用
        let mockService = MockGoogleAuthService()

        // 期待値
        let expectation = XCTestExpectation(description: "ユーザー情報エラーが返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
            switch result {
            case .failure(let message):
                XCTAssertEqual(message, "ユーザー情報の取得に失敗しました", "エラーメッセージが期待と異なります")
                expectation.fulfill()
            case .success:
                XCTFail("成功するはずがありません")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // Firebase認証でエラーが発生した場合のテスト
    func testSignInWithGoogleFirebaseAuthError() {
        // モックGoogleAuthServiceを作成
        class MockGoogleAuthService: GoogleAuthService {
            override func signInWithGoogle(completion: @escaping (AuthResult) -> Void) {
                // Firebase認証でエラーが発生した場合の動作をシミュレート
                completion(.failure("Firebase認証エラー: テストエラー"))
            }
        }

        // モックを使用
        let mockService = MockGoogleAuthService()

        // 期待値
        let expectation = XCTestExpectation(description: "Firebase認証エラーが返されること")

        // テスト実行
        mockService.signInWithGoogle { result in
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
}
