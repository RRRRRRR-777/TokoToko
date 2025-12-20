package postgres

import (
	"context"
	"database/sql"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/user"
)

// UserRepository はUserのPostgreSQL永続化実装
type UserRepository struct {
	db *sql.DB
}

// NewUserRepository は新しいUserRepositoryを生成する
func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

// FindByID はIDでユーザーを取得する
func (r *UserRepository) FindByID(ctx context.Context, id string) (*user.User, error) {
	query := `
		SELECT id, display_name, auth_provider, created_at, updated_at
		FROM users WHERE id = $1
	`

	u := &user.User{}
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&u.ID, &u.DisplayName, &u.AuthProvider, &u.CreatedAt, &u.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return u, nil
}

// Create は新しいユーザーを作成する
func (r *UserRepository) Create(ctx context.Context, u *user.User) error {
	query := `
		INSERT INTO users (id, display_name, auth_provider, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
	`

	_, err := r.db.ExecContext(
		ctx, query,
		u.ID, u.DisplayName, u.AuthProvider, u.CreatedAt, u.UpdatedAt,
	)
	return err
}

// CreateIfNotExists はユーザーが存在しない場合のみ作成する
func (r *UserRepository) CreateIfNotExists(ctx context.Context, u *user.User) error {
	query := `
		INSERT INTO users (id, display_name, auth_provider, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (id) DO NOTHING
	`

	_, err := r.db.ExecContext(
		ctx, query,
		u.ID, u.DisplayName, u.AuthProvider, u.CreatedAt, u.UpdatedAt,
	)
	return err
}
