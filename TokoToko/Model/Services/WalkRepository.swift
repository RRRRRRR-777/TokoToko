//
//  WalkRepository.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import Foundation
import FirebaseFirestore
import FirebaseAuth

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

  private init() {
    // Firestoreの設定
    configureFirestore()
  }
  
  private func configureFirestore() {
    // オフライン永続化を有効にする
    let settings = FirestoreSettings()
    settings.isPersistenceEnabled = true
    
    // ネットワークタイムアウト設定
    settings.cacheSizeBytes = 50 * 1024 * 1024  // 50MB キャッシュサイズ
    
    db.settings = settings
    
    // ネットワークタイムアウトの設定
    db.app?.options.deepLinkURLScheme = "tokotoko"
    
    // オフライン時の自動再試行設定
    db.enableNetwork { [weak self] error in
      if let error = error {
        print("⚠️ Firestore ネットワーク接続に失敗: \(error)")
      } else {
        print("✅ Firestore ネットワーク接続が確立されました")
      }
    }
  }

  // MARK: - Public Methods (既存のインターフェース互換性を保持)
  
  // すべてのWalkを取得（現在のユーザーのみ）
  func fetchWalks(completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    // 認証済みユーザーIDが必要
    guard let userId = getCurrentUserId() else {
      completion(.failure(.authenticationRequired))
      return
    }
    
    fetchWalksFromFirestore(userId: userId, completion: completion)
  }

  // IDでWalkを取得
  func fetchWalk(withID id: UUID, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    guard let userId = getCurrentUserId() else {
      completion(.failure(.authenticationRequired))
      return
    }
    
    db.collection(collectionName)
      .document(id.uuidString)
      .getDocument { [weak self] document, error in
        if let error = error {
          completion(.failure(.firestoreError(error)))
          return
        }
        
        guard let document = document, document.exists else {
          completion(.failure(.notFound))
          return
        }
        
        do {
          let walk = try document.data(as: Walk.self)
          // ユーザーIDが一致することを確認
          if walk.userId == userId {
            completion(.success(walk))
          } else {
            completion(.failure(.notFound))
          }
        } catch {
          completion(.failure(.invalidData))
        }
      }
  }

  // 新しいWalkを追加
  func createWalk(
    title: String, description: String, location: CLLocationCoordinate2D? = nil,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    guard let userId = getCurrentUserId() else {
      completion(.failure(.authenticationRequired))
      return
    }
    
    var newWalk = Walk(title: title, description: description, userId: userId)

    // 位置情報がある場合は開始地点として追加
    if let location = location {
      let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
      newWalk.addLocation(clLocation)
    }

    saveWalkToFirestore(newWalk, completion: completion)
  }

  // 完全なWalkオブジェクトを追加（WalkManagerから使用）
  func saveWalk(
    _ walk: Walk,
    completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void
  ) {
    saveWalkToFirestore(walk, completion: completion)
  }

  // Walkを更新
  func updateWalk(_ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    updateWalkInFirestore(walk, completion: completion)
  }

  // Walkを削除
  func deleteWalk(
    withID id: UUID, completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void
  ) {
    guard let userId = getCurrentUserId() else {
      completion(.failure(.authenticationRequired))
      return
    }
    
    deleteWalkFromFirestore(walkId: id, userId: userId) { result in
      switch result {
      case .success:
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: - Firestore Integration Methods
  
  // FirestoreにWalkを保存
  func saveWalkToFirestore(_ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    do {
      let walkRef = db.collection(collectionName).document(walk.id.uuidString)
      
      // タイムアウト付きでデータを保存
      let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
        completion(.failure(.networkError))
      }
      
      try walkRef.setData(from: walk) { [weak self] error in
        timeoutTimer.invalidate()  // タイマーを無効化
        
        if let error = error {
          let walkError = self?.mapFirestoreError(error) ?? .firestoreError(error)
          completion(.failure(walkError))
        } else {
          // キャッシュを更新
          self?.updateCache(with: walk)
          completion(.success(walk))
        }
      }
    } catch {
      completion(.failure(.invalidData))
    }
  }
  
  // FirestoreからユーザーのWalkを取得
  func fetchWalksFromFirestore(userId: String, completion: @escaping (Result<[Walk], WalkRepositoryError>) -> Void) {
    // タイムアウト設定
    let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
      completion(.failure(.networkError))
    }
    
    db.collection(collectionName)
      .whereField("user_id", isEqualTo: userId)
      .order(by: "created_at", descending: true)
      .getDocuments { [weak self] querySnapshot, error in
        timeoutTimer.invalidate()  // タイマーを無効化
        if let error = error {
          let mappedError = self?.mapFirestoreError(error) ?? .firestoreError(error)
          completion(.failure(mappedError))
          return
        }
        
        guard let documents = querySnapshot?.documents else {
          completion(.success([]))
          return
        }
        
        do {
          let walks = try documents.compactMap { document in
            try document.data(as: Walk.self)
          }
          
          // キャッシュを更新
          self?.cachedWalks = walks
          completion(.success(walks))
        } catch {
          completion(.failure(.invalidData))
        }
      }
  }
  
  // FirestoreでWalkを更新
  func updateWalkInFirestore(_ walk: Walk, completion: @escaping (Result<Walk, WalkRepositoryError>) -> Void) {
    guard walk.userId == getCurrentUserId() else {
      completion(.failure(.authenticationRequired))
      return
    }
    
    do {
      let walkRef = db.collection(collectionName).document(walk.id.uuidString)
      try walkRef.setData(from: walk, merge: true) { [weak self] error in
        if let error = error {
          let walkError = self?.mapFirestoreError(error) ?? .firestoreError(error)
          completion(.failure(walkError))
        } else {
          // キャッシュを更新
          self?.updateCache(with: walk)
          completion(.success(walk))
        }
      }
    } catch {
      completion(.failure(.invalidData))
    }
  }
  
  // FirestoreからWalkを削除
  func deleteWalkFromFirestore(walkId: UUID, userId: String, completion: @escaping (Result<Bool, WalkRepositoryError>) -> Void) {
    // まず、削除権限を確認
    db.collection(collectionName)
      .document(walkId.uuidString)
      .getDocument { [weak self] document, error in
        if let error = error {
          completion(.failure(.firestoreError(error)))
          return
        }
        
        guard let document = document, document.exists else {
          completion(.failure(.notFound))
          return
        }
        
        do {
          let walk = try document.data(as: Walk.self)
          guard walk.userId == userId else {
            completion(.failure(.authenticationRequired))
            return
          }
          
          // 削除を実行
          document.reference.delete { error in
            if let error = error {
              completion(.failure(.firestoreError(error)))
            } else {
              // キャッシュからも削除
              self?.removeFromCache(walkId: walkId)
              completion(.success(true))
            }
          }
        } catch {
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
      case 7: // PERMISSION_DENIED
        return .authenticationRequired
      case 5: // NOT_FOUND
        return .notFound
      case 14: // UNAVAILABLE
        return .networkError
      case 3: // INVALID_ARGUMENT
        return .invalidData
      default:
        return .firestoreError(error)
      }
    }
    
    // その他のエラー
    return .firestoreError(error)
  }
}
