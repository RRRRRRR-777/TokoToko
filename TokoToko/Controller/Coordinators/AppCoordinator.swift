//
//  AppCoordinator.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/06.
//

import SwiftUI
import CoreLocation
import MapKit

// アプリ全体の画面遷移を管理するコーディネーター
class AppCoordinator: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var selectedItem: Item? = nil

    enum Tab {
        case home
        case settings
    }

    // 画面遷移のメソッドを追加できます
    func navigateToHome() {
        selectedTab = .home
    }

    func navigateToSettings() {
        selectedTab = .settings
    }

    func showDetail(for item: Item) {
        selectedItem = item
    }
}
