//
//  WalkControlPanel.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/06/03.
//

import CoreMotion
import SwiftUI

/// 散歩の開始・停止・一時停止を制御するコントロールパネル
///
/// `WalkControlPanel`は散歩セッションの制御に必要な全てのボタンとダイアログを提供します。
/// 散歩状態に応じて適切なコントロールを表示し、ユーザーの操作を`WalkManager`に伝達します。
///
/// ## Overview
///
/// - **状態適応表示**: 散歩の状態（未開始、進行中、一時停止、完了）に応じた適切なUI表示
/// - **確認ダイアログ**: 散歩開始時のタイトル入力、終了時の確認ダイアログ
/// - **フローティング対応**: 画面上での固定配置またはインライン配置の選択可能
/// - **アクセシビリティ**: VoiceOverとUIテスト対応のアクセシビリティ識別子
///
/// ## Topics
///
/// ### Properties
/// - ``walkManager``
/// - ``isFloating``
/// - ``showingStartAlert``
/// - ``showingStopAlert``
/// - ``walkTitle``
///
/// ### Initialization
/// - ``init(walkManager:isFloating:)``
struct WalkControlPanel: View {
  /// 散歩データとセッション管理を担当するWalkManager
  ///
  /// 散歩の開始・停止・一時停止の実行、現在の散歩状態の監視を行います。
  /// @ObservedObjectにより状態変更が自動的にUIに反映されます。
  @ObservedObject var walkManager: WalkManager

  /// 散歩開始確認ダイアログの表示状態
  ///
  /// 散歩開始ボタンタップ時に表示されるタイトル入力ダイアログの表示制御に使用されます。
  @State private var showingStartAlert = false

  /// 散歩終了確認ダイアログの表示状態
  ///
  /// 散歩終了ボタンタップ時に表示される確認ダイアログの表示制御に使用されます。
  @State private var showingStopAlert = false

  /// 散歩完了後の共有シート表示状態
  ///
  /// 散歩完了時に表示される共有シートの表示制御に使用されます。
  @State private var showingShareSheet = false

  /// 共有対象の散歩データ
  ///
  /// 共有シート表示時に使用される完了した散歩データを保持します。
  @State private var walkToShare: Walk?

  /// 散歩に設定するタイトル名
  ///
  /// 散歩開始時の確認ダイアログで入力されるタイトル文字列を保持します。
  @State private var walkTitle = ""

  /// フローティング表示モードかどうかのフラグ
  ///
  /// trueの場合は画面右下固定配置、falseの場合は通常のレイアウト内配置となります。
  let isFloating: Bool

  /// WalkControlPanelの初期化メソッド
  ///
  /// 必要なWalkManagerインスタンスと表示モードを設定します。
  ///
  /// - Parameters:
  ///   - walkManager: 散歩管理を行うWalkManagerインスタンス
  ///   - isFloating: フローティング表示の有無（デフォルト: false）
  init(walkManager: WalkManager, isFloating: Bool = false) {
    self.walkManager = walkManager
    self.isFloating = isFloating
  }

