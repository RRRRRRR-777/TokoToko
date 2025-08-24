//
//  LocationAccuracySettingsView.swift
//  TokoToko
//
//  Created by Claude on 2025/08/22.
//

import CoreLocation
import SwiftUI

/// 位置情報精度設定画面
///
/// ユーザーが位置情報の精度モードとバックグラウンド更新設定を
/// カスタマイズできる画面です。3つの精度モードから選択でき、
/// 各モードの特徴と適用場面を説明します。
///
/// ## Overview
///
/// 主要な機能：
/// - **精度モード選択**: 高精度/バランス/省電力の3モードから選択
/// - **バックグラウンド更新**: ON/OFF切り替えトグル
/// - **権限状態表示**: 現在の位置情報権限の確認
/// - **設定アプリ遷移**: システム設定画面への誘導
///
/// ## Topics
///
/// ### Dependencies
/// - ``LocationSettingsManager``
/// - ``LocationAccuracyMode``
///
/// ### UI Components
/// - ``AccuracyModeRow``
/// - ``PermissionStatusRow``
/// - ``BackgroundUpdateToggle``
struct LocationAccuracySettingsView: View {

  /// 位置情報設定マネージャー
  ///
  /// 精度モードとバックグラウンド更新設定を管理します。
  /// @EnvironmentObjectとして注入され、設定変更がリアルタイムで反映されます。
  @EnvironmentObject private var settingsManager: LocationSettingsManager

  /// 現在の位置情報権限状態
  ///
  /// LocationManagerから取得した権限状態を表示用に保持します。
  @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined

  var body: some View {
    ZStack {
      Color("BackgroundColor")
        .ignoresSafeArea(.all)
      
      NavigationView {
        settingsListView
          .navigationTitle("位置情報設定")
          .navigationBarTitleDisplayMode(.inline)
          .onAppear {
            updateAuthorizationStatus()
            setupNavigationAppearance()
          }
      }
      .accentColor(.black)
    }
  }
  
  /// 設定リストビューの共通実装
  private var settingsListView: some View {
    List {
      // 精度モード選択セクション
      Section(header: 
        HStack {
          Text("位置情報の精度")
            .foregroundColor(.gray)
          Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color("BackgroundColor"))
        .listRowInsets(EdgeInsets())
      ) {
        ForEach(LocationAccuracyMode.allCases) { mode in
          AccuracyModeRow(
            mode: mode,
            isSelected: settingsManager.currentMode == mode
          ) {
            settingsManager.setAccuracyMode(mode)
            settingsManager.saveSettings()
          }
          .accessibilityIdentifier("location_accuracy_\(mode.rawValue)")
          .listRowBackground(Color("BackgroundColor"))
        }
      }
      
      // バックグラウンド更新セクション
      Section(header:
        HStack {
          Text("バックグラウンド設定")
            .foregroundColor(.gray)
          Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color("BackgroundColor"))
        .listRowInsets(EdgeInsets())
      ) {
        HStack {
          Text("バックグラウンド更新")
            .foregroundColor(.black)
          Spacer()
          Toggle("", isOn: .init(
            get: { settingsManager.isBackgroundUpdateEnabled },
            set: { enabled in
              settingsManager.setBackgroundUpdateEnabled(enabled)
              settingsManager.saveSettings()
            }
          ))
          .accessibilityIdentifier("background_update_toggle")
        }
        .listRowBackground(Color("BackgroundColor"))
        
        Text("アプリがバックグラウンドで動作中も位置情報を更新します。")
          .font(.caption)
          .foregroundColor(.black)
          .listRowBackground(Color("BackgroundColor"))
      }
      
      // 権限状態セクション
      Section(header:
        HStack {
          Text("権限状態")
            .foregroundColor(.gray)
          Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color("BackgroundColor"))
        .listRowInsets(EdgeInsets())
      ) {
        PermissionStatusRow(status: authorizationStatus)
          .listRowBackground(Color("BackgroundColor"))
        
        Button("設定アプリを開く") {
          openSettingsApp()
        }
        .foregroundColor(.black)
        .accessibilityIdentifier("open_settings_app")
        .listRowBackground(Color("BackgroundColor"))
      }
    }
    .listStyle(PlainListStyle())
    .background(Color("BackgroundColor"))
    .modifier(ScrollContentBackgroundModifier())
    .onAppear {
      setupTableViewAppearance()
    }
    .background(Color("BackgroundColor").ignoresSafeArea())
  }

  // MARK: - Private Methods

  /// 現在の位置情報権限状態を更新
  ///
  /// LocationManagerから最新の権限状態を取得して表示を更新します。
  private func updateAuthorizationStatus() {
    authorizationStatus = LocationManager.shared.checkAuthorizationStatus()
  }

