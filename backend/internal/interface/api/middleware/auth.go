package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
	"google.golang.org/api/option"
)

const (
	// AuthContextKey はgin.Contextに保存されるユーザーIDのキー
	AuthContextKey = "userID"
	// TokenCacheTTL はトークンキャッシュの有効期限
	TokenCacheTTL = 5 * time.Minute
)

// FirebaseAuthClient はFirebase Auth Clientのインターフェース
type FirebaseAuthClient interface {
	VerifyIDToken(ctx context.Context, token string) (*auth.Token, error)
}

// TokenCache はトークンの検証結果をキャッシュする構造体
type TokenCache struct {
	mu              sync.RWMutex
	cache           map[string]*cacheEntry
	cleanupInterval time.Duration
	stopCleanup     chan struct{}
}

type cacheEntry struct {
	userID    string
	expiresAt time.Time
}

// NewTokenCache は新しいTokenCacheを作成する
func NewTokenCache() *TokenCache {
	return NewTokenCacheWithInterval(1 * time.Minute)
}

// NewTokenCacheWithInterval はクリーンアップ間隔を指定してTokenCacheを作成する
func NewTokenCacheWithInterval(cleanupInterval time.Duration) *TokenCache {
	tc := &TokenCache{
		cache:           make(map[string]*cacheEntry),
		cleanupInterval: cleanupInterval,
		stopCleanup:     make(chan struct{}),
	}
	// 定期的に期限切れエントリをクリーンアップ
	go tc.cleanup()
	return tc
}

// Get はキャッシュからユーザーIDを取得する
func (tc *TokenCache) Get(token string) (string, bool) {
	tc.mu.RLock()
	defer tc.mu.RUnlock()

	entry, exists := tc.cache[token]
	if !exists {
		return "", false
	}

	if time.Now().After(entry.expiresAt) {
		return "", false
	}

	return entry.userID, true
}

// Set はキャッシュにユーザーIDを保存する
func (tc *TokenCache) Set(token, userID string) {
	tc.mu.Lock()
	defer tc.mu.Unlock()

	tc.cache[token] = &cacheEntry{
		userID:    userID,
		expiresAt: time.Now().Add(TokenCacheTTL),
	}
}

// cleanup は定期的に期限切れエントリを削除する
func (tc *TokenCache) cleanup() {
	ticker := time.NewTicker(tc.cleanupInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			tc.mu.Lock()
			now := time.Now()
			for token, entry := range tc.cache {
				if now.After(entry.expiresAt) {
					delete(tc.cache, token)
				}
			}
			tc.mu.Unlock()
		case <-tc.stopCleanup:
			return
		}
	}
}

// Stop はクリーンアップゴルーチンを停止する（テスト用）
func (tc *TokenCache) Stop() {
	close(tc.stopCleanup)
}

// AuthMiddleware はFirebase IDトークンを検証するGinミドルウェア
type AuthMiddleware struct {
	authClient FirebaseAuthClient
	cache      *TokenCache
}

// NewAuthMiddleware は新しいAuthMiddlewareを作成する
func NewAuthMiddleware(ctx context.Context, credentialsJSON string) (*AuthMiddleware, error) {
	var opts []option.ClientOption

	// 認証情報が提供されている場合
	if credentialsJSON != "" {
		opts = append(opts, option.WithCredentialsJSON([]byte(credentialsJSON)))
	}

	app, err := firebase.NewApp(ctx, nil, opts...)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize firebase app: %w", err)
	}

	authClient, err := app.Auth(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get auth client: %w", err)
	}

	return &AuthMiddleware{
		authClient: authClient,
		cache:      NewTokenCache(),
	}, nil
}

// NewAuthMiddlewareWithClient はテスト用にAuthClientを注入可能なコンストラクタ
func NewAuthMiddlewareWithClient(authClient FirebaseAuthClient) *AuthMiddleware {
	return &AuthMiddleware{
		authClient: authClient,
		cache:      NewTokenCache(),
	}
}

// Handler はGinミドルウェアハンドラーを返す
func (am *AuthMiddleware) Handler() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Authorizationヘッダーからトークンを取得
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header is required",
			})
			c.Abort()
			return
		}

		// "Bearer "プレフィックスを削除
		token := strings.TrimPrefix(authHeader, "Bearer ")
		if token == authHeader {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid authorization header format",
			})
			c.Abort()
			return
		}

		// キャッシュをチェック
		if userID, found := am.cache.Get(token); found {
			c.Set(AuthContextKey, userID)
			c.Next()
			return
		}

		// トークンを検証
		idToken, err := am.authClient.VerifyIDToken(c.Request.Context(), token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid or expired token",
			})
			c.Abort()
			return
		}

		// ユーザーIDを取得
		userID := idToken.UID

		// キャッシュに保存
		am.cache.Set(token, userID)

		// コンテキストにユーザーIDを保存
		c.Set(AuthContextKey, userID)

		c.Next()
	}
}

// GetUserID はgin.Contextからユーザー IDを取得するヘルパー関数
func GetUserID(c *gin.Context) (string, error) {
	userID, exists := c.Get(AuthContextKey)
	if !exists {
		return "", fmt.Errorf("user ID not found in context")
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return "", fmt.Errorf("user ID is not a string")
	}

	return userIDStr, nil
}
