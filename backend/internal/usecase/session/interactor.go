package session

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/session"
	"github.com/google/uuid"
)

const (
	// RefreshTokenLength はリフレッシュトークンの長さ（バイト）
	RefreshTokenLength = 32
	// DefaultSessionDuration はセッションのデフォルト有効期間
	DefaultSessionDuration = 30 * 24 * time.Hour // 30日
)

// interactor はSession Usecaseの実装
type interactor struct {
	sessionRepo     session.Repository
	sessionDuration time.Duration
}

// NewInteractor は新しいSession Interactorを生成する
func NewInteractor(sessionRepo session.Repository) Usecase {
	return &interactor{
		sessionRepo:     sessionRepo,
		sessionDuration: DefaultSessionDuration,
	}
}

// NewInteractorWithDuration はカスタム有効期間でSession Interactorを生成する
func NewInteractorWithDuration(sessionRepo session.Repository, duration time.Duration) Usecase {
	return &interactor{
		sessionRepo:     sessionRepo,
		sessionDuration: duration,
	}
}

// generateRefreshToken はセキュアなリフレッシュトークンを生成する
func generateRefreshToken() (string, error) {
	b := make([]byte, RefreshTokenLength)
	if _, err := rand.Read(b); err != nil {
		return "", fmt.Errorf("failed to generate refresh token: %w", err)
	}
	return base64.URLEncoding.EncodeToString(b), nil
}

// CreateSession は新しいセッションを作成する
func (i *interactor) CreateSession(ctx context.Context, input CreateSessionInput) (*CreateSessionOutput, error) {
	// リフレッシュトークン生成
	refreshToken, err := generateRefreshToken()
	if err != nil {
		return nil, err
	}

	// 有効期限設定
	expiresAt := time.Now().Add(i.sessionDuration)

	// セッションエンティティ生成
	s := session.NewSession(
		input.UserID,
		refreshToken,
		input.UserAgent,
		input.IPAddress,
		expiresAt,
	)

	// 永続化
	if err := i.sessionRepo.Create(ctx, s); err != nil {
		return nil, fmt.Errorf("failed to create session: %w", err)
	}

	return &CreateSessionOutput{
		SessionID:    s.ID,
		RefreshToken: refreshToken,
		ExpiresAt:    expiresAt,
	}, nil
}

// ValidateSession はセッションの有効性を検証する
func (i *interactor) ValidateSession(ctx context.Context, refreshToken string) (*session.Session, error) {
	s, err := i.sessionRepo.FindByRefreshToken(ctx, refreshToken)
	if err != nil {
		return nil, fmt.Errorf("session not found: %w", err)
	}

	// 有効期限チェック
	if err := s.Validate(); err != nil {
		return nil, err
	}

	return s, nil
}

// RefreshSession はセッションをリフレッシュする
func (i *interactor) RefreshSession(ctx context.Context, input RefreshSessionInput) (*RefreshSessionOutput, error) {
	// 既存セッションを検証
	s, err := i.ValidateSession(ctx, input.RefreshToken)
	if err != nil {
		return nil, err
	}

	// 新しいリフレッシュトークン生成
	newRefreshToken, err := generateRefreshToken()
	if err != nil {
		return nil, err
	}

	// 新しい有効期限
	newExpiresAt := time.Now().Add(i.sessionDuration)

	// セッション更新
	s.UpdateRefreshToken(newRefreshToken, newExpiresAt)
	s.UpdateClientInfo(input.UserAgent, input.IPAddress)

	// 永続化
	if err := i.sessionRepo.Update(ctx, s); err != nil {
		return nil, fmt.Errorf("failed to refresh session: %w", err)
	}

	return &RefreshSessionOutput{
		SessionID:       s.ID,
		NewRefreshToken: newRefreshToken,
		ExpiresAt:       newExpiresAt,
	}, nil
}

// RevokeSession はセッションを失効させる
func (i *interactor) RevokeSession(ctx context.Context, sessionID uuid.UUID, userID string) error {
	// セッション取得
	s, err := i.sessionRepo.FindByID(ctx, sessionID)
	if err != nil {
		return fmt.Errorf("session not found: %w", err)
	}

	// 権限チェック
	if s.UserID != userID {
		return fmt.Errorf("unauthorized: session does not belong to user")
	}

	// 削除
	if err := i.sessionRepo.Delete(ctx, sessionID); err != nil {
		return fmt.Errorf("failed to revoke session: %w", err)
	}

	return nil
}

// RevokeAllSessions はユーザーの全セッションを失効させる
func (i *interactor) RevokeAllSessions(ctx context.Context, userID string) error {
	if err := i.sessionRepo.DeleteByUserID(ctx, userID); err != nil {
		return fmt.Errorf("failed to revoke all sessions: %w", err)
	}
	return nil
}

// GetUserSessions はユーザーのセッション一覧を取得する
func (i *interactor) GetUserSessions(ctx context.Context, userID string) ([]*session.Session, error) {
	sessions, err := i.sessionRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user sessions: %w", err)
	}
	return sessions, nil
}

// CleanupExpiredSessions は期限切れセッションを削除する
func (i *interactor) CleanupExpiredSessions(ctx context.Context) (int64, error) {
	count, err := i.sessionRepo.DeleteExpired(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to cleanup expired sessions: %w", err)
	}
	return count, nil
}
