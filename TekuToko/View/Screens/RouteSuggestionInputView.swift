import SwiftUI

/// さんぽナビの入力画面
/// ユーザーの気分と散歩の時間/距離を入力するフルスクリーンビュー
struct RouteSuggestionInputView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var moodInput: String = ""
  @State private var selectedOption: WalkOption = .time
  @State private var timeValue: Double = 2.0
  @State private var distanceValue: Double = 8.0
  @State private var selectedDiscoveries: Set<DiscoveryItem> = []
  @State private var isGenerating: Bool = false
  @State private var errorMessage: String?
  @State private var generatedSuggestions: [RouteSuggestion] = []
  @State private var showResultView: Bool = false

  private let maxMoodCharacters = 200

  enum WalkOption: String, CaseIterable {
    case time = "時間"
    case distance = "距離"
  }

  enum DiscoveryItem: String, CaseIterable, Hashable {
    case nature = "🌳 自然"
    case scenery = "📸 景色"
    case gourmet = "🍽️ 食事"
    case season = "🌸 季節"
    case history = "🏛️ 歴史"
  }

  var body: some View {
    ZStack {
      // グラデーション背景
      LinearGradient(
        colors: [
          Color("RouteNavGradientStart"),
          Color("RouteNavGradientEnd")
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        // ヘッダー
        ZStack {
          Text("おさんぽナビ")
            .font(.headline)
            .foregroundColor(.primary)

          HStack {
            Button(action: {
              dismiss()
            }) {
              Image(systemName: "xmark")
                .font(.title3)
                .foregroundColor(.red)
                .padding(8)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
            }
            Spacer()
          }
          .padding(.horizontal)
        }
        .padding(.top, 16)
        .padding(.bottom, 24)

        // メインコンテンツ
        VStack(spacing: 0) {

          Spacer()

          // アイコン画像
          Image("RouteNavIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150)
            .cornerRadius(16)
            .padding(.bottom, 32)

          // 説明文カード
          VStack(spacing: 12) {
            Text("あなたの気分に合わせて")
              .font(.system(size: 18, weight: .medium))

            Text("AIが今日の散歩ルートを提案します")
              .font(.system(size: 18, weight: .medium))
          }
          .multilineTextAlignment(.center)
          .padding(.vertical, 20)
          .padding(.horizontal, 40)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color("BackgroundColor"))
              .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
          )
          .padding(.horizontal, 10)

          Spacer()

          // 発見したいものセクション
          VStack(alignment: .leading, spacing: 12) {
            Text("発見したいもの")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.primary)
              .padding(.horizontal, 20)

            // タグボタン
            HStack(spacing: 8) {
              ForEach(DiscoveryItem.allCases, id: \.self) { item in
                Button(action: {
                  withAnimation(.easeInOut(duration: 0.2)) {
                    if selectedDiscoveries.contains(item) {
                      selectedDiscoveries.remove(item)
                    } else {
                      selectedDiscoveries.insert(item)
                    }
                  }
                }) {
                  Text(item.rawValue)
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(
                      selectedDiscoveries.contains(item)
                        ? Color.blue
                        : Color("BackgroundColor")
                    )
                    .foregroundColor(
                      selectedDiscoveries.contains(item)
                        ? .white
                        : .primary
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.horizontal, 20)
          }
          .padding(.top, 8)
          .padding(.bottom, 16)

          // 時間・距離選択
          VStack(spacing: 0) {
            ForEach(WalkOption.allCases, id: \.self) { option in
              Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                  selectedOption = option
                }
              }) {
                HStack {
                  Text(option.rawValue)
                    .font(.body)
                    .foregroundColor(.primary)

                  Spacer()

                  if selectedOption == option {
                    Image(systemName: "checkmark")
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundColor(.blue)
                  }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color("BackgroundColor").opacity(0.5))
              }
              .buttonStyle(PlainButtonStyle())

              if option != WalkOption.allCases.last {
                Divider()
                  .padding(.leading, 20)
              }
            }
          }
          .background(Color("BackgroundColor"))
          .cornerRadius(12)
          .padding(.horizontal, 20)

          // スライダー
          VStack(spacing: 8) {
            if selectedOption == .time {
              Text("\(formatTime(timeValue))")
                .font(.system(size: 22, weight: .semibold))

              Slider(value: $timeValue, in: 0.5...8.0, step: 0.5)
                .accentColor(.blue)
                .padding(.horizontal, 32)
            } else {
              Text("\(Int(distanceValue))km")
                .font(.system(size: 22, weight: .semibold))

              Slider(value: $distanceValue, in: 1...20, step: 1)
                .accentColor(.blue)
                .padding(.horizontal, 32)
            }
          }
          .padding(.top, 16)
          .padding(.bottom, 16)
        }
        .padding(.top, 8)

        Spacer()

        // 気分入力（任意）
        VStack(spacing: 16) {
          HStack {
            TextField("詳しいきぶん（任意）", text: $moodInput)
              .font(.body)
              .foregroundColor(.primary)
              .padding(.vertical, 14)
              .padding(.leading, 16)
              .onChange(of: moodInput) { newValue in
                if newValue.count > maxMoodCharacters {
                  moodInput = String(newValue.prefix(maxMoodCharacters))
                }
              }

            if !moodInput.isEmpty {
              Button(action: {
                moodInput = ""
              }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.secondary)
                  .padding(.trailing, 16)
              }
            }
          }
          .background(Color("BackgroundColor"))
          .cornerRadius(24)

          // エラーメッセージ
          if let errorMessage = errorMessage {
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(.red)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }

          // きょうのさんぽボタン
          Button(action: {
            submitRouteSuggestion()
          }) {
            HStack(spacing: 8) {
              if isGenerating {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("生成中...")
                  .font(.system(size: 18, weight: .semibold))
              } else {
                Text("おさんぽナビを見る")
                  .font(.system(size: 18, weight: .semibold))
              }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isGenerating ? Color.gray : Color.blue)
            .cornerRadius(12)
          }
          .buttonStyle(PlainButtonStyle())
          .disabled(isGenerating)
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
      }
    }
    .fullScreenCover(isPresented: $showResultView) {
      RouteSuggestionResultView(
        suggestions: generatedSuggestions,
        onClose: {
          showResultView = false
        }
      )
    }
  }

  // MARK: - Private Methods

  /// 時間を「〇時間」または「〇.5時間」形式にフォーマット
  private func formatTime(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0 {
      return "\(Int(value))時間"
    } else {
      return String(format: "%.1f時間", value)
    }
  }

  /// ルート提案を送信
  private func submitRouteSuggestion() {
    #if DEBUG
      print("=== Route Suggestion Submitted ===")
      print("気分: \(moodInput.isEmpty ? "（未入力）" : moodInput)")
      print("選択: \(selectedOption.rawValue)")
      if selectedOption == .time {
        print("時間: \(formatTime(timeValue))")
      } else {
        print("距離: \(Int(distanceValue))km")
      }
      if !selectedDiscoveries.isEmpty {
        let discoveries = selectedDiscoveries.map { $0.rawValue }.joined(separator: ", ")
        print("発見したいもの: \(discoveries)")
      } else {
        print("発見したいもの: （未選択）")
      }
      print("==================================")
    #endif

    // iOS 26.0以降のみ対応
    if #available(iOS 26.0, *) {
      Task {
        await generateRouteSuggestions()
      }
    } else {
      // iOS 26.0未満では未対応メッセージを表示
      errorMessage = "この機能はiOS 26.0以降で利用可能です"
    }
  }

  /// ルート提案を生成する
  @available(iOS 26.0, *)
  private func generateRouteSuggestions() async {
    isGenerating = true
    errorMessage = nil

    // ユーザー入力を構築
    let walkOption: RouteSuggestionUserInput.WalkOption
    if selectedOption == .time {
      walkOption = .time(hours: timeValue)
    } else {
      walkOption = .distance(kilometers: distanceValue)
    }

    let discoveries = selectedDiscoveries.map { item -> String in
      // 絵文字を除去してテキストのみを抽出
      let text = item.rawValue
        .replacingOccurrences(of: "🌳 ", with: "")
        .replacingOccurrences(of: "📸 ", with: "")
        .replacingOccurrences(of: "🍽️ ", with: "")
        .replacingOccurrences(of: "🌸 ", with: "")
        .replacingOccurrences(of: "🏛️ ", with: "")
      return text
    }

    let userInput = RouteSuggestionUserInput(
      mood: moodInput,
      walkOption: walkOption,
      discoveries: discoveries
    )

    do {
      let service = RouteSuggestionService()
      let suggestions = try await service.generateRouteSuggestions(userInput: userInput)

      #if DEBUG
        print("=== Route Suggestions Generated ===")
        for (index, suggestion) in suggestions.enumerated() {
          print("[\(index + 1)] \(suggestion.title)")
          print("    説明: \(suggestion.description)")
          print("    距離: \(suggestion.estimatedDistance)km")
          print("    時間: \(suggestion.estimatedDuration)時間")
          print("    理由: \(suggestion.recommendationReason)")
        }
        print("===================================")
      #endif

      guard !suggestions.isEmpty else {
        errorMessage = "ルート提案の生成に失敗しました: 候補が見つかりませんでした"
        isGenerating = false
        return
      }

      withAnimation(.easeInOut(duration: 0.2)) {
        generatedSuggestions = suggestions
        isGenerating = false
        showResultView = true
      }
    } catch {
#if DEBUG
        print("=== Route Suggestion Error ===")
        print("エラー: \(error.localizedDescription)")
        print("==============================")
      #endif

      errorMessage = "ルート提案の生成に失敗しました: \(error.localizedDescription)"
      isGenerating = false
    }
  }
}

// MARK: - Preview

#Preview {
  RouteSuggestionInputView()
}
