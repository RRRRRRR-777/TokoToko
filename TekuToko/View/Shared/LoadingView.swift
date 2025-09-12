//
//  LoadingView.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/05/16.
//

import SwiftUI

struct LoadingView: View {
  var message: String = "読み込み中..."

  var body: some View {
    VStack(spacing: 20) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
        .scaleEffect(1.5)

      Text(message)
        .font(.headline)
        .foregroundColor(.gray)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("BackgroundColor").ignoresSafeArea())
  }
}

// オーバーレイとして使用するための拡張
extension View {
  func loadingOverlay(isLoading: Bool, message: String = "読み込み中...") -> some View {
    ZStack {
      self

      if isLoading {
        Color.black.opacity(0.4)
          .ignoresSafeArea()

        LoadingView(message: message)
          .padding(30)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color("BackgroundColor"))
              .shadow(radius: 10)
          )
      }
    }
  }
}

#Preview {
  LoadingView()
}

#Preview("オーバーレイ") {
  Text("コンテンツ")
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
    .loadingOverlay(isLoading: true)
}
