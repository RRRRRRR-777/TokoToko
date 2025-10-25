package walk

import (
	"context"

	"github.com/google/uuid"
)

// Repository はWalkの永続化層へのインターフェース（依存性逆転の原則）
// Infrastructure層でこのインターフェースを実装する
type Repository interface {
	// Create は新しいWalkを作成する
	Create(ctx context.Context, walk *Walk) error

	// FindByID はIDでWalkを取得する
	FindByID(ctx context.Context, id uuid.UUID) (*Walk, error)

	// FindByUserID はユーザーIDでWalkの一覧を取得する
	FindByUserID(ctx context.Context, userID string, limit, offset int) ([]*Walk, error)

	// Update はWalkを更新する
	Update(ctx context.Context, walk *Walk) error

	// Delete はWalkを削除する
	Delete(ctx context.Context, id uuid.UUID) error

	// Count はユーザーのWalk総数を取得する
	Count(ctx context.Context, userID string) (int, error)
}
