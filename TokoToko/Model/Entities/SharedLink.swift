//
//  SharedLink.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import Foundation

struct SharedLink: Identifiable {
  let id: UUID
  var walkId: UUID // 共有される散歩のID
  var urlToken: String // 共有リンクを一意に識別するためのトークン
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    walkId: UUID,
    urlToken: String = UUID().uuidString,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.walkId = walkId
    self.urlToken = urlToken
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  // 共有URLを生成
  var shareUrl: String {
    // 実際のアプリでは適切なベースURLを使用
    return "https://tokotoko.app/shared/\(urlToken)"
  }

  // URLトークンが有効かどうか
  var hasValidToken: Bool {
    return !urlToken.isEmpty
  }

  // 作成日時を文字列で表示
  var createdAtString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: createdAt)
  }

  // 新しいトークンを生成
  mutating func regenerateToken() {
    urlToken = UUID().uuidString
    updatedAt = Date()
  }
}
