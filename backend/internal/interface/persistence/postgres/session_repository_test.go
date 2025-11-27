package postgres

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/session"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// cleanupSessionsTestDB はセッションテストデータをクリーンアップする
func cleanupSessionsTestDB(t *testing.T, db *sql.DB) {
	_, err := db.Exec("TRUNCATE TABLE sessions, users CASCADE")
	require.NoError(t, err)
}

func TestSessionRepository_Create(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	s := session.NewSession("user-123", "refresh-token-abc", "Mozilla/5.0", "192.168.1.1", time.Now().Add(24*time.Hour))

	// Create実行
	err := repo.Create(ctx, s)
	require.NoError(t, err)

	// 検証: FindByIDで取得できることを確認
	found, err := repo.FindByID(ctx, s.ID)
	require.NoError(t, err)
	assert.Equal(t, s.ID, found.ID)
	assert.Equal(t, s.UserID, found.UserID)
	assert.Equal(t, s.RefreshToken, found.RefreshToken)
	assert.Equal(t, s.UserAgent, found.UserAgent)
	assert.Equal(t, s.IPAddress, found.IPAddress)
}

func TestSessionRepository_FindByID(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	s := session.NewSession("user-123", "refresh-token-xyz", "Chrome/100", "10.0.0.1", time.Now().Add(24*time.Hour))
	err := repo.Create(ctx, s)
	require.NoError(t, err)

	// FindByID実行
	found, err := repo.FindByID(ctx, s.ID)
	require.NoError(t, err)
	assert.Equal(t, s.ID, found.ID)
	assert.Equal(t, s.UserID, found.UserID)
	assert.Equal(t, s.RefreshToken, found.RefreshToken)
}

func TestSessionRepository_FindByID_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// 存在しないIDで検索
	_, err := repo.FindByID(ctx, uuid.New())
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestSessionRepository_FindByRefreshToken(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	refreshToken := "unique-refresh-token-12345"
	s := session.NewSession("user-123", refreshToken, "Safari/15", "172.16.0.1", time.Now().Add(24*time.Hour))
	err := repo.Create(ctx, s)
	require.NoError(t, err)

	// FindByRefreshToken実行
	found, err := repo.FindByRefreshToken(ctx, refreshToken)
	require.NoError(t, err)
	assert.Equal(t, s.ID, found.ID)
	assert.Equal(t, s.UserID, found.UserID)
	assert.Equal(t, refreshToken, found.RefreshToken)
}

func TestSessionRepository_FindByRefreshToken_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// 存在しないトークンで検索
	_, err := repo.FindByRefreshToken(ctx, "non-existent-token")
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestSessionRepository_FindByUserID(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	userID := "user-123"

	// テスト用ユーザー作成
	createTestUser(t, db, userID)
	createTestUser(t, db, "user-456")

	// 複数のSessionを作成
	s1 := session.NewSession(userID, "token-1", "Agent-1", "192.168.1.1", time.Now().Add(24*time.Hour))
	s2 := session.NewSession(userID, "token-2", "Agent-2", "192.168.1.2", time.Now().Add(24*time.Hour))
	s3 := session.NewSession("user-456", "token-3", "Agent-3", "192.168.1.3", time.Now().Add(24*time.Hour))

	require.NoError(t, repo.Create(ctx, s1))
	time.Sleep(10 * time.Millisecond) // created_atの順序を保証
	require.NoError(t, repo.Create(ctx, s2))
	require.NoError(t, repo.Create(ctx, s3))

	// user-123のSessionを取得
	sessions, err := repo.FindByUserID(ctx, userID)
	require.NoError(t, err)
	assert.Len(t, sessions, 2)
}

func TestSessionRepository_FindByUserID_Empty(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// Sessionが存在しないユーザー
	sessions, err := repo.FindByUserID(ctx, "user-123")
	require.NoError(t, err)
	assert.Len(t, sessions, 0)
}

