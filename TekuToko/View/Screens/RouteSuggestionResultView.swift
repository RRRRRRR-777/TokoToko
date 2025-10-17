import CoreLocation
import MapKit
import SwiftUI

/// ルート提案の結果を表示する全画面ビュー。
/// 提案されたルートをカード形式で見せ、左右のナビゲーションで切り替える。
struct RouteSuggestionResultView: View {
  @Environment(\.dismiss) private var dismiss

  /// 表示対象のルート提案一覧。
  let suggestions: [RouteSuggestion]

  /// 閉じる操作を親へ伝えるためのコールバック。
  var onClose: (() -> Void)?

  @State private var currentIndex: Int = 0
  @State private var mapRegion: MKCoordinateRegion
  @State private var geocodeTask: Task<Void, Never>? = nil
  @State private var lastGeocodedAddress: String?

  private let cardBackground = Color.white.opacity(0.92)

  init(suggestions: [RouteSuggestion], onClose: (() -> Void)? = nil) {
    self.suggestions = suggestions
    self.onClose = onClose

    _mapRegion = State(initialValue: Self.fallbackRegion)
    _lastGeocodedAddress = State(initialValue: nil)
  }

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color("RouteNavGradientStart"),
          Color("RouteNavGradientEnd")
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      if let suggestion = currentSuggestion {
        VStack(spacing: 16) {
          header()

          titleDescriptionCard(
            title: suggestion.title,
            description: suggestion.description
          )
          .padding(.bottom, 8)

          mapSection()
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

          textCard(title: suggestion.recommendationReason, fontSize: 16)
            .padding(.bottom, 8)

          metricsRow(for: suggestion)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

          Spacer(minLength: 0)

          navigationBar()
            .padding(.bottom, 8)
        }
        .padding(.top, 24)
        .padding(.bottom, 24)
        .transition(.opacity)
      } else {
        VStack {
          Spacer()
          Text("提案を表示できませんでした")
            .font(.headline)
            .foregroundColor(.white)
          Spacer()
          Button(action: closeView) {
            Text("閉じる")
              .font(.body)
              .padding(.horizontal, 24)
              .padding(.vertical, 12)
              .background(Color.white.opacity(0.2))
              .foregroundColor(.white)
              .cornerRadius(12)
          }
          .padding(.bottom, 32)
        }
      }
    }
    .onChange(of: currentIndex) { _ in
      updateMap(for: currentSuggestion)
    }
    .onAppear {
      updateMap(for: currentSuggestion)
    }
    .onDisappear {
      geocodeTask?.cancel()
    }
  }

  private var currentSuggestion: RouteSuggestion? {
    guard suggestions.indices.contains(currentIndex) else { return nil }
    return suggestions[currentIndex]
  }

  @ViewBuilder
  private func header() -> some View {
    HStack {
      Spacer()

      Button(action: closeView) {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.primary)
          .padding(12)
          .background(Color.white.opacity(0.85))
          .clipShape(Circle())
          .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
      }
      .accessibilityLabel("閉じる")
      .padding(.trailing, 24)
    }
  }

  private func textCard(title: String, fontSize: CGFloat) -> some View {
    Text(title)
      .font(.system(size: fontSize, weight: .semibold))
      .foregroundColor(.primary)
      .multilineTextAlignment(.leading)
      .lineLimit(2)
      .minimumScaleFactor(0.6)
      .padding(.vertical, 12)
      .padding(.horizontal, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(cardBackground)
          .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
      )
      .padding(.horizontal, 20)
  }

  private func titleDescriptionCard(title: String, description: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 22, weight: .semibold))
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
        .lineLimit(2)
        .minimumScaleFactor(0.6)

      Text(description)
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.primary)
        .multilineTextAlignment(.leading)
        .lineLimit(2)
        .minimumScaleFactor(0.6)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(cardBackground)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    )
    .padding(.horizontal, 20)
  }

  private func mapSection() -> some View {
    StaticMapView(region: $mapRegion)
      .frame(height: 230)
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
          .stroke(Color.white.opacity(0.7), lineWidth: 1)
      )
      .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
  }

  private func metricsRow(for suggestion: RouteSuggestion) -> some View {
    HStack(spacing: 16) {
      metricCard(
        systemIcon: "clock",
        label: formatDuration(suggestion.estimatedDuration)
      )

      metricCard(
        systemIcon: "point.topleft.down.curvedto.point.bottomright.up",
        label: formatDistance(suggestion.estimatedDistance)
      )
    }
    .frame(maxWidth: .infinity)
  }

  private func metricCard(systemIcon: String, label: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: systemIcon)
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(Color.primary.opacity(0.7))

      Text(label)
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.primary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(cardBackground)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    )
  }

  private func navigationBar() -> some View {
    HStack {
      Button(action: showPrevious) {
        navigationButtonIcon(name: "chevron.left")
      }
      .disabled(currentIndex == 0)
      .opacity(currentIndex == 0 ? 0.4 : 1.0)

      Spacer()

      Text("\(currentIndex + 1)/\(max(suggestions.count, 1))")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(.primary)

      Spacer()

      Button(action: showNext) {
        navigationButtonIcon(name: "chevron.right")
      }
      .disabled(currentIndex >= suggestions.count - 1)
      .opacity(currentIndex >= suggestions.count - 1 ? 0.4 : 1.0)
    }
    .padding(.horizontal, 32)
  }

  private func navigationButtonIcon(name: String) -> some View {
    Image(systemName: name)
      .font(.system(size: 18, weight: .bold))
      .foregroundColor(.primary)
      .frame(width: 52, height: 52)
      .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(Color.white.opacity(0.85))
      )
      .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
  }

  private func showPrevious() {
    guard currentIndex > 0 else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      currentIndex -= 1
    }
  }

  private func showNext() {
    guard currentIndex < suggestions.count - 1 else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      currentIndex += 1
    }
  }

  private func closeView() {
    if let onClose {
      onClose()
    } else {
      dismiss()
    }
  }

  private func updateMap(for suggestion: RouteSuggestion?) {
    geocodeTask?.cancel()

    guard let suggestion else {
      mapRegion = Self.fallbackRegion
      lastGeocodedAddress = nil
      return
    }

    let rawAddress = suggestion.address.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !rawAddress.isEmpty else {
      mapRegion = Self.fallbackRegion
      lastGeocodedAddress = nil
      return
    }

    if rawAddress == lastGeocodedAddress {
      return
    }

    lastGeocodedAddress = rawAddress
    mapRegion = Self.fallbackRegion

    geocodeTask = Task {
      let coordinate = await geocodeAddress(rawAddress)
      await MainActor.run {
        defer { self.geocodeTask = nil }
        guard lastGeocodedAddress == rawAddress else { return }
        guard let coordinate else {
          #if DEBUG
            print("[RouteSuggestionResultView] geocoding failed: \(rawAddress)")
          #endif
          lastGeocodedAddress = nil
          mapRegion = Self.fallbackRegion
          return
        }
        mapRegion = MKCoordinateRegion(center: coordinate, span: Self.fallbackSpan)
      }
    }
  }

  private func formatDistance(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0 {
      return "\(Int(value))km"
    }
    return String(format: "%.1fkm", value)
  }

  private func formatDuration(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0 {
      return "\(Int(value))時間"
    }
    return String(format: "%.1f時間", value)
  }

  private func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
    await withCheckedContinuation { continuation in
      let geocoder = CLGeocoder()

      func handleResult(_ placemarks: [CLPlacemark]?, error: Error?) {
        if let coordinate = placemarks?.first?.location?.coordinate {
          continuation.resume(returning: coordinate)
        } else if let error {
          #if DEBUG
            print("[RouteSuggestionResultView] geocoding error: \(error.localizedDescription)")
          #endif
          continuation.resume(returning: nil)
        } else {
          continuation.resume(returning: nil)
        }
      }

      geocoder.geocodeAddressString(address) { placemarks, error in
        if let placemarks, !placemarks.isEmpty {
          handleResult(placemarks, error: error)
          return
        }

        let secondAttempt = address.contains("日本") ? address : "\(address) 日本"
        geocoder.geocodeAddressString(secondAttempt) { secondPlacemarks, secondError in
          handleResult(secondPlacemarks, error: secondError)
        }
      }
    }
  }

  private static let fallbackCenter = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125) // 東京駅
  private static let fallbackSpan = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
  private static let fallbackRegion = MKCoordinateRegion(center: fallbackCenter, span: fallbackSpan)
}

