//
//  HomeController.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI

class HomeController: ObservableObject {
    private let itemService: ItemService
    @Published var items: [Item] = []

    init(itemService: ItemService = ItemService()) {
        self.itemService = itemService
        fetchItems()
    }

    func fetchItems() {
        items = itemService.getAllItems()
    }

    func addNewItem(title: String, description: String) {
        itemService.createItem(title: title, description: description)
        fetchItems() // リストを更新
    }
}
