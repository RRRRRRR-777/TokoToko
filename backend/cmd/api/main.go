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

	// 簡易ルーター設定（Phase2で本格実装予定）
	mux := http.NewServeMux()

	// ヘルスチェックエンドポイント
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `{"status":"ok","message":"TekuToko API is running"}`)
	})

	// ルートエンドポイント
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `{"message":"Welcome to TekuToko API","version":"0.1.0","status":"Phase 2 in progress"}`)
	})

	// HTTPサーバー設定
	server := &http.Server{
		Addr:              fmt.Sprintf(":%s", port),
		Handler:           mux,
		ReadHeaderTimeout: readHeaderTimeout,
	}

	// Graceful Shutdown設定
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// サーバー起動（ゴルーチン）
	go func() {
		logger.Printf("Server started on http://localhost:%s", port)
		logger.Println("Available endpoints:")
		logger.Println("  GET /        - API情報")
		logger.Println("  GET /health  - ヘルスチェック")
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
