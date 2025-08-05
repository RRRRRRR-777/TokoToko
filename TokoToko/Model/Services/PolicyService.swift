import Foundation
import FirebaseAuth
import FirebaseFirestore

enum PolicyServiceError: LocalizedError {
    case noPolicyFound
    case networkError
    case cacheError

    var errorDescription: String? {
        switch self {
        case .noPolicyFound:
            return "ポリシー情報が見つかりません"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .cacheError:
            return "キャッシュエラーが発生しました"
        }
    }
}

class PolicyService {
    private let firestore: Firestore
    private let cacheKey = "TokoTokoPolicyCache"
    private let cacheExpirationKey = "TokoTokoPolicyCacheExpiration"
    private let cacheExpirationHours: TimeInterval = 24

    init(firestore: Firestore? = nil) {
        // WalkRepositoryの設定済みFirestoreインスタンスを使用
        self.firestore = firestore ?? WalkRepository.shared.sharedFirestore
    }

    // MARK: - Public Methods

    func fetchPolicy() async throws -> Policy {
        print("PolicyService.fetchPolicy() が呼び出されました - スレッド: \(Thread.current)")
        print("PolicyService: 現在のビルド設定確認")
        
        #if DEBUG
        // デバッグモードではテストポリシーを返す
        print("PolicyService: デバッグモード - テストポリシーを返します")
        return Policy(
            version: "1.0.0",
            privacyPolicy: LocalizedContent(
                ja: """
                本アプリケーションは、お客様のプライバシーを尊重し、個人情報の保護に努めます。

                1. 収集する情報
                - 位置情報：散歩ルートの記録
                - 写真：お客様が選択した写真
                - アカウント情報：メールアドレス、表示名

                2. 情報の利用目的
                - サービスの提供と改善
                - お客様サポート

                3. 情報の共有
                お客様の同意なく第三者に個人情報を提供することはありません。
                """,
                en: "Privacy Policy content in English..."
            ),
            termsOfService: LocalizedContent(
                ja: """
                本利用規約は、TokoTokoサービスの利用条件を定めるものです。

                1. サービスの利用
                本サービスを利用するには、本規約に同意していただく必要があります。

                2. 禁止事項
                - 他者への迷惑行為
                - 不正アクセス
                - 著作権侵害

                3. 免責事項
                当社は、本サービスの利用により生じた損害について責任を負いません。
                """,
                en: "Terms of Service content in English..."
            ),
            updatedAt: Date(),
            effectiveDate: Date()
        )
        #else
        // 本番モードではFirestoreから取得
        print("PolicyService: 本番モード(RELEASE) - Firestoreから取得を開始")
        print("PolicyService: Firestoreインスタンス: \(firestore)")
        
        do {
            print("PolicyService: policies/current ドキュメント取得開始")
            let document = try await firestore
                .collection("policies")
                .document("current")
                .getDocument()

            print("PolicyService: ドキュメント取得完了 - exists: \(document.exists)")
            
            guard document.exists, let data = document.data() else {
                print("PolicyService: ドキュメントが存在しないまたはデータがnull")
                // ドキュメントが存在しない場合は、キャッシュを確認
                print("PolicyService: キャッシュから取得を試行")
                if let cachedPolicy = try? await getCachedPolicy() {
                    print("PolicyService: キャッシュから取得成功")
                    return cachedPolicy
                }
                print("PolicyService: キャッシュからも取得できず - noPolicyFoundエラーをスロー")
                throw PolicyServiceError.noPolicyFound
            }

            print("PolicyService: Firestoreデータ取得成功 - パース開始")
            let policy = try parsePolicyFromFirestore(data)
            print("PolicyService: パース成功 - version: \(policy.version)")

            // キャッシュに保存
            print("PolicyService: キャッシュに保存開始")
            try await cachePolicy(policy)
            print("PolicyService: キャッシュ保存完了")

            return policy
        } catch {
            print("PolicyService: エラー発生: \(error)")
            print("PolicyService: エラータイプ: \(type(of: error))")
            
            // エラーの場合、キャッシュから取得を試みる
            print("PolicyService: エラー時キャッシュ取得を試行")
            if let cachedPolicy = try? await getCachedPolicy() {
                print("PolicyService: エラー時キャッシュ取得成功")
                return cachedPolicy
            }
            print("PolicyService: エラー時キャッシュ取得も失敗")

            // 元のエラーを再スロー
            if error is PolicyServiceError {
                print("PolicyService: PolicyServiceErrorを再スロー")
                throw error
            } else {
                print("PolicyService: NetworkErrorとして再スロー")
                throw PolicyServiceError.networkError
            }
        }
        #endif
    }

    func cachePolicy(_ policy: Policy) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(policy)

        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date().addingTimeInterval(cacheExpirationHours * 3600), forKey: cacheExpirationKey)
    }

    func getCachedPolicy() async throws -> Policy? {
        print("PolicyService: キャッシュ取得開始")
        
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            print("PolicyService: キャッシュデータが存在しない (key: \(cacheKey))")
            return nil
        }
        print("PolicyService: キャッシュデータ存在確認OK")
        
        guard let expirationDate = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date else {
            print("PolicyService: キャッシュ有効期限データが存在しない (key: \(cacheExpirationKey))")
            return nil
        }
        print("PolicyService: キャッシュ有効期限: \(expirationDate), 現在: \(Date())")
        
        guard expirationDate > Date() else {
            print("PolicyService: キャッシュが期限切れ")
            return nil
        }
        print("PolicyService: キャッシュは有効")

        let decoder = JSONDecoder()
        do {
            let policy = try decoder.decode(Policy.self, from: data)
            print("PolicyService: キャッシュデコード成功 - version: \(policy.version)")
            return policy
        } catch {
            print("PolicyService: キャッシュデコードエラー: \(error)")
            throw error
        }
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

        // デバッグモードではUserDefaultsに保存
        #if DEBUG
        let encoder = JSONEncoder()
        let data = try encoder.encode(consent)
        let key = "TokoTokoConsentCache_\(userID)"
        UserDefaults.standard.set(data, forKey: key)
        print("DEBUG: Consent saved to UserDefaults with key: \(key)")
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
        // デバッグモードではUserDefaultsから取得
        let key = "TokoTokoConsentCache_\(userID)"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("DEBUG: No consent data found for key: \(key)")
            return nil
        }
        print("DEBUG: Consent data found for key: \(key)")
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

    /// 指定バージョンで再同意が必要かどうかを確認
    func needsReConsent(for policyVersion: String) async -> Bool {
        #if DEBUG
        // デバッグモードでは常にfalseを返す（テスト用）
        return false
        #else
        guard let userID = getCurrentUserID() else { return false }

        do {
            return !(try await hasValidConsent(userID: userID, policyVersion: policyVersion))
        } catch {
            return true // エラーの場合は再同意が必要
        }
        #endif
    }

    /// 同期版の有効な同意確認（ConsentManagerで使用）
    func hasValidConsent() async -> Bool {
        #if DEBUG
        // デバッグモードでは特別なキーをチェック
        return UserDefaults.standard.bool(forKey: "test_has_consent")
        #else
        guard let policy = try? await getCachedPolicy(),
              let userID = getCurrentUserID() else {
            return false
        }

        do {
            return try await hasValidConsent(userID: userID, policyVersion: policy.version)
        } catch {
            return false
        }
        #endif
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

        var deviceInfo: DeviceInfo?
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
    
    private func getCurrentUserID() -> String? {
        return FirebaseAuth.Auth.auth().currentUser?.uid
    }
}
