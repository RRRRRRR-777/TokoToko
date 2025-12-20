package walk

import (
	"context"

	"github.com/google/uuid"
)

// LocationRepository はWalkLocationの永続化層へのインターフェース
type LocationRepository interface {
	// BatchCreate は複数のWalkLocationを一括作成する（Upsert）
	BatchCreate(ctx context.Context, locations []*WalkLocation) error

	// FindByWalkID はWalkIDで位置情報を取得する（sequence_number順）
	FindByWalkID(ctx context.Context, walkID uuid.UUID) ([]*WalkLocation, error)

	// DeleteByWalkID はWalkIDに紐づく全ての位置情報を削除する
	DeleteByWalkID(ctx context.Context, walkID uuid.UUID) error
}
