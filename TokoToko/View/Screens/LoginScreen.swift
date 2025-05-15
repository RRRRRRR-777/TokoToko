//
//  LoginScreen.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/15.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore

struct LoginScreen: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "mappin.and.ellipse")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text("TokoTokoへようこそ")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("位置情報を共有して、友達と繋がりましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                GoogleSignInButton(style: .wide, action: signInWithGoogle)
                    .padding(.horizontal)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            setupAuthStateListener()
        }
        .navigationDestination(isPresented: $isLoggedIn) {
            MainTabView() // ログイン成功後のメイン画面
        }
    }

    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                isLoggedIn = true
            }
        }
    }

    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase設定エラー"
            isLoading = false
            return
        }

        // Google Sign In configuration
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "ウィンドウシーンの取得に失敗しました"
            isLoading = false
            return
        }

        // Start the sign in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                errorMessage = "Googleログインエラー: \(error.localizedDescription)"
                isLoading = false
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                errorMessage = "ユーザー情報の取得に失敗しました"
                isLoading = false
                return
            }

            // Firebaseの認証情報を作成
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            // Firebaseで認証
            Auth.auth().signIn(with: credential) { authResult, error in
                isLoading = false

                if let error = error {
                    errorMessage = "Firebase認証エラー: \(error.localizedDescription)"
                    return
                }

                // 認証成功
                isLoggedIn = true
            }
        }
    }
}

#Preview {
    LoginScreen()
}
