//
//  DetailView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI
import MapKit

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

                // 位置情報がある場合はマップを表示
                if controller.item.hasLocation, let location = controller.item.location {
                    VStack(alignment: .leading) {
                        Text("位置情報")
                            .font(.headline)

                        Text(controller.item.locationString)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // マップ表示
                        Map(coordinateRegion: .constant(MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )), annotationItems: [
                            MapItem(coordinate: location, title: controller.item.title)
                        ]) { item in
                            MapAnnotation(coordinate: item.coordinate) {
                                Image(systemName: item.imageName)
                                    .foregroundColor(.red)
                                    .font(.title)
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(10)
                    }
                }

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
