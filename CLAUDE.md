  # CLAUDE.md
必ず日本語で回答してください。
このファイルは、このリポジトリでコード作業を行う際のClaude Code (claude.ai/code) へのガイダンスを提供します。

## 最重要ルール - 新しいルールの追加プロセス

ユーザーから今回限りではなく常に対応が必要だと思われる指示を受けた場合：

1. 「これを標準のルールにしますか？」と質問する
2. YESの回答を得た場合、CLAUDE.mdに追加ルールとして記載する
3. 以降は標準ルールとして常に適用する

このプロセスにより、プロジェクトのルールを継続的に改善していきます。

## プロジェクト概要

TokoTokoは、ユーザーが散歩を記録し、友人や家族と散歩体験を共有できるiOS散歩・SNSアプリ（「とことこ - おさんぽSNS」）です。「散歩」×「記録」×「共有」を組み合わせ、日常の中で見つけた小さな発見を散歩を通じて共有することをコンセプトとしています。

### 主要機能（初期リリース）
- **散歩記録**: ボタンタップで開始・停止、バックグラウンド位置追跡
- **写真連携**: 散歩あたり最大10枚の写真（カメラロールから選択）、位置座標と連動
- **ルート可視化**: 散歩ルート（ポリライン）とマップ上の写真表示
- **共有システム**: 散歩完了後の自動URL生成、SNS/LINE/メール共有
- **ユーザー認証**: Firebase Authentication（メール・Googleログイン）

## 開発環境セットアップ

### 必要なツール
```bash
# xcodegen のインストール（プロジェクト生成に必要）
brew install xcodegen

# Xcodeプロジェクトファイルの生成
xcodegen generate
```

### 開発環境
- VS Code開発にはSweetPad拡張機能を使用
- SweetPad経由で必要ツールをインストール: SwiftLint, xcbeautify, xcode-build-server
- VS Codeの「実行とデバッグ」パネルから実行（launch.jsonに設定）
- プロジェクトはiOS 15.0+をデプロイメントターゲットとして使用

## アーキテクチャ
### ディレクトリ構造
```
TokoToko/
├── Model/
│   ├── Entities/          # データ構造（Walk.swift, User.swift）
│   ├── Services/          # データ操作の抽象化（WalkRepository.swift）
│   └── Network/           # API通信（APIClient.swift）
├── View/
│   ├── Screens/           # 画面固有のファイル（WalkView.swift, HomeView.swift）
│   └── Shared/            # 再利用可能なコンポーネント（ErrorView, LoadingView）
├── Resources/             # 画像、ローカライズ、カラーパレット
└── App/                   # エントリーポイント（AppDelegate, TokoTokoApp.swift）
```

### コアコンポーネント
- **AuthManager**: Google Sign-In統合を含むFirebaseベースの認証
- **WalkManager**: 散歩記録、位置追跡、散歩状態を管理するシングルトン
- **LocationManager**: GPS追跡のためのCoreLocationラッパー
- **WalkRepository**: 散歩記録のデータ永続化層

### メインビュー構造
- **MainTabView**: タブベースナビゲーション（ホーム、マップ、設定）
- **HomeView**: 散歩履歴とメインダッシュボード
- **MapView**: ルート可視化とマッピング
- **SettingsView**: ユーザー設定とログアウト

### データモデル（ERD）
- **Walk**: 散歩セッションを表すコアエンティティ:
  - 位置追跡（CLLocationの配列）
  - 状態管理（notStarted, inProgress, paused, completed）
  - 距離計算と時間追跡
  - ルート可視化のためのポリラインデータ
- **User**: ユーザー情報（email, display_name, photo_url, auth_provider）
- **Photo**: 散歩に関連付けられた写真（最大10枚/散歩、位置座標付き）
- **SharedLink**: 共有URL生成用（永続的なリンク）

## 技術スタック

### iOS クライアント
- **SwiftUI**（プライマリUIフレームワーク）
- **CoreLocation**（位置追跡）
- **MapKit**（マップ表示）
- **PhotoPicker (iOS 14+)**（写真選択）

