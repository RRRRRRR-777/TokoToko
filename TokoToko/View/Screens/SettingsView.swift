//
//  SettingsView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/20.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showingLogoutAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section(header: Text("アカウント")) {
                if let user = Auth.auth().currentUser {
                    HStack {
                        Text("メールアドレス")
                        Spacer()
                        Text(user.email ?? "不明")
                            .foregroundColor(.secondary)
                    }

                    if let photoURL = user.photoURL, let url = URL(string: photoURL.absoluteString) {
                        HStack {
                            Text("プロフィール画像")
                            Spacer()
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        }
                    }

                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Text("ログアウト")
                                .foregroundColor(.red)
                            Spacer()
                            if isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoading)
                }
            }

            Section(header: Text("アプリ設定")) {
                Text("通知")
                Text("プライバシー")
            }

            Section(header: Text("位置情報")) {
                Text("位置情報の精度")
                Text("バックグラウンド更新")
            }

            Section(header: Text("その他")) {
                Text("このアプリについて")
                Text("ヘルプ")
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("設定")
        .alert("ログアウトしますか？", isPresented: $showingLogoutAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("ログアウト", role: .destructive) {
                logout()
            }
        } message: {
            Text("アカウントからログアウトします。再度ログインする必要があります。")
        }
    }

    private func logout() {
        isLoading = true
        errorMessage = nil

        do {
            try Auth.auth().signOut()
            // AuthManagerのリスナーが自動的にログアウト状態を検出する
            DispatchQueue.main.async {
                isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                errorMessage = "ログアウトに失敗しました: \(error.localizedDescription)"
            }
        }
    }
}

// プレビュー用
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(AuthManager())
        }
    }
}
