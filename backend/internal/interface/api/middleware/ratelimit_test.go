package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestNewRateLimiter(t *testing.T) {
	// 期待値: RateLimiterが正常に初期化されること
	rl := NewRateLimiter(5, time.Minute)
	defer rl.Stop()

	assert.NotNil(t, rl)
	assert.Equal(t, 5, rl.maxRequests)
	assert.Equal(t, time.Minute, rl.window)
	assert.NotNil(t, rl.stopCh)
}

func TestNewRateLimiterWithContext(t *testing.T) {
	// 期待値: コンテキスト付きでRateLimiterが正常に初期化されること
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	rl := NewRateLimiterWithContext(ctx, 10, 2*time.Minute)
	defer rl.Stop()

	assert.NotNil(t, rl)
	assert.Equal(t, 10, rl.maxRequests)
	assert.Equal(t, 2*time.Minute, rl.window)
}

func TestRateLimiterWithContext_ContextCancellation(t *testing.T) {
	// 期待値: コンテキストがキャンセルされるとクリーンアップgoroutineが停止すること
	ctx, cancel := context.WithCancel(context.Background())

	rl := NewRateLimiterWithContext(ctx, 5, time.Minute)

	// リクエストを追加
	rl.Allow("192.168.1.1")
	assert.Equal(t, 1, len(rl.requests))

	// コンテキストをキャンセル
	cancel()

	// goroutineが停止する時間を待つ
	time.Sleep(50 * time.Millisecond)

	// RateLimiterは引き続き使用可能（クリーンアップが停止しただけ）
	assert.True(t, rl.Allow("192.168.1.2"))
}

func TestRateLimiter_Stop(t *testing.T) {
	// 期待値: Stop()でクリーンアップgoroutineが停止すること
	rl := NewRateLimiter(5, time.Minute)

	// リクエストを追加
	rl.Allow("192.168.1.1")

	// Stopを呼び出し
	rl.Stop()

	// goroutineが停止する時間を待つ
	time.Sleep(50 * time.Millisecond)

	// RateLimiterは引き続き使用可能
	assert.True(t, rl.Allow("192.168.1.2"))
}

func TestRateLimiter_Allow_UnderLimit(t *testing.T) {
	// 期待値: 制限内のリクエストは許可されること
	rl := NewRateLimiter(5, time.Minute)
	defer rl.Stop()
	ip := "192.168.1.1"

	// 5回のリクエストはすべて許可される
	for i := 0; i < 5; i++ {
		allowed := rl.Allow(ip)
		assert.True(t, allowed, "Request %d should be allowed", i+1)
	}
}

func TestRateLimiter_Allow_OverLimit(t *testing.T) {
	// 期待値: 制限を超えたリクエストは拒否されること
	rl := NewRateLimiter(5, time.Minute)
	defer rl.Stop()
	ip := "192.168.1.1"

	// 5回のリクエストを消費
	for i := 0; i < 5; i++ {
		rl.Allow(ip)
	}

	// 6回目のリクエストは拒否される
	allowed := rl.Allow(ip)
	assert.False(t, allowed, "6th request should be denied")
}

func TestRateLimiter_Allow_DifferentIPs(t *testing.T) {
	// 期待値: 異なるIPアドレスは独立してカウントされること
	rl := NewRateLimiter(2, time.Minute)
	defer rl.Stop()
	ip1 := "192.168.1.1"
	ip2 := "192.168.1.2"

	// IP1で2回リクエスト
	assert.True(t, rl.Allow(ip1))
	assert.True(t, rl.Allow(ip1))
	assert.False(t, rl.Allow(ip1)) // 3回目は拒否

	// IP2はまだ制限に達していない
	assert.True(t, rl.Allow(ip2))
	assert.True(t, rl.Allow(ip2))
}

func TestRateLimiter_Allow_WindowExpiration(t *testing.T) {
	// 期待値: ウィンドウが期限切れになるとカウントがリセットされること
	rl := NewRateLimiter(2, 100*time.Millisecond)
	defer rl.Stop()
	ip := "192.168.1.1"

	// 2回のリクエストを消費
	assert.True(t, rl.Allow(ip))
	assert.True(t, rl.Allow(ip))
	assert.False(t, rl.Allow(ip)) // 3回目は拒否

	// ウィンドウが期限切れになるまで待機
	time.Sleep(150 * time.Millisecond)

	// 新しいウィンドウでリクエストが許可される
	assert.True(t, rl.Allow(ip))
}

