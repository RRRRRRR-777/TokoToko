# Repository Guidelines

必ず日本語で記載してください。詳細は CLAUDE.md を参照し、本書は日常開発の要点のみを簡潔にまとめています。

## プロジェクト構成 / モジュール
- `TokoToko/`：アプリ本体。`App/`（エントリ）、`Model/`（Entities/Services/Network）、`View/`（Screens/Shared）、`Assets.xcassets/`、`Resources/`、`Preview Content/`。
- `TokoTokoTests/`：単体テスト（XCTest）。`TestHelpers/` あり。
- `TokoTokoUITests/`：UIテスト（XCUITest）。`Shared/` と `TestHelpers/` あり。
- `docs/`：サイト・ドキュメント。`Scripts/` と `run_refactoring_tests.sh`：ローカル検証用スクリプト。

## 開発・ビルド・テスト
- Xcode起動：`open TokoToko.xcodeproj`
- ビルド：`xcodebuild -project TokoToko.xcodeproj -scheme TokoToko -configuration Debug build`
- テスト（全体）：`xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- 重点テスト：`./run_refactoring_tests.sh` または `-only-testing:` を付与
- Lint：`swiftlint lint`（`.swiftlint.yml` 準拠）
- Format：`swift-format format --in-place --recursive .`（`.swift-format` 準拠、基本2スペース/行長100目安）
- XcodeGen：依存変更時は `xcodegen`（`project.yml` 参照）

## コーディング規約 / 命名
- Swift/SwiftUI。強制アンラップを避ける、明示的アクセス制御を推奨。
- 型は `PascalCase`、メソッド/変数は `camelCase`。ビューは `...View`、テストは `...Tests`。
- 1主要型=1ファイルを基本。UIは `View/Screens` or `View/Shared`、ロジックは `Model/Services`。

## テスト方針
- 種別：単体（`TokoTokoTests/`）、UI（`TokoTokoUITests/`）。ViewInspector 等を活用。
- 命名：`FeatureNameTests.swift`、`test_<振る舞い>_when_<条件>()`。
- カバレッジ：新規/変更点に対して追加し、既存水準以上を維持。

## コミット / PR ガイド
- Conventional Commits：`feat|fix|refactor|test|docs|style|chore[:scope]` を使用。
  - 例：`fix(WalkManager): documentsDirectoryの安全化 (#115)`
- ブランチ：`ticket/<issue-number>`（例：`ticket/114`）。
- PR：概要、関連Issue `#<id>`、UI差分はスクショ/GIF、テスト方針・結果を記載。Lint/Formatパス必須。

## セキュリティ / 設定
- `.env.sample` をコピーして `.env` を作成。秘匿情報はコミットしない。
- Firebase関連（`GoogleService-Info.plist`、`firestore.rules` 等）は直コミット鍵の埋め込み禁止。

## エージェント向け補足（CLAUDE.md 準拠）
- 曖昧な点は必ず質問で確認。ルールの恒常化はユーザーへ提案後、合意時に追記。
- TDD（Red/Green/Refactor）を小ステップで実践。差分確認→メッセージ提案→承認後にコミット。
