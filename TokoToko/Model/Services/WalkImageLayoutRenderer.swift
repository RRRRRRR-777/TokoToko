//
//  WalkImageLayoutRenderer.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/08/30.
//

import CoreLocation
import UIKit
import FirebaseAuth

/// 散歩画像のレイアウトとオーバーレイ描画を担当するクラス
enum WalkImageLayoutRenderer {

  /// マップ画像と散歩データを合成して最終画像を作成します
  ///
  /// - Parameters:
  ///   - mapImage: マップスナップショット画像
  ///   - walk: 散歩データ
  ///   - size: 最終画像のサイズ
  /// - Returns: 合成された最終画像
  /// - Throws: WalkImageGeneratorError
  static func createImageLayout(
    mapImage: UIImage,
    walk: Walk,
    size: CGSize
  ) async throws -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    format.opaque = true

    let renderer = UIGraphicsImageRenderer(size: size, format: format)

    let image = renderer.image { context in
      let cgContext = context.cgContext

      cgContext.setFillColor(WalkImageGeneratorConstants.backgroundColor.cgColor)
      cgContext.fill(CGRect(origin: .zero, size: size))

      let mapRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
      mapImage.draw(in: mapRect)

      drawTopOverlay(
        in: CGRect(
          x: 0,
          y: 0,
          width: size.width,
          height: WalkImageGeneratorConstants.OverlayHeight.top
        ),
        walk: walk,
        context: cgContext
      )

      drawBottomOverlay(
        in: CGRect(
          x: 0,
          y: size.height - WalkImageGeneratorConstants.OverlayHeight.bottom,
          width: size.width,
          height: WalkImageGeneratorConstants.OverlayHeight.bottom
        ),
        walk: walk,
        context: cgContext
      )
    }

