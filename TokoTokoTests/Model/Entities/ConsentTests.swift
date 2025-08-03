import XCTest
@testable import TokoToko

final class ConsentTests: XCTestCase {
    
    func test_Consent_初期化_初回同意() {
        let consentedAt = Date()
        let deviceInfo = DeviceInfo(
            platform: "iOS",
            osVersion: "17.0",
            appVersion: "1.0.0"
        )
        
        let consent = Consent(
            policyVersion: "1.0.0",
            consentedAt: consentedAt,
            consentType: .initial,
            deviceInfo: deviceInfo
        )
        
        XCTAssertEqual(consent.policyVersion, "1.0.0")
        XCTAssertEqual(consent.consentedAt, consentedAt)
        XCTAssertEqual(consent.consentType, .initial)
        XCTAssertNotNil(consent.deviceInfo)
        XCTAssertEqual(consent.deviceInfo?.platform, "iOS")
        XCTAssertEqual(consent.deviceInfo?.osVersion, "17.0")
        XCTAssertEqual(consent.deviceInfo?.appVersion, "1.0.0")
    }
    
    func test_Consent_初期化_更新同意() {
        let consent = Consent(
            policyVersion: "2.0.0",
            consentedAt: Date(),
            consentType: .update,
            deviceInfo: nil
        )
        
        XCTAssertEqual(consent.policyVersion, "2.0.0")
        XCTAssertEqual(consent.consentType, .update)
        XCTAssertNil(consent.deviceInfo)
    }
    
    func test_ConsentType_RawValue() {
        XCTAssertEqual(ConsentType.initial.rawValue, "initial")
        XCTAssertEqual(ConsentType.update.rawValue, "update")
    }
    
    func test_Consent_Codable() throws {
        let deviceInfo = DeviceInfo(
            platform: "iOS",
            osVersion: "17.0",
            appVersion: "1.0.0"
        )
        let consent = Consent(
            policyVersion: "1.0.0",
            consentedAt: Date(),
            consentType: .initial,
            deviceInfo: deviceInfo
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(consent)
        
        let decoder = JSONDecoder()
        let decodedConsent = try decoder.decode(Consent.self, from: data)
        
        XCTAssertEqual(decodedConsent.policyVersion, consent.policyVersion)
        XCTAssertEqual(decodedConsent.consentType, consent.consentType)
        XCTAssertNotNil(decodedConsent.deviceInfo)
        XCTAssertEqual(decodedConsent.deviceInfo?.platform, consent.deviceInfo?.platform)
        XCTAssertEqual(decodedConsent.deviceInfo?.osVersion, consent.deviceInfo?.osVersion)
        XCTAssertEqual(decodedConsent.deviceInfo?.appVersion, consent.deviceInfo?.appVersion)
    }
    
    func test_DeviceInfo_Codable() throws {
        let deviceInfo = DeviceInfo(
            platform: "iOS",
            osVersion: "17.0",
            appVersion: "1.0.0"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(deviceInfo)
        
        let decoder = JSONDecoder()
        let decodedDeviceInfo = try decoder.decode(DeviceInfo.self, from: data)
        
        XCTAssertEqual(decodedDeviceInfo.platform, deviceInfo.platform)
        XCTAssertEqual(decodedDeviceInfo.osVersion, deviceInfo.osVersion)
        XCTAssertEqual(decodedDeviceInfo.appVersion, deviceInfo.appVersion)
    }
}