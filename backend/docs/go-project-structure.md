# Goプロジェクト構成設計

## アーキテクチャパターン

**採用パターン**: Clean Architecture + DDD (Domain-Driven Design)

## ディレクトリ構成

```
backend/
├── cmd/
│   └── api/
│       └── main.go                 # エントリーポイント
├── internal/
│   ├── domain/                     # ドメイン層
│   │   ├── walk/
│   │   │   ├── walk.go            # Walkエンティティ
│   │   │   ├── repository.go      # Repository interface
│   │   │   └── service.go         # Domain service
│   │   ├── user/
│   │   │   ├── user.go
│   │   │   └── repository.go
│   │   └── photo/
│   │       ├── photo.go
│   │       └── repository.go
│   ├── usecase/                    # ユースケース層
│   │   ├── walk/
│   │   │   ├── create_walk.go
│   │   │   ├── get_walk.go
│   │   │   ├── list_walks.go
│   │   │   ├── update_walk.go
│   │   │   └── delete_walk.go
│   │   └── photo/
│   │       ├── upload_photo.go
│   │       └── delete_photo.go
│   ├── interface/                  # インターフェース層
│   │   ├── api/
│   │   │   ├── handler/           # HTTPハンドラー
│   │   │   │   ├── walk_handler.go
│   │   │   │   ├── photo_handler.go
│   │   │   │   └── share_handler.go
│   │   │   ├── middleware/        # ミドルウェア
│   │   │   │   ├── auth.go
│   │   │   │   ├── logging.go
│   │   │   │   ├── recovery.go
│   │   │   │   └── request_id.go
│   │   │   ├── router/            # ルーティング
│   │   │   │   └── router.go
│   │   │   └── presenter/         # レスポンス整形
│   │   │       ├── walk_presenter.go
│   │   │       └── error_presenter.go
│   │   └── persistence/           # データ永続化
│   │       ├── postgres/
│   │       │   ├── walk_repository.go
│   │       │   ├── user_repository.go
│   │       │   └── photo_repository.go
│   │       └── storage/
│   │           └── gcs_storage.go
│   ├── infrastructure/             # インフラ層
│   │   ├── config/
│   │   │   └── config.go          # 設定管理
│   │   ├── database/
│   │   │   └── postgres.go        # DB接続
│   │   ├── auth/
│   │   │   └── firebase.go        # Firebase Auth
│   │   ├── logger/
│   │   │   └── logger.go          # ロガー
│   │   └── telemetry/
│   │       ├── metrics.go         # メトリクス
│   │       └── tracing.go         # トレーシング
│   └── pkg/                        # 共通パッケージ
│       ├── errors/
│       │   └── errors.go          # カスタムエラー
│       ├── validator/
│       │   └── validator.go       # バリデーション
│       └── pagination/
│           └── cursor.go          # カーソルページネーション
├── api/
│   └── openapi.yaml               # OpenAPI仕様書
├── migrations/
│   ├── 001_create_users.up.sql
│   ├── 001_create_users.down.sql
│   ├── 002_create_walks.up.sql
│   └── ...
├── scripts/
│   ├── migrate.sh                 # マイグレーションスクリプト
│   └── seed.sh                    # シードデータ投入
├── deploy/
│   ├── Dockerfile
│   ├── cloudbuild.yaml           # Cloud Build設定
│   └── terraform/                # Terraform IaC
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── .github/
│   └── workflows/
│       ├── test.yaml
│       ├── lint.yaml
│       └── deploy.yaml
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

## 依存ライブラリ

### コア依存

```go
// go.mod
module github.com/RRRRRRR-777/TekuToko/backend

go 1.21