    return image
  }

  /// 上部オーバーレイ（ユーザー情報とタイトル）を描画
  ///
  /// - Parameters:
  ///   - rect: 描画領域
  ///   - walk: 散歩データ
  ///   - context: 描画コンテキスト
  private static func drawTopOverlay(
    in rect: CGRect,
    walk: Walk,
    context: CGContext
  ) {
    drawSemiTransparentBackground(in: rect, context: context)

    let iconSize: CGFloat = 80
    let iconRect = CGRect(
      x: rect.minX + WalkImageGeneratorConstants.Padding.standard,
      y: rect.minY + WalkImageGeneratorConstants.Padding.standard,
      width: iconSize,
      height: iconSize
    )

    let currentUser = Auth.auth().currentUser
    let userName = currentUser?.displayName ?? "ユーザー"

    if let photoURL = currentUser?.photoURL,
       let imageData = try? Data(contentsOf: photoURL),
       let profileImage = UIImage(data: imageData) {

      let renderer = UIGraphicsImageRenderer(size: iconRect.size)
      let circularImage = renderer.image { _ in
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: iconRect.size))
        path.addClip()
        profileImage.draw(in: CGRect(origin: .zero, size: iconRect.size))
      }
      circularImage.draw(in: iconRect)

      context.setStrokeColor(UIColor.systemGray4.cgColor)
      context.setLineWidth(2.0)
      context.strokeEllipse(in: iconRect)
    } else {
      context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
      context.fillEllipse(in: iconRect)
      context.setStrokeColor(UIColor.systemGray4.cgColor)
      context.setLineWidth(2.0)
      context.strokeEllipse(in: iconRect)
    }

    let userNameFont = UIFont.systemFont(
      ofSize: WalkImageGeneratorConstants.FontSize.userName,
      weight: .medium
    )
    drawTextWithShadow(
      userName,
      font: userNameFont,
      color: .black,
      at: CGPoint(x: iconRect.minX, y: iconRect.maxY + 24),
      context: context
    )

    let titleFont = UIFont.systemFont(
      ofSize: WalkImageGeneratorConstants.FontSize.title,
      weight: .bold
    )
    let titleSize = walk.title.size(withAttributes: [.font: titleFont])

    drawTextWithShadow(
      walk.title,
      font: titleFont,
      color: .black,
      at: CGPoint(
        x: rect.maxX - titleSize.width - WalkImageGeneratorConstants.Padding.standard,
        y: rect.midY - 25
      ),
      context: context
    )
  }

  /// 下部オーバーレイ（アプリ情報と統計情報）を描画
  ///
  /// - Parameters:
  ///   - rect: 描画領域
  ///   - walk: 散歩データ
  ///   - context: 描画コンテキスト
  private static func drawBottomOverlay(
    in rect: CGRect,
    walk: Walk,
    context: CGContext
  ) {
    let padding: CGFloat = 30

    drawSemiTransparentBackground(in: rect, context: context)

    let appAreaHeight: CGFloat = 100
    let appRect = CGRect(
      x: rect.minX,
      y: rect.minY + 20,
      width: rect.width,
      height: appAreaHeight
    )
    drawAppInfo(in: appRect, context: context)

    let statsAreaHeight: CGFloat = 120
    let statsRect = CGRect(
      x: rect.minX,
      y: rect.minY + appAreaHeight + 30,
      width: rect.width,
      height: statsAreaHeight
    )
    drawStatisticsInfo(in: statsRect, walk: walk, context: context)

    if let startTime = walk.startTime {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy/MM/dd HH:mm"
      let timeString = formatter.string(from: startTime)

      let timeFont = UIFont.systemFont(ofSize: 32, weight: .regular)
      let timeSize = timeString.size(withAttributes: [.font: timeFont])

      drawTextWithShadow(
        timeString,
        font: timeFont,
        color: .black,
        at: CGPoint(
          x: rect.maxX - timeSize.width - padding,
          y: rect.maxY - 40
        ),
        context: context
      )
    }
  }

  /// 半透明背景を描画
  private static func drawSemiTransparentBackground(
    in rect: CGRect,
    context: CGContext
  ) {
    let backgroundColor = UIColor(
      red: 252 / 255,
      green: 247 / 255,
      blue: 239 / 255,
      alpha: 0.9
    )
    context.setFillColor(backgroundColor.cgColor)
    context.fill(rect)
  }

  /// アプリ情報（アイコンとアプリ名）を中央に描画
  private static func drawAppInfo(in rect: CGRect, context: CGContext) {
    let iconSize: CGFloat = 120
    let totalWidth: CGFloat = iconSize + 20 + 350
    let startX = rect.midX - totalWidth / 2

    let iconRect = CGRect(
      x: startX,
      y: rect.midY - iconSize / 2,
      width: iconSize,
      height: iconSize
    )

    if let iconName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
       let primaryIcon = iconName["CFBundlePrimaryIcon"] as? [String: Any],
       let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
       let iconFileName = iconFiles.first,
       let appIcon = UIImage(named: iconFileName) {
      let renderer = UIGraphicsImageRenderer(size: iconRect.size)
      let roundedIcon = renderer.image { _ in
        let path = UIBezierPath(
          roundedRect: CGRect(origin: .zero, size: iconRect.size),
          cornerRadius: iconSize * 0.2
        )
        path.addClip()
        appIcon.draw(in: CGRect(origin: .zero, size: iconRect.size))
      }
      roundedIcon.draw(in: iconRect)
    }

    let appName = "とことこ-お散歩SNS"
    drawTextWithShadow(
      appName,
      font: UIFont.systemFont(ofSize: 48, weight: .bold),
      color: .black,
      at: CGPoint(x: iconRect.maxX + 20, y: iconRect.midY - 30),
      context: context
    )
  }

  /// 統計情報（距離、時間、歩数）を横並びで描画
  private static func drawStatisticsInfo(
    in rect: CGRect,
    walk: Walk,
    context: CGContext
  ) {
    let columnWidth = rect.width / 3
    let iconSize: CGFloat = 48

    drawStatisticWithIconAndShadow(
      value: walk.distanceString,
      systemIconName: "point.topleft.down.curvedto.point.bottomright.up",
      at: CGPoint(x: rect.minX + columnWidth * 0.5, y: rect.midY - 10),
      iconSize: iconSize,
      context: context
    )

    drawStatisticWithIconAndShadow(
      value: walk.durationString,
      systemIconName: "clock",
      at: CGPoint(x: rect.minX + columnWidth * 1.5, y: rect.midY - 10),
      iconSize: iconSize,
      context: context
    )

    drawStatisticWithIconAndShadow(
      value: formatStepsForDisplay(walk.totalSteps),
      systemIconName: "figure.walk",
      at: CGPoint(x: rect.minX + columnWidth * 2.5, y: rect.midY - 10),
      iconSize: iconSize,
      context: context
    )
  }

  /// シンプルなテキストを描画
  private static func drawTextWithShadow(
    _ text: String,
    font: UIFont,
    color: UIColor,
    at point: CGPoint,
    context: CGContext
  ) {
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color
    ]

    text.draw(at: point, withAttributes: attributes)
  }

  /// アイコン付き統計情報を描画
  private static func drawStatisticWithIconAndShadow(
    value: String,
    systemIconName: String,
    at center: CGPoint,
    iconSize: CGFloat,
    context: CGContext
  ) {
    let valueFont = UIFont.systemFont(ofSize: 38, weight: .bold)
    let valueSize = value.size(withAttributes: [.font: valueFont])

    drawSystemIconWithoutShadow(
      systemIconName,
      at: CGPoint(x: center.x, y: center.y - 30),
      size: iconSize,
      context: context
    )

    drawTextWithShadow(
      value,
      font: valueFont,
      color: .black,
      at: CGPoint(x: center.x - valueSize.width / 2, y: center.y + 15),
      context: context
    )
  }

  /// シンプルなシステムアイコンを描画
  private static func drawSystemIconWithoutShadow(
    _ systemName: String,
    at center: CGPoint,
    size: CGFloat,
    context: CGContext
  ) {
    let config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
    if let icon = UIImage(systemName: systemName, withConfiguration: config) {
      let iconSize = CGSize(width: size, height: size)
      let iconRect = CGRect(
        x: center.x - iconSize.width / 2,
        y: center.y - iconSize.height / 2,
        width: iconSize.width,
        height: iconSize.height
      )

      icon.withTintColor(.black).draw(in: iconRect)
    }
  }

  /// 歩数を表示用フォーマットに変換
  ///
  /// - Parameter totalSteps: 総歩数
  /// - Returns: フォーマットされた歩数文字列
  private static func formatStepsForDisplay(_ totalSteps: Int) -> String {
    guard totalSteps > 0 else {
      return "-"
    }
    return "\(totalSteps)歩"
  }
}
