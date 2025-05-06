//
//  HomeView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI
import CoreLocation

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
                        Toggle("現在位置を使用", isOn: $useCurrentLocation)
                            .accessibilityIdentifier("現在位置を使用")
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
                                // 現在位置を使用する場合は、coordinatorから位置情報を取得
                                var location: CLLocationCoordinate2D? = nil
                                if useCurrentLocation, let currentLocation = coordinator.currentLocation {
                                    location = currentLocation.coordinate
                                }

                                controller.addNewItem(
                                    title: newItemTitle,
                                    description: newItemDescription,
                                    location: location
                                )

                                // フォームをリセット
                                newItemTitle = ""
                                newItemDescription = ""
                                useCurrentLocation = false
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
