package session

import (
	"context"
	"testing"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/session"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// mockSessionRepository はテスト用のモックリポジトリ
type mockSessionRepository struct {
	sessions map[uuid.UUID]*session.Session
}

func newMockSessionRepository() *mockSessionRepository {
	return &mockSessionRepository{
		sessions: make(map[uuid.UUID]*session.Session),
	}
}

func (m *mockSessionRepository) Create(ctx context.Context, s *session.Session) error {
	m.sessions[s.ID] = s
	return nil
}

func (m *mockSessionRepository) FindByID(ctx context.Context, id uuid.UUID) (*session.Session, error) {
	s, ok := m.sessions[id]
	if !ok {
		return nil, session.ErrSessionInvalid
	}
	return s, nil
}

func (m *mockSessionRepository) FindByRefreshToken(ctx context.Context, refreshToken string) (*session.Session, error) {
	for _, s := range m.sessions {
		if s.RefreshToken == refreshToken {
			return s, nil
		}
	}
	return nil, session.ErrSessionInvalid
}

func (m *mockSessionRepository) FindByUserID(ctx context.Context, userID string) ([]*session.Session, error) {
	var result []*session.Session
	for _, s := range m.sessions {
		if s.UserID == userID {
			result = append(result, s)
		}
	}
	return result, nil
}

func (m *mockSessionRepository) Update(ctx context.Context, s *session.Session) error {
	if _, ok := m.sessions[s.ID]; !ok {
		return session.ErrSessionInvalid
	}
	m.sessions[s.ID] = s
	return nil
}

func (m *mockSessionRepository) Delete(ctx context.Context, id uuid.UUID) error {
	delete(m.sessions, id)
	return nil
}

func (m *mockSessionRepository) DeleteByUserID(ctx context.Context, userID string) error {
	for id, s := range m.sessions {
		if s.UserID == userID {
			delete(m.sessions, id)
		}
	}
	return nil
}

func (m *mockSessionRepository) DeleteExpired(ctx context.Context) (int64, error) {
	var count int64
	now := time.Now()
	for id, s := range m.sessions {
		if s.ExpiresAt.Before(now) {
			delete(m.sessions, id)
			count++
		}
	}
	return count, nil
}

func TestInteractor_CreateSession(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractor(repo)
	ctx := context.Background()

	input := CreateSessionInput{
		UserID:    "user-123",
		UserAgent: "Mozilla/5.0",
		IPAddress: "192.168.1.1",
	}

	output, err := usecase.CreateSession(ctx, input)
	require.NoError(t, err)
	assert.NotEmpty(t, output.SessionID)
	assert.NotEmpty(t, output.RefreshToken)
	assert.True(t, output.ExpiresAt.After(time.Now()))

	// セッションがリポジトリに保存されていることを確認
	assert.Len(t, repo.sessions, 1)
}

func TestInteractor_ValidateSession(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractor(repo)
	ctx := context.Background()

	// セッション作成
	input := CreateSessionInput{
		UserID:    "user-123",
		UserAgent: "Mozilla/5.0",
		IPAddress: "192.168.1.1",
	}
	output, err := usecase.CreateSession(ctx, input)
	require.NoError(t, err)

	// 検証
	s, err := usecase.ValidateSession(ctx, output.RefreshToken)
	require.NoError(t, err)
	assert.Equal(t, "user-123", s.UserID)
}

func TestInteractor_ValidateSession_Expired(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractorWithDuration(repo, -1*time.Hour) // 過去の有効期限
	ctx := context.Background()

	// 期限切れセッション作成
	input := CreateSessionInput{
		UserID:    "user-123",
		UserAgent: "Mozilla/5.0",
		IPAddress: "192.168.1.1",
	}
	output, err := usecase.CreateSession(ctx, input)
	require.NoError(t, err)

	// 検証（期限切れエラー）
	_, err = usecase.ValidateSession(ctx, output.RefreshToken)
	assert.ErrorIs(t, err, session.ErrSessionExpired)
}

func TestInteractor_ValidateSession_NotFound(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractor(repo)
	ctx := context.Background()

	// 存在しないトークンで検証
	_, err := usecase.ValidateSession(ctx, "non-existent-token")
	assert.Error(t, err)
}

func TestInteractor_RefreshSession(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractor(repo)
	ctx := context.Background()

	// セッション作成
	createInput := CreateSessionInput{
		UserID:    "user-123",
		UserAgent: "Mozilla/5.0",
		IPAddress: "192.168.1.1",
	}
	createOutput, err := usecase.CreateSession(ctx, createInput)
	require.NoError(t, err)

	oldRefreshToken := createOutput.RefreshToken

	// リフレッシュ
	refreshInput := RefreshSessionInput{
		RefreshToken: oldRefreshToken,
		UserAgent:    "Chrome/100",
		IPAddress:    "10.0.0.1",
	}
	refreshOutput, err := usecase.RefreshSession(ctx, refreshInput)
	require.NoError(t, err)

	// 新しいトークンが発行されていることを確認
	assert.NotEqual(t, oldRefreshToken, refreshOutput.NewRefreshToken)
	assert.Equal(t, createOutput.SessionID, refreshOutput.SessionID)

	// 古いトークンでは検証できないことを確認
	_, err = usecase.ValidateSession(ctx, oldRefreshToken)
	assert.Error(t, err)

	// 新しいトークンで検証できることを確認
	s, err := usecase.ValidateSession(ctx, refreshOutput.NewRefreshToken)
	require.NoError(t, err)
	assert.Equal(t, "Chrome/100", s.UserAgent)
	assert.Equal(t, "10.0.0.1", s.IPAddress)
}

func TestInteractor_RevokeSession(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractor(repo)
	ctx := context.Background()

	// セッション作成
	input := CreateSessionInput{
		UserID:    "user-123",
		UserAgent: "Mozilla/5.0",
		IPAddress: "192.168.1.1",
	}
	output, err := usecase.CreateSession(ctx, input)
	require.NoError(t, err)

	// 失効
	err = usecase.RevokeSession(ctx, output.SessionID, "user-123")
	require.NoError(t, err)

	// セッションが削除されていることを確認
	assert.Len(t, repo.sessions, 0)
}

func TestInteractor_RevokeSession_Unauthorized(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractor(repo)
	ctx := context.Background()

	// セッション作成
	input := CreateSessionInput{
		UserID:    "user-123",
		UserAgent: "Mozilla/5.0",
		IPAddress: "192.168.1.1",
	}
	output, err := usecase.CreateSession(ctx, input)
	require.NoError(t, err)

	// 別のユーザーで失効を試みる
	err = usecase.RevokeSession(ctx, output.SessionID, "user-456")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "unauthorized")

	// セッションは残っていることを確認
	assert.Len(t, repo.sessions, 1)
}

