//
//  StatsBarView.swift
//  TekuToko
//
//  Created by Claude Code on 2025/07/12.
//

import SwiftUI

struct StatsBarView: View {
  let walk: Walk
  @Binding var isExpanded: Bool
  let onToggle: () -> Void
  let onWalkDeleted: ((UUID) -> Void)?
  @State private var showingDeleteAlert = false
  @State private var showingErrorAlert = false
  @State private var errorMessage = ""
  @Environment(\.presentationMode)
  var presentationMode

  var body: some View {
    VStack {
      if isExpanded {
        expandedView
      } else {
        collapsedView
      }
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
  }

  private var expandedView: some View {
    VStack(spacing: 16) {
      statsSection
      actionButtonsSection
    }
    .padding(.all, 16)
    .frame(width: 90)
    .background(Color("BackgroundColor").opacity(0.95))
    .foregroundColor(.black)
    .cornerRadius(20)
    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    .onTapGesture {
      onToggle()
    }
    .alert("散歩を削除", isPresented: $showingDeleteAlert) {
      Button("削除", role: .destructive) {
        deleteWalk()
      }
      Button("キャンセル", role: .cancel) {}
    } message: {
      Text("この散歩記録を削除しますか？この操作は取り消せません。")
    }
    .alert("削除エラー", isPresented: $showingErrorAlert) {
      Button("OK") {}
    } message: {
      Text(errorMessage)
    }
  }

  private var statsSection: some View {
    VStack(spacing: 20) {
      distanceStatView
      durationStatView
      stepsStatView
    }
  }

  private var distanceStatView: some View {
    VStack(alignment: .center, spacing: 4) {
      Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
        .font(.title2)
      Text(walk.distanceString)
        .font(.system(size: 12))
        .fontWeight(.semibold)
    }
  }

  private var durationStatView: some View {
    VStack(alignment: .center, spacing: 4) {
      Image(systemName: "clock")
        .font(.title2)
      Text(walk.durationString)
        .font(.system(size: 12))
        .fontWeight(.semibold)
    }
  }

  private var stepsStatView: some View {
    VStack(alignment: .center, spacing: 4) {
      Image(systemName: "figure.walk")
        .font(.title2)
      Text(walk.totalSteps == 0 ? "-" : "\(walk.totalSteps)歩")
        .font(.system(size: 12))
        .fontWeight(.semibold)
    }
  }

  private var actionButtonsSection: some View {
    HStack {
      NavigationLink(
        destination:
          WalkListView()
          .navigationBarBackButtonHidden(false)
      ) {
        Image(systemName: "arrow.left.arrow.right")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.black)
          .shadow(color: .black.opacity(0.1), radius: 0.5, x: 4, y: 4)
      }
      .accessibilityIdentifier("散歩履歴一覧を表示")
      Button(action: { showingDeleteAlert = true }) {
        Image(systemName: "ellipsis")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.black)
          .shadow(color: .black.opacity(0.1), radius: 0.5, x: 4, y: 4)
      }
      .accessibilityIdentifier("散歩削除メニュー")
    }
  }

  private var collapsedView: some View {
    Button(action: onToggle) {
      Image(systemName: "info.circle.fill")
        .font(.title)
        .foregroundColor(.white)
        .background(Color.black)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
    .accessibilityLabel("統計情報を表示")
  }

  private func deleteWalk() {
    performWalkDeletion()
  }

  private func performWalkDeletion() {
    let walkRepository = WalkRepository.shared
    walkRepository.deleteWalk(withID: walk.id) { result in
      DispatchQueue.main.async {
        handleDeletionResult(result)
      }
    }
  }

  private func handleDeletionResult(_ result: Result<Bool, WalkRepositoryError>) {
    switch result {
    case .success:
      handleDeletionSuccess()
    case .failure(let error):
      handleDeletionFailure(error)
    }
  }

  private func handleDeletionSuccess() {
    onWalkDeleted?(walk.id)
    dismissView()
  }

  private func handleDeletionFailure(_ error: WalkRepositoryError) {
    errorMessage = localizedErrorMessage(for: error)
    showingErrorAlert = true
  }

  private func dismissView() {
    presentationMode.wrappedValue.dismiss()
  }

  private func localizedErrorMessage(for error: WalkRepositoryError) -> String {
    switch error {
    case .authenticationRequired:
      return "ログインが必要です"
    case .notFound:
      return "散歩記録が見つかりません"
    case .firestoreError(let underlyingError):
      return "削除に失敗しました: \(underlyingError.localizedDescription)"
    case .networkError:
      return "ネットワークエラーが発生しました"
    case .invalidData:
      return "データが破損しています"
    case .storageError(let underlyingError):
      return "ストレージエラーが発生しました: \(underlyingError.localizedDescription)"
    }
  }
}

#Preview {
  @State var isExpanded = true

  return StatsBarView(
    walk: Walk(
      title: "サンプル散歩",
      description: "テスト用",
      startTime: Date().addingTimeInterval(-3600),
      endTime: Date().addingTimeInterval(-3000),
      totalDistance: 1500,
      totalSteps: 2000,
      status: .completed
    ),
    isExpanded: $isExpanded,
    onToggle: { isExpanded.toggle() },
    onWalkDeleted: { walkId in
      print("Preview: 散歩削除 - \(walkId)")
    }
  )
  .padding()
}