#Preview {
  if #available(iOS 17.0, *) {
    RouteSuggestionResultView(
      suggestions: [
        RouteSuggestion(
          title: "皇居外苑リラックスコース",
          description: "緑豊かな皇居外苑を巡りながら、季節の花々と歴史的建造物を楽しめるコースです。",
          estimatedDistance: 10.0,
          estimatedDuration: 2.5,
          recommendationReason: "気分をリフレッシュしたい方におすすめ。日比谷公園や北の丸公園で静かな時間を過ごせます。",
          address: "東京都千代田区皇居外苑1丁目",
          postalCode: "100-0002",
          landmark: "皇居外苑"
        ),
        RouteSuggestion(
          title: "神楽坂グルメさんぽ",
          description: "石畳の路地を散策しながら、個性豊かな飲食店を巡るグルメ散歩。",
          estimatedDistance: 5.2,
          estimatedDuration: 1.5,
          recommendationReason: "新しい味に出会いたい気分に。甘味処やベーカリーを巡りながら街の雰囲気を味わえます。",
          address: "東京都新宿区神楽坂6丁目",
          postalCode: "162-0825",
          landmark: "神楽坂商店街"
        )
      ]
    )
  } else {
    Text("RouteSuggestionResultViewはiOS 17以降でプレビューできます")
  }
}
