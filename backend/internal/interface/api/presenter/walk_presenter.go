package presenter

import (
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/google/uuid"
)

// LocationResponse は位置情報のレスポンス
type LocationResponse struct {
	Latitude           float64   `json:"latitude"`
	Longitude          float64   `json:"longitude"`
	Altitude           *float64  `json:"altitude,omitempty"`
	Timestamp          time.Time `json:"timestamp"`
	HorizontalAccuracy *float64  `json:"horizontal_accuracy,omitempty"`
	VerticalAccuracy   *float64  `json:"vertical_accuracy,omitempty"`
	Speed              *float64  `json:"speed,omitempty"`
	Course             *float64  `json:"course,omitempty"`
	SequenceNumber     int       `json:"sequence_number"`
}

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
	PausedAt            *time.Time `json:"paused_at"`
	TotalPausedDuration float64    `json:"total_paused_duration"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

// WalkDetailResponse は散歩詳細APIのレスポンス（位置情報を含む）
type WalkDetailResponse struct {
	WalkResponse
	Locations []LocationResponse `json:"locations"`
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
		PausedAt:            w.PausedAt,
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

// ToLocationResponse は位置情報をレスポンスに変換する
func ToLocationResponse(loc *walk.WalkLocation) LocationResponse {
	return LocationResponse{
		Latitude:           loc.Latitude,
		Longitude:          loc.Longitude,
		Altitude:           loc.Altitude,
		Timestamp:          loc.Timestamp,
		HorizontalAccuracy: loc.HorizontalAccuracy,
		VerticalAccuracy:   loc.VerticalAccuracy,
		Speed:              loc.Speed,
		Course:             loc.Course,
		SequenceNumber:     loc.SequenceNumber,
	}
}

// ToWalkDetailResponse はWalkと位置情報をレスポンスに変換する
func ToWalkDetailResponse(w *walk.Walk, locations []*walk.WalkLocation) WalkDetailResponse {
	locationResponses := make([]LocationResponse, len(locations))
	for i, loc := range locations {
		locationResponses[i] = ToLocationResponse(loc)
	}

	return WalkDetailResponse{
		WalkResponse: ToWalkResponse(w),
		Locations:    locationResponses,
	}
}
