//
//  WalkImageGeneratorCore.swift
//  TekuToko
//
//  Created by bokuyamada on 2025/08/30.
//

import CoreLocation
import FirebaseAuth
import MapKit
import SwiftUI
import UIKit

/// 散歩記録を画像として生成するサービスクラス
///
/// `WalkImageGenerator`は散歩データから16:9比率の共有用画像を生成します。
/// マップスナップショット、統計情報、ユーザー情報を組み合わせた
/// 高品質な画像を作成し、SNS共有などに使用できます。
///
/// ## Overview
///
/// - **画像仕様**: 1920x1080px (16:9アスペクト比)
/// - **レイアウト**: 上部60%マップ、下部40%情報エリア
/// - **背景色**: #FCF7EF
/// - **生成時間**: 3秒以内を目標
/// - **ファイルサイズ**: 1MB以下
///
/// ## Topics
///
/// ### 画像生成
/// - ``generateWalkImage(from:)``
/// - ``generateMapSnapshot(from:size:)``
/// - ``createImageLayout(mapImage:walk:size:)``
///
/// ### エラーハンドリング
/// - ``WalkImageGeneratorError``
class WalkImageGenerator {

  static let shared = WalkImageGenerator()

  /// マップエリアのサイズ (全画面表示)
  private var mapAreaSize: CGSize {
    WalkImageGeneratorConstants.imageSize
  }

  init() {}

  /// 散歩データから共有用画像を生成します
  ///
  /// - Parameters:
  ///   - walk: 画像生成対象の散歩データ
  /// - Returns: 生成された画像のUIImage
  /// - Throws: WalkImageGeneratorError
  func generateWalkImage(from walk: Walk) async throws -> UIImage {
    guard !walk.locations.isEmpty else {
      throw WalkImageGeneratorError.invalidWalkData
    }

    do {
      let mapImage = try await WalkMapSnapshotGenerator.generateMapSnapshot(
        from: walk,
        size: mapAreaSize
      )

      let layoutImage = try await WalkImageLayoutRenderer.createImageLayout(
        mapImage: mapImage,
        walk: walk,
        size: WalkImageGeneratorConstants.imageSize
      )

      let compressedImage = try compressImageToTargetSize(layoutImage)

      return compressedImage

    } catch let error as WalkImageGeneratorError {
      throw error
    } catch {
      print("画像生成エラー: \(error)")
      throw WalkImageGeneratorError.imageCompositionFailed
    }
  }

  /// 画像をJPEG圧縮してファイルサイズを最適化します
  ///
  /// - Parameter image: 圧縮対象の画像
  /// - Returns: 圧縮された画像
  /// - Throws: WalkImageGeneratorError
  private func compressImageToTargetSize(_ image: UIImage) throws -> UIImage {
    var quality = WalkImageGeneratorConstants.jpegQuality
    var imageData = image.jpegData(compressionQuality: quality)

    while let data = imageData,
      data.count > WalkImageGeneratorConstants.maxFileSize && quality > 0.1
    {
      quality -= 0.1
      imageData = image.jpegData(compressionQuality: quality)
    }

    guard let finalData = imageData,
      finalData.count <= WalkImageGeneratorConstants.maxFileSize,
      let compressedImage = UIImage(data: finalData)
    else {
      throw WalkImageGeneratorError.imageTooLarge
    }

    return compressedImage
  }
}
