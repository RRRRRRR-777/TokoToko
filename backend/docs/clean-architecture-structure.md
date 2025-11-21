# Clean Architecture ディレクトリ構造

## 概要

TekuToko バックエンドは Clean Architecture パターンに基づいて設計されています。
各レイヤーは明確に分離され、依存性逆転の原則（DIP）に従っています。

## レイヤー構造

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

## ディレクトリ詳細

### 1. Domain Layer (`internal/domain/`)

ビジネスルールとエンティティを定義する最も内側の層。
外部の層に依存しない純粋なビジネスロジック。

```
domain/
├── walk/
│   ├── walk.go           # Walkエンティティ
│   ├── walk_test.go      # エンティティのテスト
│   └── repository.go     # Repositoryインターフェース（依存性逆転）
└── user/
    ├── user.go           # Userエンティティ
    └── user_test.go
```

**責務**:
- エンティティの定義
- ビジネスルールの実装
- リポジトリインターフェースの定義（実装は外側の層）

### 2. Usecase Layer (`internal/usecase/`)

アプリケーション固有のビジネスロジックを実装する層。
ドメイン層のエンティティを使用してユースケースを実現。

```
usecase/
└── walk/
    ├── interactor.go     # Usecaseインタラクター
    └── walk_usecase.go   # Walk関連のユースケース
```

**責務**:
- ユースケースの実装（Create/Read/Update/Delete）
- ドメインエンティティの操作
- トランザクション管理
- エラーハンドリング

### 3. Interface Layer (`internal/interface/`)

外部とのインターフェースを提供する層。
HTTP APIやデータベースアクセスを担当。

```
interface/
├── api/
│   ├── handler/
│   │   └── walk_handler.go      # HTTPハンドラー
│   ├── middleware/
│   │   └── middleware.go        # 認証、ログ等のミドルウェア
│   ├── presenter/
│   │   └── walk_presenter.go    # レスポンス整形
│   └── router/
│       └── router.go             # ルーティング設定
└── persistence/
    ├── postgres/
    │   └── walk_repository.go   # PostgreSQL実装
    └── storage/
        └── storage.go           # Cloud Storage実装
```

**責務**:
- HTTPリクエスト/レスポンスの処理
- リクエストバリデーション
- レスポンスフォーマット
- リポジトリの具体的実装

### 4. Infrastructure Layer (`internal/infrastructure/`)

外部サービスとの連携を担当する最も外側の層。

```
infrastructure/
├── config/
│   └── config.go         # 環境変数設定
├── database/
│   └── postgres.go       # DB接続管理
├── logger/
│   └── logger.go         # ロギング
└── telemetry/
    # メトリクス・トレーシング（Phase2で実装）
```

**責務**:
- データベース接続
- 外部API連携
- ロギング
- モニタリング・テレメトリ

### 5. DI Container (`internal/di/`)

依存性注入を管理するコンテナ。
アプリケーション全体の依存関係を初期化・管理。

```
di/
└── container.go          # DIコンテナ
```

**責務**:
- 依存関係の初期化
- リソースのライフサイクル管理
- 設定の読み込み

### 6. Shared Utilities (`internal/pkg/`)

共通ユーティリティパッケージ。

```
pkg/
├── errors/
│   └── errors.go         # エラー定義
├── validator/
│   └── validator.go      # バリデーション
└── pagination/
    └── pagination.go     # ページネーション
```

**責務**:
- 共通エラー定義
- バリデーション関数
- ページネーション処理

## 依存関係のルール

### 依存性逆転の原則（DIP）

内側の層は外側の層に依存してはいけません：

```
Domain Layer
  ↑ (依存)
Usecase Layer
  ↑ (依存)
Interface Layer
  ↑ (依存)
Infrastructure Layer
```

### 具体例

1. **ドメイン層**は`walk.Repository`インターフェースを定義
2. **インフラ層**が`postgres.WalkRepository`として実装
3. **ユースケース層**はインターフェースを通じて利用

これにより、データベースの変更（PostgreSQL → MySQL）が
ドメイン層やユースケース層に影響を与えません。

## Phase 2 での実装予定

現在のスケルトンコードに以下を追加予定：

- [ ] `usecase/walk/` - Walk CRUDユースケース
- [ ] `interface/api/handler/` - /v1/walks エンドポイント実装
- [ ] `interface/persistence/postgres/` - PostgreSQLリポジトリ実装
- [ ] `infrastructure/telemetry/` - メトリクス・トレーシング
- [ ] `di/container.go` - 完全なDI設定

## 参考

- Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- Go Clean Architecture: https://github.com/bxcodec/go-clean-arch