func TestSessionRepository_Update(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	s := session.NewSession("user-123", "original-token", "Original Agent", "192.168.1.1", time.Now().Add(24*time.Hour))
	require.NoError(t, repo.Create(ctx, s))

	// 更新
	newExpiresAt := time.Now().Add(48 * time.Hour)
	s.UpdateRefreshToken("updated-token", newExpiresAt)
	s.UpdateClientInfo("Updated Agent", "10.0.0.1")

	err := repo.Update(ctx, s)
	require.NoError(t, err)

	// 検証
	found, err := repo.FindByID(ctx, s.ID)
	require.NoError(t, err)
	assert.Equal(t, "updated-token", found.RefreshToken)
	assert.Equal(t, "Updated Agent", found.UserAgent)
	assert.Equal(t, "10.0.0.1", found.IPAddress)
}

func TestSessionRepository_Update_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// 存在しないSessionを更新
	s := session.NewSession("user-123", "token", "Agent", "192.168.1.1", time.Now().Add(24*time.Hour))
	err := repo.Update(ctx, s)
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestSessionRepository_Delete(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	s := session.NewSession("user-123", "token-to-delete", "Agent", "192.168.1.1", time.Now().Add(24*time.Hour))
	require.NoError(t, repo.Create(ctx, s))

	// 削除
	err := repo.Delete(ctx, s.ID)
	require.NoError(t, err)

	// 検証: 削除されたことを確認
	_, err = repo.FindByID(ctx, s.ID)
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestSessionRepository_Delete_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// 存在しないSessionを削除
	err := repo.Delete(ctx, uuid.New())
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestSessionRepository_DeleteByUserID(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	userID := "user-123"

	// テスト用ユーザー作成
	createTestUser(t, db, userID)
	createTestUser(t, db, "user-456")

	// 複数のSessionを作成
	s1 := session.NewSession(userID, "token-1", "Agent-1", "192.168.1.1", time.Now().Add(24*time.Hour))
	s2 := session.NewSession(userID, "token-2", "Agent-2", "192.168.1.2", time.Now().Add(24*time.Hour))
	s3 := session.NewSession("user-456", "token-3", "Agent-3", "192.168.1.3", time.Now().Add(24*time.Hour))

	require.NoError(t, repo.Create(ctx, s1))
	require.NoError(t, repo.Create(ctx, s2))
	require.NoError(t, repo.Create(ctx, s3))

	// user-123の全Sessionを削除
	err := repo.DeleteByUserID(ctx, userID)
	require.NoError(t, err)

	// 検証: user-123のSessionは存在しない
	sessions, err := repo.FindByUserID(ctx, userID)
	require.NoError(t, err)
	assert.Len(t, sessions, 0)

	// 検証: user-456のSessionは残っている
	sessions, err = repo.FindByUserID(ctx, "user-456")
	require.NoError(t, err)
	assert.Len(t, sessions, 1)
}

func TestSessionRepository_DeleteExpired(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// 期限切れSessionを作成
	expiredSession := session.NewSession("user-123", "expired-token", "Agent", "192.168.1.1", time.Now().Add(-1*time.Hour))
	require.NoError(t, repo.Create(ctx, expiredSession))

	// 有効なSessionを作成
	validSession := session.NewSession("user-123", "valid-token", "Agent", "192.168.1.2", time.Now().Add(24*time.Hour))
	require.NoError(t, repo.Create(ctx, validSession))

	// 期限切れSessionを削除
	deletedCount, err := repo.DeleteExpired(ctx)
	require.NoError(t, err)
	assert.Equal(t, int64(1), deletedCount)

	// 検証: 期限切れSessionは削除されている
	_, err = repo.FindByID(ctx, expiredSession.ID)
	assert.ErrorIs(t, err, sql.ErrNoRows)

	// 検証: 有効なSessionは残っている
	found, err := repo.FindByID(ctx, validSession.ID)
	require.NoError(t, err)
	assert.Equal(t, validSession.ID, found.ID)
}

func TestSessionRepository_DeleteExpired_NoExpired(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupSessionsTestDB(t, db)

	repo := NewSessionRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// 有効なSessionのみ作成
	validSession := session.NewSession("user-123", "valid-token", "Agent", "192.168.1.1", time.Now().Add(24*time.Hour))
	require.NoError(t, repo.Create(ctx, validSession))

	// 期限切れSessionを削除（0件）
	deletedCount, err := repo.DeleteExpired(ctx)
	require.NoError(t, err)
	assert.Equal(t, int64(0), deletedCount)
}
