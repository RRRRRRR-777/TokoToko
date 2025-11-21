package config

import (
	"os"
	"strconv"
)

// Config はアプリケーション設定
type Config struct {
	Environment string
	Port        string
	Database    DatabaseConfig
	Firebase    FirebaseConfig
	Log         LogConfig
}

// DatabaseConfig はデータベース設定
type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	Database string
	SSLMode  string
}

// FirebaseConfig はFirebase設定
type FirebaseConfig struct {
	CredentialsPath string
	ProjectID       string
}

// LogConfig はログ設定
type LogConfig struct {
	Level  string
	Format string // json or text
}

// Load は環境変数から設定を読み込む
func Load() (*Config, error) {
	dbPort, err := strconv.Atoi(getEnv("DB_PORT", "5432"))
	if err != nil {
		dbPort = 5432 // デフォルト値を使用
	}

	return &Config{
		Environment: getEnv("ENVIRONMENT", "development"),
		Port:        getEnv("PORT", "8080"),
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     dbPort,
			User:     getEnv("DB_USER", "postgres"),
			Password: getEnv("DB_PASSWORD", ""),
			Database: getEnv("DB_NAME", "tekutoko"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		Firebase: FirebaseConfig{
			CredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", ""),
			ProjectID:       getEnv("FIREBASE_PROJECT_ID", ""),
		},
		Log: LogConfig{
			Level:  getEnv("LOG_LEVEL", "info"),
			Format: getEnv("LOG_FORMAT", "json"),
		},
	}, nil
}

// getEnv は環境変数を取得する。存在しない場合はデフォルト値を返す
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// IsDevelopment は開発環境かどうかを返す
func (c *Config) IsDevelopment() bool {
	return c.Environment == "development"
}

// IsProduction は本番環境かどうかを返す
func (c *Config) IsProduction() bool {
	return c.Environment == "production"
}
