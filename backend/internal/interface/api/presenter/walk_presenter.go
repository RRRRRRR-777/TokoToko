package presenter

import (
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/google/uuid"
)

// WalkResponse は散歩APIのレスポンス
type WalkResponse struct {
	ID                  uuid.UUID  `json:"id"`
	UserID              string     `json:"user_id"`
	Title               string     `json:"title"`
	Description         string     `json:"description"`
	StartTime           *time.Time `json:"start_time"`
	EndTime             *time.Time `json:"end_time"`
	TotalDistance       float64    `json:"total_distance"`
	TotalSteps          int        `json:"total_steps"`
	PolylineData        *string    `json:"polyline_data,omitempty"`
	ThumbnailImageURL   *string    `json:"thumbnail_image_url,omitempty"`
	Status              string     `json:"status"`
	TotalPausedDuration float64    `json:"total_paused_duration"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

// WalkListResponse は散歩一覧のレスポンス
type WalkListResponse struct {
	Walks      []WalkResponse `json:"walks"`
	TotalCount int            `json:"total_count"`
	Page       int            `json:"page"`
	Limit      int            `json:"limit"`
}

// ToWalkResponse はドメインエンティティをレスポンスに変換する
func ToWalkResponse(w *walk.Walk) WalkResponse {
	return WalkResponse{
		ID:                  w.ID,
		UserID:              w.UserID,
		Title:               w.Title,
		Description:         w.Description,
		StartTime:           w.StartTime,
		EndTime:             w.EndTime,
		TotalDistance:       w.TotalDistance,
		TotalSteps:          w.TotalSteps,
		PolylineData:        w.PolylineData,
		ThumbnailImageURL:   w.ThumbnailImageURL,
		Status:              string(w.Status),
		TotalPausedDuration: w.TotalPausedDuration,
		CreatedAt:           w.CreatedAt,
		UpdatedAt:           w.UpdatedAt,
	}
}

// ToWalkListResponse はドメインエンティティリストをレスポンスに変換する
func ToWalkListResponse(walks []*walk.Walk, totalCount, page, limit int) WalkListResponse {
	responses := make([]WalkResponse, len(walks))
	for i, w := range walks {
		responses[i] = ToWalkResponse(w)
	}

	return WalkListResponse{
		Walks:      responses,
		TotalCount: totalCount,
		Page:       page,
		Limit:      limit,
	}
}
