//
//  LoginView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/05/20.
//

import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct LoginView: View {
  @EnvironmentObject private var authManager: AuthManager
  @State private var isLoading = false
  @State private var errorMessage: String?

  private let authService = GoogleAuthService()

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
    // アプリレベルでログイン状態を管理するため、onAppearでの処理は不要
  }

  private func signInWithGoogle() {
    isLoading = true
    errorMessage = nil

    authService.signInWithGoogle { result in
      DispatchQueue.main.async {
        self.isLoading = false

        switch result {
        case .success:
          // 認証成功 - AuthManagerのリスナーが自動的にログイン状態を更新する
          break
        case .failure(let message):
          self.errorMessage = message
        }
      }
    }
  }
}

#Preview {
  LoginView()
    .environmentObject(AuthManager())
}
