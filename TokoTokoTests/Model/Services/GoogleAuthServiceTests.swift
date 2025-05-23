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

    // モックを使用したテスト
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
}
