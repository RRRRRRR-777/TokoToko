package router

import (
	"net/http"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/handler"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/middleware"
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"
)

// NewRouter はHTTPルーターを生成する
func NewRouter(container *di.Container) *gin.Engine {
	// Ginのデフォルトロガーを無効化（構造化ログを使用）
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()

	// パニックリカバリーミドルウェア（標準）
	r.Use(gin.Recovery())

	// 分散トレーシングミドルウェア（最も先に適用してすべての処理をトレース）
	r.Use(otelgin.Middleware("tekutoko-api"))

	// メトリクス計装ミドルウェア（ログよりも先に適用）
	r.Use(middleware.MetricsMiddleware())

	// 構造化ログミドルウェア
	r.Use(middleware.LoggingMiddleware(container.Logger))

	// ヘルスチェックエンドポイント
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"message": "TekuToko API is running",
		})
	})

	r.GET("/ready", func(c *gin.Context) {
		// データベース接続チェック
		if err := container.DB.HealthCheck(c.Request.Context()); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status":  "not_ready",
				"message": "Database not ready",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"status":  "ready",
			"message": "TekuToko API is ready",
		})
	})

	// ルートエンドポイント
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Welcome to TekuToko API",
			"version": "0.1.0",
			"status":  "Development",
		})
	})

	// Walk API エンドポイント（認証必須）
	walkHandler := handler.NewWalkHandler(container)
	v1 := r.Group("/v1")
	{
		// 認証が必要なエンドポイント
		walks := v1.Group("/walks")
		walks.Use(container.AuthMiddleware.Handler())
		{
			walks.GET("", walkHandler.ListWalks)
			walks.POST("", walkHandler.CreateWalk)
			walks.GET("/:id", walkHandler.GetWalk)
			walks.PUT("/:id", walkHandler.UpdateWalk)
			walks.DELETE("/:id", walkHandler.DeleteWalk)
		}
	}

	// TODO: 後のフェーズで実装
	// - CORS設定 (r.Use(cors.Default()))

	return r
}
