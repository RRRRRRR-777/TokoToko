//
//  ItemRepository.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import Foundation

protocol ItemRepositoryProtocol {
    func fetchItems() -> [Item]
    func addItem(_ item: Item)
}

class ItemRepository: ItemRepositoryProtocol {
    private var items: [Item] = []

    func fetchItems() -> [Item] {
        // 実際のアプリではデータベースやAPIからデータを取得
        return items
    }

    func addItem(_ item: Item) {
        // 実際のアプリではデータベースやAPIにデータを保存
        items.append(item)
    }
}
