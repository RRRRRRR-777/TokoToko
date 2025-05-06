//
//  HomeView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var controller = HomeController()
    @State private var showingAddItemView = false
    @State private var newItemTitle = ""
    @State private var newItemDescription = ""
    @State private var useCurrentLocation = false

    var body: some View {
        NavigationView {
            List {
                ForEach(controller.items) { item in
                    NavigationLink(destination: DetailView(item: item)) {
                        ItemRow(item: item)
                    }
                    .onTapGesture {
                        coordinator.showDetail(for: item)
                    }
                }
            }
            .navigationTitle("TokoToko")
            .toolbar {
                Button(action: { showingAddItemView = true }) {
                    Label("アイテム追加", systemImage: "plus")
                }
                .accessibilityIdentifier("アイテム追加")
            }
            .sheet(isPresented: $showingAddItemView) {
                // 新規アイテム追加フォーム
                VStack {
                    Text("新規アイテム")
                        .font(.headline)
                        .padding()

                    Form {
                        TextField("タイトル", text: $newItemTitle)
                            .accessibilityIdentifier("タイトル")
                        TextField("説明", text: $newItemDescription)
                            .accessibilityIdentifier("説明")
                    }

                    HStack {
                        Button("キャンセル") {
                            newItemTitle = ""
                            newItemDescription = ""
                            showingAddItemView = false
                        }
                        .accessibilityIdentifier("キャンセル")

                        Spacer()

                        Button("保存") {
                            if !newItemTitle.isEmpty {

                                controller.addNewItem(
                                    title: newItemTitle,
                                    description: newItemDescription
                                )

                                // フォームをリセット
                                newItemTitle = ""
                                newItemDescription = ""
                                showingAddItemView = false
                            }
                        }
                        .accessibilityIdentifier("保存")
                        .disabled(newItemTitle.isEmpty)
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppCoordinator())
}
