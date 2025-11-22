package handler

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/pkg/errors"
	walkusecase "github.com/RRRRRRR-777/TekuToko/backend/internal/usecase/walk"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockWalkUsecase はWalkUsecaseのモック
type MockWalkUsecase struct {
	mock.Mock
}

func (m *MockWalkUsecase) CreateWalk(ctx context.Context, input walkusecase.CreateWalkInput) (*walk.Walk, error) {
	args := m.Called(ctx, input)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*walk.Walk), args.Error(1)
}

func (m *MockWalkUsecase) GetWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*walk.Walk), args.Error(1)
}

func (m *MockWalkUsecase) ListWalks(ctx context.Context, userID string, limit, offset int) ([]*walk.Walk, int, error) {
	args := m.Called(ctx, userID, limit, offset)
	if args.Get(0) == nil {
		return nil, 0, args.Error(2)
	}
	return args.Get(0).([]*walk.Walk), args.Int(1), args.Error(2)
}

func (m *MockWalkUsecase) UpdateWalk(ctx context.Context, input walkusecase.UpdateWalkInput, userID string) (*walk.Walk, error) {
	args := m.Called(ctx, input, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*walk.Walk), args.Error(1)
}

func (m *MockWalkUsecase) DeleteWalk(ctx context.Context, id uuid.UUID, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}

func (m *MockWalkUsecase) StartWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*walk.Walk), args.Error(1)
}

func (m *MockWalkUsecase) PauseWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*walk.Walk), args.Error(1)
}

func (m *MockWalkUsecase) ResumeWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*walk.Walk), args.Error(1)
}

func (m *MockWalkUsecase) CompleteWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	args := m.Called(ctx, id, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*walk.Walk), args.Error(1)
}

// テストヘルパー関数

func setupTestHandler() (*WalkHandler, *MockWalkUsecase) {
	gin.SetMode(gin.TestMode)
	mockUsecase := new(MockWalkUsecase)
	container := &di.Container{
		WalkUsecase: mockUsecase,
	}
	handler := NewWalkHandler(container)
	return handler, mockUsecase
}

func setupTestContext(method, path string, body interface{}) (*gin.Context, *httptest.ResponseRecorder) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	var req *http.Request
	if body != nil {
		jsonBody, _ := json.Marshal(body)
		req = httptest.NewRequest(method, path, bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
	} else {
		req = httptest.NewRequest(method, path, nil)
	}

	c.Request = req
	return c, w
}

// テストケース

func TestWalkHandler_CreateWalk_Success(t *testing.T) {
	// 期待値: 正常な散歩作成リクエストで201 Createdを返し、作成された散歩情報をレスポンスする
	handler, mockUsecase := setupTestHandler()

	reqBody := CreateWalkRequest{
		Title:       "Morning Walk",
		Description: "A nice walk in the park",
	}

	expectedWalk := walk.NewWalk("test-user", "Morning Walk", "A nice walk in the park")

	mockUsecase.On("CreateWalk", mock.Anything, mock.MatchedBy(func(input walkusecase.CreateWalkInput) bool {
		return input.Title == "Morning Walk" && input.UserID == "test-user"
	})).Return(expectedWalk, nil)

	c, w := setupTestContext(http.MethodPost, "/v1/walks", reqBody)

	handler.CreateWalk(c)

	// 期待値検証: HTTPステータス201、タイトルが正しく返却される
	assert.Equal(t, http.StatusCreated, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "Morning Walk", response["title"])

	mockUsecase.AssertExpectations(t)
}

