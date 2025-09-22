//
//  OpenSourceLicensesView.swift
//  TekuToko
//
//  Created by Assistant on 2025/09/19.
//

import SwiftUI

/// オープンソースライセンス表示画面
///
/// `TekuToko/Resources/Licenses` 配下の `.txt` を列挙し、
/// タップでファイル内容をそのまま表示します。
struct OpenSourceLicensesView: View {
  struct LicenseItem: Identifiable {
    let id = UUID()
    /// 表示名（ファイル名から拡張子を除去したもの）
    let displayName: String
    /// リソース名（拡張子なし）
    let resourceName: String
  }

  // TekuToko/Resources/Licenses/Licenses 配下の .txt を列挙してリスト化
  private var items: [LicenseItem] {
    var urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "Licenses") ?? []
    if urls.isEmpty {
      urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: nil) ?? []
    }

    // Licenses に置いた .txt をすべて対象にする（ファイル名ルールを縛らない）
    return urls
      .map { url -> LicenseItem in
        let base = url.deletingPathExtension().lastPathComponent
        return LicenseItem(displayName: base, resourceName: base)
      }
      .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
  }

  var body: some View {
    List {
      Section(
        header:
          HStack {
            Text("依存ライブラリ")
              .foregroundColor(.gray)
              .font(.footnote)
              .fontWeight(.regular)
              .textCase(.uppercase)
            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(Color("BackgroundColor"))
          .listRowInsets(EdgeInsets())
      ) {
        ForEach(items) { item in
          NavigationLink(destination: LicenseDetailView(item: item)) {
            HStack {
              Text(item.displayName)
                .foregroundColor(.black)
              Spacer()
            }
          }
          .listRowBackground(Color("BackgroundColor").opacity(0.8))
        }
      }
    }
    .listStyle(PlainListStyle())
    .modifier(BackgroundColorModifier())
    .background(Color("BackgroundColor").ignoresSafeArea())
    .navigationTitle("オープンソースライセンス")
    .navigationBarTitleDisplayMode(.inline)
    .accentColor(.black)
  }
}

/// ライセンス詳細表示
struct LicenseDetailView: View {
  let item: OpenSourceLicensesView.LicenseItem

  private func loadLicenseText() -> String {
    // `TekuToko/Resources/Licenses/<name>.txt` を読み込む
    let url =
      Bundle.main.url(forResource: item.resourceName, withExtension: "txt", subdirectory: "Licenses")
      ?? Bundle.main.url(forResource: item.resourceName, withExtension: "txt")
    guard let url, let s = try? String(contentsOf: url, encoding: .utf8) else {
      return "ライセンス本文を読み込めませんでした。"
    }
    return s
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      Color("BackgroundColor").ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text(item.displayName)
            .font(.title3).bold()
            .foregroundColor(.black)

          Text(loadLicenseText())
            .font(.system(.footnote, design: .monospaced))
            .foregroundColor(.black)
            .textSelection(.enabled)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
  }
}

// プレビュー
struct OpenSourceLicensesView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView { OpenSourceLicensesView() }
  }
}
