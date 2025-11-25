package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
)

const meterName = "tekutoko.api.http"

// MetricsMiddleware はHTTPリクエストのメトリクスを記録するミドルウェア
func MetricsMiddleware() gin.HandlerFunc {
	meter := otel.Meter(meterName)

	// メトリクス定義
	requestCounter, _ := meter.Int64Counter(
		"http.server.request.count",
		metric.WithDescription("Total number of HTTP requests"),
		metric.WithUnit("{request}"),
	)

	requestDuration, _ := meter.Float64Histogram(
		"http.server.request.duration",
		metric.WithDescription("HTTP request duration"),
		metric.WithUnit("ms"),
	)

	activeRequests, _ := meter.Int64UpDownCounter(
		"http.server.active_requests",
		metric.WithDescription("Number of active HTTP requests"),
		metric.WithUnit("{request}"),
	)

	requestSize, _ := meter.Int64Histogram(
		"http.server.request.size",
		metric.WithDescription("HTTP request size"),
		metric.WithUnit("By"),
	)

	responseSize, _ := meter.Int64Histogram(
		"http.server.response.size",
		metric.WithDescription("HTTP response size"),
		metric.WithUnit("By"),
	)

	return func(c *gin.Context) {
		start := time.Now()

		// リクエスト開始時に active requests をインクリメント
		attributes := []attribute.KeyValue{
			attribute.String("http.method", c.Request.Method),
			attribute.String("http.route", c.FullPath()),
		}
		activeRequests.Add(c.Request.Context(), 1, metric.WithAttributes(attributes...))

		// リクエストサイズ記録
		if c.Request.ContentLength > 0 {
			requestSize.Record(c.Request.Context(), c.Request.ContentLength, metric.WithAttributes(attributes...))
		}

		// リクエスト処理
		c.Next()

		// レスポンス情報
		duration := time.Since(start).Milliseconds()
		statusCode := c.Writer.Status()

		// メトリクス属性
		metricsAttributes := []attribute.KeyValue{
			attribute.String("http.method", c.Request.Method),
			attribute.String("http.route", c.FullPath()),
			attribute.Int("http.status_code", statusCode),
			attribute.String("http.status_class", statusClass(statusCode)),
		}

		// リクエストカウント
		requestCounter.Add(c.Request.Context(), 1, metric.WithAttributes(metricsAttributes...))

		// レスポンスタイム（ミリ秒）
		requestDuration.Record(c.Request.Context(), float64(duration), metric.WithAttributes(metricsAttributes...))

		// レスポンスサイズ
		responseSize.Record(c.Request.Context(), int64(c.Writer.Size()), metric.WithAttributes(metricsAttributes...))

		// リクエスト終了時に active requests をデクリメント
		activeRequests.Add(c.Request.Context(), -1, metric.WithAttributes(attributes...))
	}
}

// statusClass はHTTPステータスコードのクラス（2xx, 3xx, 4xx, 5xx）を返す
func statusClass(code int) string {
	switch {
	case code >= 200 && code < 300:
		return "2xx"
	case code >= 300 && code < 400:
		return "3xx"
	case code >= 400 && code < 500:
		return "4xx"
	case code >= 500:
		return "5xx"
	default:
		return "other"
	}
}