require (
    // HTTP Router
    github.com/go-chi/chi/v5 v5.0.11

    // Database
    github.com/jackc/pgx/v5 v5.5.1
    github.com/jmoiron/sqlx v1.3.5

    // Migration
    github.com/golang-migrate/migrate/v4 v4.17.0

    // Firebase Admin SDK
    firebase.google.com/go/v4 v4.13.0
    google.golang.org/api v0.150.0

    // Cloud Client Libraries
    cloud.google.com/go/storage v1.35.1
    cloud.google.com/go/cloudsqlconn v1.5.1

    // Logging
    go.uber.org/zap v1.26.0

    // Validation
    github.com/go-playground/validator/v10 v10.16.0

    // Config
    github.com/kelseyhightower/envconfig v1.4.0

    // Testing
    github.com/stretchr/testify v1.8.4
    github.com/DATA-DOG/go-sqlmock v1.5.2
)
```

## レイヤー責務

### 1. Domain層（internal/domain）

**責務**: ビジネスロジックの中核

```go
// internal/domain/walk/walk.go
package walk

import (
    "time"
    "github.com/google/uuid"
)

type Walk struct {
    ID                  uuid.UUID
    UserID              string
    Title               string
    Description         string
    StartTime           *time.Time
    EndTime             *time.Time
    TotalDistance       float64
    TotalSteps          int
    PolylineData        *string
    ThumbnailImageURL   *string
    Status              Status
    PausedAt            *time.Time
    TotalPausedDuration time.Duration
    CreatedAt           time.Time
    UpdatedAt           time.Time
}

type Status string

const (
    StatusNotStarted Status = "not_started"
    StatusInProgress Status = "in_progress"
    StatusPaused     Status = "paused"
    StatusCompleted  Status = "completed"
)

// ビジネスルール
func (w *Walk) Start() error {
    if w.Status != StatusNotStarted {
        return ErrWalkAlreadyStarted
    }
    now := time.Now()
    w.StartTime = &now
    w.Status = StatusInProgress
    w.UpdatedAt = now
    return nil
}

func (w *Walk) Complete() error {
    if w.Status != StatusInProgress && w.Status != StatusPaused {
        return ErrWalkNotInProgress
    }
    now := time.Now()
    w.EndTime = &now
    w.Status = StatusCompleted
    w.UpdatedAt = now
    return nil
}

// Repository interface
type Repository interface {
    Create(ctx context.Context, walk *Walk) error
    FindByID(ctx context.Context, id uuid.UUID) (*Walk, error)
    FindByUserID(ctx context.Context, userID string, cursor *Cursor) ([]*Walk, error)
    Update(ctx context.Context, walk *Walk) error
    Delete(ctx context.Context, id uuid.UUID) error
}
```

### 2. Usecase層（internal/usecase）

**責務**: アプリケーションロジック、トランザクション管理

```go
// internal/usecase/walk/create_walk.go
package walk

import (
    "context"
    "github.com/google/uuid"
    "github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
)

type CreateWalkInput struct {
    UserID      string
    Title       string
    Description string
}

type CreateWalkOutput struct {
    Walk *walk.Walk
}

type CreateWalkUsecase struct {
    walkRepo walk.Repository
}

func NewCreateWalkUsecase(walkRepo walk.Repository) *CreateWalkUsecase {
    return &CreateWalkUsecase{walkRepo: walkRepo}
}

func (uc *CreateWalkUsecase) Execute(
    ctx context.Context,
    input CreateWalkInput,
) (*CreateWalkOutput, error) {
    // バリデーション
    if err := uc.validate(input); err != nil {
        return nil, err
    }

    // ドメインオブジェクト生成
    newWalk := &walk.Walk{
        ID:          uuid.New(),
        UserID:      input.UserID,
        Title:       input.Title,
        Description: input.Description,
        Status:      walk.StatusNotStarted,
    }

    // 永続化
    if err := uc.walkRepo.Create(ctx, newWalk); err != nil {
        return nil, err
    }

    return &CreateWalkOutput{Walk: newWalk}, nil
}

