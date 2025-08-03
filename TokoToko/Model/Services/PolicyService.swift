import Foundation
import FirebaseFirestore

enum PolicyServiceError: Error {
    case noPolicyFound
    case networkError
    case cacheError
}

class PolicyService {
    private let firestore: Firestore
    private let cacheKey = "TokoTokoPolicyCache"
    private let cacheExpirationKey = "TokoTokoPolicyCacheExpiration"
    private let cacheExpirationHours: TimeInterval = 24
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    
    // MARK: - Public Methods
    
    func fetchPolicy() async throws -> Policy {
        do {
            // Firestoreから取得を試みる
            let document = try await firestore
                .collection("policies")
                .document("current")
                .getDocument()
            
            guard let data = document.data() else {
                throw PolicyServiceError.noPolicyFound
            }
            
            let policy = try parsePolicyFromFirestore(data)
            
            // キャッシュに保存
            try await cachePolicy(policy)
            
            return policy
        } catch {
            // ネットワークエラーの場合、キャッシュから取得を試みる
            if let cachedPolicy = try await getCachedPolicy() {
                return cachedPolicy
            }
            throw PolicyServiceError.networkError
        }
    }
    
    func cachePolicy(_ policy: Policy) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(policy)
        
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date().addingTimeInterval(cacheExpirationHours * 3600), forKey: cacheExpirationKey)
    }
    
    func getCachedPolicy() async throws -> Policy? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let expirationDate = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date,
              expirationDate > Date() else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Policy.self, from: data)
    }
    
    func clearCache() async throws {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpirationKey)
    }
    
    // MARK: - 同意記録機能
    
    func recordConsent(policyVersion: String, userID: String, consentType: ConsentType, deviceInfo: DeviceInfo?) async throws {
        let consent = Consent(
            policyVersion: policyVersion,
            consentedAt: Date(),
            consentType: consentType,
            deviceInfo: deviceInfo
        )
        
        let consentData = try convertConsentToFirestore(consent)
        
        // MockのためのテストデータはUserDefaultsに保存
        #if DEBUG
        let encoder = JSONEncoder()
        let data = try encoder.encode(consent)
        UserDefaults.standard.set(data, forKey: "TokoTokoConsentCache_\(userID)")
        #else
        try await firestore
            .collection("users")
            .document(userID)
            .collection("consents")
            .addDocument(data: consentData)
        #endif
    }
    
    func getLatestConsent(userID: String) async throws -> Consent? {
        #if DEBUG
        // テスト環境ではUserDefaultsから取得
        guard let data = UserDefaults.standard.data(forKey: "TokoTokoConsentCache_\(userID)") else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Consent.self, from: data)
        #else
        let querySnapshot = try await firestore
            .collection("users")
            .document(userID)
            .collection("consents")
            .order(by: "consentedAt", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first,
              let data = document.data() as? [String: Any] else {
            return nil
        }
        
        return try parseConsentFromFirestore(data)
        #endif
    }
    
    func hasValidConsent(userID: String, policyVersion: String) async throws -> Bool {
        guard let latestConsent = try await getLatestConsent(userID: userID) else {
            return false
        }
        
        return latestConsent.policyVersion == policyVersion
    }
    
    // MARK: - Private Methods
    
    private func parsePolicyFromFirestore(_ data: [String: Any]) throws -> Policy {
        guard let version = data["version"] as? String,
              let privacyPolicyData = data["privacyPolicy"] as? [String: Any],
              let termsOfServiceData = data["termsOfService"] as? [String: Any],
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp,
              let effectiveDateTimestamp = data["effectiveDate"] as? Timestamp,
              let privacyPolicyJa = privacyPolicyData["ja"] as? String,
              let termsOfServiceJa = termsOfServiceData["ja"] as? String else {
            throw PolicyServiceError.noPolicyFound
        }
        
        let privacyPolicy = LocalizedContent(
            ja: privacyPolicyJa,
            en: privacyPolicyData["en"] as? String
        )
        
        let termsOfService = LocalizedContent(
            ja: termsOfServiceJa,
            en: termsOfServiceData["en"] as? String
        )
        
        return Policy(
            version: version,
            privacyPolicy: privacyPolicy,
            termsOfService: termsOfService,
            updatedAt: updatedAtTimestamp.dateValue(),
            effectiveDate: effectiveDateTimestamp.dateValue()
        )
    }
    
    private func convertConsentToFirestore(_ consent: Consent) throws -> [String: Any] {
        var data: [String: Any] = [
            "policyVersion": consent.policyVersion,
            "consentedAt": Timestamp(date: consent.consentedAt),
            "consentType": consent.consentType.rawValue
        ]
        
        if let deviceInfo = consent.deviceInfo {
            data["deviceInfo"] = [
                "platform": deviceInfo.platform,
                "osVersion": deviceInfo.osVersion,
                "appVersion": deviceInfo.appVersion
            ]
        }
        
        return data
    }
    
    private func parseConsentFromFirestore(_ data: [String: Any]) throws -> Consent {
        guard let policyVersion = data["policyVersion"] as? String,
              let consentedAtTimestamp = data["consentedAt"] as? Timestamp,
              let consentTypeString = data["consentType"] as? String,
              let consentType = ConsentType(rawValue: consentTypeString) else {
            throw PolicyServiceError.noPolicyFound
        }
        
        var deviceInfo: DeviceInfo? = nil
        if let deviceInfoData = data["deviceInfo"] as? [String: Any],
           let platform = deviceInfoData["platform"] as? String,
           let osVersion = deviceInfoData["osVersion"] as? String,
           let appVersion = deviceInfoData["appVersion"] as? String {
            deviceInfo = DeviceInfo(
                platform: platform,
                osVersion: osVersion,
                appVersion: appVersion
            )
        }
        
        return Consent(
            policyVersion: policyVersion,
            consentedAt: consentedAtTimestamp.dateValue(),
            consentType: consentType,
            deviceInfo: deviceInfo
        )
    }
}

