//
//  User.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import Foundation

struct User: Identifiable {
  let id: String
  var email: String
  var displayName: String
  var photoUrl: String?
  var authProvider: String // "google", "email", etc.
  var createdAt: Date
  var updatedAt: Date

  init(
    id: String,
    email: String,
    displayName: String,
    photoUrl: String? = nil,
    authProvider: String,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.email = email
    self.displayName = displayName
    self.photoUrl = photoUrl
    self.authProvider = authProvider
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  // プロフィール画像があるかどうか
  var hasProfileImage: Bool {
    return photoUrl != nil && !photoUrl!.isEmpty
  }

  // 表示名が設定されているかどうか
  var hasDisplayName: Bool {
    return !displayName.isEmpty
  }
}