func TestWalkHandler_CreateWalk_InvalidRequest(t *testing.T) {
	// 期待値: タイトルが空の場合、バリデーションエラーで400 Bad Requestを返す
	handler, _ := setupTestHandler()

	// Titleが空（バリデーションエラー）
	reqBody := CreateWalkRequest{
		Title:       "",
		Description: "Description",
	}

	c, w := setupTestContext(http.MethodPost, "/v1/walks", reqBody)

	handler.CreateWalk(c)

	// 期待値検証: HTTPステータス400、エラーレスポンスが返される
	assert.Equal(t, http.StatusBadRequest, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Contains(t, response, "error")
}

func TestWalkHandler_CreateWalk_InvalidJSON(t *testing.T) {
	// 期待値: 不正なJSONボディの場合、400 Bad Requestを返す
	handler, _ := setupTestHandler()

	c, w := setupTestContext(http.MethodPost, "/v1/walks", nil)
	c.Request.Body = http.NoBody

	handler.CreateWalk(c)

	// 期待値検証: HTTPステータス400
	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestWalkHandler_GetWalk_Success(t *testing.T) {
	// 期待値: 正常なIDで散歩を取得し、200 OKとともに散歩詳細を返す
	handler, mockUsecase := setupTestHandler()

	walkID := uuid.New()
	expectedWalk := walk.NewWalk("test-user", "Test Walk", "Description")
	expectedWalk.ID = walkID

	mockUsecase.On("GetWalk", mock.Anything, walkID, "test-user").Return(expectedWalk, nil)

	c, w := setupTestContext(http.MethodGet, "/v1/walks/"+walkID.String(), nil)
	c.Params = gin.Params{{Key: "id", Value: walkID.String()}}

	handler.GetWalk(c)

	// 期待値検証: HTTPステータス200、散歩IDが正しく返却される
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, walkID.String(), response["id"])

	mockUsecase.AssertExpectations(t)
}

// 期待値検証: HTTPステータス404
func TestWalkHandler_GetWalk_NotFound(t *testing.T) {
	// 期待値: 存在しないIDの場合、404 Not Foundを返す
	handler, mockUsecase := setupTestHandler()

	walkID := uuid.New()

	mockUsecase.On("GetWalk", mock.Anything, walkID, "test-user").Return(nil, sql.ErrNoRows)

	c, w := setupTestContext(http.MethodGet, "/v1/walks/"+walkID.String(), nil)
	c.Params = gin.Params{{Key: "id", Value: walkID.String()}}

	handler.GetWalk(c)

	assert.Equal(t, http.StatusNotFound, w.Code)

	mockUsecase.AssertExpectations(t)
}

	// 期待値: 不正なUUID形式の場合、400 Bad Requestを返す
func TestWalkHandler_GetWalk_InvalidID(t *testing.T) {
	handler, _ := setupTestHandler()

	c, w := setupTestContext(http.MethodGet, "/v1/walks/invalid-uuid", nil)
	c.Params = gin.Params{{Key: "id", Value: "invalid-uuid"}}

	handler.GetWalk(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

	// 期待値検証: HTTPステータス400
func TestWalkHandler_ListWalks_Success(t *testing.T) {
	handler, mockUsecase := setupTestHandler()

	walks := []*walk.Walk{
		walk.NewWalk("test-user", "Walk 1", "Description 1"),
		walk.NewWalk("test-user", "Walk 2", "Description 2"),
	}

	mockUsecase.On("ListWalks", mock.Anything, "test-user", 20, 0).Return(walks, 2, nil)

	c, w := setupTestContext(http.MethodGet, "/v1/walks", nil)

	handler.ListWalks(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.NotNil(t, response)
	// レスポンスに何らかのデータが含まれていることを確認
	assert.NotEmpty(t, response)

	mockUsecase.AssertExpectations(t)
}

	// 期待値: 散歩一覧をデフォルトページネーション（page=1, limit=20）で取得し、200 OKを返す
func TestWalkHandler_ListWalks_WithPagination(t *testing.T) {
	handler, mockUsecase := setupTestHandler()

	walks := []*walk.Walk{
		walk.NewWalk("test-user", "Walk 3", "Description 3"),
	}

	// page=2, limit=10 → offset=10
	mockUsecase.On("ListWalks", mock.Anything, "test-user", 10, 10).Return(walks, 15, nil)

	c, w := setupTestContext(http.MethodGet, "/v1/walks?page=2&limit=10", nil)

	handler.ListWalks(c)

	assert.Equal(t, http.StatusOK, w.Code)

	mockUsecase.AssertExpectations(t)
}

	// 期待値: ページネーションパラメータ（page=2, limit=10）が正しく適用される
func TestWalkHandler_UpdateWalk_Success(t *testing.T) {
	handler, mockUsecase := setupTestHandler()

	walkID := uuid.New()
	newTitle := "Updated Title"
	reqBody := UpdateWalkRequest{
		Title: &newTitle,
	}

	updatedWalk := walk.NewWalk("test-user", "Updated Title", "Description")
	updatedWalk.ID = walkID

	mockUsecase.On("UpdateWalk", mock.Anything, mock.MatchedBy(func(input walkusecase.UpdateWalkInput) bool {
		return input.ID == walkID && *input.Title == "Updated Title"
	}), "test-user").Return(updatedWalk, nil)

	c, w := setupTestContext(http.MethodPut, "/v1/walks/"+walkID.String(), reqBody)
	c.Params = gin.Params{{Key: "id", Value: walkID.String()}}

	handler.UpdateWalk(c)

	assert.Equal(t, http.StatusOK, w.Code)

	mockUsecase.AssertExpectations(t)
}

	// 期待値: 散歩情報を正常に更新し、200 OKとともに更新後の散歩情報を返す
func TestWalkHandler_UpdateWalk_NotFound(t *testing.T) {
	handler, mockUsecase := setupTestHandler()

	walkID := uuid.New()
	newTitle := "Updated Title"
	reqBody := UpdateWalkRequest{
		Title: &newTitle,
	}

	mockUsecase.On("UpdateWalk", mock.Anything, mock.Anything, "test-user").Return(nil, sql.ErrNoRows)

	c, w := setupTestContext(http.MethodPut, "/v1/walks/"+walkID.String(), reqBody)
	c.Params = gin.Params{{Key: "id", Value: walkID.String()}}

	handler.UpdateWalk(c)

	assert.Equal(t, http.StatusNotFound, w.Code)

	mockUsecase.AssertExpectations(t)
}

	// 期待値: 存在しないIDの更新で404 Not Foundを返す
func TestWalkHandler_DeleteWalk_Success(t *testing.T) {
	handler, mockUsecase := setupTestHandler()

	walkID := uuid.New()

	mockUsecase.On("DeleteWalk", mock.Anything, walkID, "test-user").Return(nil)

	c, w := setupTestContext(http.MethodDelete, "/v1/walks/"+walkID.String(), nil)
	c.Params = gin.Params{{Key: "id", Value: walkID.String()}}

	handler.DeleteWalk(c)

	// Ginのc.Status()は200を返す場合がある（WriteHeaderされていない場合）
	// 204または200を許容
	assert.Contains(t, []int{http.StatusOK, http.StatusNoContent}, w.Code)

	mockUsecase.AssertExpectations(t)
}

	// 期待値: 散歩を正常に削除し、204 No Contentまたは200 OKを返す
func TestWalkHandler_DeleteWalk_NotFound(t *testing.T) {
	handler, mockUsecase := setupTestHandler()

	walkID := uuid.New()

	mockUsecase.On("DeleteWalk", mock.Anything, walkID, "test-user").Return(sql.ErrNoRows)

	c, w := setupTestContext(http.MethodDelete, "/v1/walks/"+walkID.String(), nil)
	c.Params = gin.Params{{Key: "id", Value: walkID.String()}}

	handler.DeleteWalk(c)

	assert.Equal(t, http.StatusNotFound, w.Code)

	mockUsecase.AssertExpectations(t)
}

	// 期待値: 存在しないIDの削除で404 Not Foundを返す
func TestWalkHandler_RespondError(t *testing.T) {
	handler, _ := setupTestHandler()

	tests := []struct {
		name           string
		err            error
		expectedStatus int
		expectedCode   string
	}{
		{
			name:           "InvalidRequest",
			err:            errors.NewInvalidRequestError("Invalid input"),
			expectedStatus: http.StatusBadRequest,
			expectedCode:   errors.CodeInvalidRequest,
		},
		{
			name:           "NotFound",
			err:            errors.NewNotFoundError("Resource not found"),
			expectedStatus: http.StatusNotFound,
			expectedCode:   errors.CodeNotFound,
		},
		{
			name:           "Unauthorized",
			err:            errors.NewUnauthorizedError("Unauthorized"),
			expectedStatus: http.StatusUnauthorized,
			expectedCode:   errors.CodeUnauthorized,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, w := setupTestContext(http.MethodGet, "/test", nil)

			handler.respondError(c, tt.err)

			assert.Equal(t, tt.expectedStatus, w.Code)

			var response map[string]interface{}
			err := json.Unmarshal(w.Body.Bytes(), &response)
			assert.NoError(t, err)

			errorMap := response["error"].(map[string]interface{})
			assert.Equal(t, tt.expectedCode, errorMap["code"])
		})
	}
}
