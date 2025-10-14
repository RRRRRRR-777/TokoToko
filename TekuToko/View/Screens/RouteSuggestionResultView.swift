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
  @State private var mapAnnotations: [MapItem]
  @State private var geocodeTask: Task<Void, Never>? = nil

  private let cardBackground = Color.white.opacity(0.92)

  init(suggestions: [RouteSuggestion], onClose: (() -> Void)? = nil) {
    self.suggestions = suggestions
    self.onClose = onClose

    let mapData = Self.defaultMapData()
    _mapRegion = State(initialValue: mapData.region)
    _mapAnnotations = State(initialValue: mapData.annotations)
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

          textCard(title: suggestion.title, fontSize: 24)

          textCard(title: suggestion.description, fontSize: 16)

          mapSection()
            .padding(.horizontal, 24)

          textCard(title: suggestion.recommendationReason, fontSize: 16)

          metricsRow(for: suggestion)
            .padding(.horizontal, 24)

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
    StaticMapView(region: $mapRegion, annotations: mapAnnotations)
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

    let defaultData = Self.defaultMapData()
    mapRegion = defaultData.region
    mapAnnotations = defaultData.annotations

    guard let suggestion else { return }

    let candidates = areaCandidates(for: suggestion)
    guard !candidates.isEmpty else { return }

    geocodeTask = Task {
      defer {
        Task { @MainActor in
          self.geocodeTask = nil
        }
      }
      for candidate in candidates {
        guard !Task.isCancelled else { return }
        guard let coordinate = await geocodeAddress(candidate) else { continue }

        await MainActor.run {
          let span = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
          mapRegion = MKCoordinateRegion(center: coordinate, span: span)
          mapAnnotations = [
            MapItem(
              coordinate: coordinate,
              title: candidate,
              imageName: "mappin.and.ellipse"
            )
          ]
        }
        return
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

  private func areaCandidates(for suggestion: RouteSuggestion) -> [String] {
    var candidates: [String] = []

    let baseTitle = suggestion.title.trimmingCharacters(in: .whitespacesAndNewlines)
    if !baseTitle.isEmpty {
      candidates.append(baseTitle)
    }

    let cleaned = removeCommonSuffixes(from: baseTitle)
    if !cleaned.isEmpty {
      candidates.append(cleaned)
    }

    let splitDelimiters = CharacterSet(charactersIn: "・／/|　 ")
    let splitComponents = cleaned.components(separatedBy: splitDelimiters)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    candidates.append(contentsOf: splitComponents)

    // 重複を排除しつつ、入力順序を維持
    var unique: [String] = []
    for candidate in candidates {
      if !unique.contains(candidate) {
        unique.append(candidate)
      }
    }

    return unique
  }

  private func removeCommonSuffixes(from text: String) -> String {
    var result = text
    let suffixes = ["コース", "散歩", "さんぽ", "ルート", "散策", "プラン", "周辺", "めぐり", "ウォーク"]
    suffixes.forEach { suffix in
      if result.hasSuffix(suffix) {
        result.removeLast(suffix.count)
      }
    }
    return result.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
    await withCheckedContinuation { continuation in
      let geocoder = CLGeocoder()
      geocoder.geocodeAddressString(address) { placemarks, error in
        if error != nil {
          continuation.resume(returning: nil)
          return
        }
        let coordinate = placemarks?.first?.location?.coordinate
        continuation.resume(returning: coordinate)
      }
    }
  }

  private static func defaultMapData() -> (region: MKCoordinateRegion, annotations: [MapItem]) {
    let center = CLLocationCoordinate2D(latitude: 35.6886, longitude: 139.7528)
    let span = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
    let region = MKCoordinateRegion(center: center, span: span)
    let annotation = MapItem(
      coordinate: center,
      title: "北の丸公園",
      imageName: "mappin.and.ellipse"
    )
    return (region, [annotation])
  }
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
          recommendationReason: "気分をリフレッシュしたい方におすすめ。日比谷公園や北の丸公園で静かな時間を過ごせます。"
        ),
        RouteSuggestion(
          title: "神楽坂グルメさんぽ",
          description: "石畳の路地を散策しながら、個性豊かな飲食店を巡るグルメ散歩。",
          estimatedDistance: 5.2,
          estimatedDuration: 1.5,
          recommendationReason: "新しい味に出会いたい気分に。甘味処やベーカリーを巡りながら街の雰囲気を味わえます。"
        )
      ]
    )
  } else {
    Text("RouteSuggestionResultViewはiOS 17以降でプレビューできます")
  }
}