func TestInteractor_RevokeAllSessions(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractor(repo)
	ctx := context.Background()

	// 複数のセッション作成
	for i := 0; i < 3; i++ {
		input := CreateSessionInput{
			UserID:    "user-123",
			UserAgent: "Mozilla/5.0",
			IPAddress: "192.168.1.1",
		}
		_, err := usecase.CreateSession(ctx, input)
		require.NoError(t, err)
	}

	// 別のユーザーのセッション
	input := CreateSessionInput{
		UserID:    "user-456",
		UserAgent: "Mozilla/5.0",
		IPAddress: "192.168.1.1",
	}
	_, err := usecase.CreateSession(ctx, input)
	require.NoError(t, err)

	assert.Len(t, repo.sessions, 4)

	// user-123の全セッションを失効
	err = usecase.RevokeAllSessions(ctx, "user-123")
	require.NoError(t, err)

	// user-123のセッションのみ削除されていることを確認
	assert.Len(t, repo.sessions, 1)
}

func TestInteractor_GetUserSessions(t *testing.T) {
	repo := newMockSessionRepository()
	usecase := NewInteractor(repo)
	ctx := context.Background()

	// 複数のセッション作成
	for i := 0; i < 3; i++ {
		input := CreateSessionInput{
			UserID:    "user-123",
			UserAgent: "Mozilla/5.0",
			IPAddress: "192.168.1.1",
		}
		_, err := usecase.CreateSession(ctx, input)
		require.NoError(t, err)
	}

	// セッション一覧取得
	sessions, err := usecase.GetUserSessions(ctx, "user-123")
	require.NoError(t, err)
	assert.Len(t, sessions, 3)
}

func TestInteractor_CleanupExpiredSessions(t *testing.T) {
	repo := newMockSessionRepository()
	ctx := context.Background()

	// 有効なセッション
	validSession := session.NewSession("user-123", "valid-token", "Agent", "192.168.1.1", time.Now().Add(24*time.Hour))
	repo.sessions[validSession.ID] = validSession

	// 期限切れセッション
	expiredSession := session.NewSession("user-456", "expired-token", "Agent", "192.168.1.2", time.Now().Add(-1*time.Hour))
	repo.sessions[expiredSession.ID] = expiredSession

	usecase := NewInteractor(repo)

	// クリーンアップ
	count, err := usecase.CleanupExpiredSessions(ctx)
	require.NoError(t, err)
	assert.Equal(t, int64(1), count)

	// 有効なセッションのみ残っていることを確認
	assert.Len(t, repo.sessions, 1)
	_, exists := repo.sessions[validSession.ID]
	assert.True(t, exists)
}

func TestGenerateRefreshToken(t *testing.T) {
	token1, err := generateRefreshToken()
	require.NoError(t, err)
	assert.NotEmpty(t, token1)

	token2, err := generateRefreshToken()
	require.NoError(t, err)
	assert.NotEmpty(t, token2)

	// 毎回異なるトークンが生成されることを確認
	assert.NotEqual(t, token1, token2)
}
