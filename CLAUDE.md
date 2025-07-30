# CLAUDE.md
必ず日本語で回答してください。
このファイルは、このリポジトリでコード作業を行う際のClaude Code (claude.ai/code) へのガイダンスを提供します。

## 最重要ルール
**🚨 絶対遵守 - 違反は許可されません 🚨**

###  新しいルールの追加プロセス
* ユーザーから今回限りではなく常に対応が必要だと思われる指示を受けた場合
  1. 「これを標準のルールにしますか？」と質問する
  2. YESの回答を得た場合、CLAUDE.mdに追加ルールとして記載する
  3. 以降は標準ルールとして常に適用する
* このプロセスにより、プロジェクトのルールを継続的に改善していきます。

### TDD TODOリスト（t-wada流）
**🔴 最重要・強制実行・例外なし**: 以下のルールは100%遵守すること
#### 基本方針
- 🔴 Red: 失敗するテストを書く
- 🟢 Green: テストを通す最小限の実装
- 🔵 Refactor: リファクタリング
- 小さなステップで進める
- 仮実装（ベタ書き）から始める
- 三角測量で一般化する
- 明白な実装が分かる場合は直接実装してもOK
- テストリストを常に更新する
- 不安なところからテストを書く
#### TDD実践のコツ

1. **最初のテスト**: まず失敗するテストを書く（コンパイルエラーもOK）
2. **仮実装**: テストを通すためにベタ書きでもOK（例：`return 42`）
3. **三角測量**: 2つ目、3つ目のテストケースで一般化する
4. **リファクタリング**: テストが通った後で整理する
5. **TODOリスト更新**: 実装中に思いついたことはすぐリストに追加
6. **1つずつ**: 複数のテストを同時に書かない
7. **コミット**: テストが通ったらすぐコミット

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
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TokoTokoTests/WalkManagerTests

# UIテスト実行
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TokoTokoUITests
```

### リンティングとフォーマッティング
**🔴 品質確保・必須実行**: コード変更後は必ず実行
```bash
# SwiftLint設定が存在（.swiftlint.yml）
swiftlint lint

