package walk

import (
	"time"

	"github.com/google/uuid"
)

// WalkStatus は散歩のステータスを表す
type WalkStatus string

const (
	// StatusNotStarted は散歩が開始されていない状態
	StatusNotStarted WalkStatus = "not_started"
	// StatusInProgress は散歩が進行中の状態
	StatusInProgress WalkStatus = "in_progress"
	// StatusPaused は散歩が一時停止されている状態
	StatusPaused WalkStatus = "paused"
	// StatusCompleted は散歩が完了した状態
	StatusCompleted WalkStatus = "completed"
)

// Walk は散歩のドメインエンティティ
type Walk struct {
	ID                  uuid.UUID  `json:"id"`
	UserID              string     `json:"user_id"`
	Title               string     `json:"title"`
	Description         string     `json:"description"`
	StartTime           *time.Time `json:"start_time"`
	EndTime             *time.Time `json:"end_time"`
	TotalDistance       float64    `json:"total_distance"` // メートル
	TotalSteps          int        `json:"total_steps"`    // 歩数
	PolylineData        *string    `json:"polyline_data"`  // エンコード済みポリライン
	ThumbnailImageURL   *string    `json:"thumbnail_image_url"`
	Status              WalkStatus `json:"status"`
	PausedAt            *time.Time `json:"paused_at"`
	TotalPausedDuration float64    `json:"total_paused_duration"` // 秒
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

// NewWalk は新しいWalkエンティティを生成する
func NewWalk(userID, title, description string) *Walk {
	now := time.Now()
	return &Walk{
		ID:                  uuid.New(),
		UserID:              userID,
		Title:               title,
		Description:         description,
		Status:              StatusNotStarted,
		TotalDistance:       0,
		TotalSteps:          0,
		TotalPausedDuration: 0,
		CreatedAt:           now,
		UpdatedAt:           now,
	}
}

// Start は散歩を開始する
func (w *Walk) Start() error {
	// TODO: バリデーション実装
	// - 既に開始済みの場合はエラー
	// - 完了済みの場合はエラー
	now := time.Now()
	w.StartTime = &now
	w.Status = StatusInProgress
	w.UpdatedAt = now
	return nil
}

// Pause は散歩を一時停止する
func (w *Walk) Pause() error {
	// TODO: バリデーション実装
	// - 進行中でない場合はエラー
	now := time.Now()
	w.PausedAt = &now
	w.Status = StatusPaused
	w.UpdatedAt = now
	return nil
}

// Resume は散歩を再開する
func (w *Walk) Resume() error {
	// TODO: バリデーション実装
	// - 一時停止中でない場合はエラー
	if w.PausedAt != nil {
		pausedDuration := time.Since(*w.PausedAt).Seconds()
		w.TotalPausedDuration += pausedDuration
	}
	w.PausedAt = nil
	w.Status = StatusInProgress
	w.UpdatedAt = time.Now()
	return nil
}

// Complete は散歩を完了する
func (w *Walk) Complete() error {
	// TODO: バリデーション実装
	// - 開始されていない場合はエラー
	// - 既に完了済みの場合はエラー
	now := time.Now()
	w.EndTime = &now
	w.Status = StatusCompleted
	w.UpdatedAt = now
	return nil
}

// UpdateDistance は総距離を更新する
func (w *Walk) UpdateDistance(distance float64) {
	w.TotalDistance = distance
	w.UpdatedAt = time.Now()
}

// UpdateSteps は総歩数を更新する
func (w *Walk) UpdateSteps(steps int) {
	w.TotalSteps = steps
	w.UpdatedAt = time.Now()
}

// IsInProgress は散歩が進行中かどうかを返す
func (w *Walk) IsInProgress() bool {
	return w.Status == StatusInProgress
}

// IsCompleted は散歩が完了済みかどうかを返す
func (w *Walk) IsCompleted() bool {
	return w.Status == StatusCompleted
}
