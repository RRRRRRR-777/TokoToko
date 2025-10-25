package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"
)

const (
	defaultPort         = "8080"
	shutdownTimeout     = 10 * time.Second
	readHeaderTimeout   = 10 * time.Second
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

	// TODO: Phase2で実装
	// - Config読み込み (internal/infrastructure/config)
	// - Database接続 (internal/infrastructure/database)
	// - Firebase Admin SDK初期化 (internal/infrastructure/auth)
	// - Logger初期化 (internal/infrastructure/logger)
	// - Router初期化 (internal/interface/api/router)
	// - Middleware設定 (internal/interface/api/middleware)
	// - Handler登録 (internal/interface/api/handler)

	logger.Printf("Server will listen on port %s", port)

	// Graceful Shutdown設定
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// TODO: HTTPサーバー起動
	// server := &http.Server{
	// 	Addr:              fmt.Sprintf(":%s", port),
	// 	Handler:           router,
	// 	ReadHeaderTimeout: readHeaderTimeout,
	// }

	// サーバー起動（ゴルーチン）
	// go func() {
	// 	logger.Printf("Server started on port %s", port)
	// 	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
	// 		logger.Fatalf("Server failed to start: %v", err)
	// 	}
	// }()

	// シャットダウンシグナル待機
	<-ctx.Done()
	logger.Println("Shutdown signal received, starting graceful shutdown...")

	// Graceful Shutdown
	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	// TODO: サーバーシャットダウン
	// if err := server.Shutdown(shutdownCtx); err != nil {
	// 	logger.Printf("Server forced to shutdown: %v", err)
	// }

	logger.Println("Server exited")

	// 一時的なメッセージ（Phase2実装完了後は削除）
	fmt.Printf("TekuToko API server initialized (port: %s)\n", port)
	fmt.Println("Phase 2 implementation in progress...")
	fmt.Println("Waiting for shutdown signal...")

	select {
	case <-shutdownCtx.Done():
		logger.Println("Shutdown timeout exceeded")
	}
}
