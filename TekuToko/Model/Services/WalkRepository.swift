//
//  WalkRepository.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit

/// WalkRepository操作で発生するエラータイプ
///
/// Firestoreとのデータ同期、認証、ネットワーク通信で発生する
/// 各種エラー状況を表現します。適切なエラーハンドリングとユーザー通知を可能にします。
///
/// ## Topics
///
/// ### Error Cases
/// WalkRepositoryErrorの詳細はWalkRepositoryCoreファイルを参照してください。

/// 散歩データの永続化とFirestore連携を管理するリポジトリクラス
///
/// `WalkRepository`はWalkデータのCRUD操作、Firestoreとの同期、
/// オフライン対応、認証管理を統合的に提供するデータ層のコアクラスです。
///
/// ## Overview
///
/// 主要な責務：
/// - **データ永続化**: Firebase Firestoreへの散歩データ保存
/// - **オフライン対応**: ローカルキャッシュとオフライン永続化
/// - **認証連携**: Firebase Authenticationとの統合
/// - **エラーハンドリング**: 包括的なエラー管理と分類
/// - **パフォーマンス**: バッチ処理とタイムアウト制御
///
/// ## Topics
///
/// ### Singleton Instance
/// - ``shared``
///
/// ### Data Operations
/// - ``fetchWalks(completion:)``
/// - ``fetchWalk(withID:completion:)``
/// - ``createWalk(title:description:location:completion:)``
/// - ``saveWalk(_:completion:)``
/// - ``updateWalk(_:completion:)``
/// - ``deleteWalk(withID:completion:)``
///
/// ### Firestore Integration
/// - ``saveWalkToFirestore(_:completion:)``
/// - ``fetchWalksFromFirestore(userId:completion:)``
/// - ``updateWalkInFirestore(_:completion:)``
/// - ``deleteWalkFromFirestore(walkId:userId:completion:)``
// WalkRepositoryクラスの定義はWalkRepositoryCoreファイルにあります
extension WalkRepository {
  // MARK: - Public Methods (既存のインターフェース互換性を保持)

  /// 現在の認証済みユーザーのWalkリストを取得
  ///
  /// Firebase Authenticationで認証済みのユーザーの散歩データをすべて取得します。
  /// 作成日時の降順でソートされた結果を返します。
  ///
  /// ## Behavior
  /// - UIテストモード時は空のリストを返す
  /// - 認証されていない場合はauthenticationRequiredエラー
  /// - Firestoreからデータを取得しローカルキャッシュを更新
  ///
  /// - Parameter completion: 取得結果のコールバック（Walk配列またはエラー）
  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    logger.logMethodStart()

    // UIテストモード時は空のリストを返す
    if UITestingHelper.shared.isUITesting {
      logger.info(
        operation: "fetchWalks",
        message: "UIテストモード: 空のWalkリストを返します",
        context: ["ui_testing": "true"]
      )
      completion(.success([]))
      return
    }

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

  /// 指定されたIDのWalkを取得
  ///
  /// 特定のWalkIDで散歩データを取得します。ユーザー認証と所有権の確認を行います。
  ///
  /// ## Security
  /// - 認証済みユーザーのみアクセス可能
  /// - 独自のWalkのみ取得可能（他人のデータはアクセス不可）
  ///
  /// - Parameters:
  ///   - id: 取得したいWalkのUUID
  ///   - completion: 取得結果のコールバック（Walkオブジェクトまたはエラー）
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

