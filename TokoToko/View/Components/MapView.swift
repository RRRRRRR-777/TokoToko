//
//  MapView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI
import MapKit

struct MapView: View {
   @EnvironmentObject var coordinator: AppCoordinator
   @State private var region: MKCoordinateRegion
   @State private var userTrackingMode: MapUserTrackingMode = .follow

   // 表示するアノテーション
   var annotations: [MapItem] = []

   init(region: MKCoordinateRegion = MKCoordinateRegion(
       center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671), // 東京駅をデフォルト位置に
       span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
   ), annotations: [MapItem] = []) {
       _region = State(initialValue: region)
       self.annotations = annotations
   }

   var body: some View {
       Map(coordinateRegion: $region,
           showsUserLocation: true,
           userTrackingMode: $userTrackingMode,
           annotationItems: annotations) { item in
           MapAnnotation(coordinate: item.coordinate) {
               VStack {
                   Image(systemName: item.imageName)
                       .foregroundColor(.red)
                       .font(.title)

                   Text(item.title)
                       .font(.caption)
                       .foregroundColor(.black)
                       .background(Color.white.opacity(0.7))
                       .cornerRadius(5)
               }
           }
       }
       .onAppear {
           // 現在位置が取得できている場合は、その位置にマップを移動
           if let location = coordinator.currentLocation {
               region = coordinator.locationManager.region(for: location)
           }

           // 位置情報の許可状態を確認し、許可されている場合のみ更新を開始
           let status = coordinator.locationAuthorizationStatus
           if status == .authorizedWhenInUse || status == .authorizedAlways {
               coordinator.startLocationUpdates()
           }
       }
       .onDisappear {
           // 画面を離れる時に位置情報の更新を停止（必要に応じて）
           // coordinator.stopLocationUpdates()
       }
       .onChange(of: coordinator.currentLocation) { oldLocation, newLocation in
           // 位置情報が更新されたらマップを移動（必要に応じて）
           if let location = newLocation, userTrackingMode == .follow {
               region = coordinator.locationManager.region(for: location)
           }
       }
   }
}

// マップ上に表示するアイテムのモデル
struct MapItem: Identifiable {
   let id = UUID()
   let coordinate: CLLocationCoordinate2D
   let title: String
   let imageName: String

   init(coordinate: CLLocationCoordinate2D, title: String, imageName: String = "mappin.circle.fill") {
       self.coordinate = coordinate
       self.title = title
       self.imageName = imageName
   }
}

#Preview {
   MapView()
       .environmentObject(AppCoordinator())
}
