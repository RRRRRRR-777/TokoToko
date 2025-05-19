//
//  HomeView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/16.
//

import CoreLocation
import SwiftUI

struct HomeView: View {
  @State private var walks: [Walk] = []
  @State private var isLoading = false
  @State private var showingAddWalkView = false
  @State private var newWalkTitle = ""
  @State private var newWalkDescription = ""
  @State private var useCurrentLocation = false

  // 位置情報マネージャー
  private let locationManager = LocationManager.shared
  @State private var currentLocation: CLLocation?

  // リポジトリ
  private let walkRepository = WalkRepository.shared

  var body: some View {
    List {
      ForEach(walks) { walk in
        NavigationLink(destination: DetailView(walk: walk)) {
          WalkRow(walk: walk)
        }
      }
    }
    .navigationTitle("TokoToko")
    .toolbar {
      Button(action: { showingAddWalkView = true }) {
        Label("記録追加", systemImage: "plus")
      }
      .accessibilityIdentifier("記録追加")
    }
    .sheet(isPresented: $showingAddWalkView) {
      // 新規記録追加フォーム
      VStack {
        Text("新規記録")
          .font(.headline)
          .padding()

        Form {
          TextField("タイトル", text: $newWalkTitle)
            .accessibilityIdentifier("タイトル")
          TextField("説明", text: $newWalkDescription)
            .accessibilityIdentifier("説明")
          Toggle("現在位置を使用", isOn: $useCurrentLocation)
            .accessibilityIdentifier("現在位置を使用")
        }

        HStack {
          Button("キャンセル") {
            resetForm()
            showingAddWalkView = false
          }
          .accessibilityIdentifier("キャンセル")

          Spacer()

          Button("保存") {
            if !newWalkTitle.isEmpty {
              saveNewWalk()
            }
          }
          .accessibilityIdentifier("保存")
          .disabled(newWalkTitle.isEmpty)
        }
        .padding()
      }
    }
    .onAppear {
      loadWalks()
      setupLocationManager()
    }
    .loadingOverlay(isLoading: isLoading)
  }

  // 記録の読み込み
  private func loadWalks() {
    isLoading = true
    walkRepository.fetchWalks { result in
      isLoading = false
      switch result {
      case .success(let fetchedWalks):
        self.walks = fetchedWalks
      case .failure(let error):
        print("Error loading walks: \(error)")
      // エラー処理をここに追加
      }
    }
  }

  // 新規記録の保存
  private func saveNewWalk() {
    isLoading = true

    // 現在位置を使用する場合は、locationManagerから位置情報を取得
    var location: CLLocationCoordinate2D? = nil
    if useCurrentLocation, let currentLocation = currentLocation {
      location = currentLocation.coordinate
    }

    walkRepository.createWalk(
      title: newWalkTitle,
      description: newWalkDescription,
      location: location
    ) { result in
      isLoading = false
      switch result {
      case .success(_):
        // フォームをリセットして閉じる
        resetForm()
        showingAddWalkView = false
        // 記録リストを更新
        loadWalks()
      case .failure(let error):
        print("Error saving walk: \(error)")
      // エラー処理をここに追加
      }
    }
  }

  // フォームのリセット
  private func resetForm() {
    newWalkTitle = ""
    newWalkDescription = ""
    useCurrentLocation = false
  }

  // 位置情報マネージャーの設定
  private func setupLocationManager() {
    // 位置情報の許可状態を確認
    let status = locationManager.checkAuthorizationStatus()

    // 許可されている場合は位置情報の更新を開始
    if status == .authorizedWhenInUse || status == .authorizedAlways {
      locationManager.startUpdatingLocation()
      currentLocation = locationManager.currentLocation
    } else if status == .notDetermined {
      // まだ決定されていない場合は許可を求める
      locationManager.requestWhenInUseAuthorization()
    }
  }
}

#Preview {
  NavigationView {
    HomeView()
  }
}
