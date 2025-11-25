package middleware

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockAuthClient はFirebaseAuthClientのモック実装
type MockAuthClient struct {
	mock.Mock
}

func (m *MockAuthClient) VerifyIDToken(ctx context.Context, token string) (*auth.Token, error) {
	args := m.Called(ctx, token)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*auth.Token), args.Error(1)
}

func TestTokenCache_SetAndGet(t *testing.T) {
	// 期待値: トークンをキャッシュに保存し、正常に取得できること
	cache := NewTokenCache()

	token := "test-token"
	userID := "test-user-id"

	// Set
	cache.Set(token, userID)

	// Get - 期待値検証: 保存したユーザーIDが取得できる
	retrievedUserID, found := cache.Get(token)
	assert.True(t, found)
	assert.Equal(t, userID, retrievedUserID)
}

func TestTokenCache_GetNonExistent(t *testing.T) {
	// 期待値: 存在しないトークンの取得はfalseを返すこと
	cache := NewTokenCache()

	retrievedUserID, found := cache.Get("non-existent-token")

	// 期待値検証: 存在しないトークンはfound=false
	assert.False(t, found)
	assert.Empty(t, retrievedUserID)
}

func TestTokenCache_Expiration(t *testing.T) {
	// 期待値: 期限切れトークンは取得できないこと
	cache := NewTokenCache()

	token := "expiring-token"
	userID := "test-user-id"

	// Set with very short TTL for testing
	cache.Set(token, userID)

	// Manually expire the entry
	cache.mu.Lock()
	cache.cache[token].expiresAt = time.Now().Add(-1 * time.Second)
	cache.mu.Unlock()

	// Get - 期待値検証: 期限切れトークンはfound=false
	retrievedUserID, found := cache.Get(token)
	assert.False(t, found)
	assert.Empty(t, retrievedUserID)
}

func TestGetUserID_Success(t *testing.T) {
	// 期待値: コンテキストからユーザーIDを正常に取得できること
	gin.SetMode(gin.TestMode)

	c, _ := gin.CreateTestContext(httptest.NewRecorder())
	expectedUserID := "test-user-123"
	c.Set(AuthContextKey, expectedUserID)

	userID, err := GetUserID(c)

	// 期待値検証: エラーなし、ユーザーIDが一致
	assert.NoError(t, err)
	assert.Equal(t, expectedUserID, userID)
}

func TestGetUserID_NotFound(t *testing.T) {
	// 期待値: ユーザーIDがコンテキストに存在しない場合、エラーを返すこと
	gin.SetMode(gin.TestMode)

	c, _ := gin.CreateTestContext(httptest.NewRecorder())

	userID, err := GetUserID(c)

	// 期待値検証: エラーが発生、ユーザーIDは空
	assert.Error(t, err)
	assert.Empty(t, userID)
	assert.Contains(t, err.Error(), "user ID not found in context")
}

func TestGetUserID_InvalidType(t *testing.T) {
	// 期待値: ユーザーIDの型が不正な場合、エラーを返すこと
	gin.SetMode(gin.TestMode)

	c, _ := gin.CreateTestContext(httptest.NewRecorder())
	c.Set(AuthContextKey, 12345) // Set non-string value

	userID, err := GetUserID(c)

	// 期待値検証: エラーが発生、ユーザーIDは空
	assert.Error(t, err)
	assert.Empty(t, userID)
	assert.Contains(t, err.Error(), "user ID is not a string")
}

// === 新規追加テスト ===

func TestTokenCache_Cleanup(t *testing.T) {
	// 期待値: クリーンアップが期限切れエントリを削除すること
	cache := NewTokenCacheWithInterval(10 * time.Millisecond)
	defer cache.Stop()

	// 複数の期限切れエントリを追加（削除ループを確実に実行）
	cache.Set("expired1", "user1")
	cache.Set("expired2", "user2")
	cache.Set("expired3", "user3")

	cache.mu.Lock()
	cache.cache["expired1"].expiresAt = time.Now().Add(-1 * time.Second)
	cache.cache["expired2"].expiresAt = time.Now().Add(-2 * time.Second)
	cache.cache["expired3"].expiresAt = time.Now().Add(-3 * time.Second)
	cache.mu.Unlock()

	// 有効なエントリを追加
	cache.Set("valid1", "user4")
	cache.Set("valid2", "user5")

	// クリーンアップ前の状態を確認
	cache.mu.RLock()
	initialSize := len(cache.cache)
	cache.mu.RUnlock()
	assert.Equal(t, 5, initialSize, "クリーンアップ前は5エントリあるべき")

	// クリーンアップを待つ（複数回実行される可能性を考慮）
	time.Sleep(50 * time.Millisecond)

	// 期待値検証: 期限切れエントリは削除され、有効なエントリは残る
	cache.mu.RLock()
	_, exists1 := cache.cache["expired1"]
	_, exists2 := cache.cache["expired2"]
	_, exists3 := cache.cache["expired3"]
	_, validExists1 := cache.cache["valid1"]
	_, validExists2 := cache.cache["valid2"]
	finalSize := len(cache.cache)
	cache.mu.RUnlock()

	assert.False(t, exists1, "期限切れエントリ1は削除されるべき")
	assert.False(t, exists2, "期限切れエントリ2は削除されるべき")
	assert.False(t, exists3, "期限切れエントリ3は削除されるべき")
	assert.True(t, validExists1, "有効なエントリ1は残るべき")
	assert.True(t, validExists2, "有効なエントリ2は残るべき")
	assert.Equal(t, 2, finalSize, "クリーンアップ後は2エントリあるべき")
}

