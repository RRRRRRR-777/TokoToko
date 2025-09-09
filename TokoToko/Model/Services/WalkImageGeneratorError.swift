//
//  WalkImageGeneratorError.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/08/30.
//

import CoreLocation
import UIKit

/// 画像生成処理中に発生する可能性があるエラー
enum WalkImageGeneratorError: LocalizedError {
  case invalidWalkData
  case mapSnapshotFailed
  case imageCompositionFailed
  case imageTooLarge
  case coordinateCalculationError

  var errorDescription: String? {
    switch self {
    case .invalidWalkData:
      return "散歩データが無効です"
    case .mapSnapshotFailed:
      return "マップスナップショットの生成に失敗しました"
    case .imageCompositionFailed:
      return "画像の合成に失敗しました"
    case .imageTooLarge:
      return "生成された画像のサイズが大きすぎます"
    case .coordinateCalculationError:
      return "座標計算に失敗しました"
    }
  }
}

/// WalkImageGenerator関連の定数定義
enum WalkImageGeneratorConstants {

  /// 生成画像の解像度 (16:9縦長アスペクト比)
  static let imageSize = CGSize(width: 1080, height: 1920)

  /// 背景色 (FCF7EF)
  static let backgroundColor = UIColor(red: 252 / 255, green: 247 / 255, blue: 239 / 255, alpha: 1.0)

  /// 最大ファイルサイズ (1MB)
  static let maxFileSize: Int = 1_000_000

  /// JPEG品質
  static let jpegQuality: CGFloat = 0.8

  /// マップ縮尺調整定数（複数点用）
  static let mapScaleFactor: Double = 9.0

  /// オーバーレイの高さ
  enum OverlayHeight {
    static let top: CGFloat = 200
    static let bottom: CGFloat = 300
  }

  /// パディング
  enum Padding {
    static let standard: CGFloat = 30
    static let small: CGFloat = 20
  }

  /// マップ範囲定数
  enum MapSpan {
    static let singlePoint: Double = 0.0003  // 単一点用（約30-50m）
    static let defaultRegion: Double = 0.01  // デフォルト用
    static let multiPointPadding: Double = 1.3  // 複数点の余白係数
  }

  /// マーカーサイズ
  enum MarkerSize {
    static let radius: CGFloat = 15
    static let innerRadius: CGFloat = 5
  }

  /// フォントサイズ
  enum FontSize {
    static let userName: CGFloat = 32
    static let title: CGFloat = 42
    static let appName: CGFloat = 48
    static let statistics: CGFloat = 38
    static let timestamp: CGFloat = 32
    static let appIcon: CGFloat = 18
  }
}

/// Bundle拡張
extension Bundle {
  var appName: String {
    object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
    object(forInfoDictionaryKey: "CFBundleName") as? String ??
    "TekuToko"
  }
}

/// String拡張
extension String {
  func size(withAttributes attributes: [NSAttributedString.Key: Any]) -> CGSize {
    (self as NSString).size(withAttributes: attributes)
  }
}
