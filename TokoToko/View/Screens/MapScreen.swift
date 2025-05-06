//
//  MapScreen.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI
import MapKit

struct MapScreen: View {
  @EnvironmentObject var coordinator: AppCoordinator
  @StateObject private var controller = HomeController()
  @State private var showingLocationPermissionAlert = false
  @State private var showingBackgroundPermissionAlert = false

  var body: some View {
      VStack {
          // 位置情報の許可状態に応じて表示を切り替え
          switch coordinator.locationAuthorizationStatus {
          case .notDetermined:
              // まだ許可を求めていない場合
              requestPermissionView

          case .restricted, .denied:
              // 許可が拒否されている場合
              permissionDeniedView

          case .authorizedWhenInUse, .authorizedAlways:
              // 許可されている場合
              MapView(annotations: createAnnotationsFromItems())
                  .edgesIgnoringSafeArea(.all)

          @unknown default:
              Text("位置情報の許可状態が不明です")
          }
      }
      .navigationTitle("マップ")
      .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
              Button(action: {
                  showingBackgroundPermissionAlert = true
              }) {
                  Image(systemName: "location.fill")
              }
              .alert("バックグラウンド位置情報", isPresented: $showingBackgroundPermissionAlert) {
                  Button("許可する") {
                      coordinator.requestAlwaysPermission()
                  }
                  Button("キャンセル", role: .cancel) {}
              } message: {
                  Text("バックグラウンドでも位置情報を取得するために許可が必要です。")
              }
          }
      }
  }

  // アイテムからマップアノテーションを作成
  private func createAnnotationsFromItems() -> [MapItem] {
      return controller.items.compactMap { item in
          guard let location = item.location else { return nil }
          return MapItem(
              coordinate: location,
              title: item.title,
              imageName: "mappin.circle.fill"
          )
      }
  }

  // 位置情報の許可を求めるビュー
  private var requestPermissionView: some View {
      VStack(spacing: 20) {
          Image(systemName: "location.circle")
              .font(.system(size: 100))
              .foregroundColor(.blue)

          Text("位置情報の使用許可が必要です")
              .font(.title)

          Text("このアプリはあなたの現在地を表示するために位置情報を使用します。")
              .multilineTextAlignment(.center)
              .padding()

          Button("位置情報を許可する") {
              coordinator.requestLocationPermission()
          }
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      .padding()
  }

  // 位置情報の許可が拒否された場合のビュー
  private var permissionDeniedView: some View {
      VStack(spacing: 20) {
          Image(systemName: "location.slash")
              .font(.system(size: 100))
              .foregroundColor(.red)

          Text("位置情報へのアクセスが拒否されています")
              .font(.title)

          Text("このアプリを使用するには、設定アプリから位置情報へのアクセスを許可してください。")
              .multilineTextAlignment(.center)
              .padding()

          Button("設定を開く") {
              if let url = URL(string: UIApplication.openSettingsURLString) {
                  UIApplication.shared.open(url)
              }
          }
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      .padding()
  }
}

#Preview {
  NavigationView {
      MapScreen()
          .environmentObject(AppCoordinator())
  }
}