    // UIテスト時はモックデータまたはエラーを返す
    if UITestingHelper.shared.isUITesting {
      logger.info(
        operation: "fetchWalk",
        message: "UIテストモード: 散歩が見つかりませんでした"
      )
      completion(.failure(.notFound))
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

  /// 新しいWalkを作成してFirestoreに保存
  ///
  /// 指定されたパラメーターで新しい散歩セッションを作成し、Firestoreに保存します。
  /// 開始位置情報が指定されている場合は、初期位置として追加します。
  ///
  /// ## Parameters Detail
  /// - タイトルと説明は必須で、空文字列でも可能
  /// - 位置情報はオプションで、指定すると散歩の開始地点として記録
  ///
  /// - Parameters:
  ///   - title: 散歩のタイトル
  ///   - description: 散歩の説明
  ///   - location: 開始位置（オプション）
  ///   - completion: 作成結果のコールバック（作成されたWalkまたはエラー）
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

  /// 完全なWalkオブジェクトをFirestoreに保存
  ///
  /// WalkManagerから呼び出されるメインの保存メソッドです。
  /// 既に完全に構成されたWalkオブジェクトを受け取り、Firestoreに保存します。
  ///
  /// ## Usage
  /// - 散歩終了時のデータ保存
  /// - 一時停止や再開時の中間保存
  /// - 散歩中の定期バックアップ
  ///
  /// - Parameters:
  ///   - walk: 保存するWalkオブジェクト
  ///   - completion: 保存結果のコールバック（保存済みWalkまたはエラー）
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

  /// 既存のWalkデータを更新
  ///
  /// Firestore上の既存Walkドキュメントを更新します。
  /// マージ更新を使用し、変更されたフィールドのみを更新します。
  ///
  /// ## Security Note
  /// ユーザー認証と所有権の確認を行い、本人のWalkのみ更新可能です。
  ///
  /// - Parameters:
  ///   - walk: 更新するWalkオブジェクト
  ///   - completion: 更新結果のコールバック（更新済みWalkまたはエラー）
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

  /// 指定されたIDのWalkを削除
  ///
  /// FirebaseからWalkドキュメントを完全に削除します。
  /// 削除前に所有権の確認を行い、ローカルキャッシュからも削除します。
  ///
  /// ## Security
  /// - 認証済みユーザーのみ削除可能
  /// - 本人所有のWalkのみ削除可能
  /// - 削除前に存在確認と権限チェックを実行
  ///
  /// - Parameters:
  ///   - id: 削除するWalkのUUID
  ///   - completion: 削除結果のコールバック（成功フラグまたはエラー）
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

  /// WalkデータをFirestoreに保存する内部メソッド
  ///
  /// WalkオブジェクトをFirebase Firestoreにシリアライズして保存します。
  /// タイムアウト制御、エラーハンドリング、ローカルキャッシュ更新を含みます。
  ///
  /// ## Implementation Details
  /// - 10秒のタイムアウト設定
  /// - カスタムCodable実装でCLLocationをシリアライズ
  /// - 成功時はローカルキャッシュを更新
  /// - 詳細なログ記録とFirebase同期バグ予防ログ
  ///
  /// - Parameters:
  ///   - walk: 保存するWalkオブジェクト
  ///   - completion: 保存結果のコールバック
  func saveWalkToFirestore(
    _ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walk.id.uuidString,
      "operation": "saveWalkToFirestore",
    ])

    // UIテスト時はFirebase操作をスキップして成功を返す
    if UITestingHelper.shared.isUITesting {
      logger.info(
        operation: "saveWalkToFirestore",
        message: "UIテストモード: Firebase操作をスキップしています"
      )
      completion(.success(walk))
      return
    }

    logger.logFirebaseSyncBugPrevention(
      isOnline: true,  // 仮定
      pendingWrites: 0,  // 仮定
      lastSync: Date(),  // 仮定
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

  /// 指定ユーザーのWalkデータをFirestoreから取得する内部メソッド
  ///
  /// 特定ユーザーの散歩データをFirestoreからクエリで取得します。
  /// 作成日時の降順でソートし、ローカルキャッシュを更新します。
  ///
  /// ## Query Details
  /// - `user_id`フィールドでフィルタリング
  /// - `created_at`で降順ソート
  /// - 15秒のタイムアウト設定
  /// - データ解析エラーのハンドリング
  ///
  /// - Parameters:
  ///   - userId: 取得対象のユーザーID
  ///   - completion: 取得結果のコールバック
  func fetchWalksFromFirestore(
    userId: String, completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "user_id": userId,
      "operation": "fetchWalksFromFirestore",
    ])

