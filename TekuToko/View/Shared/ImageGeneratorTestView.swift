//
//  ImageGeneratorTestView.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/07/24.
//

import CoreLocation
import SwiftUI

/// 画像生成機能のテスト用ビュー
struct ImageGeneratorTestView: View {
  @StateObject private var viewModel = ImageGeneratorTestViewModel()

  private let testCases = TestWalkFactory.allTestCases

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        HeaderView()

        GeneratedImageView(
          image: viewModel.generatedImage,
          showingPreview: $viewModel.showingImagePreview
        )

        ErrorView(errorMessage: viewModel.errorMessage)

        TestButtonsView(
          testCases: testCases,
          isGenerating: viewModel.isGenerating,
          onGenerate: viewModel.generateImage
        )

        Spacer()
      }
      .navigationTitle("画像生成テスト")
      .navigationBarTitleDisplayMode(.inline)
    }
    .fullScreenCover(isPresented: $viewModel.showingImagePreview) {
      if let image = viewModel.generatedImage {
        ImagePreviewView(image: image, isPresented: $viewModel.showingImagePreview)
      }
    }
  }
}

// MARK: - ViewModel
@MainActor
final class ImageGeneratorTestViewModel: ObservableObject {
  @Published var generatedImage: UIImage?
  @Published var isGenerating = false
  @Published var errorMessage: String?
  @Published var showingImagePreview = false

  private let imageGenerator = WalkImageGenerator.shared

  func generateImage(from walk: Walk) {
    isGenerating = true
    errorMessage = nil

    Task {
      do {
        let image = try await imageGenerator.generateWalkImage(from: walk)
        self.generatedImage = image
        self.isGenerating = false
      } catch {
        self.errorMessage = error.localizedDescription
        self.isGenerating = false
      }
    }
  }
}

// MARK: - View Components
private struct HeaderView: View {
  var body: some View {
    Text("画像生成テスト")
      .font(.largeTitle)
      .fontWeight(.bold)
      .padding()
  }
}

private struct GeneratedImageView: View {
  let image: UIImage?
  @Binding var showingPreview: Bool

