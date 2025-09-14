import FirebaseAuth
import FirebaseFirestore
import Foundation
import Yams

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
  // Firestoreは遅延初期化して、UIテスト/DEBUGで未使用なら起動時依存を発火させない
  private lazy var firestore: Firestore = {
    Firestore.firestore()
  }()
  // 後方互換: 旧キー(TokoToko*)から新キー(TekuToko*)へ移行
  private let newCacheKey = "TekuTokoPolicyCache"
  private let newCacheExpirationKey = "TekuTokoPolicyCacheExpiration"
  private let oldCacheKey = "TekuTokoPolicyCache"
  private let oldCacheExpirationKey = "TekuTokoPolicyCacheExpiration"
  private let cacheExpirationHours: TimeInterval = 24

  init(firestore: Firestore? = nil) {
    if let firestore {
      self.firestore = firestore
    }
  }

  // MARK: - Public Methods

  func fetchPolicy() async throws -> Policy {
    // 新しいフォールバック順序: YMLファイル → キャッシュ → エラー

    // 1. YMLファイルから読み込みを試行
    if let ymlPolicy = try? await loadPolicyFromYML() {
      // YML読み込み成功時はキャッシュに保存
      try await cachePolicy(ymlPolicy)
      return ymlPolicy
    }

    // 2. キャッシュから読み込みを試行
    if let cachedPolicy = try? await getCachedPolicy() {
      return cachedPolicy
    }

    // 3. すべて失敗した場合はエラー
    throw PolicyServiceError.noPolicyFound
  }

  func cachePolicy(_ policy: Policy) async throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(policy)

    UserDefaults.standard.set(data, forKey: newCacheKey)
    UserDefaults.standard.set(
      Date().addingTimeInterval(cacheExpirationHours * 3600), forKey: newCacheExpirationKey)
  }

  func getCachedPolicy() async throws -> Policy? {
    // 新キー優先、なければ旧キーをフォールバックで参照
    let data =
      UserDefaults.standard.data(forKey: newCacheKey)
      ?? UserDefaults.standard.data(forKey: oldCacheKey)
    guard let data else {
      return nil
    }

    let expirationDate =
      (UserDefaults.standard.object(forKey: newCacheExpirationKey) as? Date)
      ?? (UserDefaults.standard.object(forKey: oldCacheExpirationKey) as? Date)
    guard let expirationDate else {
      return nil
    }

    guard expirationDate > Date() else {
      return nil
    }

    let decoder = JSONDecoder()
    do {
      let policy = try decoder.decode(Policy.self, from: data)
      return policy
    } catch {
      throw error
    }
  }

  func clearCache() async throws {
    UserDefaults.standard.removeObject(forKey: newCacheKey)
    UserDefaults.standard.removeObject(forKey: newCacheExpirationKey)
    UserDefaults.standard.removeObject(forKey: oldCacheKey)
    UserDefaults.standard.removeObject(forKey: oldCacheExpirationKey)
  }

  // MARK: - 同意記録機能

  func recordConsent(
    policyVersion: String, userID: String, consentType: ConsentType, deviceInfo: DeviceInfo?
  ) async throws {
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
      let newKey = "TekuTokoConsentCache_\(userID)"
      let oldKey = "TekuTokoConsentCache_\(userID)"
      // 新旧両方に書き込み（短期間の移行を想定）
      UserDefaults.standard.set(data, forKey: newKey)
      UserDefaults.standard.set(data, forKey: oldKey)
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
      let newKey = "TekuTokoConsentCache_\(userID)"
      let oldKey = "TekuTokoConsentCache_\(userID)"
      guard
        let data = UserDefaults.standard.data(forKey: newKey)
          ?? UserDefaults.standard.data(forKey: oldKey)
      else { return nil }
      let decoder = JSONDecoder()
      return try decoder.decode(Consent.self, from: data)
    #else
      let querySnapshot =
        try await firestore
        .collection("users")
        .document(userID)
        .collection("consents")
        .order(by: "consentedAt", descending: true)
        .limit(to: 1)
        .getDocuments()

      guard let document = querySnapshot.documents.first,
        let data = document.data() as? [String: Any]
      else {
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
      guard let userID = getCurrentUserID() else {
        return false
      }

      do {
        return !(try await hasValidConsent(userID: userID, policyVersion: policyVersion))
      } catch {
        return true  // エラーの場合は再同意が必要
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
        let userID = getCurrentUserID()
      else {
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

  /// YMLファイルからポリシー情報を読み込む
  private func loadPolicyFromYML() async throws -> Policy {
    guard let url = Bundle.main.url(forResource: "policy", withExtension: "yml") else {
      throw PolicyServiceError.noPolicyFound
    }

    let yamlString = try String(contentsOf: url, encoding: .utf8)
    let yamlData = try Yams.load(yaml: yamlString)

    guard let rootData = yamlData as? [String: Any],
          let policyData = rootData["policy"] as? [String: Any] else {
      throw PolicyServiceError.noPolicyFound
    }

    return try parsePolicyFromYML(policyData)
  }

  /// YMLデータをPolicyオブジェクトに変換
  private func parsePolicyFromYML(_ data: [String: Any]) throws -> Policy {
    // 必須フィールドの検証
    guard let version = data["version"] as? String,
          !version.isEmpty
    else {
      throw PolicyServiceError.noPolicyFound
    }

    guard let privacyPolicyData = data["privacy_policy"] as? [String: Any],
          let privacyPolicyJa = privacyPolicyData["ja"] as? String,
          !privacyPolicyJa.isEmpty
    else {
      throw PolicyServiceError.noPolicyFound
    }

    guard let termsOfServiceData = data["terms_of_service"] as? [String: Any],
          let termsOfServiceJa = termsOfServiceData["ja"] as? String,
          !termsOfServiceJa.isEmpty
    else {
      throw PolicyServiceError.noPolicyFound
    }

    // 日付の解析
    let updatedAt: Date
    if let updatedAtString = data["updated_at"] as? String {
      let formatter = ISO8601DateFormatter()
      updatedAt = formatter.date(from: updatedAtString) ?? Date()
    } else {
      updatedAt = Date()
    }

    let effectiveDate: Date
    if let effectiveDateString = data["effective_date"] as? String {
      let formatter = ISO8601DateFormatter()
      effectiveDate = formatter.date(from: effectiveDateString) ?? Date()
    } else {
      effectiveDate = Date()
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
      updatedAt: updatedAt,
      effectiveDate: effectiveDate
    )
  }

  private func parsePolicyFromFirestore(_ data: [String: Any]) throws -> Policy {
    // 必須フィールドの検証
    guard let version = data["version"] as? String,
      !version.isEmpty
    else {
      throw PolicyServiceError.noPolicyFound
    }

    guard let privacyPolicyData = data["privacyPolicy"] as? [String: Any],
      let privacyPolicyJa = privacyPolicyData["ja"] as? String,
      !privacyPolicyJa.isEmpty
    else {
      throw PolicyServiceError.noPolicyFound
    }

    guard let termsOfServiceData = data["termsOfService"] as? [String: Any],
      let termsOfServiceJa = termsOfServiceData["ja"] as? String,
      !termsOfServiceJa.isEmpty
    else {
      throw PolicyServiceError.noPolicyFound
    }

    // タイムスタンプの検証とフォールバック
    let updatedAt: Date
    if let updatedAtTimestamp = data["updatedAt"] as? Timestamp {
      updatedAt = updatedAtTimestamp.dateValue()
    } else {
      // フォールバック: 現在時刻を使用
      updatedAt = Date()
    }

    let effectiveDate: Date
    if let effectiveDateTimestamp = data["effectiveDate"] as? Timestamp {
      effectiveDate = effectiveDateTimestamp.dateValue()
    } else {
      // フォールバック: 現在時刻を使用
      effectiveDate = Date()
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
      updatedAt: updatedAt,
      effectiveDate: effectiveDate
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
    // 必須フィールドの検証
    guard let policyVersion = data["policyVersion"] as? String,
      !policyVersion.isEmpty
    else {
      throw PolicyServiceError.noPolicyFound
    }

    guard let consentedAtTimestamp = data["consentedAt"] as? Timestamp else {
      throw PolicyServiceError.noPolicyFound
    }

    guard let consentTypeString = data["consentType"] as? String,
      let consentType = ConsentType(rawValue: consentTypeString)
    else {
      throw PolicyServiceError.noPolicyFound
    }

    // オプションフィールドの検証
    var deviceInfo: DeviceInfo?
    if let deviceInfoData = data["deviceInfo"] as? [String: Any],
      let platform = deviceInfoData["platform"] as? String,
      let osVersion = deviceInfoData["osVersion"] as? String,
      let appVersion = deviceInfoData["appVersion"] as? String,
      !platform.isEmpty, !osVersion.isEmpty, !appVersion.isEmpty {

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
    FirebaseAuth.Auth.auth().currentUser?.uid
  }
}
