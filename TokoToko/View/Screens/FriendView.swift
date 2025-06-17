//
//  FriendView.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/16.
//

import SwiftUI

struct FriendView: View {
    var body: some View {
        VStack {
            Text("フレンド")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            Text("友達機能は近日公開予定です")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("フレンド")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        FriendView()
    }
}