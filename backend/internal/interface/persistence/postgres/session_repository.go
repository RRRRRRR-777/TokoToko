package postgres

import (
	"context"
	"database/sql"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/session"
	"github.com/google/uuid"
)

// SessionRepository はPostgreSQLを使用したSessionリポジトリ実装
type SessionRepository struct {
	db *sql.DB
}

// NewSessionRepository は新しいSessionRepositoryを生成する
func NewSessionRepository(db *sql.DB) session.Repository {
	return &SessionRepository{
		db: db,
	}
}

// Create は新しいSessionを作成する
func (r *SessionRepository) Create(ctx context.Context, s *session.Session) error {
	query := `
		INSERT INTO sessions (
			id, user_id, refresh_token, user_agent, ip_address,
			expires_at, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8
		)
	`

	_, err := r.db.ExecContext(
		ctx, query,
		s.ID, s.UserID, s.RefreshToken, s.UserAgent, s.IPAddress,
		s.ExpiresAt, s.CreatedAt, s.UpdatedAt,
	)
	if err != nil {
		return err
	}

	return nil
}

// FindByID はIDでSessionを取得する
func (r *SessionRepository) FindByID(ctx context.Context, id uuid.UUID) (*session.Session, error) {
	query := `
		SELECT id, user_id, refresh_token, user_agent, ip_address,
		       expires_at, created_at, updated_at
		FROM sessions
		WHERE id = $1
	`

	s := &session.Session{}
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&s.ID, &s.UserID, &s.RefreshToken, &s.UserAgent, &s.IPAddress,
		&s.ExpiresAt, &s.CreatedAt, &s.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, sql.ErrNoRows
	}
	if err != nil {
		return nil, err
	}

	return s, nil
}

// FindByRefreshToken はリフレッシュトークンでSessionを取得する
func (r *SessionRepository) FindByRefreshToken(ctx context.Context, refreshToken string) (*session.Session, error) {
	query := `
		SELECT id, user_id, refresh_token, user_agent, ip_address,
		       expires_at, created_at, updated_at
		FROM sessions
		WHERE refresh_token = $1
	`

	s := &session.Session{}
	err := r.db.QueryRowContext(ctx, query, refreshToken).Scan(
		&s.ID, &s.UserID, &s.RefreshToken, &s.UserAgent, &s.IPAddress,
		&s.ExpiresAt, &s.CreatedAt, &s.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, sql.ErrNoRows
	}
	if err != nil {
		return nil, err
	}

	return s, nil
}

// FindByUserID はユーザーIDでSessionの一覧を取得する
func (r *SessionRepository) FindByUserID(ctx context.Context, userID string) ([]*session.Session, error) {
	query := `
		SELECT id, user_id, refresh_token, user_agent, ip_address,
		       expires_at, created_at, updated_at
		FROM sessions
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	sessions := make([]*session.Session, 0)
	for rows.Next() {
		s := &session.Session{}
		if err = rows.Scan(
			&s.ID, &s.UserID, &s.RefreshToken, &s.UserAgent, &s.IPAddress,
			&s.ExpiresAt, &s.CreatedAt, &s.UpdatedAt,
		); err != nil {
			return nil, err
		}
		sessions = append(sessions, s)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return sessions, nil
}

// Update はSessionを更新する
func (r *SessionRepository) Update(ctx context.Context, s *session.Session) error {
	query := `
		UPDATE sessions SET
			refresh_token = $2,
			user_agent = $3,
			ip_address = $4,
			expires_at = $5,
			updated_at = $6
		WHERE id = $1
	`

	result, err := r.db.ExecContext(
		ctx, query,
		s.ID, s.RefreshToken, s.UserAgent, s.IPAddress, s.ExpiresAt, s.UpdatedAt,
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

// Delete はSessionを削除する
func (r *SessionRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM sessions WHERE id = $1`

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

// DeleteByUserID はユーザーIDに紐づく全てのSessionを削除する
func (r *SessionRepository) DeleteByUserID(ctx context.Context, userID string) error {
	query := `DELETE FROM sessions WHERE user_id = $1`

	_, err := r.db.ExecContext(ctx, query, userID)
	if err != nil {
		return err
	}

	return nil
}

// DeleteExpired は有効期限切れのSessionを削除する
func (r *SessionRepository) DeleteExpired(ctx context.Context) (int64, error) {
	query := `DELETE FROM sessions WHERE expires_at < NOW()`

	result, err := r.db.ExecContext(ctx, query)
	if err != nil {
		return 0, err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return 0, err
	}

	return rowsAffected, nil
}
