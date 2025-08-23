//
//  WalkImageGenerator.swift
//  TokoToko
//
//  Created by bokuyamada on 2025/07/24.
//

import CoreLocation
import MapKit
import SwiftUI
import UIKit
import FirebaseAuth

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

    /// 画像生成処理中に発生する可能性があるエラー
    enum WalkImageGeneratorError: LocalizedError {
        case invalidWalkData
        case mapSnapshotFailed
        case imageCompositionFailed
        case imageTooLarge

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
            }
        }
    }

    static let shared = WalkImageGenerator()

    // MARK: - 画像仕様定数

    /// 生成画像の解像度 (16:9縦長アスペクト比)
    private let imageSize = CGSize(width: 1080, height: 1920)

    /// マップエリアのサイズ (全画面表示)
    private var mapAreaSize: CGSize {
        imageSize
    }

    /// 背景色 (FCF7EF)
    private let backgroundColor = UIColor(red: 252 / 255, green: 247 / 255, blue: 239 / 255, alpha: 1.0)

    /// 最大ファイルサイズ (1MB)
    private let maxFileSize: Int = 1_000_000

    /// JPEG品質
    private let jpegQuality: CGFloat = 0.8

    /// マップ縮尺調整定数（複数点用）
    private let mapScaleFactor: Double = 9.0

    // MARK: - レイアウト定数

    /// オーバーレイの高さ
    private enum OverlayHeight {
        static let top: CGFloat = 200
        static let bottom: CGFloat = 300
    }

    /// パディング
    private enum Padding {
        static let standard: CGFloat = 30
        static let small: CGFloat = 20
    }

    /// マップ範囲定数
    private enum MapSpan {
        static let singlePoint: Double = 0.0003  // 単一点用（約30-50m）
        static let defaultRegion: Double = 0.01  // デフォルト用
        static let multiPointPadding: Double = 1.3  // 複数点の余白係数
    }

    /// マーカーサイズ
    private enum MarkerSize {
        static let radius: CGFloat = 15
        static let innerRadius: CGFloat = 5
    }

    /// フォントサイズ
    private enum FontSize {
        static let userName: CGFloat = 32
        static let title: CGFloat = 42
        static let appName: CGFloat = 48
        static let statistics: CGFloat = 38
        static let timestamp: CGFloat = 32
        static let appIcon: CGFloat = 18
    }

    init() {}

    /// 散歩データから共有用画像を生成します
    ///
    /// - Parameters:
    ///   - walk: 画像生成対象の散歩データ
    /// - Returns: 生成された画像のUIImage
    /// - Throws: WalkImageGeneratorError
    func generateWalkImage(from walk: Walk) async throws -> UIImage {
        // 散歩データの検証
        guard walk.hasLocation,
              let startTime = walk.startTime else {
            throw WalkImageGeneratorError.invalidWalkData
        }

        // マップスナップショットの生成
        let mapImage = try await generateMapSnapshot(from: walk, size: mapAreaSize)

        // 画像レイアウト合成
        let finalImage = try await createImageLayout(mapImage: mapImage, walk: walk, size: imageSize)

        // JPEG圧縮でファイルサイズを最適化
        let optimizedImage = try compressImageToTargetSize(finalImage)

        return optimizedImage
    }

    /// 散歩ルートのマップスナップショットを生成します
    ///
    /// - Parameters:
    ///   - walk: スナップショット対象の散歩データ
    ///   - size: スナップショットのサイズ
    /// - Returns: 生成されたマップ画像
    /// - Throws: WalkImageGeneratorError
    private func generateMapSnapshot(from walk: Walk, size: CGSize) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            // MKMapSnapshotterのオプション設定
            let options = MKMapSnapshotter.Options()
            options.size = size

            // 散歩ルートが画面に収まるようにリージョンを計算
            let region = calculateRegion(for: walk.locations)
            options.region = region

            // 北向き固定
            options.camera = MKMapCamera()
            options.camera.heading = 0
            options.camera.centerCoordinate = region.center
            options.camera.altitude = altitudeForRegion(region)

            // スナップショッター作成・実行
            let snapshotter = MKMapSnapshotter(options: options)

            snapshotter.start { snapshot, error in
                if let error = error {
                    print("マップスナップショット生成エラー: \(error)")
                    continuation.resume(throwing: WalkImageGeneratorError.mapSnapshotFailed)
                    return
                }

                guard let snapshot = snapshot else {
                    continuation.resume(throwing: WalkImageGeneratorError.mapSnapshotFailed)
                    return
                }

                // ポリラインを描画したスナップショット画像を作成
                let finalMapImage = self.drawPolylineOnSnapshot(snapshot: snapshot, locations: walk.locations)
                continuation.resume(returning: finalMapImage)
            }
        }
    }

    /// スナップショットにポリラインを描画します
    ///
    /// - Parameters:
    ///   - snapshot: ベースとなるマップスナップショット
    ///   - locations: 散歩の位置情報配列
    /// - Returns: ポリライン描画済みの画像
    private func drawPolylineOnSnapshot(snapshot: MKMapSnapshotter.Snapshot, locations: [CLLocation]) -> UIImage {
        let image = snapshot.image

        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        image.draw(at: CGPoint.zero)

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return image
        }

        if locations.count == 1 {
            // 単一点の場合はマーカーを描画
            drawSinglePointMarker(context: context, snapshot: snapshot, location: locations[0])
        } else if locations.count >= 2 {
            // 複数点の場合はポリラインを描画
            drawPolyline(context: context, snapshot: snapshot, locations: locations)
        }

        let resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        return resultImage
    }

    /// 単一点のマーカーを描画
    private func drawSinglePointMarker(context: CGContext, snapshot: MKMapSnapshotter.Snapshot, location: CLLocation) {
        let point = snapshot.point(for: location.coordinate)
        let markerRadius = MarkerSize.radius
        let innerRadius = MarkerSize.innerRadius

        // 外側の青い円
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fillEllipse(in: CGRect(
            x: point.x - markerRadius,
            y: point.y - markerRadius,
            width: markerRadius * 2,
            height: markerRadius * 2
        ))

        // 内側の白い円
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(
            x: point.x - innerRadius,
            y: point.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))
    }

    /// ポリラインを描画
    private func drawPolyline(context: CGContext, snapshot: MKMapSnapshotter.Snapshot, locations: [CLLocation]) {
        // ポリライン描画設定
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(8.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        // 最初の点に移動
        let firstPoint = snapshot.point(for: locations[0].coordinate)
        context.move(to: firstPoint)

        // 残りの点を線で結ぶ
        for i in 1..<locations.count {
            let point = snapshot.point(for: locations[i].coordinate)
            context.addLine(to: point)
        }

        context.strokePath()
    }

    /// 散歩ルートに適したマップリージョンを計算します
    ///
    /// - Parameter locations: 散歩の位置情報配列
    /// - Returns: 計算されたマップリージョン
    private func calculateRegion(for locations: [CLLocation]) -> MKCoordinateRegion {
        guard !locations.isEmpty else {
            // デフォルトリージョン（東京駅）
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                span: MKCoordinateSpan(latitudeDelta: MapSpan.defaultRegion, longitudeDelta: MapSpan.defaultRegion)
            )
        }

        if locations.count == 1 {
            // 単一点の場合
            return MKCoordinateRegion(
                center: locations[0].coordinate,
                span: MKCoordinateSpan(latitudeDelta: MapSpan.singlePoint, longitudeDelta: MapSpan.singlePoint)
            )
        }

        // 複数点の場合、境界を計算
        let coordinates = locations.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * MapSpan.multiPointPadding / mapScaleFactor,
            longitudeDelta: (maxLon - minLon) * MapSpan.multiPointPadding / mapScaleFactor
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    /// リージョンに適したカメラ高度を計算します
    ///
    /// - Parameter region: マップリージョン
    /// - Returns: カメラ高度（メートル）
    private func altitudeForRegion(_ region: MKCoordinateRegion) -> CLLocationDistance {
        let latitudeDelta = region.span.latitudeDelta
        let baseAltitude: CLLocationDistance = 50000 // 基準高度
        return baseAltitude * latitudeDelta / 0.01 // デルタに比例
    }

    /// マップ画像と散歩データを合成して最終画像を作成します
    ///
    /// - Parameters:
    ///   - mapImage: マップスナップショット画像
    ///   - walk: 散歩データ
    ///   - size: 最終画像のサイズ
    /// - Returns: 合成された最終画像
    /// - Throws: WalkImageGeneratorError
    private func createImageLayout(mapImage: UIImage, walk: Walk, size: CGSize) async throws -> UIImage {
        // メモリ効率化のため、UIGraphicsImageRendererのフォーマットを最適化
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // デバイススケールを1.0に固定してメモリ使用量を削減
        format.opaque = true // 不透明画像として処理してメモリ効率化

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let image = renderer.image { context in
            let cgContext = context.cgContext

            // 背景色で塗りつぶし
            cgContext.setFillColor(backgroundColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))

            // マップ画像を全画面に描画
            let mapRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            mapImage.draw(in: mapRect)

            // 上部オーバーレイ: ユーザー情報とタイトル
            drawTopOverlay(in: CGRect(x: 0, y: 0, width: size.width, height: OverlayHeight.top), walk: walk, context: cgContext)

            // 下部オーバーレイ: アプリ情報と統計情報
            drawBottomOverlay(in: CGRect(x: 0, y: size.height - OverlayHeight.bottom, width: size.width, height: OverlayHeight.bottom), walk: walk, context: cgContext)
        }

        return image
    }

    /// 上部オーバーレイ（ユーザー情報とタイトル）を描画
    ///
    /// - Parameters:
    ///   - rect: 描画領域
    ///   - walk: 散歩データ
    ///   - context: 描画コンテキスト
    private func drawTopOverlay(in rect: CGRect, walk: Walk, context: CGContext) {
        // 半透明の背景を描画
        drawSemiTransparentBackground(in: rect, context: context)

        // 左側: ユーザーアイコンとユーザー名（縦並び）
        let iconSize: CGFloat = 80
        let iconRect = CGRect(
            x: rect.minX + Padding.standard,
            y: rect.minY + Padding.standard,
            width: iconSize,
            height: iconSize
        )

        // Firebase Authからユーザー情報を取得
        let currentUser = Auth.auth().currentUser
        let userName = currentUser?.displayName ?? "ユーザー"

        // プロフィール画像があれば使用、なければデフォルトの円
        if let photoURL = currentUser?.photoURL,
           let imageData = try? Data(contentsOf: photoURL),
           let profileImage = UIImage(data: imageData) {

            // プロフィール画像を円形に描画
            let renderer = UIGraphicsImageRenderer(size: iconRect.size)
            let circularImage = renderer.image { _ in
                let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: iconRect.size))
                path.addClip()
                profileImage.draw(in: CGRect(origin: .zero, size: iconRect.size))
            }
            circularImage.draw(in: iconRect)

            // 境界線を描画
            context.setStrokeColor(UIColor.systemGray4.cgColor)
            context.setLineWidth(2.0)
            context.strokeEllipse(in: iconRect)
        } else {
            // デフォルトのユーザーアイコンの円を描画
            context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            context.fillEllipse(in: iconRect)
            context.setStrokeColor(UIColor.systemGray4.cgColor)
            context.setLineWidth(2.0)
            context.strokeEllipse(in: iconRect)
        }

        // ユーザー名（アイコンの下に配置、左揃え）
        let userNameFont = UIFont.systemFont(ofSize: FontSize.userName, weight: .medium)
        drawTextWithShadow(
            userName,
            font: userNameFont,
            color: .black,
            at: CGPoint(x: iconRect.minX, y: iconRect.maxY + 24),
            context: context
        )

        // 右側: 散歩タイトル
        let titleFont = UIFont.systemFont(ofSize: FontSize.title, weight: .bold)
        let titleSize = walk.title.size(withAttributes: [.font: titleFont])

        drawTextWithShadow(
            walk.title,
            font: titleFont,
            color: .black, // 白→黒に変更
            at: CGPoint(x: rect.maxX - titleSize.width - Padding.standard, y: rect.midY - 25),
            context: context
        )
    }

    /// 下部オーバーレイ（アプリ情報と統計情報）を描画
    ///
    /// - Parameters:
    ///   - rect: 描画領域
    ///   - walk: 散歩データ
    ///   - context: 描画コンテキスト
    private func drawBottomOverlay(in rect: CGRect, walk: Walk, context: CGContext) {
        let padding: CGFloat = 30

        // 半透明の背景を描画
        drawSemiTransparentBackground(in: rect, context: context)

        // 上部: アプリアイコンとアプリ名（中央配置）
        let appAreaHeight: CGFloat = 100
        let appRect = CGRect(x: rect.minX, y: rect.minY + 20, width: rect.width, height: appAreaHeight)
        drawAppInfo(in: appRect, context: context)

        // 中部: 統計情報（距離、時間、歩数）
        let statsAreaHeight: CGFloat = 120
        let statsRect = CGRect(x: rect.minX, y: rect.minY + appAreaHeight + 30, width: rect.width, height: statsAreaHeight)
        drawStatisticsInfo(in: statsRect, walk: walk, context: context)

        // 右下: 開始時間
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
                at: CGPoint(x: rect.maxX - timeSize.width - padding, y: rect.maxY - 40), // -20→-60に変更して上に移動
                context: context
            )
        }
    }

    /// 半透明背景を描画
    private func drawSemiTransparentBackground(in rect: CGRect, context: CGContext) {
        let backgroundColor = UIColor(red: 252 / 255, green: 247 / 255, blue: 239 / 255, alpha: 0.9)
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
    }

    /// アプリ情報（アイコンとアプリ名）を中央に描画
    private func drawAppInfo(in rect: CGRect, context: CGContext) {
        let iconSize: CGFloat = 120
        let totalWidth: CGFloat = iconSize + 20 + 350
        let startX = rect.midX - totalWidth / 2

        let iconRect = CGRect(
            x: startX,
            y: rect.midY - iconSize / 2,
            width: iconSize,
            height: iconSize
        )

        // Info.plistからアプリアイコンを取得
        if let iconName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
           let primaryIcon = iconName["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let iconFileName = iconFiles.first,
           let appIcon = UIImage(named: iconFileName) {
            // 角丸処理
            let renderer = UIGraphicsImageRenderer(size: iconRect.size)
            let roundedIcon = renderer.image { _ in
                let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: iconRect.size), cornerRadius: iconSize * 0.2)
                path.addClip()
                appIcon.draw(in: CGRect(origin: .zero, size: iconRect.size))
            }
            roundedIcon.draw(in: iconRect)
        }

        // アプリ名
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
    private func drawStatisticsInfo(in rect: CGRect, walk: Walk, context: CGContext) {
        let columnWidth = rect.width / 3
        let iconSize: CGFloat = 48

        // 距離
        drawStatisticWithIconAndShadow(
            value: walk.distanceString,
            systemIconName: "point.topleft.down.curvedto.point.bottomright.up",
            at: CGPoint(x: rect.minX + columnWidth * 0.5, y: rect.midY - 10),
            iconSize: iconSize,
            context: context
        )

        // 時間
        drawStatisticWithIconAndShadow(
            value: walk.durationString,
            systemIconName: "clock",
            at: CGPoint(x: rect.minX + columnWidth * 1.5, y: rect.midY - 10),
            iconSize: iconSize,
            context: context
        )

        // 歩数
        drawStatisticWithIconAndShadow(
            value: formatStepsForDisplay(walk.totalSteps),
            systemIconName: "figure.walk",
            at: CGPoint(x: rect.minX + columnWidth * 2.5, y: rect.midY - 10),
            iconSize: iconSize,
            context: context
        )
    }

    /// シンプルなテキストを描画（縁取りなし）
    private func drawTextWithShadow(_ text: String, font: UIFont, color: UIColor, at point: CGPoint, context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        text.draw(at: point, withAttributes: attributes)
    }

    /// アイコン付き統計情報を描画
    private func drawStatisticWithIconAndShadow(value: String, systemIconName: String, at center: CGPoint, iconSize: CGFloat, context: CGContext) {
        let valueFont = UIFont.systemFont(ofSize: 38, weight: .bold) // 32→38に拡大
        let valueSize = value.size(withAttributes: [.font: valueFont])

        // アイコンを描画
        drawSystemIconWithoutShadow(
            systemIconName,
            at: CGPoint(x: center.x, y: center.y - 30), // -25→-30に調整
            size: iconSize,
            context: context
        )

        // 値をアイコンの下に
        drawTextWithShadow(
            value,
            font: valueFont,
            color: .black, // 白→黒に変更
            at: CGPoint(x: center.x - valueSize.width / 2, y: center.y + 15), // +10→+15に調整
            context: context
        )
    }

    /// シンプルなシステムアイコンを描画（影なし）
    private func drawSystemIconWithoutShadow(_ systemName: String, at center: CGPoint, size: CGFloat, context: CGContext) {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
        if let icon = UIImage(systemName: systemName, withConfiguration: config) {
            let iconSize = CGSize(width: size, height: size)
            let iconRect = CGRect(
                x: center.x - iconSize.width / 2,
                y: center.y - iconSize.height / 2,
                width: iconSize.width,
                height: iconSize.height
            )

            // 黒いアイコンを描画
            icon.withTintColor(.black).draw(in: iconRect)
        }
    }

    /// 影付きシステムアイコンを描画
    private func drawSystemIconWithShadow(_ systemName: String, at center: CGPoint, size: CGFloat, context: CGContext) {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
        if let icon = UIImage(systemName: systemName, withConfiguration: config) {
            let iconSize = CGSize(width: size, height: size)
            let iconRect = CGRect(
                x: center.x - iconSize.width / 2,
                y: center.y - iconSize.height / 2,
                width: iconSize.width,
                height: iconSize.height
            )

            // 影を描画
            context.saveGState()
            context.setShadow(offset: CGSize(width: 1, height: 1), blur: 2.0, color: UIColor.black.cgColor)
            icon.withTintColor(.white).draw(in: iconRect)
            context.restoreGState()
        }
    }

    /// 旧バージョンとの互換性のためのテキスト描画メソッド（非推奨）
    private func drawText(_ text: String, font: UIFont, color: UIColor, at point: CGPoint, context: CGContext) {
        drawTextWithShadow(text, font: font, color: color, at: point, context: context)
    }

    /// 画像をJPEG圧縮してファイルサイズを最適化します
    ///
    /// - Parameter image: 圧縮対象の画像
    /// - Returns: 圧縮された画像
    /// - Throws: WalkImageGeneratorError
    private func compressImageToTargetSize(_ image: UIImage) throws -> UIImage {
        var quality = jpegQuality
        var imageData = image.jpegData(compressionQuality: quality)

        // 段階的に品質を下げてファイルサイズを調整
        while let data = imageData, data.count > maxFileSize && quality > 0.1 {
            quality -= 0.1
            imageData = image.jpegData(compressionQuality: quality)
        }

        guard let finalData = imageData,
              finalData.count <= maxFileSize,
              let compressedImage = UIImage(data: finalData) else {
            throw WalkImageGeneratorError.imageTooLarge
        }

        return compressedImage
    }

    /// 歩数を表示用フォーマットに変換
    ///
    /// 歩数データの状態に応じて適切な表示形式を返します。
    /// 防御的プログラミングの観点から、負数値や異常値に対しても安全に処理します。
    ///
    /// - Parameter totalSteps: 総歩数
    /// - Returns: 
    ///   - 歩数取得不可時（0以下）: 「-」
    ///   - 有効な歩数データ: 「XXX歩」形式
    private func formatStepsForDisplay(_ totalSteps: Int) -> String {
        guard totalSteps > 0 else {
            return "-"
        }
        return "\(totalSteps)歩"
    }
}

// MARK: - Bundle Extension

extension Bundle {
    /// アプリアイコンを取得するプロパティ
    var appIcon: UIImage? {
        guard let iconsDictionary = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last else { return nil }
        return UIImage(named: lastIcon)
    }
}

// MARK: - String Extension

extension String {
    func size(withAttributes attributes: [NSAttributedString.Key: Any]) -> CGSize {
        (self as NSString).size(withAttributes: attributes)
    }
}
