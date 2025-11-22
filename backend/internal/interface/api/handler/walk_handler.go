package handler

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/presenter"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/pkg/errors"
	walkusecase "github.com/RRRRRRR-777/TekuToko/backend/internal/usecase/walk"
	"github.com/google/uuid"
)

// WalkHandler は散歩APIのハンドラー
type WalkHandler struct {
	container   *di.Container
	walkUsecase walkusecase.Usecase
}

// NewWalkHandler は新しいWalkHandlerを生成する
func NewWalkHandler(container *di.Container) *WalkHandler {
	return &WalkHandler{
		container:   container,
		walkUsecase: container.WalkUsecase,
	}
}

// CreateWalkRequest はWalk作成のリクエスト
type CreateWalkRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
}

// UpdateWalkRequest はWalk更新のリクエスト
type UpdateWalkRequest struct {
	Title       *string          `json:"title,omitempty"`
	Description *string          `json:"description,omitempty"`
	Status      *walk.WalkStatus `json:"status,omitempty"`
	TotalSteps  *int             `json:"total_steps,omitempty"`
}

// ListWalks は散歩一覧を取得する
// GET /v1/walks?page=1&limit=20
func (h *WalkHandler) ListWalks(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(r)

	// ページネーションパラメータ取得
	page := 1
	limit := 20
	if pageStr := r.URL.Query().Get("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 100 {
			limit = l
		}
	}

	offset := (page - 1) * limit

	// Usecase呼び出し
	walks, totalCount, err := h.walkUsecase.ListWalks(ctx, userID, limit, offset)
	if err != nil {
		h.respondError(w, err)
		return
	}

	// レスポンス返却
	response := presenter.ToWalkListResponse(walks, totalCount, page, limit)
	h.respondJSON(w, http.StatusOK, response)
}

// GetWalk は散歩詳細を取得する
// GET /v1/walks/{id}
func (h *WalkHandler) GetWalk(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(r)

	// IDパラメータ取得
	idStr := strings.TrimPrefix(r.URL.Path, "/v1/walks/")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, errors.NewInvalidRequestError("Invalid walk ID"))
		return
	}

	// Usecase呼び出し
	wlk, err := h.walkUsecase.GetWalk(ctx, id, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			h.respondError(w, errors.NewNotFoundError("Walk not found"))
			return
		}
		h.respondError(w, err)
		return
	}

	// レスポンス返却
	response := presenter.ToWalkResponse(wlk)
	h.respondJSON(w, http.StatusOK, response)
}

// CreateWalk は新しい散歩を作成する
// POST /v1/walks
func (h *WalkHandler) CreateWalk(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(r)

	// リクエストボディをパース
	var req CreateWalkRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, errors.NewInvalidRequestError("Invalid request body"))
		return
	}

	// バリデーション
	if req.Title == "" {
		h.respondError(w, errors.NewInvalidRequestError("Title is required"))
		return
	}

	// Usecase呼び出し
	input := walkusecase.CreateWalkInput{
		UserID:      userID,
		Title:       req.Title,
		Description: req.Description,
	}
	wlk, err := h.walkUsecase.CreateWalk(ctx, input)
	if err != nil {
		h.respondError(w, err)
		return
	}

	// レスポンス返却
	response := presenter.ToWalkResponse(wlk)
	h.respondJSON(w, http.StatusCreated, response)
}

// UpdateWalk は散歩を更新する
// PUT /v1/walks/{id}
func (h *WalkHandler) UpdateWalk(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(r)

	// IDパラメータ取得
	idStr := strings.TrimPrefix(r.URL.Path, "/v1/walks/")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, errors.NewInvalidRequestError("Invalid walk ID"))
		return
	}

	// リクエストボディをパース
	var req UpdateWalkRequest
	if decodeErr := json.NewDecoder(r.Body).Decode(&req); decodeErr != nil {
		h.respondError(w, errors.NewInvalidRequestError("Invalid request body"))
		return
	}

	// Usecase呼び出し
	input := walkusecase.UpdateWalkInput{
		ID:          id,
		Title:       req.Title,
		Description: req.Description,
		Status:      req.Status,
		TotalSteps:  req.TotalSteps,
	}
	wlk, err := h.walkUsecase.UpdateWalk(ctx, input, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			h.respondError(w, errors.NewNotFoundError("Walk not found"))
			return
		}
		h.respondError(w, err)
		return
	}

	// レスポンス返却
	response := presenter.ToWalkResponse(wlk)
	h.respondJSON(w, http.StatusOK, response)
}

// DeleteWalk は散歩を削除する
// DELETE /v1/walks/{id}
func (h *WalkHandler) DeleteWalk(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(r)

	// IDパラメータ取得
	idStr := strings.TrimPrefix(r.URL.Path, "/v1/walks/")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(w, errors.NewInvalidRequestError("Invalid walk ID"))
		return
	}

	// Usecase呼び出し
	if err := h.walkUsecase.DeleteWalk(ctx, id, userID); err != nil {
		if err == sql.ErrNoRows {
			h.respondError(w, errors.NewNotFoundError("Walk not found"))
			return
		}
		h.respondError(w, err)
		return
	}

	// レスポンス返却
	w.WriteHeader(http.StatusNoContent)
}

// ヘルパーメソッド

// getUserID は現在のユーザーIDを取得する
// TODO: 認証実装後に実装
func (h *WalkHandler) getUserID(r *http.Request) string {
	if userID := r.Header.Get("X-User-ID"); userID != "" {
		return userID
	}
	return "test-user" // 仮のユーザーID
}

// respondJSON はJSON形式でレスポンスを返す
func (h *WalkHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(data); err != nil {
		h.container.Logger.Error(fmt.Sprintf("Failed to encode JSON: %v", err))
	}
}

// respondError はエラーレスポンスを返す
func (h *WalkHandler) respondError(w http.ResponseWriter, err error) {
	appErr := errors.GetAppError(err)
	if appErr == nil {
		appErr = errors.NewInternalError("Internal server error", err)
	}

	status := http.StatusInternalServerError
	switch appErr.Code {
	case errors.CodeInvalidRequest:
		status = http.StatusBadRequest
	case errors.CodeUnauthorized:
		status = http.StatusUnauthorized
	case errors.CodeForbidden:
		status = http.StatusForbidden
	case errors.CodeNotFound:
		status = http.StatusNotFound
	case errors.CodeConflict:
		status = http.StatusConflict
	}

	response := map[string]interface{}{
		"error": map[string]string{
			"code":    appErr.Code,
			"message": appErr.Message,
		},
	}

	h.respondJSON(w, status, response)
}
