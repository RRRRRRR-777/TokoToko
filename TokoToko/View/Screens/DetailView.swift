//
//  DetailView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI


struct DetailView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var controller: DetailController

    init(item: Item) {
        _controller = StateObject(wrappedValue: DetailController(item: item))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(controller.item.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityIdentifier(controller.item.title)

                Text(controller.item.description)
                    .font(.body)
                    .accessibilityIdentifier(controller.item.description)

                // 作成日時
                Text("作成日時: \(controller.item.createdAt.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        DetailView(item: Item(title: "サンプルアイテム", description: "これはサンプルの詳細説明です。長めのテキストを表示することもできます。"))
            .environmentObject(AppCoordinator())
    }
}
