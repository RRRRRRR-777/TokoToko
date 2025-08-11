//
//  ImagePopupView.swift
//  TokoToko
//
//  Created by Claude Code on 2025/07/12.
//

import SwiftUI

struct ImagePopupView: View {
  let imageURL: String
  let onClose: () -> Void

  @State private var scale: CGFloat = 0.8
  @State private var opacity: Double = 0

  var body: some View {
    ZStack {
      // 背景オーバーレイ
      Color.black.opacity(0.8)
        .ignoresSafeArea()
        .onTapGesture {
          dismissWithAnimation()
        }

      VStack {
        HStack {
          Spacer()
          Button {
            dismissWithAnimation()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.title)
              .foregroundColor(.white)
              .background(Color.black.opacity(0.5))
              .clipShape(Circle())
          }
          .padding()
        }

        Spacer()

        // メイン画像
        AsyncImage(url: URL(string: imageURL)) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(12)
            .shadow(radius: 10)
            .padding(.horizontal, 15)
        }
        placeholder: {
          ProgressView()
            .frame(width: 200, height: 200)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(12)
        }
        .scaleEffect(scale)

        Spacer()
      }
    }
    .opacity(opacity)
    .onAppear {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        scale = 1.0
        opacity = 1.0
      }
    }
  }

  private func dismissWithAnimation() {
    withAnimation(.easeOut(duration: 0.2)) {
      scale = 0.8
      opacity = 0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      onClose()
    }
  }
}

#Preview {
  ImagePopupView(
    imageURL: "https://picsum.photos/600/400",
    onClose: {
      print("Popup closed")
    }
  )
}