  var body: some View {
    if let image = image {
      VStack {
        Text("生成された画像:")
          .font(.headline)

        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxHeight: 200)
          .border(Color.gray, width: 1)
          .onTapGesture {
            showingPreview = true
          }

        Text("タップして拡大表示")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}

private struct ErrorView: View {
  let errorMessage: String?

  var body: some View {
    if let errorMessage = errorMessage {
      Text("エラー: \(errorMessage)")
        .foregroundColor(.red)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
  }
}

private struct TestButtonsView: View {
  let testCases: [TestWalkData]
  let isGenerating: Bool
  let onGenerate: (Walk) -> Void

  var body: some View {
    VStack(spacing: 16) {
      ForEach(testCases, id: \.title) { testCase in
        TestButton(
          testCase: testCase,
          isGenerating: isGenerating,
          onGenerate: onGenerate
        )
      }
    }
    .padding(.horizontal)
  }
}

private struct TestButton: View {
  let testCase: TestWalkData
  let isGenerating: Bool
  let onGenerate: (Walk) -> Void

  var body: some View {
    Button(action: { onGenerate(testCase.walk) }) {
      HStack {
        if isGenerating {
          ProgressView()
            .scaleEffect(0.8)
        }
        Text(testCase.buttonTitle)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(testCase.color)
      .foregroundColor(.white)
      .cornerRadius(10)
    }
    .disabled(isGenerating)
  }
}

// MARK: - Test Data Factory
struct TestWalkData {
  let title: String
  let buttonTitle: String
  let color: Color
  let walk: Walk
}

enum TestWalkFactory {
  static let allTestCases: [TestWalkData] = [
    TestWalkData(
      title: "短距離散歩",
      buttonTitle: "テスト画像1を生成",
      color: .blue,
      walk: createShortWalk()
    ),
    TestWalkData(
      title: "長距離散歩",
      buttonTitle: "テスト画像2を生成（長距離）",
      color: .green,
      walk: createLongWalk()
    ),
    TestWalkData(
      title: "単一点",
      buttonTitle: "テスト画像3を生成（単一点）",
      color: .orange,
      walk: createSinglePointWalk()
    ),
  ]

  /// 短距離散歩データを作成
  static func createShortWalk() -> Walk {
    let startTime = Date().addingTimeInterval(-3600)  // 1時間前
    let endTime = Date().addingTimeInterval(-300)  // 5分前

    // 東京駅周辺の座標
    let baseLocation = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    let locations: [CLLocation] = [
      CLLocation(latitude: baseLocation.latitude, longitude: baseLocation.longitude),
      CLLocation(
        latitude: baseLocation.latitude + 0.001, longitude: baseLocation.longitude + 0.001),
      CLLocation(
        latitude: baseLocation.latitude + 0.002, longitude: baseLocation.longitude + 0.001),
      CLLocation(
        latitude: baseLocation.latitude + 0.002, longitude: baseLocation.longitude + 0.002),
      CLLocation(
        latitude: baseLocation.latitude + 0.001, longitude: baseLocation.longitude + 0.003),
      CLLocation(latitude: baseLocation.latitude, longitude: baseLocation.longitude + 0.003),
    ]

    var walk = Walk(
      title: "東京駅周辺の散歩",
      description: "お昼休みの短い散歩です",
      startTime: startTime,
      endTime: endTime,
      totalSteps: 1250,
      status: .completed
    )

    // 位置情報を追加
    for location in locations {
      walk.addLocation(location)
    }

    return walk
  }

  /// 長距離散歩データを作成
  static func createLongWalk() -> Walk {
    let startTime = Date().addingTimeInterval(-7200)  // 2時間前
    let endTime = Date().addingTimeInterval(-600)  // 10分前

    // 皇居周辺の長距離ルート
    let locations: [CLLocation] = [
      CLLocation(latitude: 35.6812, longitude: 139.7671),  // 東京駅
      CLLocation(latitude: 35.6852, longitude: 139.7565),  // 皇居外苑
      CLLocation(latitude: 35.6896, longitude: 139.7507),  // 皇居東御苑
      CLLocation(latitude: 35.6959, longitude: 139.7539),  // 北の丸公園
      CLLocation(latitude: 35.6936, longitude: 139.7619),  // 千鳥ヶ淵
      CLLocation(latitude: 35.6885, longitude: 139.7677),  // 日比谷公園
      CLLocation(latitude: 35.6794, longitude: 139.7677),  // 有楽町
      CLLocation(latitude: 35.6763, longitude: 139.7648),  // 銀座
      CLLocation(latitude: 35.6812, longitude: 139.7671),  // 東京駅に戻る
    ]

    var walk = Walk(
      title: "皇居ランニングコース",
      description: "皇居周辺の定番ランニングコースです",
      startTime: startTime,
      endTime: endTime,
      totalSteps: 8500,
      status: .completed
    )

    // 位置情報を追加
    for location in locations {
      walk.addLocation(location)
    }

    return walk
  }

  /// 単一点散歩データを作成
  static func createSinglePointWalk() -> Walk {
    let startTime = Date().addingTimeInterval(-1800)  // 30分前
    let endTime = Date().addingTimeInterval(-300)  // 5分前

    // 単一点（渋谷スクランブル交差点）
    let location = CLLocation(latitude: 35.6598, longitude: 139.7006)

    var walk = Walk(
      title: "カフェでのんびり",
      description: "渋谷のカフェで休憩",
      startTime: startTime,
      endTime: endTime,
      totalSteps: 0,
      status: .completed
    )

    walk.addLocation(location)

    return walk
  }
}

/// 画像プレビュー用のフルスクリーンビュー
struct ImagePreviewView: View {
  let image: UIImage
  @Binding var isPresented: Bool
  @State private var scale: CGFloat = 1.0
  @State private var offset: CGSize = .zero

  var body: some View {
    NavigationView {
      GeometryReader { _ in
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(scale)
          .offset(offset)
          .gesture(
            MagnificationGesture()
              .onChanged { value in
                scale = value
              }
              .simultaneously(
                with:
                  DragGesture()
                  .onChanged { value in
                    offset = value.translation
                  }
              )
          )
          .onTapGesture(count: 2) {
            withAnimation {
              scale = scale > 1 ? 1 : 2
              offset = .zero
            }
          }
      }
      .background(Color.black)
      .navigationTitle("画像プレビュー")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("閉じる") {
            isPresented = false
          }
          .foregroundColor(.white)
        }
      }
    }
  }
}

#Preview {
  ImageGeneratorTestView()
}
