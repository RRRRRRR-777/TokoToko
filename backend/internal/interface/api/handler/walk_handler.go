package handler

import (
	"database/sql"
	"fmt"
	"net/http"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/api/middleware"
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

// LocationRequest は位置情報のリクエスト
type LocationRequest struct {
	Latitude           float64   `json:"latitude" binding:"required"`
	Longitude          float64   `json:"longitude" binding:"required"`
	Altitude           *float64  `json:"altitude,omitempty"`
	Timestamp          time.Time `json:"timestamp" binding:"required"`
	HorizontalAccuracy *float64  `json:"horizontal_accuracy,omitempty"`
	VerticalAccuracy   *float64  `json:"vertical_accuracy,omitempty"`
	Speed              *float64  `json:"speed,omitempty"`
	Course             *float64  `json:"course,omitempty"`
	SequenceNumber     int       `json:"sequence_number"`
}

// UpdateWalkRequest はWalk更新のリクエスト
// upsert対応: 存在しない場合は新規作成するため、作成に必要なフィールドも含む
type UpdateWalkRequest struct {
	Title               *string           `json:"title,omitempty"`
	Description         *string           `json:"description,omitempty"`
	Status              *walk.WalkStatus  `json:"status,omitempty"`
	TotalSteps          *int              `json:"total_steps,omitempty"`
	StartTime           *time.Time        `json:"start_time,omitempty"`
	EndTime             *time.Time        `json:"end_time,omitempty"`
	TotalDistance       *float64          `json:"total_distance,omitempty"`
	PolylineData        *string           `json:"polyline_data,omitempty"`
	ThumbnailImageURL   *string           `json:"thumbnail_image_url,omitempty"`
	PausedAt            *time.Time        `json:"paused_at,omitempty"`
	TotalPausedDuration *float64          `json:"total_paused_duration,omitempty"`
	Locations           []LocationRequest `json:"locations,omitempty"`
}

// ListWalks は散歩一覧を取得する
// GET /v1/walks?page=1&limit=20
func (h *WalkHandler) ListWalks(c *gin.Context) {
	ctx := c.Request.Context()

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

// GetWalk は散歩詳細を取得する（位置情報を含む）
// GET /v1/walks/:id
func (h *WalkHandler) GetWalk(c *gin.Context) {
	ctx := c.Request.Context()

	userID := h.getUserID(c)

	// IDパラメータ取得
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		h.respondError(c, errors.NewInvalidRequestError("Invalid walk ID"))
		return
	}

	// Usecase呼び出し（位置情報を含む）
	result, err := h.walkUsecase.GetWalkWithLocations(ctx, id, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			h.respondError(c, errors.NewNotFoundError("Walk not found"))
			return
		}
		h.respondError(c, err)
		return
	}

	// レスポンス返却（位置情報を含む）
	response := presenter.ToWalkDetailResponse(result.Walk, result.Locations)
	c.JSON(http.StatusOK, response)
}

// CreateWalk は新しい散歩を作成する
// POST /v1/walks
func (h *WalkHandler) CreateWalk(c *gin.Context) {
	ctx := c.Request.Context()

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

	// LocationRequestをドメインモデルに変換
	var locations []*walk.WalkLocation
	if len(req.Locations) > 0 {
		locations = make([]*walk.WalkLocation, len(req.Locations))
		for i, loc := range req.Locations {
			locations[i] = walk.NewWalkLocationWithOptionals(
				id,
				loc.Latitude,
				loc.Longitude,
				loc.Altitude,
				loc.Timestamp,
				loc.HorizontalAccuracy,
				loc.VerticalAccuracy,
				loc.Speed,
				loc.Course,
				loc.SequenceNumber,
			)
		}
	}

	// Usecase呼び出し（upsert対応）
	input := walkusecase.UpdateWalkInput{
		ID:                  id,
		Title:               req.Title,
		Description:         req.Description,
		Status:              req.Status,
		TotalSteps:          req.TotalSteps,
		StartTime:           req.StartTime,
		EndTime:             req.EndTime,
		TotalDistance:       req.TotalDistance,
		PolylineData:        req.PolylineData,
		ThumbnailImageURL:   req.ThumbnailImageURL,
		PausedAt:            req.PausedAt,
		TotalPausedDuration: req.TotalPausedDuration,
		Locations:           locations,
	}
	wlk, err := h.walkUsecase.UpdateWalk(ctx, input, userID)
	if err != nil {
		fmt.Printf("[DEBUG] UpdateWalk error: %+v\n", err)
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
// 認証ミドルウェアで設定されたユーザーIDを取得する
// エラーが発生する場合は認証設定に問題があるため、panicで早期検知する
func (h *WalkHandler) getUserID(c *gin.Context) string {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		panic(fmt.Sprintf("authentication misconfiguration: %v", err))
	}
	return userID
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
