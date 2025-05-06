//
//  ItemRow.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI

struct ItemRow: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.title)
                .font(.headline)
                .accessibilityIdentifier(item.title)
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .accessibilityIdentifier(item.description)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("item-row-\(item.id)")
    }
}

#Preview {
    ItemRow(item: Item(title: "サンプルアイテム", description: "これはサンプルの説明です"))
}
