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
  
  /// エラーメッセージ表示用
  @State private var errorMessage: String?
  
  /// エラーアラート表示フラグ
  @State private var showingErrorAlert = false

  var body: some View {
    settingsListView
      .navigationTitle("位置情報設定")
      .navigationBarTitleDisplayMode(.inline)
      .background(Color("BackgroundColor"))
      .onAppear {
        updateAuthorizationStatus()
      }
      .alert("設定エラー", isPresented: $showingErrorAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage ?? "設定の保存に失敗しました")
      }
  }

  /// 設定リストビューの共通実装
  private var settingsListView: some View {
    List {
      accuracyModeSection
      backgroundUpdateSection
      permissionStatusSection
    }
    .listStyle(PlainListStyle())
    .background(Color("BackgroundColor"))
    .modifier(ScrollContentBackgroundModifier())
  }

  /// 精度モード選択セクション
  private var accuracyModeSection: some View {
    Section(header: sectionHeader("位置情報の精度")) {
      ForEach(LocationAccuracyMode.allCases) { mode in
        AccuracyModeRow(
          mode: mode,
          isSelected: settingsManager.currentMode == mode
        ) {
          settingsManager.setAccuracyMode(mode)
          saveSettingsWithErrorHandling()
        }
        .accessibilityIdentifier("location_accuracy_\(mode.rawValue)")
        .listRowBackground(Color("BackgroundColor"))
      }
    }
  }

  /// バックグラウンド更新セクション
  private var backgroundUpdateSection: some View {
    Section(header: sectionHeader("バックグラウンド設定")) {
      backgroundUpdateToggleRow
    }
  }

  /// バックグラウンド更新トグル行
  private var backgroundUpdateToggleRow: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("バックグラウンド更新")
          .foregroundColor(.black)
        Spacer()
        Toggle("", isOn: .init(
          get: { settingsManager.isBackgroundUpdateEnabled },
          set: { enabled in
            settingsManager.setBackgroundUpdateEnabled(enabled)
            saveSettingsWithErrorHandling()
          }
        ))
        .accessibilityIdentifier("background_update_toggle")
      }

      Text("アプリがバックグラウンドで動作中も位置情報を更新します。")
        .font(.caption)
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .listRowBackground(Color("BackgroundColor"))
  }

  /// 権限状態セクション
  private var permissionStatusSection: some View {
    Section(header: sectionHeader("権限状態")) {
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

  /// セクションヘッダーの共通実装
  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.footnote)
      .foregroundColor(.gray)
      .textCase(nil)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Private Methods

  /// 現在の位置情報権限状態を更新
  ///
  /// LocationManagerから最新の権限状態を取得して表示を更新します。
  private func updateAuthorizationStatus() {
    authorizationStatus = LocationManager.shared.checkAuthorizationStatus()
  }

  /// 設定アプリを開く
  ///
  /// ユーザーをiOSの設定アプリの位置情報設定画面に誘導します。
  private func openSettingsApp() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(settingsUrl)
    }
  }
  
  /// 設定保存処理（エラーハンドリング付き）
  ///
  /// 設定をFirestoreに保存し、エラーが発生した場合は
  /// ユーザーに通知とログ記録を行います。
  private func saveSettingsWithErrorHandling() {
    do {
      try settingsManager.saveSettings()
      // 成功時のログ
      EnhancedVibeLogger.shared.info(
        "位置情報設定を保存しました",
        additionalInfo: [
          "accuracyMode": settingsManager.currentMode.rawValue,
          "backgroundUpdate": String(settingsManager.isBackgroundUpdateEnabled)
        ]
      )
    } catch {
      // エラー処理
      EnhancedVibeLogger.shared.error(
        "位置情報設定の保存に失敗",
        error: error,
        additionalInfo: [
          "accuracyMode": settingsManager.currentMode.rawValue,
          "backgroundUpdate": String(settingsManager.isBackgroundUpdateEnabled)
        ]
      )
      
      // ユーザーへのフィードバック
      errorMessage = "設定の保存に失敗しました。\nインターネット接続を確認してください。"
      showingErrorAlert = true
      
      // 設定を元に戻す（オプション）
      // 必要に応じて前の状態に復元する処理を追加可能
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
