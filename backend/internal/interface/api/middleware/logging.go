package middleware

import (
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/logger"
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/trace"
	"go.uber.org/zap"
)

// LoggingMiddleware はHTTPリクエスト/レスポンスを構造化ログに記録するミドルウェア
func LoggingMiddleware(log logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// リクエスト開始時刻
		start := time.Now()

		// リクエストパス
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		// リクエスト処理
		c.Next()

		// レスポンス情報
		latency := time.Since(start)
		statusCode := c.Writer.Status()
		method := c.Request.Method
		clientIP := c.ClientIP()

		// ログフィールド
		fields := []zap.Field{
			zap.String("method", method),
			zap.String("path", path),
			zap.String("query", query),
			zap.Int("status", statusCode),
			zap.Duration("latency", latency),
			zap.String("client_ip", clientIP),
			zap.String("user_agent", c.Request.UserAgent()),
		}

		// トレースIDがある場合は追加（Cloud LoggingとCloud Traceの相関）
		if spanContext := trace.SpanContextFromContext(c.Request.Context()); spanContext.IsValid() {
			fields = append(fields,
				zap.String("trace_id", spanContext.TraceID().String()),
				zap.String("span_id", spanContext.SpanID().String()),
			)
		}

		// エラーがある場合は追加
		if len(c.Errors) > 0 {
			fields = append(fields, zap.String("errors", c.Errors.String()))
		}

		// ステータスコードに応じてログレベルを変更
		switch {
		case statusCode >= 500:
			log.Error("HTTP request completed with server error", fields...)
		case statusCode >= 400:
			log.Warn("HTTP request completed with client error", fields...)
		default:
			log.Info("HTTP request completed", fields...)
		}
	}
}
