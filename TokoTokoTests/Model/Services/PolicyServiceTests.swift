import XCTest
import FirebaseFirestore
@testable import TekuToko

final class PolicyServiceTests: XCTestCase {
    private var sut: PolicyService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = PolicyService()
        // 同意キャッシュをクリア（同期的に実行）
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.hasPrefix("TokoTokoConsentCache_") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - キャッシュテスト
    
    func test_cachePolicy_保存と取得() async throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー", en: nil),
            termsOfService: LocalizedContent(ja: "利用規約", en: nil),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        
        // When
        try await sut.cachePolicy(policy)
        let cachedPolicy = try await sut.getCachedPolicy()
        
        // Then
        XCTAssertNotNil(cachedPolicy)
        XCTAssertEqual(cachedPolicy?.version, policy.version)
        XCTAssertEqual(cachedPolicy?.privacyPolicy.ja, policy.privacyPolicy.ja)
        XCTAssertEqual(cachedPolicy?.termsOfService.ja, policy.termsOfService.ja)
    }
    
    func test_getCachedPolicy_キャッシュなしの場合() async throws {
        // When
        let cachedPolicy = try await sut.getCachedPolicy()
        
        // Then
        XCTAssertNil(cachedPolicy)
    }
    
    func test_clearCache() async throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー", en: nil),
            termsOfService: LocalizedContent(ja: "利用規約", en: nil),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        try await sut.cachePolicy(policy)
        
        // When
        try await sut.clearCache()
        let cachedPolicy = try await sut.getCachedPolicy()
        
        // Then
        XCTAssertNil(cachedPolicy)
    }
    
    func test_cachePolicy_期限切れの場合() async throws {
        // Given
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(ja: "プライバシーポリシー", en: nil),
            termsOfService: LocalizedContent(ja: "利用規約", en: nil),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        
        // キャッシュを保存
        try await sut.cachePolicy(policy)
        
        // 期限を過去に設定
        UserDefaults.standard.set(Date().addingTimeInterval(-3600), forKey: "TokoTokoPolicyCacheExpiration")
        
        // When
        let cachedPolicy = try await sut.getCachedPolicy()
        
        // Then
        XCTAssertNil(cachedPolicy)
    }
    
    // MARK: - 同意記録テスト
    
    func test_recordConsent_初回同意() async throws {
        // Given
        let policyVersion = "1.0.0"
        let userID = "testUser123"
        let deviceInfo = DeviceInfo(
            platform: "iOS",
            osVersion: "17.0",
            appVersion: "1.0.0"
        )
        
        // When
        try await sut.recordConsent(policyVersion: policyVersion, userID: userID, consentType: .initial, deviceInfo: deviceInfo)
        
        // Then
        let consent = try await sut.getLatestConsent(userID: userID)
        XCTAssertNotNil(consent)
        XCTAssertEqual(consent?.policyVersion, policyVersion)
        XCTAssertEqual(consent?.consentType, .initial)
        XCTAssertEqual(consent?.deviceInfo?.platform, "iOS")
    }
    
    func test_recordConsent_更新同意() async throws {
        // Given
        let policyVersion = "2.0.0"
        let userID = "testUser123"
        
        
        // When
        try await sut.recordConsent(policyVersion: policyVersion, userID: userID, consentType: .update, deviceInfo: nil)
        
        print("TEST: recordConsent completed")
        
        // Then
        let consent = try await sut.getLatestConsent(userID: userID)
        print("TEST: Retrieved consent: \(String(describing: consent))")
        
        XCTAssertNotNil(consent)
        XCTAssertEqual(consent?.policyVersion, policyVersion)
        XCTAssertEqual(consent?.consentType, .update)
        XCTAssertNil(consent?.deviceInfo)
        
        print("TEST: Test completed")
    }
    
    func test_hasValidConsent_同意済み() async throws {
        // Given
        let policyVersion = "1.0.0"
        let userID = "testUser123"
        
        // 同意を記録
        try await sut.recordConsent(policyVersion: policyVersion, userID: userID, consentType: .initial, deviceInfo: nil)
        
        // When
        let hasValidConsent = try await sut.hasValidConsent(userID: userID, policyVersion: policyVersion)
        
        // Then
        XCTAssertTrue(hasValidConsent)
    }
    
    func test_hasValidConsent_古いバージョンの同意() async throws {
        // Given
        let oldPolicyVersion = "1.0.0"
        let newPolicyVersion = "2.0.0"
        let userID = "testUser123"
        
        // 古いバージョンで同意を記録
        try await sut.recordConsent(policyVersion: oldPolicyVersion, userID: userID, consentType: .initial, deviceInfo: nil)
        
        // When
        let hasValidConsent = try await sut.hasValidConsent(userID: userID, policyVersion: newPolicyVersion)
        
        // Then
        XCTAssertFalse(hasValidConsent)
    }
    
    func test_hasValidConsent_同意なし() async throws {
        // Given
        let policyVersion = "1.0.0"
        let userID = "testUser123"
        
        // 確実にキャッシュをクリア
        UserDefaults.standard.removeObject(forKey: "TokoTokoConsentCache_\(userID)")
        
        // When
        let hasValidConsent = try await sut.hasValidConsent(userID: userID, policyVersion: policyVersion)
        
        // Then
        XCTAssertFalse(hasValidConsent)
    }
}