  /// UI外観の統合設定
  ///
  /// ナビゲーションバー、テーブルビュー、スクロールビューの外観を統一して
  /// ダークモード・ライトモード統一とスクロール背景問題を解決します。
  private func setupNavigationAppearance() {
    // ナビゲーションバー外観設定
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundColor = UIColor(named: "BackgroundColor")
    appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
    
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    
    // 統合背景制御
    setupUnifiedBackgroundAppearance()
  }

  /// 統合背景外観設定
  ///
  /// 全UIコンポーネントの背景色をBackgroundColorに統一します。
  private func setupUnifiedBackgroundAppearance() {
    let backgroundColor = UIColor(named: "BackgroundColor")
    
    // テーブルビュー関連
    UITableView.appearance().backgroundColor = backgroundColor
    UITableView.appearance().separatorStyle = .none
    UITableView.appearance().separatorColor = .clear
    UITableViewCell.appearance().backgroundColor = .clear
    UITableViewHeaderFooterView.appearance().backgroundColor = backgroundColor
    UITableViewHeaderFooterView.appearance().backgroundConfiguration = nil
    
    // スクロールビューと全体制御
    UIScrollView.appearance().backgroundColor = backgroundColor
    UIWindow.appearance().backgroundColor = backgroundColor
    UIView.appearance(whenContainedInInstancesOf: [UITableView.self]).backgroundColor = backgroundColor
  }

  /// 動的背景制御
  ///
  /// ビュー階層を直接探索して背景色を動的に設定します。
  /// SwiftUIとUIKitの境界で発生する背景問題の最終解決策です。
  private func setupTableViewAppearance() {
    DispatchQueue.main.async {
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
         let window = windowScene.windows.first {
        window.backgroundColor = UIColor(named: "BackgroundColor")
        self.applyBackgroundColorRecursively(to: window)
      }
    }
  }
  
  /// ビュー階層に背景色を再帰的に適用
  private func applyBackgroundColorRecursively(to view: UIView) {
    let backgroundColor = UIColor(named: "BackgroundColor")
    
    // UITableViewとその親階層に特別な処理
    if let tableView = view as? UITableView {
      tableView.backgroundColor = backgroundColor
      var parentView = tableView.superview
      while parentView != nil {
        parentView?.backgroundColor = backgroundColor
        parentView = parentView?.superview
      }
    }
    
    // 全サブビューに適用
    view.backgroundColor = backgroundColor
    for subview in view.subviews {
      applyBackgroundColorRecursively(to: subview)
    }
  }

  /// 設定アプリを開く
  ///
  /// ユーザーをiOSの設定アプリの位置情報設定画面に誘導します。
  private func openSettingsApp() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(settingsUrl)
    }
  }
}

// MARK: - View Modifiers

/// iOS版別スクロール背景制御
///
/// iOS 16以降の.scrollContentBackground(.hidden)を活用しつつ、
/// 全バージョンで確実な背景色統一を提供します。
private struct ScrollContentBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 16.0, *) {
      content
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
    } else {
      content
        .background(Color("BackgroundColor"))
    }
  }
}

// MARK: - Supporting Views

/// 精度モード選択行
///
/// 各精度モードの名称、説明、選択状態を表示する行コンポーネントです。
private struct AccuracyModeRow: View {
  let mode: LocationAccuracyMode
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(mode.displayName)
            .font(.body)
            .foregroundColor(.black)

          Text(mode.description)
            .font(.caption)
            .foregroundColor(.black)
            .multilineTextAlignment(.leading)
        }

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.accentColor)
        } else {
          Image(systemName: "circle")
            .foregroundColor(.secondary)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
  }
}

/// 権限状態表示行
///
/// 現在の位置情報権限状態を表示します。
private struct PermissionStatusRow: View {
  let status: CLAuthorizationStatus

  var body: some View {
    HStack {
      Text("位置情報権限")
        .foregroundColor(.black)
      Spacer()
      Text(statusText)
        .foregroundColor(statusColor)
        .font(.caption)
    }
  }

  /// 権限状態の表示テキスト
  private var statusText: String {
    switch status {
    case .notDetermined:
      return "未確認"
    case .denied:
      return "拒否"
    case .restricted:
      return "制限"
    case .authorizedWhenInUse:
      return "使用中のみ"
    case .authorizedAlways:
      return "常に許可"
    @unknown default:
      return "不明"
    }
  }

  /// 権限状態の表示色
  private var statusColor: Color {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      return .green
    case .denied, .restricted:
      return .red
    case .notDetermined:
      return .orange
    @unknown default:
      return .secondary
    }
  }
}

// MARK: - Preview

struct LocationAccuracySettingsView_Previews: PreviewProvider {
  static var previews: some View {
    LocationAccuracySettingsView()
      .environmentObject(LocationSettingsManager())
  }
}
