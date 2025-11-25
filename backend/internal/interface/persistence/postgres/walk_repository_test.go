package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	_ "github.com/lib/pq"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// getEnvOrDefault は環境変数を取得し、存在しない場合はデフォルト値を返す
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// setupTestDB はテスト用のデータベース接続を作成する
func setupTestDB(t *testing.T) *sql.DB {
	host := getEnvOrDefault("DB_HOST", "localhost")
	port := getEnvOrDefault("DB_PORT", "5432")
	user := getEnvOrDefault("DB_USER", "postgres")
	password := getEnvOrDefault("DB_PASSWORD", "postgres")
	dbname := getEnvOrDefault("DB_NAME", "tekutoko")

	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	db, err := sql.Open("postgres", dsn)
	require.NoError(t, err)

	err = db.Ping()
	require.NoError(t, err)

	return db
}

// cleanupTestDB はテストデータをクリーンアップする
func cleanupTestDB(t *testing.T, db *sql.DB) {
	_, err := db.Exec("TRUNCATE TABLE walks, users CASCADE")
	require.NoError(t, err)
}

// createTestUser はテスト用のユーザーを作成する
func createTestUser(t *testing.T, db *sql.DB, userID string) {
	query := `INSERT INTO users (id, display_name, auth_provider) VALUES ($1, $2, $3) ON CONFLICT (id) DO NOTHING`
	_, err := db.Exec(query, userID, "Test User", "google")
	require.NoError(t, err)
}

func TestWalkRepository_Create(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	w := walk.NewWalk("user-123", "Morning Walk", "Beautiful morning walk")

	// Create実行
	err := repo.Create(ctx, w)
	require.NoError(t, err)

	// 検証: FindByIDで取得できることを確認
	found, err := repo.FindByID(ctx, w.ID)
	require.NoError(t, err)
	assert.Equal(t, w.ID, found.ID)
	assert.Equal(t, w.UserID, found.UserID)
	assert.Equal(t, w.Title, found.Title)
	assert.Equal(t, w.Description, found.Description)
	assert.Equal(t, w.Status, found.Status)
}

func TestWalkRepository_FindByID(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	w := walk.NewWalk("user-123", "Test Walk", "Test Description")
	err := repo.Create(ctx, w)
	require.NoError(t, err)

	// FindByID実行
	found, err := repo.FindByID(ctx, w.ID)
	require.NoError(t, err)
	assert.Equal(t, w.ID, found.ID)
	assert.Equal(t, w.UserID, found.UserID)
	assert.Equal(t, w.Title, found.Title)
}

func TestWalkRepository_FindByID_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	// 存在しないIDで検索
	w := walk.NewWalk("user-123", "Test", "Test")
	_, err := repo.FindByID(ctx, w.ID)
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestWalkRepository_FindByUserID(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	userID := "user-123"

	// テスト用ユーザー作成
	createTestUser(t, db, userID)
	createTestUser(t, db, "user-456")

	// 複数のWalkを作成
	w1 := walk.NewWalk(userID, "Walk 1", "Description 1")
	w2 := walk.NewWalk(userID, "Walk 2", "Description 2")
	w3 := walk.NewWalk("user-456", "Walk 3", "Description 3")

	require.NoError(t, repo.Create(ctx, w1))
	time.Sleep(10 * time.Millisecond) // created_atの順序を保証
	require.NoError(t, repo.Create(ctx, w2))
	require.NoError(t, repo.Create(ctx, w3))

	// user-123のWalkを取得
	walks, err := repo.FindByUserID(ctx, userID, 10, 0)
	require.NoError(t, err)
	assert.Len(t, walks, 2)

	// 新しい順にソートされているか確認
	assert.Equal(t, w2.ID, walks[0].ID)
	assert.Equal(t, w1.ID, walks[1].ID)
}

func TestWalkRepository_FindByUserID_Pagination(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	userID := "user-123"

	// テスト用ユーザー作成
	createTestUser(t, db, userID)

	// 5つのWalkを作成
	for i := 0; i < 5; i++ {
		w := walk.NewWalk(userID, "Walk", "Description")
		require.NoError(t, repo.Create(ctx, w))
		time.Sleep(10 * time.Millisecond)
	}

	// ページネーション: limit=2, offset=0
	walks, err := repo.FindByUserID(ctx, userID, 2, 0)
	require.NoError(t, err)
	assert.Len(t, walks, 2)

	// ページネーション: limit=2, offset=2
	walks, err = repo.FindByUserID(ctx, userID, 2, 2)
	require.NoError(t, err)
	assert.Len(t, walks, 2)
}

func TestWalkRepository_Update(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	w := walk.NewWalk("user-123", "Original Title", "Original Description")
	require.NoError(t, repo.Create(ctx, w))

	// 更新
	w.Title = "Updated Title"
	w.Description = "Updated Description"
	w.TotalDistance = 1500.5
	w.TotalSteps = 2000
	w.UpdatedAt = time.Now()

	err := repo.Update(ctx, w)
	require.NoError(t, err)

	// 検証
	found, err := repo.FindByID(ctx, w.ID)
	require.NoError(t, err)
	assert.Equal(t, "Updated Title", found.Title)
	assert.Equal(t, "Updated Description", found.Description)
	assert.Equal(t, 1500.5, found.TotalDistance)
	assert.Equal(t, 2000, found.TotalSteps)
}

func TestWalkRepository_Update_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	// 存在しないWalkを更新
	w := walk.NewWalk("user-123", "Test", "Test")
	err := repo.Update(ctx, w)
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestWalkRepository_Delete(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	// テスト用ユーザー作成
	createTestUser(t, db, "user-123")

	// テストデータ作成
	w := walk.NewWalk("user-123", "Test Walk", "Test Description")
	require.NoError(t, repo.Create(ctx, w))

	// 削除
	err := repo.Delete(ctx, w.ID)
	require.NoError(t, err)

	// 検証: 削除されたことを確認
	_, err = repo.FindByID(ctx, w.ID)
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestWalkRepository_Delete_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	// 存在しないWalkを削除
	w := walk.NewWalk("user-123", "Test", "Test")
	err := repo.Delete(ctx, w.ID)
	assert.ErrorIs(t, err, sql.ErrNoRows)
}

func TestWalkRepository_Count(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()
	defer cleanupTestDB(t, db)

	repo := NewWalkRepository(db)
	ctx := context.Background()

	userID := "user-123"

	// テスト用ユーザー作成
	createTestUser(t, db, userID)
	createTestUser(t, db, "user-456")

	// 初期状態: 0件
	count, err := repo.Count(ctx, userID)
	require.NoError(t, err)
	assert.Equal(t, 0, count)

	// 3つのWalkを作成
	for i := 0; i < 3; i++ {
		w := walk.NewWalk(userID, "Walk", "Description")
		require.NoError(t, repo.Create(ctx, w))
	}

	// カウント確認: 3件
	count, err = repo.Count(ctx, userID)
	require.NoError(t, err)
	assert.Equal(t, 3, count)

	// 別ユーザーのWalkを作成
	w := walk.NewWalk("user-456", "Walk", "Description")
	require.NoError(t, repo.Create(ctx, w))

	// user-123のカウントは変わらない
	count, err = repo.Count(ctx, userID)
	require.NoError(t, err)
	assert.Equal(t, 3, count)
}
