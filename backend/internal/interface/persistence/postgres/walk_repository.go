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
	query := `
		INSERT INTO walks (
			id, user_id, title, description, start_time, end_time,
			total_distance, total_steps, polyline_data, thumbnail_image_url,
			status, paused_at, total_paused_duration, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
		)
	`

	_, err := r.db.ExecContext(
		ctx, query,
		w.ID, w.UserID, w.Title, w.Description, w.StartTime, w.EndTime,
		w.TotalDistance, w.TotalSteps, w.PolylineData, w.ThumbnailImageURL,
		w.Status, w.PausedAt, w.TotalPausedDuration, w.CreatedAt, w.UpdatedAt,
	)
	if err != nil {
		return err
	}

	return nil
}

// FindByID はIDでWalkを取得する
func (r *WalkRepository) FindByID(ctx context.Context, id uuid.UUID) (*walk.Walk, error) {
	query := `
		SELECT id, user_id, title, description, start_time, end_time,
		       total_distance, total_steps, polyline_data, thumbnail_image_url,
		       status, paused_at, total_paused_duration, created_at, updated_at
		FROM walks
		WHERE id = $1
	`

	w := &walk.Walk{}
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&w.ID, &w.UserID, &w.Title, &w.Description, &w.StartTime, &w.EndTime,
		&w.TotalDistance, &w.TotalSteps, &w.PolylineData, &w.ThumbnailImageURL,
		&w.Status, &w.PausedAt, &w.TotalPausedDuration, &w.CreatedAt, &w.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, sql.ErrNoRows
	}
	if err != nil {
		return nil, err
	}

	return w, nil
}

// FindByUserID はユーザーIDでWalkの一覧を取得する
func (r *WalkRepository) FindByUserID(ctx context.Context, userID string, limit, offset int) ([]*walk.Walk, error) {
	query := `
		SELECT id, user_id, title, description, start_time, end_time,
		       total_distance, total_steps, polyline_data, thumbnail_image_url,
		       status, paused_at, total_paused_duration, created_at, updated_at
		FROM walks
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.QueryContext(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	walks := make([]*walk.Walk, 0)
	for rows.Next() {
		w := &walk.Walk{}
		if err = rows.Scan(
			&w.ID, &w.UserID, &w.Title, &w.Description, &w.StartTime, &w.EndTime,
			&w.TotalDistance, &w.TotalSteps, &w.PolylineData, &w.ThumbnailImageURL,
			&w.Status, &w.PausedAt, &w.TotalPausedDuration, &w.CreatedAt, &w.UpdatedAt,
		); err != nil {
			return nil, err
		}
		walks = append(walks, w)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return walks, nil
}

// Update はWalkを更新する
func (r *WalkRepository) Update(ctx context.Context, w *walk.Walk) error {
	query := `
		UPDATE walks SET
			user_id = $2,
			title = $3,
			description = $4,
			start_time = $5,
			end_time = $6,
			total_distance = $7,
			total_steps = $8,
			polyline_data = $9,
			thumbnail_image_url = $10,
			status = $11,
			paused_at = $12,
			total_paused_duration = $13,
			updated_at = $14
		WHERE id = $1
	`

	result, err := r.db.ExecContext(
		ctx, query,
		w.ID, w.UserID, w.Title, w.Description, w.StartTime, w.EndTime,
		w.TotalDistance, w.TotalSteps, w.PolylineData, w.ThumbnailImageURL,
		w.Status, w.PausedAt, w.TotalPausedDuration, w.UpdatedAt,
	)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// Upsert はWalkを作成または更新する（存在しなければ作成、存在すれば更新）
func (r *WalkRepository) Upsert(ctx context.Context, w *walk.Walk) error {
	query := `
		INSERT INTO walks (
			id, user_id, title, description, start_time, end_time,
			total_distance, total_steps, polyline_data, thumbnail_image_url,
			status, paused_at, total_paused_duration, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
		ON CONFLICT (id) DO UPDATE SET
			user_id = EXCLUDED.user_id,
			title = EXCLUDED.title,
			description = EXCLUDED.description,
			start_time = EXCLUDED.start_time,
			end_time = EXCLUDED.end_time,
			total_distance = EXCLUDED.total_distance,
			total_steps = EXCLUDED.total_steps,
			polyline_data = EXCLUDED.polyline_data,
			thumbnail_image_url = EXCLUDED.thumbnail_image_url,
			status = EXCLUDED.status,
			paused_at = EXCLUDED.paused_at,
			total_paused_duration = EXCLUDED.total_paused_duration,
			updated_at = EXCLUDED.updated_at
	`

	_, err := r.db.ExecContext(
		ctx, query,
		w.ID, w.UserID, w.Title, w.Description, w.StartTime, w.EndTime,
		w.TotalDistance, w.TotalSteps, w.PolylineData, w.ThumbnailImageURL,
		w.Status, w.PausedAt, w.TotalPausedDuration, w.CreatedAt, w.UpdatedAt,
	)
	return err
}

// Delete はWalkを削除する
func (r *WalkRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM walks WHERE id = $1`

	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// Count はユーザーのWalk総数を取得する
func (r *WalkRepository) Count(ctx context.Context, userID string) (int, error) {
	query := `SELECT COUNT(*) FROM walks WHERE user_id = $1`

	var count int
	err := r.db.QueryRowContext(ctx, query, userID).Scan(&count)
	if err != nil {
		return 0, err
	}

	return count, nil
}
