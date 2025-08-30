import SwiftUI

/// iOS版に応じたスクロール背景の制御を提供するViewModifier
///
/// iOS 16以降の`.scrollContentBackground(.hidden)`を活用しつつ、
/// 全バージョンで確実な背景色統一を提供する共通モジュールです。
///
/// ## 設計思想
/// - iOS版別の互換性保証（iOS 15/16+対応）
/// - 複数画面での再利用性
/// - 背景色統一の一貫性確保
///
/// ## Usage
/// ```swift
/// List {
///   // リスト内容
/// }
/// .modifier(ScrollContentBackgroundModifier())
/// ```
///
/// ## 対応iOS版
/// - iOS 16+: `.scrollContentBackground(.hidden)`を使用
/// - iOS 15: ViewModifierのパススルー（従来の背景制御方法を維持）
public struct ScrollContentBackgroundModifier: ViewModifier {
  
  /// ViewModifierの本体実装
  ///
  /// iOS版別の条件分岐によりスクロール背景を適切に制御します。
  /// iOS 16以降では新しいAPIを使用し、それ以前のバージョンでは
  /// 既存の背景制御方法を維持します。
  ///
  /// - Parameter content: 修飾対象のView
  /// - Returns: 背景制御が適用されたView
  public func body(content: Content) -> some View {
    if #available(iOS 16.0, *) {
      content
        .scrollContentBackground(.hidden)
    } else {
      // iOS 15以前では、UITableView.appearance()による背景制御を適用
      content
        .onAppear {
          UITableView.appearance().backgroundColor = UIColor.clear
          UITableView.appearance().separatorStyle = .none
          UITableViewCell.appearance().backgroundColor = UIColor.clear
          UITableViewHeaderFooterView.appearance().backgroundView = UIView()
          UITableViewHeaderFooterView.appearance().backgroundView?.backgroundColor = UIColor.clear
        }
    }
  }
}

// MARK: - View Extension

extension View {
  
  /// ScrollContentBackgroundModifierを適用するための便利メソッド
  ///
  /// より簡潔な記述でスクロール背景制御を適用できます。
  ///
  /// ## Usage
  /// ```swift
  /// List {
  ///   // リスト内容
  /// }
  /// .hideScrollContentBackground()
  /// ```
  ///
  /// - Returns: ScrollContentBackgroundModifierが適用されたView
  public func hideScrollContentBackground() -> some View {
    modifier(ScrollContentBackgroundModifier())
  }
}