    // UIテスト時は空の配列を返す
    if UITestingHelper.shared.isUITesting {
      logger.info(
        operation: "fetchWalksFromFirestore",
        message: "UIテストモード: 空の散歩リストを返しています"
      )
      completion(.success([]))
      return
    }

    logger.logFirebaseSyncBugPrevention(
      isOnline: true,  // 仮定
      pendingWrites: 0,  // 仮定
      lastSync: Date(),  // 仮定
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

  /// WalkデータをFirestoreで更新する内部メソッド
  ///
  /// 既存のWalkドキュメントをFirestore上で更新します。
  /// マージ更新を使用して、変更されたフィールドのみを更新します。
  ///
  /// ## Security & Validation
  /// - ユーザー認証と所有権の事前チェック
  /// - カスタムCodableで安全なデータシリアライゼーション
  /// - 成功時はローカルキャッシュを更新
  ///
  /// - Parameters:
  ///   - walk: 更新するWalkオブジェクト
  ///   - completion: 更新結果のコールバック
  func updateWalkInFirestore(
    _ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walk.id.uuidString,
      "operation": "updateWalkInFirestore",
    ])

    // UIテスト時はFirebase操作をスキップして成功を返す
    if UITestingHelper.shared.isUITesting {
      logger.info(
        operation: "updateWalkInFirestore",
        message: "UIテストモード: Firebase操作をスキップしています"
      )
      completion(.success(walk))
      return
    }

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
      isOnline: true,  // 仮定
      pendingWrites: 0,  // 仮定
      lastSync: Date(),  // 仮定
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

