import Foundation

struct Consent: Codable {
    let policyVersion: String
    let consentedAt: Date
    let consentType: ConsentType
    let deviceInfo: DeviceInfo?
}

enum ConsentType: String, Codable {
    case initial
    case update
}

struct DeviceInfo: Codable {
    let platform: String
    let osVersion: String
    let appVersion: String
}