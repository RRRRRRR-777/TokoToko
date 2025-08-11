import Foundation

struct Policy: Codable {
    let version: String
    let privacyPolicy: LocalizedContent
    let termsOfService: LocalizedContent
    let updatedAt: Date
    let effectiveDate: Date
}

struct LocalizedContent: Codable {
    let ja: String
    let en: String?
}
