package middleware

import (
	"log"
	"net/http"
	"time"
)

// Logger はHTTPリクエストをログ出力するミドルウェア
func Logger(logger *log.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()

			// リクエスト処理
			next.ServeHTTP(w, r)

			// ログ出力
			logger.Printf(
				"%s %s %s %v",
				r.Method,
				r.RequestURI,
				r.RemoteAddr,
				time.Since(start),
			)
		})
	}
}

// Recovery はパニックを回復するミドルウェア
func Recovery(logger *log.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if err := recover(); err != nil {
					logger.Printf("Panic recovered: %v", err)
					w.WriteHeader(http.StatusInternalServerError)
					w.Write([]byte(`{"error":"Internal Server Error"}`))
				}
			}()
			next.ServeHTTP(w, r)
		})
	}
}

// CORS はCORSヘッダーを設定するミドルウェア
func CORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
