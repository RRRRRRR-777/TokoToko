//
//  DetailController.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI

class DetailController: ObservableObject {
    @Published var item: Item
    private let itemService: ItemService

    init(item: Item, itemService: ItemService = ItemService()) {
        self.item = item
        self.itemService = itemService
    }

    // 詳細画面での項目更新などの機能を追加できます
}
