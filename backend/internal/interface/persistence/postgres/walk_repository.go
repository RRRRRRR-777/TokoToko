package postgres

import (
	"context"
	"database/sql"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/google/uuid"
)

// WalkRepository はPostgreSQLを使用したWalkリポジトリ実装
type WalkRepository struct {
	db *sql.DB
}

// NewWalkRepository は新しいWalkRepositoryを生成する
func NewWalkRepository(db *sql.DB) walk.Repository {
	return &WalkRepository{
		db: db,
	}
}

// Create は新しいWalkを作成する
func (r *WalkRepository) Create(ctx context.Context, w *walk.Walk) error {
	// TODO: Phase2で実装
	// - INSERT INTO walks ...
	// - トランザクション管理
	// - エラーハンドリング
	return nil
}

// FindByID はIDでWalkを取得する
func (r *WalkRepository) FindByID(ctx context.Context, id uuid.UUID) (*walk.Walk, error) {
	// TODO: Phase2で実装
	// - SELECT * FROM walks WHERE id = $1
	// - スキャン処理
	// - Not Foundエラーハンドリング
	return nil, nil
}

// FindByUserID はユーザーIDでWalkの一覧を取得する
func (r *WalkRepository) FindByUserID(ctx context.Context, userID string, limit, offset int) ([]*walk.Walk, error) {
	// TODO: Phase2で実装
	// - SELECT * FROM walks WHERE user_id = $1 LIMIT $2 OFFSET $3
	// - ORDER BY created_at DESC
	// - スキャン処理
	return nil, nil
}

// Update はWalkを更新する
func (r *WalkRepository) Update(ctx context.Context, w *walk.Walk) error {
	// TODO: Phase2で実装
	// - UPDATE walks SET ... WHERE id = $1
	// - トランザクション管理
	// - 楽観的ロック (updated_at)
	return nil
}

// Delete はWalkを削除する
func (r *WalkRepository) Delete(ctx context.Context, id uuid.UUID) error {
	// TODO: Phase2で実装
	// - DELETE FROM walks WHERE id = $1
	// - カスケード削除 (写真等)
	return nil
}

// Count はユーザーのWalk総数を取得する
func (r *WalkRepository) Count(ctx context.Context, userID string) (int, error) {
	// TODO: Phase2で実装
	// - SELECT COUNT(*) FROM walks WHERE user_id = $1
	return 0, nil
}
