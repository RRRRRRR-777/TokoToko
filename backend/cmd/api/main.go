package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/router"
	"go.uber.org/zap"
)

const (
	defaultPort       = "8080"
	shutdownTimeout   = 10 * time.Second
	readHeaderTimeout = 10 * time.Second
)

func main() {
	// DI Container初期化（Logger含む）
	ctx := context.Background()
	container, err := di.NewContainer(ctx)
	if err != nil {
		// Containerの初期化に失敗した場合は標準出力にエラーを出力
		fmt.Fprintf(os.Stderr, "Failed to initialize container: %v\n", err)
		os.Exit(1)
	}
	defer container.Close()

	// 構造化ロガー取得
	logger := container.Logger

	logger.Info("Starting TekuToko API server",
		zap.String("environment", container.Config.Environment),
	)

	// 環境変数からポート取得
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	// Router初期化（Gin）
	r := router.NewRouter(container)

	// HTTPサーバー設定
	server := &http.Server{
		Addr:              fmt.Sprintf(":%s", port),
		Handler:           r,
		ReadHeaderTimeout: readHeaderTimeout,
	}

	// Graceful Shutdown設定
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// サーバー起動（ゴルーチン）
	go func() {
		logger.Info("Server started",
			zap.String("port", port),
			zap.String("address", fmt.Sprintf("http://localhost:%s", port)),
		)
		logger.Info("Available endpoints",
			zap.Strings("endpoints", []string{
				"GET /          - API情報",
				"GET /health    - ヘルスチェック（Liveness Probe）",
				"GET /ready     - レディネスチェック（Readiness Probe）",
				"GET /v1/walks  - 散歩一覧取得",
				"POST /v1/walks - 散歩作成",
			}),
		)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Server failed to start", zap.Error(err))
		}
	}()

	// シャットダウンシグナル待機
	<-ctx.Done()
	logger.Info("Shutdown signal received, starting graceful shutdown")

	// Graceful Shutdown
	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		logger.Error("Server forced to shutdown", zap.Error(err))
	}

	logger.Info("Server exited")
}