func TestAuthMiddleware_Handler_WithValidToken(t *testing.T) {
	// 期待値: 有効なFirebaseトークンで認証が成功すること
	gin.SetMode(gin.TestMode)

	mockClient := new(MockAuthClient)
	middleware := NewAuthMiddlewareWithClient(mockClient)

	// モックの設定
	expectedToken := &auth.Token{
		UID: "firebase-user-123",
	}
	mockClient.On("VerifyIDToken", mock.Anything, "valid-firebase-token").Return(expectedToken, nil)

	router := gin.New()
	router.Use(middleware.Handler())
	router.GET("/test", func(c *gin.Context) {
		userID, _ := GetUserID(c)
		c.JSON(http.StatusOK, gin.H{"userID": userID})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer valid-firebase-token")

	router.ServeHTTP(w, req)

	// 期待値検証: HTTPステータス200、ユーザーIDが返却される
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "firebase-user-123")
	mockClient.AssertExpectations(t)
}

func TestAuthMiddleware_Handler_WithInvalidToken(t *testing.T) {
	// 期待値: 無効なトークンで401エラーを返すこと
	gin.SetMode(gin.TestMode)

	mockClient := new(MockAuthClient)
	middleware := NewAuthMiddlewareWithClient(mockClient)

	// モックの設定: トークン検証失敗
	mockClient.On("VerifyIDToken", mock.Anything, "invalid-token").Return(nil, errors.New("token verification failed"))

	router := gin.New()
	router.Use(middleware.Handler())
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "Bearer invalid-token")

	router.ServeHTTP(w, req)

	// 期待値検証: HTTPステータス401、エラーメッセージ
	assert.Equal(t, http.StatusUnauthorized, w.Code)
	assert.Contains(t, w.Body.String(), "Invalid or expired token")
	mockClient.AssertExpectations(t)
}

func TestAuthMiddleware_Handler_WithCachedToken(t *testing.T) {
	// 期待値: キャッシュされたトークンでFirebase呼び出しをスキップすること
	gin.SetMode(gin.TestMode)

	mockClient := new(MockAuthClient)
	middleware := NewAuthMiddlewareWithClient(mockClient)

	// 1回目: Firebase検証を呼び出す
	expectedToken := &auth.Token{
		UID: "cached-user-123",
	}
	mockClient.On("VerifyIDToken", mock.Anything, "cached-token").Return(expectedToken, nil).Once()

	router := gin.New()
	router.Use(middleware.Handler())
	router.GET("/test", func(c *gin.Context) {
		userID, _ := GetUserID(c)
		c.JSON(http.StatusOK, gin.H{"userID": userID})
	})

	// 1回目のリクエスト
	w1 := httptest.NewRecorder()
	req1 := httptest.NewRequest(http.MethodGet, "/test", nil)
	req1.Header.Set("Authorization", "Bearer cached-token")
	router.ServeHTTP(w1, req1)

	// 2回目のリクエスト（キャッシュヒット）
	w2 := httptest.NewRecorder()
	req2 := httptest.NewRequest(http.MethodGet, "/test", nil)
	req2.Header.Set("Authorization", "Bearer cached-token")
	router.ServeHTTP(w2, req2)

	// 期待値検証: 両方とも成功、Firebaseは1回のみ呼び出される
	assert.Equal(t, http.StatusOK, w1.Code)
	assert.Equal(t, http.StatusOK, w2.Code)
	assert.Contains(t, w1.Body.String(), "cached-user-123")
	assert.Contains(t, w2.Body.String(), "cached-user-123")
	mockClient.AssertExpectations(t) // Onceで1回のみ検証
}

func TestAuthMiddleware_Handler_MissingAuthorizationHeader(t *testing.T) {
	// 期待値: Authorizationヘッダーがない場合、401エラーを返すこと
	gin.SetMode(gin.TestMode)

	mockClient := new(MockAuthClient)
	middleware := NewAuthMiddlewareWithClient(mockClient)

	router := gin.New()
	router.Use(middleware.Handler())
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	// Authorizationヘッダーなし

	router.ServeHTTP(w, req)

	// 期待値検証: HTTPステータス401、エラーメッセージ
	assert.Equal(t, http.StatusUnauthorized, w.Code)
	assert.Contains(t, w.Body.String(), "Authorization header is required")
}

func TestAuthMiddleware_Handler_InvalidHeaderFormat(t *testing.T) {
	// 期待値: Bearer形式でない場合、401エラーを返すこと
	gin.SetMode(gin.TestMode)

	mockClient := new(MockAuthClient)
	middleware := NewAuthMiddlewareWithClient(mockClient)

	router := gin.New()
	router.Use(middleware.Handler())
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("Authorization", "InvalidFormat")

	router.ServeHTTP(w, req)

	// 期待値検証: HTTPステータス401、エラーメッセージ
	assert.Equal(t, http.StatusUnauthorized, w.Code)
	assert.Contains(t, w.Body.String(), "Invalid authorization header format")
}

func TestNewAuthMiddlewareWithClient(t *testing.T) {
	// 期待値: テスト用コンストラクタが正しくミドルウェアを生成すること
	mockClient := new(MockAuthClient)

	middleware := NewAuthMiddlewareWithClient(mockClient)

	// 期待値検証: ミドルウェアが正しく初期化される
	assert.NotNil(t, middleware)
	assert.NotNil(t, middleware.authClient)
	assert.NotNil(t, middleware.cache)
	assert.Equal(t, mockClient, middleware.authClient)
}
