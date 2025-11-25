package router

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"firebase.google.com/go/v4/auth"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/database"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/logger"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/middleware"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// mockAuthClient はテスト用のFirebase Auth Client
type mockAuthClient struct{}

func (m *mockAuthClient) VerifyIDToken(_ context.Context, _ string) (*auth.Token, error) {
	return &auth.Token{UID: "test-user-id"}, nil
}

// setupTestRouter はテスト用のルーターをセットアップする
func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)

	// テスト用ロガー
	testLogger, _ := logger.NewLogger("error", "console")

	// テスト用認証ミドルウェア
	mockAuth := &mockAuthClient{}
	authMiddleware := middleware.NewAuthMiddlewareWithClient(mockAuth)

	container := &di.Container{
		DB:             &database.PostgresDB{},
		Logger:         testLogger,
		AuthMiddleware: authMiddleware,
	}

	return NewRouter(container)
}

// テストケース

func TestRouter_HealthCheck(t *testing.T) {
	// 期待値: /healthエンドポイントが200 OKとステータス情報を返す
	router := setupTestRouter()

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/health", nil)

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, "ok", response["status"])
	assert.Equal(t, "TekuToko API is running", response["message"])
}

func TestRouter_RootEndpoint(t *testing.T) {
	// 期待値: /エンドポイントがAPIバージョン情報を返す
	router := setupTestRouter()

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, "Welcome to TekuToko API", response["message"])
	assert.Equal(t, "0.1.0", response["version"])
	assert.Equal(t, "Development", response["status"])
}

func TestRouter_WalkEndpoints_MethodNotAllowed(t *testing.T) {
	router := setupTestRouter()

	tests := []struct {
		name   string
		method string
		path   string
	}{
		{
			name:   "PATCH on /v1/walks",
			method: http.MethodPatch,
			path:   "/v1/walks",
		},
		{
			name:   "HEAD on /v1/walks",
			method: http.MethodHead,
			path:   "/v1/walks",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			req := httptest.NewRequest(tt.method, tt.path, nil)

			router.ServeHTTP(w, req)

			// Ginは未定義のメソッドに対して404を返す
			assert.Equal(t, http.StatusNotFound, w.Code)
		})
	}
}

func TestRouter_WalkEndpoints_RouteExists(t *testing.T) {
	router := setupTestRouter()

	tests := []struct {
		name           string
		method         string
		path           string
		expectedStatus int // 実際のレスポンスではなく、ルーティングが存在するか
	}{
		{
			name:           "GET /v1/walks",
			method:         http.MethodGet,
			path:           "/v1/walks",
			expectedStatus: http.StatusOK, // 実際にはmockが必要だが、ルーティング確認
		},
		{
			name:           "POST /v1/walks",
			method:         http.MethodPost,
			path:           "/v1/walks",
			expectedStatus: http.StatusBadRequest, // bodyなしでバリデーションエラー
		},
		{
			name:           "GET /v1/walks/:id",
			method:         http.MethodGet,
			path:           "/v1/walks/invalid-uuid",
			expectedStatus: http.StatusBadRequest, // UUID検証エラー
		},
		{
			name:           "PUT /v1/walks/:id",
			method:         http.MethodPut,
			path:           "/v1/walks/550e8400-e29b-41d4-a716-446655440000",
			expectedStatus: http.StatusBadRequest, // bodyなしでエラー
		},
		{
			name:           "DELETE /v1/walks/:id",
			method:         http.MethodDelete,
			path:           "/v1/walks/invalid-uuid",
			expectedStatus: http.StatusBadRequest, // UUID検証エラー
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			req := httptest.NewRequest(tt.method, tt.path, nil)
			req.Header.Set("Content-Type", "application/json")

			router.ServeHTTP(w, req)

			// ルーティングが存在することを確認（404ではない）
			assert.NotEqual(t, http.StatusNotFound, w.Code, "Route should exist")
		})
	}
}

func TestRouter_NotFoundEndpoint(t *testing.T) {
	// 期待値: 存在しないパスで404 Not Foundを返す
	router := setupTestRouter()

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/non-existent-path", nil)

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestRouter_CORSHeaders(t *testing.T) {
	router := setupTestRouter()

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodOptions, "/health", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "GET")

	router.ServeHTTP(w, req)

	// 現時点ではCORS未実装なので、将来の実装を確認する場所
	// TODO: CORS実装後にヘッダー確認を追加
}

func TestRouter_GinMode(t *testing.T) {
	// テストモードでの動作確認
	gin.SetMode(gin.TestMode)
	router := setupTestRouter()

	assert.NotNil(t, router)
}

func TestRouter_HealthEndpointContentType(t *testing.T) {
	router := setupTestRouter()

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/health", nil)

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Header().Get("Content-Type"), "application/json")
}