  var body: some View {
    Group {
      if isFloating {
        // 右下固定配置用のボタン（円形）
        if walkManager.isWalking {
          // 散歩中の状態に応じてボタンを切り替え
          if walkManager.currentWalk?.status == .paused {
            // 一時停止中：停止ボタン
            Button(action: {
              showingStopAlert = true
            }) {
              Image(systemName: "stop.fill")
                .font(.title)
                .frame(width: 60, height: 60)
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .accessibilityIdentifier("散歩停止")
          } else {
            // 散歩中：一時停止ボタン（長押しで停止）
            Button(action: {
              walkManager.pauseWalk()
            }) {
              Image(systemName: "pause.fill")
                .font(.title)
                .frame(width: 60, height: 60)
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .onLongPressGesture {
              showingStopAlert = true
            }
            .accessibilityIdentifier("散歩一時停止")
          }
        } else {
          startWalkButton(isCircular: true)
        }
      } else {
        // 通常配置用のボタン（横並び）
        HStack(spacing: 16) {
          if walkManager.isWalking {
            // 散歩中のボタン
            Button(action: {
              if walkManager.currentWalk?.status == .paused {
                walkManager.resumeWalk()
              } else {
                walkManager.pauseWalk()
              }
            }) {
              HStack {
                Image(
                  systemName: walkManager.currentWalk?.status == .paused
                    ? "play.fill" : "pause.fill")
                Text(walkManager.currentWalk?.status == .paused ? "再開" : "一時停止")
              }
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.orange)
              .foregroundColor(.white)
              .cornerRadius(12)
            }
            .accessibilityIdentifier(walkManager.currentWalk?.status == .paused ? "散歩再開" : "散歩一時停止")

            Button(action: {
              showingStopAlert = true
            }) {
              HStack {
                Image(systemName: "stop.fill")
                Text("終了")
              }
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.red)
              .foregroundColor(.white)
              .cornerRadius(12)
            }
            .accessibilityIdentifier("散歩終了")
          } else {
            startWalkButton(isCircular: false)
          }
        }
      }
    }
    .alert("散歩を開始", isPresented: $showingStartAlert) {
      TextField("散歩のタイトル（任意）", text: $walkTitle)
      Button("開始") {
        walkManager.startWalk(title: walkTitle)
        walkTitle = ""
      }
      Button("キャンセル", role: .cancel) {
        walkTitle = ""
      }
    } message: {
      Text("散歩を開始しますか？タイトルを入力することもできます。")
    }
    .alert("散歩を終了", isPresented: $showingStopAlert) {
      Button("終了", role: .destructive) {
        if let currentWalk = walkManager.currentWalk {
          walkToShare = currentWalk
        }
        walkManager.stopWalk()

        // 散歩完了後に共有シートを表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          if let walk = walkToShare {
            showingShareSheet = true
          }
        }
      }
      Button("キャンセル", role: .cancel) {}
    } message: {
      Text("散歩を終了しますか？記録が保存されます。")
    }
    .sheet(isPresented: $showingShareSheet) {
      if let walk = walkToShare {
        WalkCompletionView(walk: walk, isPresented: $showingShareSheet)
      }
    }
  }

  // 散歩開始ボタンの共通コンポーネント
  private func startWalkButton(isCircular: Bool) -> some View {
    Button(action: {
      showingStartAlert = true
    }) {
      Image(systemName: "figure.walk")
        .font(.title)
        .frame(width: 60, height: 60)
        .background(
          LinearGradient(
            gradient: Gradient(colors: [
              Color(red: 0 / 255, green: 163 / 255, blue: 129 / 255),
              Color(red: 0 / 255, green: 143 / 255, blue: 109 / 255)
            ]),
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .foregroundColor(.white)
        .clipShape(Circle())
        .shadow(
          color: Color(red: 0 / 255, green: 163 / 255, blue: 129 / 255).opacity(0.4),
          radius: 8, x: 0, y: 4
        )
    }
    .accessibilityIdentifier("新しい散歩を開始")
    .scaleEffect(walkManager.isWalking ? 0.95 : 1.0)
    .animation(.easeInOut(duration: 0.1), value: walkManager.isWalking)
  }
}

/// 散歩の統計情報を表示するビューコンポーネント
///
/// `WalkInfoDisplay`は散歩中の重要な統計データ（時間、歩数、距離）を
/// 見やすい形式で横並びに表示するコンポーネントです。歩数データのソースに応じて
/// 適切なインジケーターと説明を表示します。
///
/// ## Overview
///
/// - **経過時間表示**: 散歩開始からの経過時間をフォーマット済み文字列で表示
/// - **歩数表示**: センサー実測値、計測不可状態を適切に区別して表示
/// - **距離表示**: 移動距離をキロメートル単位で表示
/// - **ソースインジケーター**: 歩数データの計測状態をアイコンで視覚的に表現
///
/// ## Topics
///
/// ### Properties
/// - ``elapsedTime``
/// - ``totalSteps``
/// - ``distance``
/// - ``stepCountSource``
struct WalkInfoDisplay: View {
  /// 散歩開始からの経過時間
  ///
  /// HH:mm形式でフォーマットされた経過時間文字列です。
  let elapsedTime: String

  /// 総歩数
  ///
  /// 散歩中に計測された総歩数です。
  /// 表示目的のみに使用され、実際の値は`stepCountSource`から取得されます。
  let totalSteps: Int

  /// 移動距離
  ///
  /// GPS軌跡から計算された移動距離をキロメートル単位で表示するための文字列です。
  let distance: String

  /// 歩数データのソース情報
  ///
  /// 歩数がセンサー実測値、計測不可のいずれかを示し、
  /// 適切なインジケーターとラベル表示に使用されます。
  let stepCountSource: StepCountSource

  /// 歩数表示の有無に応じた動的スペーシング
  ///
  /// 歩数が表示される場合は40pt、表示されない場合は80ptのスペーシングを返します。
  private var dynamicSpacing: CGFloat {
    if case .coremotion = stepCountSource {
      return 40
    } else {
      return 80
    }
  }

  var body: some View {
    HStack {
      Spacer()

      HStack(spacing: dynamicSpacing) {
        VStack(alignment: .center, spacing: 4) {
          Text("経過時間")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(elapsedTime)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary)
        }

        stepCountSection

        VStack(alignment: .center, spacing: 4) {
          Text("距離")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(distance)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary)
        }
      }

      Spacer()
    }
  }

  // 歩数セクション：StepCountSource.unavailable時は非表示
  @ViewBuilder private var stepCountSection: some View {
    if case .coremotion = stepCountSource {
      VStack(alignment: .center, spacing: 4) {
        HStack(spacing: 4) {
          stepCountLabel
            .font(.caption)
            .foregroundColor(.secondary)
          stepSourceIndicator
        }

        stepCountDisplay
      }
    }
  }

  // 歩数ラベル
  private var stepCountLabel: some View {
    Text(stepCountLabelText)
  }

  // 歩数ラベルテキスト
  private var stepCountLabelText: String {
    switch stepCountSource {
    case .coremotion:
      return "歩数"
    case .unavailable:
      return "歩数"
    }
  }

  // 歩数ソースインジケーター
  private var stepSourceIndicator: some View {
    Group {
      switch stepCountSource {
      case .coremotion:
        Image(systemName: "sensor.tag.radiowaves.forward.fill")
          .font(.caption2)
          .foregroundColor(.green)
          .help("センサー実測値")
      case .unavailable:
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.caption2)
          .foregroundColor(.red)
          .help("歩数計測不可")
      }
    }
  }

  // 歩数表示
  private var stepCountDisplay: some View {
    Group {
      if let steps = stepCountSource.steps {
        Text(String(steps) + "歩")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
      } else {
        Text("計測不可")
          .font(.title3)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
      }
    }
  }
}

#Preview {
  VStack {
    WalkControlPanel(walkManager: WalkManager.shared)
      .padding()

    Divider()

    WalkInfoDisplay(
      elapsedTime: "12:34",
      totalSteps: 1234,
      distance: "1.2 km",
      stepCountSource: .coremotion(steps: 1234)
    )
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .padding()

    WalkInfoDisplay(
      elapsedTime: "05:20",
      totalSteps: 0,
      distance: "0.3 km",
      stepCountSource: .unavailable
    )
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .padding()
  }
}
