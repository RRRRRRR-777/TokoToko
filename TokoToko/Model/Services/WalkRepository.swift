//
//  WalkRepository.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Foundation

// エラー型を定義
enum WalkRepositoryError: Error, Equatable {
  case notFound
  case firestoreError(Error)
  case networkError
  case authenticationRequired
  case invalidData

  // Equatable実装
  static func == (lhs: WalkRepositoryError, rhs: WalkRepositoryError) -> Bool {
    switch (lhs, rhs) {
    case (.notFound, .notFound),
      (.networkError, .networkError),
      (.authenticationRequired, .authenticationRequired),
      (.invalidData, .invalidData):
      return true
    case (.firestoreError, .firestoreError):
      // Errorは等価比較が困難なため、同じタイプであることのみチェック
      return true
    default:
      return false
    }
  }
}

class WalkRepository {
  // シングルトンインスタンス
  static let shared = WalkRepository()

  // Firestore参照
  private let db = Firestore.firestore()
  private let collectionName = "walks"

  // オフライン対応用の内部データストレージ
  private var cachedWalks: [Walk] = []

  // ログ
  private let logger = EnhancedVibeLogger.shared

  private init() {
    // Firestoreの設定
    configureFirestore()
  }

  private func configureFirestore() {
    logger.logMethodStart()

    // オフライン永続化を有効にする
    let settings = FirestoreSettings()
    let newSettings = Firestore.firestore().settings
    newSettings.cacheSettings = PersistentCacheSettings()
    db.settings = newSettings

    // Firestore設定完了（deepLinkURLSchemeは必要に応じてAppDelegate等で設定）

    // オフライン時の自動再試行設定
    db.enableNetwork { [weak self] error in
      if let error = error {
        self?.logger.logError(
          error,
          operation: "configureFirestore:enableNetwork",
          humanNote: "Firestoreネットワーク接続に失敗",
          aiTodo: "ネットワーク接続状態とFirebase設定を確認"
        )
      } else {
        self?.logger.info(
          operation: "configureFirestore:enableNetwork",
          message: "Firestoreネットワーク接続が確立されました",
          context: ["cache_size": "50MB", "persistence": "enabled"]
        )
      }
    }

    logger.info(
      operation: "configureFirestore",
      message: "Firestore設定完了",
      context: [
        "persistence_enabled": "true", // PersistentCacheSettings.unlimited を使用しているため常にtrue
        "cache_size_bytes": "unlimited", // PersistentCacheSettings.unlimited を使用しているため
      ]
    )
  }

  // MARK: - Public Methods (既存のインターフェース互換性を保持)

  // すべてのWalkを取得（現在のユーザーのみ）
  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    logger.logMethodStart()

    // 認証済みユーザーIDが必要
    guard let userId = getCurrentUserId() else {
      logger.warning(
        operation: "fetchWalks",
        message: "認証されていないユーザーによるWalk取得試行",
        humanNote: "ユーザーが認証されていません",
        aiTodo: "認証状態を確認してください"
      )
      completion(.failure(.authenticationRequired))
      return
    }

    logger.info(
      operation: "fetchWalks",
      message: "認証済みユーザーのWalk取得開始",
      context: ["user_id": userId]
    )

