package handler

import (
	"database/sql"
	"fmt"
	"net/http"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/presenter"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/pkg/errors"
	walkusecase "github.com/RRRRRRR-777/TekuToko/backend/internal/usecase/walk"
	"github.com/gin-gonic/gin"
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
	Title       string `json:"title" binding:"required"`
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
func (h *WalkHandler) ListWalks(c *gin.Context) {
	ctx := c.Request.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(c)

	// ページネーションパラメータ取得
	pageInt := 1
	limitInt := 20
	if p, exists := c.GetQuery("page"); exists {
		if val, parseErr := parsePositiveInt(p, 1000); parseErr == nil {
			pageInt = val
		}
	}
	if l, exists := c.GetQuery("limit"); exists {
		if val, parseErr := parsePositiveInt(l, 100); parseErr == nil {
			limitInt = val
		}
	}

	offset := (pageInt - 1) * limitInt

	// Usecase呼び出し
	walks, totalCount, err := h.walkUsecase.ListWalks(ctx, userID, limitInt, offset)
	if err != nil {
		h.respondError(c, err)
		return
	}

	// レスポンス返却
	response := presenter.ToWalkListResponse(walks, totalCount, pageInt, limitInt)
	c.JSON(http.StatusOK, response)
}

// GetWalk は散歩詳細を取得する
// GET /v1/walks/:id
func (h *WalkHandler) GetWalk(c *gin.Context) {
	ctx := c.Request.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(c)

	// IDパラメータ取得
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(c, errors.NewInvalidRequestError("Invalid walk ID"))
		return
	}

	// Usecase呼び出し
	wlk, err := h.walkUsecase.GetWalk(ctx, id, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			h.respondError(c, errors.NewNotFoundError("Walk not found"))
			return
		}
		h.respondError(c, err)
		return
	}

	// レスポンス返却
	response := presenter.ToWalkResponse(wlk)
	c.JSON(http.StatusOK, response)
}

// CreateWalk は新しい散歩を作成する
// POST /v1/walks
func (h *WalkHandler) CreateWalk(c *gin.Context) {
	ctx := c.Request.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(c)

	// リクエストボディをバインド
	var req CreateWalkRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.respondError(c, errors.NewInvalidRequestError("Invalid request body"))
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
		h.respondError(c, err)
		return
	}

	// レスポンス返却
	response := presenter.ToWalkResponse(wlk)
	c.JSON(http.StatusCreated, response)
}

// UpdateWalk は散歩を更新する
// PUT /v1/walks/:id
func (h *WalkHandler) UpdateWalk(c *gin.Context) {
	ctx := c.Request.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(c)

	// IDパラメータ取得
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(c, errors.NewInvalidRequestError("Invalid walk ID"))
		return
	}

	// リクエストボディをバインド
	var req UpdateWalkRequest
	if bindErr := c.ShouldBindJSON(&req); bindErr != nil {
		h.respondError(c, errors.NewInvalidRequestError("Invalid request body"))
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
			h.respondError(c, errors.NewNotFoundError("Walk not found"))
			return
		}
		h.respondError(c, err)
		return
	}

	// レスポンス返却
	response := presenter.ToWalkResponse(wlk)
	c.JSON(http.StatusOK, response)
}

// DeleteWalk は散歩を削除する
// DELETE /v1/walks/:id
func (h *WalkHandler) DeleteWalk(c *gin.Context) {
	ctx := c.Request.Context()

	// TODO: 認証実装後にuserIDを取得
	userID := h.getUserID(c)

	// IDパラメータ取得
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(c, errors.NewInvalidRequestError("Invalid walk ID"))
		return
	}

	// Usecase呼び出し
	if err := h.walkUsecase.DeleteWalk(ctx, id, userID); err != nil {
		if err == sql.ErrNoRows {
			h.respondError(c, errors.NewNotFoundError("Walk not found"))
			return
		}
		h.respondError(c, err)
		return
	}

	// レスポンス返却
	c.Status(http.StatusNoContent)
}

// ヘルパーメソッド

// getUserID は現在のユーザーIDを取得する
// TODO: 認証実装後に実装
func (h *WalkHandler) getUserID(c *gin.Context) string {
	if userID := c.GetHeader("X-User-ID"); userID != "" {
		return userID
	}
	return "test-user" // 仮のユーザーID
}

// respondError はエラーレスポンスを返す
func (h *WalkHandler) respondError(c *gin.Context, err error) {
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

	c.JSON(status, gin.H{
		"error": gin.H{
			"code":    appErr.Code,
			"message": appErr.Message,
		},
	})
}

// parsePositiveInt は文字列を正の整数に変換する
func parsePositiveInt(s string, max int) (int, error) {
	var val int
	if _, err := fmt.Sscanf(s, "%d", &val); err != nil {
		return 0, err
	}
	if val <= 0 || val > max {
		return 0, fmt.Errorf("value out of range")
	}
	return val, nil
}
