package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/router"
)

const (
	defaultPort       = "8080"
	shutdownTimeout   = 10 * time.Second
	readHeaderTimeout = 10 * time.Second
)

func main() {
	// ログ初期化
	logger := log.New(os.Stdout, "[TekuToko API] ", log.LstdFlags|log.Lshortfile)
	logger.Println("Starting TekuToko API server...")

	// 環境変数からポート取得
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	// DI Container初期化
	ctx := context.Background()
	container, err := di.NewContainer(ctx)
	if err != nil {
		logger.Fatalf("Failed to initialize container: %v", err)
	}
	defer container.Close()

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
		logger.Printf("Server started on http://localhost:%s", port)
		logger.Println("Available endpoints:")
		logger.Println("  GET /          - API情報")
		logger.Println("  GET /health    - ヘルスチェック（Liveness Probe）")
		logger.Println("  GET /ready     - レディネスチェック（Readiness Probe）")
		logger.Println("  GET /v1/walks  - 散歩一覧取得")
		logger.Println("  POST /v1/walks - 散歩作成")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Server failed to start: %v", err)
		}
	}()

	// シャットダウンシグナル待機
	<-ctx.Done()
	logger.Println("Shutdown signal received, starting graceful shutdown...")

	// Graceful Shutdown
	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		logger.Printf("Server forced to shutdown: %v", err)
	}

	logger.Println("Server exited")
}
