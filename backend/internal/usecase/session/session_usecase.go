package session

import (
	"context"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/session"
	"github.com/google/uuid"
)

// CreateSessionInput はセッション作成の入力
type CreateSessionInput struct {
	UserID    string
	UserAgent string
	IPAddress string
}

// CreateSessionOutput はセッション作成の出力
type CreateSessionOutput struct {
	SessionID    uuid.UUID
	RefreshToken string
	ExpiresAt    time.Time
}

// RefreshSessionInput はセッションリフレッシュの入力
type RefreshSessionInput struct {
	RefreshToken string
	UserAgent    string
	IPAddress    string
}

// RefreshSessionOutput はセッションリフレッシュの出力
type RefreshSessionOutput struct {
	SessionID       uuid.UUID
	NewRefreshToken string
	ExpiresAt       time.Time
}

// Usecase はSessionのユースケースインターフェース
type Usecase interface {
	// CreateSession は新しいセッションを作成する
	CreateSession(ctx context.Context, input CreateSessionInput) (*CreateSessionOutput, error)

	// ValidateSession はセッションの有効性を検証する
	ValidateSession(ctx context.Context, refreshToken string) (*session.Session, error)

	// RefreshSession はセッションをリフレッシュする
	RefreshSession(ctx context.Context, input RefreshSessionInput) (*RefreshSessionOutput, error)

	// RevokeSession はセッションを失効させる
	RevokeSession(ctx context.Context, sessionID uuid.UUID, userID string) error

	// RevokeAllSessions はユーザーの全セッションを失効させる
	RevokeAllSessions(ctx context.Context, userID string) error

	// GetUserSessions はユーザーのセッション一覧を取得する
	GetUserSessions(ctx context.Context, userID string) ([]*session.Session, error)

	// CleanupExpiredSessions は期限切れセッションを削除する
	CleanupExpiredSessions(ctx context.Context) (int64, error)
}
