package di

import (
	"context"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/config"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/database"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/logger"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/telemetry"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/middleware"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/persistence/postgres"
	walkusecase "github.com/RRRRRRR-777/TekuToko/backend/internal/usecase/walk"
)

// Container は依存性注入コンテナ
// アプリケーション全体で使用される依存関係を管理する
type Container struct {
	Config          *config.Config
	DB              *database.PostgresDB
	Logger          logger.Logger
	MetricsProvider *telemetry.MetricsProvider
	AuthMiddleware  *middleware.AuthMiddleware
	WalkRepository  walk.Repository
	WalkUsecase     walkusecase.Usecase
}

// NewContainer は新しいコンテナを生成する
func NewContainer(ctx context.Context) (*Container, error) {
	// 設定読み込み
	cfg, err := config.Load()
	if err != nil {
		return nil, err
	}

	// Logger初期化
	log, err := logger.NewLogger(cfg.Log.Level, cfg.Log.Format)
	if err != nil {
		return nil, err
	}

	// メトリクスプロバイダー初期化
	metricsProvider, err := telemetry.NewMetricsProvider(
		ctx,
		cfg.Firebase.ProjectID, // GCPプロジェクトID
		"tekutoko-api",         // サービス名
		cfg.Environment,        // 環境
		log,
	)
	if err != nil {
		return nil, err
	}

	// Database接続
	db, err := database.NewPostgresDB(cfg)
	if err != nil {
		return nil, err
	}

	// AuthMiddleware初期化
	// Firebase認証情報は環境変数から取得（開発環境では空文字列でも動作）
	authMw, err := middleware.NewAuthMiddleware(ctx, cfg.Firebase.CredentialsJSON)
	if err != nil {
		return nil, err
	}

	// Repository初期化
	walkRepo := postgres.NewWalkRepository(db.DB)

	// Usecase初期化
	walkUsecase := walkusecase.NewInteractor(walkRepo)

	return &Container{
		Config:          cfg,
		DB:              db,
		Logger:          log,
		MetricsProvider: metricsProvider,
		AuthMiddleware:  authMw,
		WalkRepository:  walkRepo,
		WalkUsecase:     walkUsecase,
	}, nil
}

// Close はコンテナが保持するリソースを解放する
func (c *Container) Close() error {
	// メトリクスプロバイダーのシャットダウン
	if c.MetricsProvider != nil {
		if err := c.MetricsProvider.Shutdown(context.Background()); err != nil {
			c.Logger.Error("Failed to shutdown metrics provider")
		}
	}

	// DBクローズ
	if c.DB != nil {
		return c.DB.Close()
	}
	return nil
}
