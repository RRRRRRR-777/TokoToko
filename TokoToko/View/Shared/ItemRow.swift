//
//  ItemRow.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import SwiftUI

struct WalkRow: View {
  let walk: Walk

  var body: some View {
    VStack(alignment: .leading) {
      Text(walk.title)
        .font(.headline)
        .accessibilityIdentifier(walk.title)
      Text(walk.description)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .accessibilityIdentifier(walk.description)
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("walk-row-\(walk.id)")
  }
}

#Preview {
  WalkRow(walk: Walk(title: "サンプル記録", description: "これはサンプルの説明です"))
}