    fetchWalksFromFirestore(userId: userId, completion: completion)
  }

  // IDでWalkを取得
  func fetchWalk(withID id: UUID, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void)
  {
    logger.logMethodStart(context: ["walk_id": id.uuidString])

    guard let userId = getCurrentUserId() else {
      logger.warning(
        operation: "fetchWalk",
        message: "認証されていないユーザーによるWalk取得試行",
        context: ["walk_id": id.uuidString],
        humanNote: "ユーザーが認証されていません",
        aiTodo: "認証状態を確認してください"
      )
      completion(.failure(.authenticationRequired))
      return
    }

    db.collection(collectionName)
      .document(id.uuidString)
      .getDocument { [weak self] document, error in
        if let error = error {
          self?.logger.logError(
            error,
            operation: "fetchWalk:getDocument",
            humanNote: "Firestoreからのドキュメント取得に失敗",
            aiTodo: "ネットワーク接続とFirebase設定を確認"
          )
          completion(.failure(.firestoreError(error)))
          return
        }

        guard let document = document, document.exists else {
          self?.logger.warning(
            operation: "fetchWalk:getDocument",
            message: "指定されたWalkが見つかりません",
            context: ["walk_id": id.uuidString, "user_id": userId],
            humanNote: "存在しないWalkの取得試行",
            aiTodo: "IDの正確性を確認してください"
          )
          completion(.failure(.notFound))
          return
        }

        do {
          let walk = try document.data(as: Walk.self)
          // ユーザーIDが一致することを確認
          if walk.userId == userId {
            self?.logger.info(
              operation: "fetchWalk:getDocument",
              message: "Walk取得成功",
              context: [
                "walk_id": id.uuidString,
                "user_id": userId,
                "walk_title": walk.title,
                "walk_status": walk.status.rawValue,
              ]
            )
            completion(.success(walk))
          } else {
            self?.logger.warning(
              operation: "fetchWalk:getDocument",
              message: "異なるユーザーのWalkへのアクセス試行",
              context: [
                "walk_id": id.uuidString,
                "requested_user_id": userId,
                "walk_owner_id": walk.userId ?? "unknown",
              ],
              humanNote: "権限のないWalkへのアクセス",
              aiTodo: "ユーザー権限を確認してください"
            )
            completion(.failure(.notFound))
          }
        } catch {
          self?.logger.logError(
            error,
            operation: "fetchWalk:dataDecoding",
            humanNote: "Walkデータの解析に失敗",
            aiTodo: "データ構造の整合性を確認"
          )
          completion(.failure(.invalidData))
        }
      }
  }

  // 新しいWalkを追加
  func createWalk(
    title: String, description: String, location: CLLocationCoordinate2D? = nil,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "title": title,
      "description": description,
      "has_location": location != nil ? "true" : "false",
    ])

    guard let userId = getCurrentUserId() else {
      logger.warning(
        operation: "createWalk",
        message: "認証されていないユーザーによるWalk作成試行",
        context: ["title": title],
        humanNote: "ユーザーが認証されていません",
        aiTodo: "認証状態を確認してください"
      )
      completion(.failure(.authenticationRequired))
      return
    }

    var newWalk = Walk(title: title, description: description, userId: userId)

    // 位置情報がある場合は開始地点として追加
    if let location = location {
      let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
      newWalk.addLocation(clLocation)
      logger.info(
        operation: "createWalk",
        message: "開始地点の位置情報を追加",
        context: [
          "latitude": String(location.latitude),
          "longitude": String(location.longitude),
        ]
      )
    }

    logger.info(
      operation: "createWalk",
      message: "新しいWalk作成開始",
      context: [
        "walk_id": newWalk.id.uuidString,
        "user_id": userId,
        "title": title,
        "has_description": !description.isEmpty ? "true" : "false",
      ]
    )

    saveWalkToFirestore(newWalk, completion: completion)
  }

  // 完全なWalkオブジェクトを追加（WalkManagerから使用）
  func saveWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walk.id.uuidString,
      "title": walk.title,
      "status": walk.status.rawValue,
    ])

    logger.info(
      operation: "saveWalk",
      message: "Walk保存開始",
      context: [
        "walk_id": walk.id.uuidString,
        "user_id": walk.userId ?? "unknown",
        "title": walk.title,
        "status": walk.status.rawValue,
        "locations_count": String(walk.locations.count),
      ]
    )

    saveWalkToFirestore(walk, completion: completion)
  }

  // Walkを更新
  func updateWalk(_ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    logger.logMethodStart(context: [
      "walk_id": walk.id.uuidString,
      "title": walk.title,
      "status": walk.status.rawValue,
    ])

    logger.info(
      operation: "updateWalk",
      message: "Walk更新開始",
      context: [
        "walk_id": walk.id.uuidString,
        "user_id": walk.userId ?? "unknown",
        "title": walk.title,
        "status": walk.status.rawValue,
        "locations_count": String(walk.locations.count),
      ]
    )

    updateWalkInFirestore(walk, completion: completion)
  }

  // Walkを削除
  func deleteWalk(
    withID id: UUID, completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: ["walk_id": id.uuidString])

    guard let userId = getCurrentUserId() else {
      logger.warning(
        operation: "deleteWalk",
        message: "認証されていないユーザーによるWalk削除試行",
        context: ["walk_id": id.uuidString],
        humanNote: "ユーザーが認証されていません",
        aiTodo: "認証状態を確認してください"
      )
      completion(.failure(.authenticationRequired))
      return
    }

    logger.info(
      operation: "deleteWalk",
      message: "Walk削除開始",
      context: [
        "walk_id": id.uuidString,
        "user_id": userId,
      ]
    )

    deleteWalkFromFirestore(walkId: id, userId: userId) { [weak self] result in
      switch result {
      case .success:
        self?.logger.info(
          operation: "deleteWalk",
          message: "Walk削除成功",
          context: [
            "walk_id": id.uuidString,
            "user_id": userId,
          ]
        )
        completion(.success(true))
      case .failure(let error):
        self?.logger.logError(
          error as Error,
          operation: "deleteWalk",
          humanNote: "Walk削除に失敗",
          aiTodo: "削除権限と存在を確認"
        )
        completion(.failure(error))
      }
    }
  }

  // MARK: - Firestore Integration Methods

  // FirestoreにWalkを保存
  func saveWalkToFirestore(
    _ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walk.id.uuidString,
      "operation": "saveWalkToFirestore",
    ])

    logger.logFirebaseSyncBugPrevention(
      isOnline: true, // 仮定
      pendingWrites: 0, // 仮定
      lastSync: Date(), // 仮定
      context: [
        "walk_id": walk.id.uuidString,
        "collection": collectionName,
        "user_id": walk.userId ?? "unknown",
      ]
    )

    do {
      let walkRef = db.collection(collectionName).document(walk.id.uuidString)

      // タイムアウト付きでデータを保存
      let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) {
        [weak self] _ in
        self?.logger.warning(
          operation: "saveWalkToFirestore",
          message: "Firestore保存タイムアウト",
          context: ["walk_id": walk.id.uuidString, "timeout": "10.0"],
          humanNote: "ネットワークタイムアウトが発生",
          aiTodo: "ネットワーク接続を確認してください"
        )
        completion(.failure(.networkError))
      }

      try walkRef.setData(from: walk) { [weak self] error in
        timeoutTimer.invalidate()  // タイマーを無効化

        if let error = error {
          let walkError = self?.mapFirestoreError(error) ?? .firestoreError(error)
          self?.logger.logError(
            error,
            operation: "saveWalkToFirestore:setData",
            humanNote: "Firestoreへの保存に失敗",
            aiTodo: "ネットワーク接続とFirebase設定を確認"
          )
          completion(.failure(walkError))
        } else {
          // キャッシュを更新
          self?.updateCache(with: walk)
          self?.logger.info(
            operation: "saveWalkToFirestore:setData",
            message: "Firestore保存成功",
            context: [
              "walk_id": walk.id.uuidString,
              "collection": self?.collectionName ?? "",
              "user_id": walk.userId ?? "unknown",
              "cached": "true",
            ]
          )
          completion(.success(walk))
        }
      }
    } catch {
      logger.logError(
        error,
        operation: "saveWalkToFirestore:setData",
        humanNote: "Walkデータの変換に失敗",
        aiTodo: "データ構造の整合性を確認"
      )
      completion(.failure(.invalidData))
    }
  }

  // FirestoreからユーザーのWalkを取得
  func fetchWalksFromFirestore(
    userId: String, completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "user_id": userId,
      "operation": "fetchWalksFromFirestore",
    ])

    logger.logFirebaseSyncBugPrevention(
      isOnline: true, // 仮定
      pendingWrites: 0, // 仮定
      lastSync: Date(), // 仮定
      context: [
        "user_id": userId,
        "collection": collectionName,
      ]
    )

    // タイムアウト設定
    let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) {
      [weak self] _ in
      self?.logger.warning(
        operation: "fetchWalksFromFirestore",
        message: "Firestore取得タイムアウト",
        context: ["user_id": userId, "timeout": "15.0"],
        humanNote: "ネットワークタイムアウトが発生",
        aiTodo: "ネットワーク接続を確認してください"
      )
      completion(.failure(.networkError))
    }

    db.collection(collectionName)
      .whereField("user_id", isEqualTo: userId)
      .order(by: "created_at", descending: true)
      .getDocuments { [weak self] querySnapshot, error in
        timeoutTimer.invalidate()  // タイマーを無効化

        if let error = error {
          let mappedError = self?.mapFirestoreError(error) ?? .firestoreError(error)
          self?.logger.logError(
            error,
            operation: "fetchWalksFromFirestore:getDocuments",
            humanNote: "Firestoreからの取得に失敗",
            aiTodo: "ネットワーク接続とFirebase設定を確認"
          )
          completion(.failure(mappedError))
          return
        }

        guard let documents = querySnapshot?.documents else {
          self?.logger.info(
            operation: "fetchWalksFromFirestore:getDocuments",
            message: "Walkデータが見つかりません",
            context: ["user_id": userId, "documents_count": "0"]
          )
          completion(.success([]))
          return
        }

        // データ解析
        let parseResult = documents.compactMap { document in
          do {
            return try document.data(as: Walk.self)
          } catch {
            self?.logger.logError(
              error,
              operation: "fetchWalksFromFirestore:dataParsing",
              humanNote: "Walk解析エラー",
              aiTodo: "データ構造の整合性を確認"
            )
            return nil
          }
        }

        // キャッシュを更新
        self?.cachedWalks = parseResult

        self?.logger.info(
          operation: "fetchWalksFromFirestore:getDocuments",
          message: "Walks取得成功",
          context: [
            "user_id": userId,
            "documents_count": String(documents.count),
            "parsed_count": String(parseResult.count),
            "cached": "true",
          ]
        )

        completion(.success(parseResult))
      }
  }

  // FirestoreでWalkを更新
  func updateWalkInFirestore(
    _ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walk.id.uuidString,
      "operation": "updateWalkInFirestore",
    ])

    guard walk.userId == getCurrentUserId() else {
      logger.warning(
        operation: "updateWalkInFirestore",
        message: "異なるユーザーのWalk更新試行",
        context: [
          "walk_id": walk.id.uuidString,
          "walk_user_id": walk.userId ?? "unknown",
          "current_user_id": getCurrentUserId() ?? "nil",
        ],
        humanNote: "権限のないWalk更新試行",
        aiTodo: "ユーザー権限を確認してください"
      )
      completion(.failure(.authenticationRequired))
      return
    }

    logger.logFirebaseSyncBugPrevention(
      isOnline: true, // 仮定
      pendingWrites: 0, // 仮定
      lastSync: Date(), // 仮定
      context: [
        "walk_id": walk.id.uuidString,
        "collection": collectionName,
        "user_id": walk.userId ?? "unknown",
      ]
    )

    do {
      let walkRef = db.collection(collectionName).document(walk.id.uuidString)
      try walkRef.setData(from: walk, merge: true) { [weak self] error in
        if let error = error {
          let walkError = self?.mapFirestoreError(error) ?? .firestoreError(error)
          self?.logger.logError(
            error,
            operation: "updateWalkInFirestore:setData",
            humanNote: "Firestoreでの更新に失敗",
            aiTodo: "ネットワーク接続とFirebase設定を確認"
          )
          completion(.failure(walkError))
        } else {
          // キャッシュを更新
          self?.updateCache(with: walk)
          self?.logger.info(
            operation: "updateWalkInFirestore:setData",
            message: "Firestore更新成功",
            context: [
              "walk_id": walk.id.uuidString,
              "collection": self?.collectionName ?? "",
              "user_id": walk.userId ?? "unknown",
              "cached": "true",
            ]
          )
          completion(.success(walk))
        }
      }
    } catch {
      logger.logError(
        error,
        operation: "updateWalkInFirestore:setData",
        humanNote: "Walkデータの変換に失敗",
        aiTodo: "データ構造の整合性を確認"
      )
      completion(.failure(.invalidData))
    }
  }

  // FirestoreからWalkを削除
  func deleteWalkFromFirestore(
    walkId: UUID, userId: String, completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walkId.uuidString,
      "user_id": userId,
      "operation": "deleteWalkFromFirestore",
    ])

    logger.logFirebaseSyncBugPrevention(
      isOnline: true, // 仮定
      pendingWrites: 0, // 仮定
      lastSync: Date(), // 仮定
      context: [
        "walk_id": walkId.uuidString,
        "collection": collectionName,
        "user_id": userId,
      ]
    )

    // まず、削除権限を確認
    db.collection(collectionName)
      .document(walkId.uuidString)
      .getDocument { [weak self] document, error in
        if let error = error {
          self?.logger.logError(
            error,
            operation: "deleteWalkFromFirestore:getDocument",
            humanNote: "削除権限確認のためのドキュメント取得に失敗",
            aiTodo: "ネットワーク接続とFirebase設定を確認"
          )
          completion(.failure(.firestoreError(error)))
          return
        }

        guard let document = document, document.exists else {
          self?.logger.warning(
            operation: "deleteWalkFromFirestore:getDocument",
            message: "削除対象のWalkが見つかりません",
            context: [
              "walk_id": walkId.uuidString,
              "user_id": userId,
            ],
            humanNote: "存在しないWalkの削除試行",
            aiTodo: "IDの正確性を確認してください"
          )
          completion(.failure(.notFound))
          return
        }

        do {
          let walk = try document.data(as: Walk.self)
          guard walk.userId == userId else {
            self?.logger.warning(
              operation: "deleteWalkFromFirestore:getDocument",
              message: "異なるユーザーのWalk削除試行",
              context: [
                "walk_id": walkId.uuidString,
                "requested_user_id": userId,
                "walk_owner_id": walk.userId ?? "unknown",
              ],
              humanNote: "権限のないWalk削除試行",
              aiTodo: "ユーザー権限を確認してください"
            )
            completion(.failure(.authenticationRequired))
            return
          }

          // 削除を実行
          document.reference.delete { [weak self] error in
            if let error = error {
              self?.logger.logError(
                error,
                operation: "deleteWalkFromFirestore:delete",
                humanNote: "Firestoreからの削除に失敗",
                aiTodo: "ネットワーク接続とFirebase設定を確認"
              )
              completion(.failure(.firestoreError(error)))
            } else {
              // キャッシュからも削除
              self?.removeFromCache(walkId: walkId)
              self?.logger.info(
                operation: "deleteWalkFromFirestore:delete",
                message: "Firestore削除成功",
                context: [
                  "walk_id": walkId.uuidString,
                  "user_id": userId,
                  "collection": self?.collectionName ?? "",
                  "cached": "removed",
                ]
              )
              completion(.success(true))
            }
          }
        } catch {
          self?.logger.logError(
            error,
            operation: "deleteWalkFromFirestore:dataParsing",
            humanNote: "削除権限確認のためのWalkデータ解析に失敗",
            aiTodo: "データ構造の整合性を確認"
          )
          completion(.failure(.invalidData))
        }
      }
  }
  // MARK: - Private Helper Methods

  private func getCurrentUserId() -> String? {
    // Firebase Authから現在のユーザーIDを取得
    let userId = Auth.auth().currentUser?.uid
    return userId
  }

  private func updateCache(with walk: Walk) {
    if let index = cachedWalks.firstIndex(where: { $0.id == walk.id }) {
      cachedWalks[index] = walk
    } else {
      cachedWalks.append(walk)
    }
  }

  private func removeFromCache(walkId: UUID) {
    cachedWalks.removeAll { $0.id == walkId }
  }

  // MARK: - Error Handling

  private func mapFirestoreError(_ error: Error) -> WalkRepositoryError {
    let nsError = error as NSError

    // ネットワーク関連のエラー
    if nsError.domain == NSURLErrorDomain {
      switch nsError.code {
      case NSURLErrorNotConnectedToInternet,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorTimedOut:
        return .networkError
      default:
        return .firestoreError(error)
      }
    }

    // Firestoreエラーコードのマッピング
    if nsError.domain == "com.google.firebase.firestore" {
      switch nsError.code {
      case 7:  // PERMISSION_DENIED
        return .authenticationRequired
      case 5:  // NOT_FOUND
        return .notFound
      case 14:  // UNAVAILABLE
        return .networkError
      case 3:  // INVALID_ARGUMENT
        return .invalidData
      default:
        return .firestoreError(error)
      }
    }

    // その他のエラー
    return .firestoreError(error)
  }
}
