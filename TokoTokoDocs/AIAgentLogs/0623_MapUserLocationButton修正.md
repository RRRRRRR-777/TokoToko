# 0623 MapUserLocationButton位置・表示統一修正

## プロンプト
```
MapUserLocationButtonに対して位置の設定を加えても反映されなかったりします。例えばシミュレーターでは右上にあるのに、プレビューでは右上から少し下にあります。
```

## 出力結果
MapUserLocationButtonの位置問題とプレビュー・HomeView間での表示統一問題を解決しました。

### 問題の分析
1. SwiftUIのmapControlsは内部的な制約があり、paddingが期待通りに動作しない
2. iOS 17のMapコンポーネントがデフォルトでMapUserLocationButtonを表示（左上）
3. mapControlsで追加したカスタムボタンが別途表示（右上）により2つのボタンが同時表示
4. HomeViewの.onTapGestureとMapUserLocationButtonの機能が競合

### 実装した解決策
1. **ZStackレイアウトへの変更**: mapControlsによる位置設定からZStackを使用したカスタムレイアウトに変更
2. **デフォルトコントロールの無効化**: .mapControlVisibility(.hidden)でシステム標準ボタンを非表示
3. **ジェスチャー競合の解消**: HomeViewの不要な.onTapGestureを削除
4. **完全カスタムボタン実装**: MapUserLocationButtonを純粋なSwiftUIボタンで置き換え

## 成果物
- 修正したファイル:
  - `/TokoToko/View/Shared/MapViewComponent.swift`
  - `/TokoToko/View/Screens/HomeView.swift`
  - `/CLAUDE.md` (タスク完了時の自動処理ルール追加)

- 実行したコマンド:
  - `xcodebuild build` (修正確認)
  - `git commit` (変更のコミット)

- 得られた知見:
  - SwiftUIのmapControlsは環境により表示が異なる場合がある
  - プレビューと実機/シミュレーターでMapコンポーネントの動作に差が生じる
  - ジェスチャーの競合により期待しない表示問題が発生する可能性
  - 完全カスタム実装により環境依存を排除できる

## 実行時間
開始: 2025-06-23(Sun) 20:30
完了: 2025-06-23(Sun) 21:15