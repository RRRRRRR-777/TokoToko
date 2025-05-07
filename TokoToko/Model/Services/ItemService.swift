//
//  ItemService.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import Foundation
import CoreLocation

class ItemService {
    private let repository: ItemRepositoryProtocol

    init(repository: ItemRepositoryProtocol = ItemRepository()) {
        self.repository = repository
    }

    func getAllItems() -> [Item] {
        return repository.fetchItems()
    }

    func createItem(title: String, description: String, location: CLLocationCoordinate2D? = nil) {
        let newItem = Item(title: title, description: description, location: location)
        repository.addItem(newItem)
    }
}
