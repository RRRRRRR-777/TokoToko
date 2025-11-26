package middleware

import (
	"context"
	"net"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// RateLimiter はIPアドレスベースのレート制限を提供
type RateLimiter struct {
	mu          sync.RWMutex
	requests    map[string]*requestInfo
	maxRequests int
	window      time.Duration
	stopCh      chan struct{}
}

type requestInfo struct {
	count     int
	windowEnd time.Time
}

// NewRateLimiter は新しいRateLimiterを作成
// Deprecated: NewRateLimiterWithContext を使用してください
func NewRateLimiter(maxRequests int, window time.Duration) *RateLimiter {
	return NewRateLimiterWithContext(context.Background(), maxRequests, window)
}

// NewRateLimiterWithContext はコンテキスト付きで新しいRateLimiterを作成
// コンテキストがキャンセルされると、バックグラウンドのクリーンアップgoroutineが停止します
func NewRateLimiterWithContext(ctx context.Context, maxRequests int, window time.Duration) *RateLimiter {
	rl := &RateLimiter{
		requests:    make(map[string]*requestInfo),
		maxRequests: maxRequests,
		window:      window,
		stopCh:      make(chan struct{}),
	}

	// 定期的に期限切れエントリをクリーンアップ
	go rl.cleanup(ctx)

	return rl
}

// Stop はバックグラウンドのクリーンアップgoroutineを停止
func (rl *RateLimiter) Stop() {
	close(rl.stopCh)
}

// Allow は指定されたIPからのリクエストを許可するかどうかを判定
func (rl *RateLimiter) Allow(ip string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	info, exists := rl.requests[ip]

	if !exists || now.After(info.windowEnd) {
		// 新しいウィンドウを開始
		rl.requests[ip] = &requestInfo{
			count:     1,
			windowEnd: now.Add(rl.window),
		}
		return true
	}

	if info.count >= rl.maxRequests {
		return false
	}

	info.count++
	return true
}

// GetRetryAfter は次のリクエストが許可されるまでの秒数を返す
func (rl *RateLimiter) GetRetryAfter(ip string) int {
	rl.mu.RLock()
	defer rl.mu.RUnlock()

	info, exists := rl.requests[ip]
	if !exists {
		return 0
	}

	remaining := time.Until(info.windowEnd)
	if remaining <= 0 {
		return 0
	}

	return int(remaining.Seconds()) + 1
}

// cleanup は期限切れエントリを定期的に削除
func (rl *RateLimiter) cleanup(ctx context.Context) {
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-rl.stopCh:
			return
		case <-ticker.C:
			rl.mu.Lock()
			now := time.Now()
			for ip, info := range rl.requests {
				if now.After(info.windowEnd) {
					delete(rl.requests, ip)
				}
			}
			rl.mu.Unlock()
		}
	}
}

// RateLimitMiddleware はGin用のレート制限ミドルウェア
func RateLimitMiddleware(rl *RateLimiter) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := getClientIP(c)

		if !rl.Allow(ip) {
			retryAfter := rl.GetRetryAfter(ip)
			c.Header("Retry-After", strconv.Itoa(retryAfter))
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Too many requests. Please wait before retrying.",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// getClientIP はリクエストからクライアントIPを取得
func getClientIP(c *gin.Context) string {
	// X-Forwarded-For ヘッダーを確認（プロキシ経由の場合）
	if xff := c.GetHeader("X-Forwarded-For"); xff != "" {
		// 最初のIPを取得（クライアントの実際のIP）
		ips := strings.Split(xff, ",")
		if len(ips) > 0 {
			ip := strings.TrimSpace(ips[0])
			if ip != "" {
				return ip
			}
		}
	}

	// X-Real-IP ヘッダーを確認
	if xri := c.GetHeader("X-Real-IP"); xri != "" {
		return strings.TrimSpace(xri)
	}

	// RemoteAddr からIPを抽出
	ip, _, err := net.SplitHostPort(c.Request.RemoteAddr)
	if err != nil {
		return c.Request.RemoteAddr
	}

	return ip
}