# Swift Format設定が存在（.swift-format）
swift-format lint --configuration .swift-format [file]
```

### Gitワークフロー
- `main`: 本番ブランチ
- `dev-*`: 開発ブランチ（例: dev-1.0.0）
- `ticket/*`: 機能ブランチ（例: ticket/1）

#### コミット規約
##### コミット粒度の原則
- **1つの論理的変更 = 1つのコミット**: 関連する変更はまとめ、無関係な変更は分ける
- **原子性を保つ**: そのコミットだけで完結する変更にする（壊れた状態でコミットしない）
- **レビューしやすいサイズ**: 1コミットあたり100-300行程度を目安とする
- **論理的関連性の厳守**: 異なる関心事（バグ修正とドキュメント更新など）は必ず別コミットに分ける
- **変更種別の分離**: 機能実装、バグ修正、テスト追加、ドキュメント更新は種別ごとに分ける
- **混在コミットの禁止**: 関連性のない複数の変更を同一コミットに含めない

##### コミットメッセージ規約
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

#### TDD実践時のコミット順序
1. `test: [機能名] のテストケース追加 (#[チケット番号])` (Red)
2. `feat: [機能名] の実装 (#[チケット番号])` (Green)
3. `refactor: [機能名] のコード整理 (#[チケット番号])` (Refactor)

#### コミット実行・Push規則
**🔴 絶対遵守・例外なし**:
- **コミット粒度の徹底**: 論理的に分割可能な変更は、できるだけ細かく分けてコミットする
- **事前差分確認**: コミット実行前に必ず`git diff`でステージングされた差分を確認する
- **コミットメッセージ確認**: 差分確認後、提案するコミットメッセージをユーザーに提示し承認を得る
- **🚨 必須確認**: コミット実行前に必ずユーザーに「コミットしますか？」と確認する
- **🚨 出力**: 直接コミットすることは禁止しているのでコマンドだけ出力してください。また、EOFは使用しないようにしてください。


### 処理完了時の自動ログ記録
**🔴 必須実行・例外なし**:
1. **記録タイミング**:
   - 重要なタスクや機能実装が完全に終了した時
   - ユーザーからの要求に対する処理が完了した時
   - 問題解決や設計決定が完了した時

2. **記録場所**: `~/RRRRRRR777/TokoTokoDocs/AIAgentLogs/` 配下
   - ディレクトリが存在しない場合は作成する
   - ファイル名: `[MMDD]_[成果物概要20文字以内].md`

3. **記録形式**:
   ```markdown
   # [日付] [タスク名]

   ## プロンプト
   ```
   [ユーザーからの入力内容]
   ```

   ## 出力結果
   ```
   [Claudeの応答内容の要約]
   ```

   ## 成果物
   - 作成/修正したファイル一覧
   - 実行したコマンド
   - 得られた知見

   ## 実行時間
   開始: [開始時刻 YYYY-MM-DD(ddd) HH:mm]
   完了: [完了時刻 YYYY-MM-DD(ddd) HH:mm]
   ```

4. **記録内容の要件**:
   - プロンプト: ユーザーの要求を正確に記録
   - 出力結果: 主要な判断と実行内容を簡潔に要約
   - 成果物: 具体的なファイルパスとコマンドを記載
   - ファイル名: 成果物の概要を20文字以内で表現

5. **🚨 自動実行**: 処理完了時に例外なく実行する（忘れた場合は重大な違反）

6. **関連会話の統合ルール**:
   - **同一テーマ判定**: 同じ技術概念や機能に関する連続した質問・回答
   - **統合条件**: 同日内で関連性の高い複数のログファイルが存在する場合
   - **統合方法**:
     - 最初のファイルを基準として内容を拡張
     - 各プロンプト・回答を時系列順で追記
     - 最終的な総合知見をまとめて記載
   - **統合後の処理**: 個別ファイルは削除し、統合ファイルに集約
   - **統合タイミング**: 関連する新しいログ作成時に自動実行

## Gemini CLI 連携ガイド

### 目的
ユーザーが **「Geminiと相談しながら進めて」** （または類似表現）と指示した場合、
Claude は **Gemini CLI** を随時呼び出しながら、複数ターンにわたる協業を行う。

---

### トリガー
- 正規表現: `/Gemini.*相談しながら/`
- 一度トリガーした後は、ユーザーが明示的に終了を指示するまで **協業モード** を維持する。

---

### 協業ワークフロー (ループ可)
| # | 処理 | 詳細 |
|---|------|------|
| 1 | **PROMPT 準備** | 最新のユーザー要件 + これまでの議論要約を `$PROMPT` に格納 |
| 2 | **Gemini 呼び出し** | ```bash\ngemini <<EOF\n$PROMPT\nEOF\n```<br>必要に応じ `--max_output_tokens` 等を追加 |
| 3 | **出力貼り付け** | `Gemini ➜` セクションに全文、長い場合は要約＋原文リンク |
| 4 | **Claude コメント** | `Claude ➜` セクションで Gemini の提案を分析・統合し、次アクションを提示 |
| 5 | **継続判定** | ユーザー入力 or プラン継続で 1〜4 を繰り返す。<br>「Geminiコラボ終了」「ひとまずOK」等で通常モード復帰 |
---
### 形式テンプレート
```md
**Gemini ➜**
<Gemini からの応答>
**Claude ➜**
<統合コメント & 次アクション>

## プロジェクト概要
* TokoTokoは、ユーザーが散歩を記録し、友人や家族と散歩体験を共有できるiOS散歩・SNSアプリ（「とことこ - おさんぽSNS」）です。「散歩」×「記録」×「共有」を組み合わせ、日常の中で見つけた小さな発見を散歩を通じて共有することをコンセプトとしています。

### 主要機能（初期リリース）
- **散歩記録**: ボタンタップで開始・停止、バックグラウンド位置追跡
- **写真連携**: 散歩あたり最大10枚の写真（カメラロールから選択）、位置座標と連動
- **ルート可視化**: 散歩ルート（ポリライン）とマップ上の写真表示
- **共有システム**: 散歩完了後の自動URL生成、SNS/LINE/メール共有
- **ユーザー認証**: Firebase Authentication（メール・Googleログイン）

### 開発環境セットアップ
#### 必要なツール
```bash
# xcodegen のインストール（プロジェクト生成に必要）
brew install xcodegen

# Xcodeプロジェクトファイルの生成
set -a && source .env && set +a && xcodegen generate
```

#### 開発環境
- VS Code開発にはSweetPad拡張機能を使用
- SweetPad経由で必要ツールをインストール: SwiftLint, xcbeautify, xcode-build-server
- VS Codeの「実行とデバッグ」パネルから実行（launch.jsonに設定）
- プロジェクトはiOS 15.0+をデプロイメントターゲットとして使用

### アーキテクチャ
#### ディレクトリ構造
```
TokoToko/
├── Model/
│   ├── Entities/          # データ構造（Walk.swift, MapItem.swift）
│   ├── Services/          # データ操作の抽象化（WalkRepository.swift, GoogleAuthService.swift, LocationManager.swift, StepCountManager.swift, WalkManager.swift）
│   ├── Network/           # API通信（将来実装予定）
│   └── Testing/           # テスト用のプロトコルとヘルパー（TestingProtocols.swift, UITestingHelper.swift）
├── View/
│   ├── Screens/           # 画面固有のファイル（HomeView.swift, LoginView.swift, SettingsView.swift, SplashView.swift, WalkHistoryView.swift）
│   └── Shared/            # 再利用可能なコンポーネント（DetailView.swift, LoadingView.swift, MapViewComponent.swift, ThumbnailImageView.swift, WalkControlPanel.swift, WalkRow.swift）
├── Assets.xcassets/       # アプリアイコン、カラーパレット
├── Preview Content/       # SwiftUIプレビュー用のアセット
└── App/                   # エントリーポイント（TokoTokoApp.swift）
```

#### コアコンポーネント
- **GoogleAuthService**: Google Sign-In統合を含むFirebaseベースの認証
- **WalkManager**: 散歩記録、位置追跡、散歩状態を管理するシングルトン
- **LocationManager**: GPS追跡のためのCoreLocationラッパー
- **StepCountManager**: 歩数計測を管理するコンポーネント
- **WalkRepository**: 散歩記録のデータ永続化層

#### メインビュー構造
- **SplashView**: 初期ローディング画面
- **LoginView**: ログイン画面
- **HomeView**: 散歩履歴とメインダッシュボード
- **WalkHistoryView**: 散歩履歴の詳細表示
- **MapViewComponent**: ルート可視化とマッピング
- **SettingsView**: ユーザー設定とログアウト
- **DetailView**: 詳細情報表示用の汎用コンポーネント

#### データモデル（ERD）
- **Walk**: 散歩セッションを表すコアエンティティ:
  - 位置追跡（CLLocationの配列）
  - 状態管理（notStarted, inProgress, paused, completed）
  - 距離計算と時間追跡
  - ルート可視化のためのポリラインデータ
- **MapItem**: マップ上のアイテム（散歩ルート、写真位置等）
- **User**: ユーザー情報（email, display_name, photo_url, auth_provider）
- **Photo**: 散歩に関連付けられた写真（最大10枚/散歩、位置座標付き）
- **SharedLink**: 共有URL生成用（永続的なリンク）

### 技術スタック

#### iOS クライアント
- **SwiftUI**（プライマリUIフレームワーク）
- **CoreLocation**（位置追跡）
- **MapKit**（マップ表示）
- **PhotoPicker (iOS 14+)**（写真選択）

#### バックエンド（Firebase）
| サービス | 用途 |
|---------|------|
| Firebase Authentication | アカウント管理（email/Googleログイン） |
| Firestore | ルート、写真、ユーザー情報メタデータ |
| Firebase Storage | 写真ファイルストレージ |
| Firebase Hosting + Firestore | 公開共有リンク |
| Cloud Functions | 削除処理（将来機能） |

#### 主要な依存関係
- Firebase（Analytics, Auth, Firestore, Core）
- GoogleSignIn
- ViewInspector（テスト用）

## 開発ガイドライン

### タスク完了時の自動処理ルール
**🔴 絶対遵守・自動実行**: 「完了です」と報告する際に必ず自動実行すること

1. **自動コミット処理**:
   - タスク完了報告と同時にコミット処理を自動実行
   - CLAUDE.md内のコミット規約に従った適切なコミットメッセージを生成
   - `git diff`で差分確認後、ユーザーに承認を求めてからコミット実行
   - コミット粒度の原則に従い、論理的に分割可能な変更は適切に分けてコミット

2. **自動リファクタリング処理**:
   - 完了報告と同時に「試行錯誤したので余計なコードをリファクタしてください」を自動実行
   - 不要なコード、重複コード、試行錯誤の痕跡を自動的に整理
   - コード品質向上のための標準処理として位置づけ
   - リファクタリング後は再度テストを実行し、品質を確認

3. **処理順序**:
   - 完了報告 → 自動リファクタリング → コミット処理の順で実行
   - 各段階でユーザーの承認を適切に取得

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
set -a && source .env && set +a && xcodegen generate
```

## Firebase連携

### 新規Firebaseプロジェクト作成タスク
* Firebase DatabaseとAuthentication連携の初期セットアップを進める
* Firebase Project ID: TokoToko-iOS
* プロジェクトの初期セットアップを行う