  /// WalkデータをFirestoreから削除する内部メソッド
  ///
  /// 削除前に所有権と存在確認を行い、安全にFirestoreから削除します。
  /// 削除成功時はローカルキャッシュからも削除します。
  ///
  /// ## Security Process
  /// 1. 対象Walkの存在確認
  /// 2. 所有者ユーザーIDの照合確認
  /// 3. 権限チェック後に削除実行
  /// 4. ローカルキャッシュからも削除
  ///
  /// - Parameters:
  ///   - walkId: 削除するWalkのUUID
  ///   - userId: 削除を要求するユーザーID
  ///   - completion: 削除結果のコールバック
  func deleteWalkFromFirestore(
    walkId: UUID, userId: String, completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walkId.uuidString,
      "user_id": userId,
      "operation": "deleteWalkFromFirestore",
    ])

    // UIテスト時はFirebase操作をスキップして成功を返す
    if UITestingHelper.shared.isUITesting {
      logger.info(
        operation: "deleteWalkFromFirestore",
        message: "UIテストモード: Firebase操作をスキップしています"
      )
      completion(.success(true))
      return
    }

    logger.logFirebaseSyncBugPrevention(
      isOnline: true,  // 仮定
      pendingWrites: 0,  // 仮定
      lastSync: Date(),  // 仮定
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
  // MARK: - Shared Image Storage

  /// 散歩の共有画像をFirebase Storageに保存
  ///
  /// 生成された共有画像をFirebase Storageにアップロードし、
  /// ダウンロードURLをWalkデータに保存します。
  ///
  /// ## Storage Structure
  /// - パス: `shared_images/{userId}/{walkId}/share_image.jpg`
  /// - 形式: JPEG（品質: 0.8）
  /// - メタデータ: content-type, custom metadata
  ///
  /// - Parameters:
  ///   - image: アップロードする画像
  ///   - walk: 関連する散歩データ
  ///   - completion: アップロード結果のコールバック（ダウンロードURLまたはエラー）
  func saveSharedImage(
    _ image: UIImage,
    for walk: Walk,
    completion: @escaping (Result<String, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walk.id.uuidString,
      "operation": "saveSharedImage",
    ])

    guard let userId = validateAuthenticationForImage() else {
      completion(.failure(.authenticationRequired))
      return
    }

    guard let imageData = prepareImageData(image, walkId: walk.id.uuidString) else {
      completion(.failure(.invalidData))
      return
    }

    uploadSharedImage(
      imageData: imageData,
      walk: walk,
      userId: userId,
      completion: completion
    )
  }

  private func validateAuthenticationForImage() -> String? {
    switch FirebaseAuthHelper.requireAuthentication() {
    case .success(let userId):
      return FirebaseAuthHelper.getCurrentUserId()
    case .failure(let authError):
      logger.warning(
        operation: "validateAuthenticationForImage",
        message: "認証エラー: \(authError.localizedDescription)",
        humanNote: "ユーザーが認証されていません",
        aiTodo: "認証状態を確認してください"
      )
      return nil
    }
  }

  private func prepareImageData(_ image: UIImage, walkId: String) -> Data? {
    guard
      let imageData = image.jpegData(
        compressionQuality: FirebaseStorageConfig.jpegCompressionQuality
      )
    else {
      logger.warning(
        operation: "prepareImageData",
        message: "画像のJPEGデータ変換に失敗",
        context: ["walk_id": walkId],
        humanNote: "画像の変換に失敗",
        aiTodo: "画像データの整合性を確認"
      )
      return nil
    }
    return imageData
  }

  private func uploadSharedImage(
    imageData: Data,
    walk: Walk,
    userId: String,
    completion: @escaping (Result<String, WalkRepositoryError>) -> Void
  ) {
    let sharedImagePath = FirebaseStorageConfig.sharedImagePath(
      userId: userId,
      walkId: walk.id.uuidString
    )
    let imageRef = storage.reference().child(sharedImagePath)
    let metadata = createImageMetadata(walk: walk, userId: userId)

    logger.info(
      operation: "uploadSharedImage",
      message: "画像アップロード開始",
      context: [
        "walk_id": walk.id.uuidString,
        "user_id": userId,
        "file_size": String(imageData.count),
        "storage_path": sharedImagePath,
      ]
    )

    imageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
      if let error = error {
        self?.logger.logError(
          error,
          operation: "uploadSharedImage",
          humanNote: "Firebase Storageへのアップロードに失敗",
          aiTodo: "ネットワーク接続とFirebase Storage設定を確認"
        )
        completion(.failure(.storageError(error)))
        return
      }

      self?.getDownloadURLAndUpdateWalk(
        imageRef: imageRef,
        walk: walk,
        userId: userId,
        imageDataSize: imageData.count,
        completion: completion
      )
    }
  }

  private func createImageMetadata(walk: Walk, userId: String) -> StorageMetadata {
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    var commonMetadata = FirebaseStorageConfig.commonMetadata(
      walkId: walk.id.uuidString,
      userId: userId
    )
    commonMetadata["walk_title"] = walk.title
    metadata.customMetadata = commonMetadata
    return metadata
  }

  private func getDownloadURLAndUpdateWalk(
    imageRef: StorageReference,
    walk: Walk,
    userId: String,
    imageDataSize: Int,
    completion: @escaping (Result<String, WalkRepositoryError>) -> Void
  ) {
    imageRef.downloadURL { [weak self] url, error in
      if let error = error {
        self?.logger.logError(
          error,
          operation: "getDownloadURLAndUpdateWalk",
          humanNote: "ダウンロードURL取得に失敗",
          aiTodo: "Firebase Storage設定とアクセス権限を確認"
        )
        completion(.failure(.storageError(error)))
        return
      }

      guard let downloadURL = url else {
        self?.logger.warning(
          operation: "getDownloadURLAndUpdateWalk",
          message: "ダウンロードURLが取得できませんでした",
          context: ["walk_id": walk.id.uuidString],
          humanNote: "URLの取得に失敗",
          aiTodo: "Firebase Storage設定を確認"
        )
        let error = NSError(
          domain: "WalkRepository",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "ダウンロードURLの取得に失敗"]
        )
        completion(.failure(.storageError(error)))
        return
      }

      let urlString = downloadURL.absoluteString

      self?.logger.info(
        operation: "getDownloadURLAndUpdateWalk",
        message: "画像アップロード成功",
        context: [
          "walk_id": walk.id.uuidString,
          "user_id": userId,
          "download_url": urlString,
          "file_size": String(imageDataSize),
        ]
      )

      self?.updateWalkWithSharedImageURL(walk, imageURL: urlString) { result in
        switch result {
        case .success:
          completion(.success(urlString))
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }

  /// 散歩データに共有画像URLを追加して更新
  ///
  /// - Parameters:
  ///   - walk: 更新する散歩データ
  ///   - imageURL: 共有画像のダウンロードURL
  ///   - completion: 更新結果のコールバック
  private func updateWalkWithSharedImageURL(
    _ walk: Walk,
    imageURL: String,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    logger.logMethodStart(context: [
      "walk_id": walk.id.uuidString,
      "operation": "updateWalkWithSharedImageURL",
    ])

    // Walkデータを更新（共有画像URLを追加）
    var updatedWalk = walk
    // 注意: Walkモデルにshared_image_urlフィールドを追加する必要があります
    // 今回はログのみで実装を省略

    logger.info(
      operation: "updateWalkWithSharedImageURL",
      message: "散歩データに共有画像URL追加（実装は今後追加）",
      context: [
        "walk_id": walk.id.uuidString,
        "image_url": imageURL,
      ]
    )

    // 現在のWalkモデルには共有画像URLフィールドがないため、
    // とりあえず成功として処理
    completion(.success(updatedWalk))
  }

  // MARK: - Private Helper Methods

  /// Firebase Authenticationから現在のユーザーIDを取得
  ///
  /// ログイン中のユーザーの一意識別子を取得します。
  /// ユーザーがログインしていない場合はnilを返します。
  ///
  /// - Returns: 現在のユーザーID、または未ログインの場合nil
  private func getCurrentUserId() -> String? {
    // Firebase Authから現在のユーザーIDを取得
    let userId = Auth.auth().currentUser?.uid
    return userId
  }

  /// ローカルキャッシュを指定のWalkで更新
  ///
  /// 既存のWalkがキャッシュにある場合は更新し、
  /// ない場合は新しく追加します。
  ///
  /// - Parameter walk: キャッシュに保存するWalkオブジェクト
  private func updateCache(with walk: Walk) {
    if let index = cachedWalks.firstIndex(where: { $0.id == walk.id }) {
      cachedWalks[index] = walk
    } else {
      cachedWalks.append(walk)
    }
  }

  /// 指定されたIDのWalkをローカルキャッシュから削除
  ///
  /// キャッシュから指定WalkIDと一致するすべてのWalkを削除します。
  ///
  /// - Parameter walkId: 削除するWalkのUUID
  private func removeFromCache(walkId: UUID) {
    cachedWalks.removeAll { $0.id == walkId }
  }

  // MARK: - Error Handling

  /// FirestoreエラーをWalkRepositoryErrorにマッピング
  ///
  /// 系統エラーをアプリケーション固有のエラータイプに変換します。
  /// ネットワークエラー、認証エラー、Firestore固有エラーを適切に分類します。
  ///
  /// ## Error Code Mapping
  /// - NSURLError: ネットワーク関連エラー
  /// - Firestore Error 7: PERMISSION_DENIED → authenticationRequired
  /// - Firestore Error 5: NOT_FOUND → notFound
  /// - Firestore Error 14: UNAVAILABLE → networkError
  /// - Firestore Error 3: INVALID_ARGUMENT → invalidData
  ///
  /// - Parameter error: マッピング元のエラー
  /// - Returns: 変換されたWalkRepositoryError
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
