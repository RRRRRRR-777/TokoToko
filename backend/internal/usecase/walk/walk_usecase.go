package walk

import (
	"context"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/google/uuid"
)

// CreateWalkInput はWalk作成の入力
type CreateWalkInput struct {
	UserID      string
	Title       string
	Description string
}

// UpdateWalkInput はWalk更新の入力
// upsert対応: 存在しない場合は新規作成するため、作成に必要なフィールドも含む
type UpdateWalkInput struct {
	ID                  uuid.UUID
	Title               *string
	Description         *string
	Status              *walk.WalkStatus
	TotalSteps          *int
	StartTime           *time.Time
	EndTime             *time.Time
	TotalDistance       *float64
	PolylineData        *string
	ThumbnailImageURL   *string
	PausedAt            *time.Time
	TotalPausedDuration *float64
}

// Usecase はWalkのユースケースインターフェース
type Usecase interface {
	// CreateWalk は新しいWalkを作成する
	CreateWalk(ctx context.Context, input CreateWalkInput) (*walk.Walk, error)

	// GetWalk はIDでWalkを取得する
	GetWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error)

	// ListWalks はユーザーのWalk一覧を取得する
	ListWalks(ctx context.Context, userID string, limit, offset int) ([]*walk.Walk, int, error)

	// UpdateWalk はWalkを更新する
	UpdateWalk(ctx context.Context, input UpdateWalkInput, userID string) (*walk.Walk, error)

	// DeleteWalk はWalkを削除する
	DeleteWalk(ctx context.Context, id uuid.UUID, userID string) error

	// StartWalk は散歩を開始する
	StartWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error)

	// PauseWalk は散歩を一時停止する
	PauseWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error)

	// ResumeWalk は散歩を再開する
	ResumeWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error)

	// CompleteWalk は散歩を完了する
	CompleteWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error)
}