### バックエンド（Firebase）
| サービス | 用途 |
|---------|------|
| Firebase Authentication | アカウント管理（email/Googleログイン） |
| Firestore | ルート、写真、ユーザー情報メタデータ |
| Firebase Storage | 写真ファイルストレージ |
| Firebase Hosting + Firestore | 公開共有リンク |
| Cloud Functions | 削除処理（将来機能） |

### 主要な依存関係
- Firebase（Analytics, Auth, Firestore, Core）
- GoogleSignIn
- ViewInspector（テスト用）

## テスト

### TDD（テスト駆動開発）原則
このプロジェクトではTDD（Test-Driven Development）を採用しています。

#### TDDサイクル（Red-Green-Refactor）
1. **Red**: まず失敗するテストを書く
2. **Green**: テストが通る最小限のコードを書く
3. **Refactor**: コードをクリーンアップし、重複を除去する

#### TDD実施ガイドライン
- 新機能追加前に必ずテストを先に書く
- テストケースは具体的で理解しやすい名前を付ける
- 1つのテストは1つの機能・動作のみを検証する
- モックやスタブを活用して外部依存を排除する
- テストは実装詳細ではなく、公開インターフェースをテストする

#### テスト種類と配置
- **単体テスト**: `TokoTokoTests/` - ビジネスロジック、データモデル、サービス層
- **UIテスト**: `TokoTokoUITests/` - 画面遷移、ユーザーインタラクション
- **統合テスト**: Firebase連携、位置情報サービス等の外部システム連携

#### テストツール
- **XCTest**: iOS標準テストフレームワーク
- **ViewInspector**: SwiftUIコンポーネントのテスト
- **UITestingHelper**: UIテスト用のモック状態管理

#### テスト実行コマンド
```bash
# 全体テスト実行
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16'

# 変更したファイルに関連する単体テストのみ実行（推奨）
# 例: WalkManagerを変更した場合
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TokoTokoTests/WalkManagerTests

# 特定のテストクラスのみ実行
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TokoTokoTests/GoogleAuthServiceTests

# 特定のテストメソッドのみ実行
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TokoTokoTests/WalkManagerTests/testStartWalk

# UIテスト実行
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TokoTokoUITests
```

#### TDD実践での効率的なテスト実行
- 開発中は変更したファイルに対応するテストクラスのみを実行
- コミット前に関連する全テストを実行して確認
- CI/CDパイプラインでは全テストを実行

#### 実装変更時の単体テスト修正ルール
**必須**: 実装でメソッドシグネチャやクラス構造を変更した場合は、必ず対応する単体テストも修正する必要があるかを確認し、必要に応じて修正して実行する

1. **変更の影響確認**: 実装変更が既存のテストに影響するかを確認
2. **テスト修正**: 必要に応じてテストコードを修正（期待値の変更、メソッド名の変更など）
3. **テスト実行**: 修正したテストが正常に動作することを確認
4. **テスト結果の検証**: 全てのテストがパスすることを確認

##### 修正が必要な典型的なケース
- メソッド名の変更
- メソッドの引数・戻り値の変更
- クラス名やプロパティ名の変更
- 公開インターフェースの変更
- エラーハンドリングの変更

## リンティングとフォーマッティング
```bash
# SwiftLint設定が存在（.swiftlint.yml）
swiftlint lint

# Swift Format設定が存在（.swift-format）
swift-format lint --configuration .swift-format [file]
```

## Gitワークフロー
- `main`: 本番ブランチ
- `dev-*`: 開発ブランチ（例: dev-1.0.0）
- `ticket/*`: 機能ブランチ（例: ticket/1）

### コミット粒度とメッセージガイドライン

#### コミット粒度の原則
- **1つの論理的変更 = 1つのコミット**: 関連する変更はまとめ、無関係な変更は分ける
- **原子性を保つ**: そのコミットだけで完結する変更にする（壊れた状態でコミットしない）
- **レビューしやすいサイズ**: 1コミットあたり100-300行程度を目安とする

#### 適切なコミット粒度の例
✅ **Good**: 単一機能の追加
- `feat: 散歩記録開始/停止ボタンの実装`
- ファイル: `HomeView.swift`, `WalkManager.swift`

