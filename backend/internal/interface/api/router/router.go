package router

import (
	"net/http"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
)

// NewRouter はHTTPルーターを生成する
func NewRouter(container *di.Container) http.Handler {
	mux := http.NewServeMux()

	// ヘルスチェックエンドポイント
	mux.HandleFunc("/health", healthCheckHandler)
	mux.HandleFunc("/ready", readinessCheckHandler(container))

	// ルートエンドポイント
	mux.HandleFunc("/", rootHandler)

	// TODO: Phase2で実装
	// - /v1/walks エンドポイント
	// - 認証ミドルウェア
	// - ロギングミドルウェア
	// - CORS設定

	return mux
}

func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"ok","message":"TekuToko API is running"}`))
}

func readinessCheckHandler(container *di.Container) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// データベース接続チェック
		if err := container.DB.HealthCheck(r.Context()); err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusServiceUnavailable)
			_, _ = w.Write([]byte(`{"status":"not_ready","message":"Database not ready"}`))
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ready","message":"TekuToko API is ready"}`))
	}
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"message":"Welcome to TekuToko API","version":"0.1.0","status":"Phase 2 in progress"}`))
}
