package di

import (
	"context"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/config"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/database"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/logger"
)

// Container は依存性注入コンテナ
// アプリケーション全体で使用される依存関係を管理する
type Container struct {
	Config *config.Config
	DB     *database.PostgresDB
	Logger logger.Logger
	// TODO: Phase2で追加
	// WalkRepository walk.Repository
	// WalkUsecase    *walkusecase.Interactor
	// HTTPHandler    *handler.Handler
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

	// Database接続
	db, err := database.NewPostgresDB(cfg)
	if err != nil {
		return nil, err
	}

	// TODO: Phase2で実装
	// - WalkRepositoryの初期化
	// - WalkUsecaseの初期化
	// - HTTPHandlerの初期化

	return &Container{
		Config: cfg,
		DB:     db,
		Logger: log,
	}, nil
}

// Close はコンテナが保持するリソースを解放する
func (c *Container) Close() error {
	if c.DB != nil {
		return c.DB.Close()
	}
	return nil
}
