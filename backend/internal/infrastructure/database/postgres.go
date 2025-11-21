package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/config"
	_ "github.com/lib/pq" // PostgreSQLドライバ
)

// PostgresDB はPostgreSQLデータベース接続
type PostgresDB struct {
	*sql.DB
}

// NewPostgresDB は新しいPostgreSQLデータベース接続を作成する
func NewPostgresDB(cfg *config.Config) (*PostgresDB, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Database,
		cfg.Database.SSLMode,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// 接続プール設定
	db.SetMaxOpenConns(25)                 // 最大オープン接続数
	db.SetMaxIdleConns(25)                 // 最大アイドル接続数
	db.SetConnMaxLifetime(5 * time.Minute) // 接続の最大ライフタイム

	// 接続確認
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &PostgresDB{DB: db}, nil
}

// Close はデータベース接続を閉じる
func (db *PostgresDB) Close() error {
	return db.DB.Close()
}

// HealthCheck はデータベースの健全性をチェックする
func (db *PostgresDB) HealthCheck(ctx context.Context) error {
	return db.PingContext(ctx)
}
