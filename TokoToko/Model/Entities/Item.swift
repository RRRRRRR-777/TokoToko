//
//  Item.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import Foundation

struct Item: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, description: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.createdAt = createdAt
    }
}
