  # CLAUDE.md
必ず日本語で回答してください。
このファイルは、このリポジトリでコード作業を行う際のClaude Code (claude.ai/code) へのガイダンスを提供します。

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
- 単体テスト: `TokoTokoTests/`
- UIテスト: `TokoTokoUITests/`
- SwiftUIテストにViewInspectorを使用
- UITestingHelperがUIテスト用のモック状態を提供

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
