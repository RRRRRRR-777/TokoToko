import XCTest
@testable import TokoToko

final class PolicyTests: XCTestCase {
    
    func test_Policy_初期化() {
        let privacyPolicy = LocalizedContent(ja: "プライバシーポリシー本文", en: "Privacy Policy content")
        let termsOfService = LocalizedContent(ja: "利用規約本文", en: "Terms of Service content")
        let updatedAt = Date()
        let effectiveDate = Date().addingTimeInterval(-86400)
        
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: privacyPolicy,
            termsOfService: termsOfService,
            updatedAt: updatedAt,
            effectiveDate: effectiveDate
        )
        
        XCTAssertEqual(policy.version, "1.0.0")
        XCTAssertEqual(policy.privacyPolicy.ja, "プライバシーポリシー本文")
        XCTAssertEqual(policy.privacyPolicy.en, "Privacy Policy content")
        XCTAssertEqual(policy.termsOfService.ja, "利用規約本文")
        XCTAssertEqual(policy.termsOfService.en, "Terms of Service content")
        XCTAssertEqual(policy.updatedAt, updatedAt)
        XCTAssertEqual(policy.effectiveDate, effectiveDate)
    }
    
    func test_LocalizedContent_日本語のみ() {
        let content = LocalizedContent(ja: "日本語のみ", en: nil)
        
        XCTAssertEqual(content.ja, "日本語のみ")
        XCTAssertNil(content.en)
    }
    
    func test_Policy_Codable() throws {
        let privacyPolicy = LocalizedContent(ja: "プライバシーポリシー", en: "Privacy Policy")
        let termsOfService = LocalizedContent(ja: "利用規約", en: "Terms of Service")
        let policy = Policy(
            version: "1.0.0",
            privacyPolicy: privacyPolicy,
            termsOfService: termsOfService,
            updatedAt: Date(),
            effectiveDate: Date()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(policy)
        
        let decoder = JSONDecoder()
        let decodedPolicy = try decoder.decode(Policy.self, from: data)
        
        XCTAssertEqual(decodedPolicy.version, policy.version)
        XCTAssertEqual(decodedPolicy.privacyPolicy.ja, policy.privacyPolicy.ja)
        XCTAssertEqual(decodedPolicy.privacyPolicy.en, policy.privacyPolicy.en)
        XCTAssertEqual(decodedPolicy.termsOfService.ja, policy.termsOfService.ja)
        XCTAssertEqual(decodedPolicy.termsOfService.en, policy.termsOfService.en)
    }
}