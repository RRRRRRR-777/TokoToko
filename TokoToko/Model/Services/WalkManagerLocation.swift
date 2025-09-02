//
//  WalkManagerLocation.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/08/30.
//

import CoreLocation
import Foundation

// MARK: - LocationUpdateDelegate

/// LocationManagerからの位置情報更新を処理する拡張
extension WalkManager: LocationUpdateDelegate {
  /// 位置情報が更新された時に呼び出されます
  ///
  /// 位置情報の更新は`$currentLocation`のCombine監視で処理されるため、
  /// このメソッドでは直接的な処理は行いません。
  ///
  /// - Parameter location: 更新されたGPS位置情報
  func didUpdateLocation(_ location: CLLocation) {
    // 位置情報の更新は$currentLocationの監視で処理
  }

  /// 位置情報の取得エラーが発生した時に呼び出されます
  ///
  /// GPSシグナルの取得失敗、権限エラーなどの位置情報関連エラーをログ出力します。
  ///
  /// - Parameter error: 発生したエラー
  func didFailWithError(_ error: Error) {
    logger.logError(
      error,
      operation: "location_update",
      humanNote: "位置情報の取得に失敗しました"
    )
  }
}

// MARK: - StepCountDelegate

/// StepCountManagerからの歩数更新を処理する拡張
extension WalkManager {
  /// 歩数カウントが更新された時に呼び出されます
  ///
  /// CoreMotionからの実際の歩数を受け取り、UI更新のためにメインスレッドで
  /// `currentStepCount`を更新します。散歩記録中の場合は、現在のWalkオブジェクトの
  /// 歩数も同期的に更新します。
  ///
  /// - Parameter stepCount: 更新された歩数データ
  func stepCountDidUpdate(_ stepCount: StepCountSource) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }

      self.currentStepCount = stepCount

      // 散歩中の場合、現在のWalkにも歩数を更新
      if var walk = self.currentWalk, self.isRecording {
        walk.totalSteps = stepCount.steps ?? 0
        self.currentWalk = walk
      }

      #if DEBUG
        if let steps = stepCount.steps {
          print("📊 歩数更新: \(steps)歩 (\(stepCount.isRealTime ? "実測" : "推定"))")
        }
      #endif
    }
  }

  /// 歩数計測エラーが発生した時に呼び出されます
  ///
  /// CoreMotionセンサーのエラーや権限問題を処理し、
  /// 歩数を利用不可状態に設定します。
  ///
  /// - Parameter error: 発生したエラー
  func stepCountDidFailWithError(_ error: Error) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      self.currentStepCount = .unavailable

      self.logger.logError(
        error,
        operation: "step_count_update",
        humanNote: "歩数計測でエラーが発生しました"
      )

      #if DEBUG
        print("❌ 歩数計測エラー: \(error.localizedDescription)")
      #endif
    }
  }
}

// MARK: - Computed Properties

extension WalkManager {
  /// 現在の総歩数
  ///
  /// 散歩中の場合は現在のWalkの歩数、それ以外の場合は0を返します。
  ///
  /// - Returns: 総歩数
  var totalSteps: Int {
    currentWalk?.totalSteps ?? 0
  }

  /// 経過時間の文字列表現
  ///
  /// 時間:分:秒の形式で表現されます（例: "1:23:45"）。
  /// 1時間未満の場合は分:秒形式になります（例: "23:45"）。
  ///
  /// - Returns: フォーマットされた時間文字列
  var elapsedTimeString: String {
    let hours = Int(elapsedTime) / 3600
    let minutes = Int(elapsedTime) % 3600 / 60
    let seconds = Int(elapsedTime) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }

  /// 距離の文字列表現
  ///
  /// キロメートルまたはメートル単位で適切にフォーマットされます。
  /// 1km以上の場合は小数点1桁まで表示し、1km未満の場合はメートル単位で表示します。
  ///
  /// - Returns: フォーマットされた距離文字列
  var distanceString: String {
    if distance >= 1000 {
      return String(format: "%.1f km", distance / 1000)
    } else {
      return String(format: "%.0f m", distance)
    }
  }
}