func (uc *CreateWalkUsecase) validate(input CreateWalkInput) error {
    // バリデーションロジック
    return nil
}
```

### 3. Interface層（internal/interface）

**責務**: HTTP API、データアクセス実装

```go
// internal/interface/api/handler/walk_handler.go
package handler

import (
    "net/http"
    "github.com/go-chi/chi/v5"
    "github.com/RRRRRRR-777/TekuToko/backend/internal/usecase/walk"
)

type WalkHandler struct {
    createWalkUC *walk.CreateWalkUsecase
    getWalkUC    *walk.GetWalkUsecase
    // ...
}

func NewWalkHandler(
    createWalkUC *walk.CreateWalkUsecase,
    getWalkUC *walk.GetWalkUsecase,
) *WalkHandler {
    return &WalkHandler{
        createWalkUC: createWalkUC,
        getWalkUC:    getWalkUC,
    }
}

func (h *WalkHandler) CreateWalk(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    // リクエストボディ解析
    var req CreateWalkRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, "Invalid request body")
        return
    }

    // 認証ユーザー取得
    userID := GetUserIDFromContext(ctx)

    // ユースケース実行
    output, err := h.createWalkUC.Execute(ctx, walk.CreateWalkInput{
        UserID:      userID,
        Title:       req.Title,
        Description: req.Description,
    })
    if err != nil {
        respondError(w, http.StatusInternalServerError, err.Error())
        return
    }

    // レスポンス整形
    respondJSON(w, http.StatusCreated, map[string]interface{}{
        "data": toWalkResponse(output.Walk),
        "meta": meta{
            RequestID: GetRequestIDFromContext(ctx),
            Timestamp: time.Now(),
        },
    })
}
```

### 4. Infrastructure層（internal/infrastructure）

**責務**: 外部システム連携

```go
// internal/infrastructure/database/postgres.go
package database

import (
    "context"
    "cloud.google.com/go/cloudsqlconn"
    "github.com/jackc/pgx/v5/pgxpool"
)

func NewPostgresDB(ctx context.Context, cfg Config) (*pgxpool.Pool, error) {
    // Cloud SQL Connector設定
    d, err := cloudsqlconn.NewDialer(ctx)
    if err != nil {
        return nil, err
    }

    // 接続文字列構築
    dsn := fmt.Sprintf(
        "host=%s user=%s password=%s dbname=%s sslmode=disable",
        cfg.InstanceConnectionName,
        cfg.User,
        cfg.Password,
        cfg.Database,
    )

    // 接続プール設定
    config, err := pgxpool.ParseConfig(dsn)
    if err != nil {
        return nil, err
    }

    config.MaxConns = 25
    config.MinConns = 5
    config.MaxConnLifetime = 5 * time.Minute

    // 接続プール作成
    pool, err := pgxpool.NewWithConfig(ctx, config)
    if err != nil {
        return nil, err
    }

    // 接続確認
    if err := pool.Ping(ctx); err != nil {
        return nil, err
    }

    return pool, nil
}
```

## ミドルウェア設計

### 認証ミドルウェア

```go
// internal/interface/api/middleware/auth.go
package middleware

import (
    "context"
    "net/http"
    "strings"
    firebase "firebase.google.com/go/v4"
)

type AuthMiddleware struct {
    firebaseApp *firebase.App
}

