package session

import (
	"context"

	"github.com/google/uuid"
)

// Repository はSessionの永続化層へのインターフェース（依存性逆転の原則）
// Infrastructure層でこのインターフェースを実装する
type Repository interface {
	// Create は新しいSessionを作成する
	Create(ctx context.Context, session *Session) error

	// FindByID はIDでSessionを取得する
	FindByID(ctx context.Context, id uuid.UUID) (*Session, error)

	// FindByRefreshToken はリフレッシュトークンでSessionを取得する
	FindByRefreshToken(ctx context.Context, refreshToken string) (*Session, error)

	// FindByUserID はユーザーIDでSessionの一覧を取得する
	FindByUserID(ctx context.Context, userID string) ([]*Session, error)

	// Update はSessionを更新する
	Update(ctx context.Context, session *Session) error

	// Delete はSessionを削除する
	Delete(ctx context.Context, id uuid.UUID) error

	// DeleteByUserID はユーザーIDに紐づく全てのSessionを削除する
	DeleteByUserID(ctx context.Context, userID string) error

	// DeleteExpired は有効期限切れのSessionを削除する
	DeleteExpired(ctx context.Context) (int64, error)
}