✅ **Good**: バグ修正
- `fix: 位置追跡が停止しない問題を修正`
- ファイル: `LocationManager.swift`

✅ **Good**: リファクタリング
- `refactor: WalkManager の状態管理ロジックを簡素化`
- ファイル: `WalkManager.swift`, `WalkManagerTests.swift`

#### 避けるべきコミット粒度
❌ **Bad**: 複数の無関係な変更
- `feat: ホーム画面とマップ画面とプロフィール機能の追加`

❌ **Bad**: 不完全な変更
- `WIP: 散歩機能作成中`（テストなしで実装途中）

❌ **Bad**: 過度に細かい分割
- `add import statement`
- `fix typo in comment`

#### コミットメッセージ規約
```
<type>: <description>

[optional body]

[optional footer]
```

**Type**:
- `feat`: 新機能
- `fix`: バグ修正
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `docs`: ドキュメント更新
- `style`: コードスタイルの修正
- `chore`: その他の雑務

**例**:
```
feat: 散歩ルート表示機能の実装 (#4)
- ブランチに付与されている番号を参照する

MapViewにポリライン表示を追加し、散歩の軌跡を
視覚的に確認できるようにした。

- MapViewComponent にポリライン描画ロジック追加
- Walk モデルに coordinatesArray プロパティ追加
- 関連する単体テストを追加

Closes #123
```

#### TDD実践時のコミット順序
1. `test: [機能名] のテストケース追加 (#[チケット番号])` (Red)
2. `feat: [機能名] の実装 (#[チケット番号])` (Green)
3. `refactor: [機能名] のコード整理 (#[チケット番号])` (Refactor)

この順序により、TDDサイクルがコミット履歴で追跡可能になります。

#### コミット署名とメタデータ規則
**重要**: 以下の記述は不要

- `🤖 Generated with [Claude Code](https://claude.ai/code)`
- `Co-Authored-By: Claude <noreply@anthropic.com>`

これらは自動生成感が強く、コミット履歴をシンプルに保つため省略します。

#### チケット番号の記載規則
- **ticket/[番号]**ブランチで開発中は、コミットタイトルの末尾に`(#[番号])`を付ける
- 例: `feat: 新機能の実装 (#4)`
- mainブランチや他のブランチでは、必要に応じてIssue番号を記載

#### Push規則
**重要**: Claude Codeは自動でPushしない

- ローカルコミットのみ実行し、リモートへのPushは行わない
- ユーザーが明示的にPushを要求した場合のみ`git push`を実行
- Pull Request作成時もローカルでの作成まで行い、Pushは別途確認する

この規則により、ユーザーがコミット内容を確認してからリモートに反映できます。

## 開発ガイドライン

### コード構成規則
- 新規ファイル作成よりも既存ファイル編集を優先
- MVアーキテクチャパターンに従う
- エンティティモデルは`Model/Entities/`に配置
- ビジネスロジックは`Model/Services/`に配置
- UIコンポーネントは`View/Screens/`または`View/Shared/`に配置

### 画面設計仕様
- **ホーム画面**: 新しい散歩開始、現在位置マップ表示
- **散歩中画面**: 進行状況表示（距離、時間、歩数）、散歩終了ボタン
- **散歩後画面**: ルート確認、写真レビュー・削除、保存・共有機能
- **設定画面**: プロフィール設定、通知設定、アカウント設定
- **共有リンク表示画面**: 散歩ルートと写真の公開ビュー

### アプリケーションフロー
1. **ログインフロー**: アプリ起動 → ログイン状態確認 → ホーム画面
2. **散歩記録フロー**: 散歩開始 → 位置追跡 → 散歩終了 → 確認・保存 → 共有リンク生成
3. **履歴フロー**: 履歴タブ → 散歩リスト取得 → 詳細表示

### 制限事項
- 無料プラン: 散歩あたり最大10枚の写真
- プレミアムプラン（将来）: 散歩あたり最大100枚の写真

## ビルド
プロジェクトはproject.yml設定でXcodeGenを使用。依存関係変更後は常にプロジェクトを再生成:
```bash
xcodegen generate
```