func (m *AuthMiddleware) Authenticate(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Authorizationヘッダー取得
        authHeader := r.Header.Get("Authorization")
        if authHeader == "" {
            http.Error(w, "Missing authorization header", http.StatusUnauthorized)
            return
        }

        // Bearer Token抽出
        token := strings.TrimPrefix(authHeader, "Bearer ")
        if token == authHeader {
            http.Error(w, "Invalid authorization format", http.StatusUnauthorized)
            return
        }

        // Firebase ID Token検証
        client, _ := m.firebaseApp.Auth(r.Context())
        idToken, err := client.VerifyIDToken(r.Context(), token)
        if err != nil {
            http.Error(w, "Invalid token", http.StatusUnauthorized)
            return
        }

        // コンテキストにユーザーID設定
        ctx := context.WithValue(r.Context(), "user_id", idToken.UID)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

## エラーハンドリング

```go
// internal/pkg/errors/errors.go
package errors

type AppError struct {
    Code       string
    Message    string
    StatusCode int
    Err        error
}

func (e *AppError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("%s: %v", e.Message, e.Err)
    }
    return e.Message
}

// 定義済みエラー
var (
    ErrNotFound = &AppError{
        Code:       "NOT_FOUND",
        Message:    "Resource not found",
        StatusCode: http.StatusNotFound,
    }

    ErrUnauthorized = &AppError{
        Code:       "UNAUTHORIZED",
        Message:    "Unauthorized access",
        StatusCode: http.StatusUnauthorized,
    }

    ErrInvalidRequest = &AppError{
        Code:       "INVALID_REQUEST",
        Message:    "Invalid request",
        StatusCode: http.StatusBadRequest,
    }
)
```

## 設定管理

```go
// internal/infrastructure/config/config.go
package config

import "github.com/kelseyhightower/envconfig"

type Config struct {
    Environment string `envconfig:"ENVIRONMENT" default:"development"`
    Port        int    `envconfig:"PORT" default:"8080"`

    Database DatabaseConfig
    Firebase FirebaseConfig
    Storage  StorageConfig
}

type DatabaseConfig struct {
    InstanceConnectionName string `envconfig:"DB_INSTANCE_CONNECTION_NAME" required:"true"`
    User                   string `envconfig:"DB_USER" required:"true"`
    Password               string `envconfig:"DB_PASSWORD" required:"true"`
    Database               string `envconfig:"DB_NAME" default:"tekutoko"`
}

type FirebaseConfig struct {
    ProjectID string `envconfig:"FIREBASE_PROJECT_ID" required:"true"`
}

type StorageConfig struct {
    BucketName string `envconfig:"GCS_BUCKET_NAME" required:"true"`
}

func Load() (*Config, error) {
    var cfg Config
    if err := envconfig.Process("", &cfg); err != nil {
        return nil, err
    }
    return &cfg, nil
}
```

## テスト戦略

### ユニットテスト

```go
// internal/usecase/walk/create_walk_test.go
package walk_test

import (
    "context"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

type MockWalkRepository struct {
    mock.Mock
}

func (m *MockWalkRepository) Create(ctx context.Context, walk *walk.Walk) error {
    args := m.Called(ctx, walk)
    return args.Error(0)
}

func TestCreateWalkUsecase_Execute(t *testing.T) {
    // Setup
    mockRepo := new(MockWalkRepository)
    uc := walk.NewCreateWalkUsecase(mockRepo)

    input := walk.CreateWalkInput{
        UserID:      "user123",
        Title:       "朝の散歩",
        Description: "公園を散歩",
    }

    mockRepo.On("Create", mock.Anything, mock.Anything).Return(nil)

    // Execute
    output, err := uc.Execute(context.Background(), input)

    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, output.Walk)
    assert.Equal(t, input.Title, output.Walk.Title)
    mockRepo.AssertExpectations(t)
}
```

## Makefile

```makefile
.PHONY: help test lint build run migrate

help: ## ヘルプ表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

test: ## テスト実行
	go test -v -race -coverprofile=coverage.out ./...

lint: ## Lint実行
	golangci-lint run ./...

build: ## ビルド
	go build -o bin/api cmd/api/main.go

run: ## ローカル実行
	go run cmd/api/main.go

migrate-up: ## マイグレーション適用
	migrate -path migrations -database "${DATABASE_URL}" up

migrate-down: ## マイグレーションロールバック
	migrate -path migrations -database "${DATABASE_URL}" down 1

docker-build: ## Dockerイメージビルド
	docker build -t tekutoko-api:latest -f deploy/Dockerfile .
```

## iOS側統合設計

### Repository抽象化層

**目的**: Firebase/Goバックエンドを切り替え可能にする

#### Protocol定義
```swift
// TekuToko/Model/Services/Protocol/WalkRepository.swift
protocol WalkRepository {
    func create(_ walk: Walk) async throws -> Walk
    func fetch(id: UUID) async throws -> Walk
    func fetchByUser(userId: String, cursor: String?) async throws -> ([Walk], String?)
    func update(_ walk: Walk) async throws -> Walk
    func delete(id: UUID) async throws
}
```

#### Firebase実装（既存）
```swift
// TekuToko/Model/Services/WalkRepository.swift
// 既存のFirebaseWalkRepositoryをリネーム
class FirebaseWalkRepository: WalkRepository {
    private let db = Firestore.firestore()

    func create(_ walk: Walk) async throws -> Walk {
        // 既存のFirestore実装を維持
    }
}
```

#### Go Backend実装（新規）
```swift
// TekuToko/Model/Services/GoBackendWalkRepository.swift
class GoBackendWalkRepository: WalkRepository {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "https://api.tekutoko.app/v1") {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    func create(_ walk: Walk) async throws -> Walk {
        let url = URL(string: "\(baseURL)/walks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(try await getIdToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = WalkCreateRequest(
            title: walk.title,
            description: walk.description
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let apiResponse = try JSONDecoder().decode(WalkAPIResponse.self, from: data)
        return apiResponse.data
    }

    // 他のメソッドも同様に実装
}
```

#### Factory Pattern
```swift
// TekuToko/Model/Services/WalkRepositoryFactory.swift
class WalkRepositoryFactory {
    static func create() -> WalkRepository {
        if FeatureFlags.useGoBackend {
            return GoBackendWalkRepository()
        } else {
            return FirebaseWalkRepository()
        }
    }
}
```

#### Feature Flag管理
```swift
// TekuToko/Model/Services/FeatureFlags.swift
import FirebaseRemoteConfig

struct FeatureFlags {
    private static let remoteConfig = RemoteConfig.remoteConfig()

    static var useGoBackend: Bool {
        #if DEBUG
        // 開発時はUserDefaultsで手動切り替え
        return UserDefaults.standard.bool(forKey: "use_go_backend")
        #else
        // 本番はFirebase Remote Configで動的制御
        return remoteConfig["use_go_backend"].boolValue
        #endif
    }

    // 機能ごとのFlag
    static var useGoBackendForWalks: Bool {
        remoteConfig["go_backend_walks"].boolValue
    }

    static var useGoBackendForPhotos: Bool {
        remoteConfig["go_backend_photos"].boolValue
    }
}
```

#### 既存コードの変更
```swift
// TekuToko/Model/Services/WalkManager.swift
class WalkManager {
    // 変更前
    // private let repository = WalkRepository()

    // 変更後
    private let repository: WalkRepository

    init(repository: WalkRepository = WalkRepositoryFactory.create()) {
        self.repository = repository
    }
}
```

### Phase2での実装タスク

#### iOS側作業
1. `WalkRepository` プロトコル定義
2. `FirebaseWalkRepository` リファクタリング（既存コードをProtocol準拠に）
3. `GoBackendWalkRepository` 実装
4. `WalkRepositoryFactory` 実装
5. `FeatureFlags` 実装
6. `WalkManager` 等のDI対応
7. 単体テスト追加（Mock Repository使用）

#### 工数見積もり
- Protocol定義: 0.5日
- Firebase実装リファクタ: 1日
- Go Backend実装: 2日
- Factory/Feature Flag: 0.5日
- 既存コード修正: 1日
- テスト: 1日
- **合計**: 6日

## 関連ドキュメント
- [API設計書](./openapi.yaml)
- [データベーススキーマ](./database-schema.md)
- [デプロイアーキテクチャ](./deployment-architecture.md)
- [要件定義書 - データ移行戦略](./requirements.md#3-データ移行制約)