func TestRateLimitMiddleware_AllowedRequest(t *testing.T) {
	// 期待値: 制限内のリクエストは正常に処理されること
	gin.SetMode(gin.TestMode)

	rl := NewRateLimiter(5, time.Minute)
	defer rl.Stop()
	router := gin.New()
	router.Use(RateLimitMiddleware(rl))
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.RemoteAddr = "192.168.1.1:12345"

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRateLimitMiddleware_BlockedRequest(t *testing.T) {
	// 期待値: 制限を超えたリクエストは429を返すこと
	gin.SetMode(gin.TestMode)

	rl := NewRateLimiter(2, time.Minute)
	defer rl.Stop()
	router := gin.New()
	router.Use(RateLimitMiddleware(rl))
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// 2回のリクエストを消費
	for i := 0; i < 2; i++ {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.1:12345"
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code)
	}

	// 3回目のリクエストは429を返す
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.RemoteAddr = "192.168.1.1:12345"
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusTooManyRequests, w.Code)
}

func TestRateLimitMiddleware_ErrorResponseFormat(t *testing.T) {
	// 期待値: エラーレスポンスが正しい形式であること
	gin.SetMode(gin.TestMode)

	rl := NewRateLimiter(1, time.Minute)
	defer rl.Stop()
	router := gin.New()
	router.Use(RateLimitMiddleware(rl))
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// 1回目のリクエスト
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.RemoteAddr = "192.168.1.1:12345"
	router.ServeHTTP(w, req)

	// 2回目のリクエスト（制限超過）
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/test", nil)
	req.RemoteAddr = "192.168.1.1:12345"
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusTooManyRequests, w.Code)
	assert.Contains(t, w.Body.String(), `"error"`)
	assert.Contains(t, w.Body.String(), "Too many requests")
}

func TestRateLimitMiddleware_RetryAfterHeader(t *testing.T) {
	// 期待値: 429レスポンスにRetry-Afterヘッダーが含まれること
	gin.SetMode(gin.TestMode)

	rl := NewRateLimiter(1, time.Minute)
	defer rl.Stop()
	router := gin.New()
	router.Use(RateLimitMiddleware(rl))
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// 1回目のリクエスト
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.RemoteAddr = "192.168.1.1:12345"
	router.ServeHTTP(w, req)

	// 2回目のリクエスト（制限超過）
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/test", nil)
	req.RemoteAddr = "192.168.1.1:12345"
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusTooManyRequests, w.Code)
	assert.NotEmpty(t, w.Header().Get("Retry-After"))
}

func TestRateLimitMiddleware_XForwardedFor(t *testing.T) {
	// 期待値: X-Forwarded-ForヘッダーからIPを取得すること
	gin.SetMode(gin.TestMode)

	rl := NewRateLimiter(1, time.Minute)
	defer rl.Stop()
	router := gin.New()
	router.Use(RateLimitMiddleware(rl))
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// X-Forwarded-For付きのリクエスト
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.RemoteAddr = "10.0.0.1:12345"
	req.Header.Set("X-Forwarded-For", "203.0.113.195, 70.41.3.18, 150.172.238.178")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	// 同じX-Forwarded-Forからの2回目のリクエストは拒否
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/test", nil)
	req.RemoteAddr = "10.0.0.2:12345" // 異なるRemoteAddr
	req.Header.Set("X-Forwarded-For", "203.0.113.195, 70.41.3.18, 150.172.238.178")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusTooManyRequests, w.Code)
}

func TestGetClientIP(t *testing.T) {
	// 期待値: クライアントIPが正しく抽出されること
	tests := []struct {
		name          string
		remoteAddr    string
		xForwardedFor string
		xRealIP       string
		expectedIP    string
	}{
		{
			name:       "RemoteAddrのみ",
			remoteAddr: "192.168.1.1:12345",
			expectedIP: "192.168.1.1",
		},
		{
			name:          "X-Forwarded-For優先",
			remoteAddr:    "10.0.0.1:12345",
			xForwardedFor: "203.0.113.195, 70.41.3.18",
			expectedIP:    "203.0.113.195",
		},
		{
			name:       "X-Real-IP優先",
			remoteAddr: "10.0.0.1:12345",
			xRealIP:    "203.0.113.100",
			expectedIP: "203.0.113.100",
		},
		{
			name:          "X-Forwarded-ForがX-Real-IPより優先",
			remoteAddr:    "10.0.0.1:12345",
			xForwardedFor: "203.0.113.195",
			xRealIP:       "203.0.113.100",
			expectedIP:    "203.0.113.195",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gin.SetMode(gin.TestMode)
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)
			c.Request, _ = http.NewRequest("GET", "/test", nil)
			c.Request.RemoteAddr = tt.remoteAddr
			if tt.xForwardedFor != "" {
				c.Request.Header.Set("X-Forwarded-For", tt.xForwardedFor)
			}
			if tt.xRealIP != "" {
				c.Request.Header.Set("X-Real-IP", tt.xRealIP)
			}

			ip := getClientIP(c)
			assert.Equal(t, tt.expectedIP, ip)
		})
	}
}
