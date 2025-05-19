//
//  DetailView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import MapKit
import SwiftUI

struct DetailView: View {
  @State private var walk: Walk
  @State private var isLoading = false

  // リポジトリ
  private let walkRepository = WalkRepository.shared

  init(walk: Walk) {
    _walk = State(initialValue: walk)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text(walk.title)
          .font(.largeTitle)
          .fontWeight(.bold)
          .accessibilityIdentifier(walk.title)

        Text(walk.description)
          .font(.body)
          .accessibilityIdentifier(walk.description)

        // 位置情報がある場合はマップを表示
        if walk.hasLocation, let location = walk.location {
          VStack(alignment: .leading) {
            Text("位置情報")
              .font(.headline)

            Text(walk.locationString)
              .font(.caption)
              .foregroundColor(.secondary)

            // マップ表示
            Map(
              coordinateRegion: .constant(
                MKCoordinateRegion(
                  center: location,
                  span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )),
              annotationItems: [
                MapItem(coordinate: location, title: walk.title)
              ]
            ) { item in
              MapAnnotation(coordinate: item.coordinate) {
                Image(systemName: "mappin.circle.fill")
                  .foregroundColor(.red)
                  .font(.title)
              }
            }
            .frame(height: 200)
            .cornerRadius(10)
          }
        }

        // 作成日時
        Text("作成日時: \(walk.createdAt.formatted())")
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer(minLength: 50)
      }
      .padding()
    }
    .navigationTitle("詳細")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      Button(action: { refreshWalkDetails() }) {
        Image(systemName: "arrow.clockwise")
      }
    }
    .loadingOverlay(isLoading: isLoading)
    .onAppear {
      refreshWalkDetails()
    }
  }

  // 記録の詳細を更新
  private func refreshWalkDetails() {
    isLoading = true
    walkRepository.fetchWalk(withID: walk.id) { result in
      isLoading = false
      switch result {
      case .success(let updatedWalk):
        self.walk = updatedWalk
      case .failure(let error):
        print("Error refreshing walk details: \(error)")
      // エラー処理をここに追加
      }
    }
  }
}

#Preview {
  NavigationView {
    DetailView(walk: Walk(title: "サンプル記録", description: "これはサンプルの詳細説明です。長めのテキストを表示することもできます。"))
  }
}
