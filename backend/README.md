# TekuToko Backend API

てくとこ - おさんぽSNS のバックエンドAPI (Go + GKE Autopilot + PostgreSQL)

## プロジェクト概要

このバックエンドは、iOSアプリ「てくとこ」のAPIサーバーとして、散歩記録・位置情報・認証機能を提供します。

**アーキテクチャドキュメント**: [backend/docs/go-project-structure.md](./docs/go-project-structure.md)

## アーキテクチャ

- **パターン**: Clean Architecture + DDD (Domain-Driven Design)
- **レイヤー構成**:
  - **Domain層**: エンティティ、値オブジェクト、リポジトリインターフェース
  - **Usecase層**: ビジネスロジック、アプリケーションフロー
  - **Interface層**: HTTP API、永続化アダプター
  - **Infrastructure層**: 外部サービス接続 (DB, Firebase, ロギング)

**依存関係ルール**: 内側の層は外側の層に依存しない (依存性逆転の原則)

```
┌─────────────────────────────────────┐
│       Infrastructure Layer          │
│  (Database, Firebase, Logging)      │
├─────────────────────────────────────┤
│       Interface Layer               │
│  (HTTP Handlers, Repository Impl)   │
├─────────────────────────────────────┤
│       Usecase Layer                 │
│  (Application Business Logic)       │
├─────────────────────────────────────┤
│       Domain Layer                  │
│  (Entities, Value Objects)          │
└─────────────────────────────────────┘
```

## ディレクトリ構造

```
backend/
├── cmd/
│   └── api/
│       └── main.go                 # アプリケーションエントリーポイント
├── internal/
│   ├── domain/                     # ドメイン層
│   │   ├── walk/                   # 散歩ドメイン
│   │   └── user/                   # ユーザードメイン
│   ├── usecase/                    # ユースケース層
│   │   └── walk/                   # 散歩ユースケース
│   ├── interface/                  # インターフェース層
│   │   ├── api/                    # HTTP API
│   │   │   ├── handler/            # リクエストハンドラー
│   │   │   ├── router/             # ルーティング
│   │   │   ├── presenter/          # レスポンス整形
│   │   │   └── middleware/         # ミドルウェア
│   │   └── persistence/            # 永続化アダプター
│   │       ├── postgres/           # PostgreSQLリポジトリ
│   │       └── storage/            # Cloud Storageアダプター
│   ├── infrastructure/             # インフラストラクチャ層
│   │   ├── config/                 # 設定管理
│   │   ├── database/               # DB接続
│   │   ├── auth/                   # Firebase認証
│   │   ├── logger/                 # ロギング
│   │   └── telemetry/              # メトリクス・トレーシング
│   └── pkg/                        # 共通ユーティリティ
│       ├── errors/                 # エラー定義
│       ├── validator/              # バリデーション
│       └── pagination/             # ページネーション
├── api/
│   └── openapi.yaml                # OpenAPI仕様書
├── migrations/                     # データベースマイグレーション
├── scripts/                        # 自動化スクリプト
├── deploy/                         # デプロイ設定
│   ├── docker/                     # Dockerfile
│   ├── cloudbuild/                 # Cloud Build設定
│   └── terraform/                  # Terraform (IaC)
├── .github/
│   └── workflows/                  # GitHub Actions CI/CD
├── Makefile                        # 開発タスク自動化
├── go.mod                          # Go依存関係管理
└── README.md                       # このファイル
```

## 開発環境要件

- **Go**: 1.22.x 以上
- **Docker Desktop**: ローカル開発用
- **Make**: タスクランナー
- **gcloud CLI + kubectl**: GKE Autopilotデプロイ用
- **golangci-lint**: コード品質チェック用

## セットアップ

### クイックスタート（推奨）

```bash
# 開発環境を自動セットアップ
./scripts/dev-setup.sh
```

このスクリプトは以下を自動実行します:
- ✅ .envファイルの作成
- ✅ Dockerコンテナの起動
- ✅ PostgreSQLの起動確認
- ✅ 開発ツールのインストール確認

### 手動セットアップ

#### 1. 依存関係インストール

```bash
# Go依存パッケージ取得
go mod download

# 開発ツールインストール
make tools
```

#### 2. 環境変数設定

```bash
# .envファイル作成
cp .env.example .env

# 必要な環境変数を編集
vi .env
```

#### 3. ローカル開発環境起動

```bash
# PostgreSQLコンテナ起動
docker-compose up -d postgres

# コンテナ状態確認
docker-compose ps

# マイグレーション実行（準備ができたら）
make migrate-up
```

## ローカル実行

```bash
# APIサーバー起動
make run

# またはホットリロード有効で起動
make dev
```

APIサーバーは `http://localhost:8080` で起動します。

## テスト・リンティング

```bash
# 全テスト実行
make test

# カバレッジ付きテスト
make test-coverage

# Lint実行
make lint

# フォーマット
make fmt
```

## データベースマイグレーション

```bash
# マイグレーション作成
make migrate-create name=create_walks_table

# マイグレーション適用
make migrate-up

# マイグレーションロールバック
make migrate-down
```

**マイグレーションツール**: `golang-migrate/migrate`

**命名規約**: `YYYYMMDDHHMMSS_description.up.sql` / `YYYYMMDDHHMMSS_description.down.sql`

## デプロイ

### GKE Autopilotへのデプロイ

```bash
# Dockerイメージビルド & プッシュ
make docker-build
make docker-push

# Kubernetesマニフェスト適用
kubectl apply -k deploy/kubernetes/overlays/prod

# デプロイ状態確認
kubectl rollout status deployment/tekutoko-api
```

### CI/CDパイプライン

GitHub Actionsで自動デプロイ設定済み:

1. **PR作成時**: テスト・Lint実行
2. **mainマージ時**: ビルド → GCRプッシュ → GKEデプロイ

詳細: [.github/workflows/](../.github/workflows/)

## 規約

### ブランチ命名

- `feature/タスク番号-機能名` (例: `feature/A-go-workspace-init`)
- `fix/バグ概要` (例: `fix/walk-distance-calculation`)

### コミットメッセージ

```
<type>: <description>

[optional body]

[optional footer]
```

**Type**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

## 参考ドキュメント

- [OpenAPI仕様書](./api/openapi.yaml)
- [データベーススキーマ](./docs/database-schema.md)
- [デプロイアーキテクチャ](./docs/deployment-architecture.md)
- [Phase 1設計サマリー](./docs/phase1-summary.md)

## 開発チーム

- **プロジェクト**: TekuToko - おさんぽSNS
- **リポジトリ**: https://github.com/RRRRRRR-777/TokoToko
