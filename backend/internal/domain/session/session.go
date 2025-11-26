package session

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// Session はリフレッシュトークンセッションのドメインエンティティ
type Session struct {
	ID           uuid.UUID `json:"id"`
	UserID       string    `json:"user_id"`
	RefreshToken string    `json:"refresh_token"`
	UserAgent    string    `json:"user_agent"`
	IPAddress    string    `json:"ip_address"`
	ExpiresAt    time.Time `json:"expires_at"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// エラー定義
var (
	ErrSessionExpired = errors.New("session has expired")
	ErrSessionInvalid = errors.New("session is invalid")
)

// NewSession は新しいSessionエンティティを生成する
func NewSession(userID, refreshToken, userAgent, ipAddress string, expiresAt time.Time) *Session {
	now := time.Now()
	return &Session{
		ID:           uuid.New(),
		UserID:       userID,
		RefreshToken: refreshToken,
		UserAgent:    userAgent,
		IPAddress:    ipAddress,
		ExpiresAt:    expiresAt,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
}

// IsExpired はセッションが有効期限切れかどうかを返す
func (s *Session) IsExpired() bool {
	return time.Now().After(s.ExpiresAt)
}

// IsValid はセッションが有効かどうかを返す
func (s *Session) IsValid() bool {
	return !s.IsExpired()
}

// Validate はセッションの有効性を検証する
func (s *Session) Validate() error {
	if s.IsExpired() {
		return ErrSessionExpired
	}
	return nil
}

// UpdateRefreshToken はリフレッシュトークンを更新する
func (s *Session) UpdateRefreshToken(newToken string, newExpiresAt time.Time) {
	s.RefreshToken = newToken
	s.ExpiresAt = newExpiresAt
	s.UpdatedAt = time.Now()
}

// UpdateClientInfo はクライアント情報を更新する
func (s *Session) UpdateClientInfo(userAgent, ipAddress string) {
	s.UserAgent = userAgent
	s.IPAddress = ipAddress
	s.UpdatedAt = time.Now()
}
