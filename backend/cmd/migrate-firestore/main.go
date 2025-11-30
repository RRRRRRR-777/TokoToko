package main

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"time"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/config"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/database"
	"github.com/joho/godotenv"
	"go.uber.org/zap"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
)

type migrateFlags struct {
	dryRun    bool
	auth      bool
	walks     bool
	locations bool
	consents  bool
}

func main() {
	flags := parseFlags()

	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found")
	}

	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	defer func() { _ = logger.Sync() }()

	if err := run(cfg, logger, flags); err != nil {
		logger.Fatal("Migration failed", zap.Error(err))
	}
}

func parseFlags() migrateFlags {
	flags := migrateFlags{}
	flag.BoolVar(&flags.dryRun, "dry-run", false, "データ数確認のみ")
	flag.BoolVar(&flags.auth, "auth", true, "Firebase Auth → users")
	flag.BoolVar(&flags.walks, "walks", true, "walks → walks")
	flag.BoolVar(&flags.locations, "locations", true, "location_data → walk_locations")
	flag.BoolVar(&flags.consents, "consents", true, "consents → consents")
	flag.Parse()
	return flags
}

func run(cfg *config.Config, logger *zap.Logger, flags migrateFlags) error {
	ctx := context.Background()

	// Firebase初期化
	opts, err := getFirebaseOpts(cfg)
	if err != nil {
		return err
	}

	app, err := firebase.NewApp(ctx, nil, opts...)
	if err != nil {
		return fmt.Errorf("failed to initialize Firebase: %w", err)
	}

	authClient, err := app.Auth(ctx)
	if err != nil {
		return fmt.Errorf("failed to initialize Auth client: %w", err)
	}

	firestoreClient, err := app.Firestore(ctx)
	if err != nil {
		return fmt.Errorf("failed to initialize Firestore client: %w", err)
	}
	defer firestoreClient.Close()

	// PostgreSQL接続
	db, err := database.NewPostgresDB(cfg)
	if err != nil {
		return fmt.Errorf("failed to connect to PostgreSQL: %w", err)
	}
	defer db.Close()

	// ドライラン
	if flags.dryRun {
		logger.Info("=== Dry-run mode ===")
		performDryRun(ctx, firestoreClient, logger)
		return nil
	}

	// 移行実行
	return executeMigrations(ctx, db.DB, authClient, firestoreClient, logger, flags)
}

func getFirebaseOpts(cfg *config.Config) ([]option.ClientOption, error) {
	if cfg.Firebase.CredentialsPath != "" {
		return []option.ClientOption{option.WithCredentialsFile(cfg.Firebase.CredentialsPath)}, nil
	}
	if cfg.Firebase.CredentialsJSON != "" {
		return []option.ClientOption{option.WithCredentialsJSON([]byte(cfg.Firebase.CredentialsJSON))}, nil
	}
	return nil, fmt.Errorf("firebase credentials not configured")
}

func executeMigrations(ctx context.Context, db *sql.DB, authClient *auth.Client, firestoreClient *firestore.Client, logger *zap.Logger, flags migrateFlags) error {
	logger.Info("=== Starting migration ===")

	if flags.auth {
		if err := runMigrateAuth(ctx, db, authClient, logger); err != nil {
			return fmt.Errorf("auth migration failed: %w", err)
		}
	}

	if flags.walks {
		if err := runMigrateWalks(ctx, db, firestoreClient, logger); err != nil {
			return fmt.Errorf("walks migration failed: %w", err)
		}
	}

	if flags.locations {
		if err := runMigrateLocations(ctx, db, firestoreClient, logger); err != nil {
			return fmt.Errorf("locations migration failed: %w", err)
		}
	}

	if flags.consents {
		if err := runMigrateConsents(ctx, db, firestoreClient, logger); err != nil {
			return fmt.Errorf("consents migration failed: %w", err)
		}
	}

	logger.Info("=== Migration completed ===")
	return nil
}

// performDryRun はデータ数をカウント
func performDryRun(ctx context.Context, client *firestore.Client, logger *zap.Logger) {
	// users
	users, _ := client.Collection("users").Documents(ctx).GetAll()
	logger.Info("users", zap.Int("count", len(users)))

	// walks
	walks, _ := client.Collection("walks").Documents(ctx).GetAll()
	logger.Info("walks", zap.Int("count", len(walks)))

	// location_data
	totalLocations := 0
	for _, doc := range walks {
		if arr, ok := doc.Data()["location_data"].([]interface{}); ok {
			totalLocations += len(arr)
		}
	}
	logger.Info("location_data", zap.Int("count", totalLocations))

	// consents
	totalConsents := 0
	for _, doc := range users {
		consents, _ := doc.Ref.Collection("consents").Documents(ctx).GetAll()
		totalConsents += len(consents)
	}
	logger.Info("consents", zap.Int("count", totalConsents))
}

// runMigrateAuth はFirebase Auth → usersテーブル
func runMigrateAuth(ctx context.Context, db *sql.DB, authClient *auth.Client, logger *zap.Logger) error {
	logger.Info("Migrating Firebase Auth → users")

	iter := authClient.Users(ctx, "")
	count := 0

	for {
		user, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return fmt.Errorf("failed to fetch user: %w", err)
		}

		// 認証プロバイダー
		authProvider := "unknown"
		if len(user.ProviderUserInfo) > 0 {
			authProvider = user.ProviderUserInfo[0].ProviderID
		}

		// 表示名
		displayName := user.DisplayName
		if displayName == "" && user.Email != "" {
			displayName = user.Email
		}

		// タイムスタンプ
		createdAt := time.UnixMilli(user.UserMetadata.CreationTimestamp)
		updatedAt := time.UnixMilli(user.UserMetadata.LastLogInTimestamp)
		if updatedAt.IsZero() {
			updatedAt = createdAt
		}

		_, err = db.ExecContext(ctx, `
			INSERT INTO users (id, display_name, auth_provider, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5)
			ON CONFLICT (id) DO UPDATE SET
				display_name = EXCLUDED.display_name,
				auth_provider = EXCLUDED.auth_provider,
				updated_at = EXCLUDED.updated_at
		`, user.UID, displayName, authProvider, createdAt, updatedAt)
		if err != nil {
			return fmt.Errorf("failed to upsert user %s: %w", user.UID, err)
		}

		count++
		if count%100 == 0 {
			logger.Info("Progress", zap.Int("users", count))
		}
	}

	logger.Info("Completed", zap.Int("total_users", count))
	return nil
}

// runMigrateWalks はwalks → walksテーブル
func runMigrateWalks(ctx context.Context, db *sql.DB, client *firestore.Client, logger *zap.Logger) error {
	logger.Info("Migrating walks → walks")

	iter := client.Collection("walks").Documents(ctx)
	count := 0

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return fmt.Errorf("failed to fetch walk: %w", err)
		}

		data := doc.Data()

		// title: NOT NULL制約のためデフォルト値を設定
		title := getString(data, "title")
		if title == "" {
			title = "Untitled"
		}

		// status: ENUM型のためデフォルト値を設定
		status := getString(data, "status")
		if status == "" {
			status = "not_started"
		}

		_, err = db.ExecContext(ctx, `
			INSERT INTO walks (id, user_id, title, description, start_time, end_time,
				total_distance, total_steps, polyline_data, thumbnail_image_url,
				status, paused_at, total_paused_duration, created_at, updated_at)
			VALUES ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11::walk_status, $12, $13, $14, $15)
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
		`,
			doc.Ref.ID,
			getStringOrNil(data, "user_id"),
			title,
			getString(data, "description"),
			getTime(data, "start_time"),
			getTime(data, "end_time"),
			getFloat(data, "total_distance"),
			getInt(data, "total_steps"),
			getStringOrNil(data, "polyline_data"),
			getStringOrNil(data, "thumbnail_image_url"),
			status,
			getTime(data, "paused_at"),
			getFloat(data, "total_paused_duration"),
			getTime(data, "created_at"),
			getTime(data, "updated_at"),
		)
		if err != nil {
			return fmt.Errorf("failed to upsert walk %s: %w", doc.Ref.ID, err)
		}

		count++
		if count%100 == 0 {
			logger.Info("Progress", zap.Int("walks", count))
		}
	}

	logger.Info("Completed", zap.Int("total_walks", count))
	return nil
}

// runMigrateLocations はlocation_data → walk_locationsテーブル
func runMigrateLocations(ctx context.Context, db *sql.DB, client *firestore.Client, logger *zap.Logger) error {
	logger.Info("Migrating location_data → walk_locations")

	iter := client.Collection("walks").Documents(ctx)
	count := 0

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return fmt.Errorf("failed to fetch walk: %w", err)
		}

		walkID := doc.Ref.ID
		locationData, ok := doc.Data()["location_data"].([]interface{})
		if !ok {
			continue
		}

		for i, item := range locationData {
			loc, ok := item.(map[string]interface{})
			if !ok {
				continue
			}

			// NOT NULL制約のバリデーション
			lat := getFloat(loc, "latitude")
			lng := getFloat(loc, "longitude")
			ts := getTime(loc, "timestamp")

			// latitude, longitude, timestampが必須
			if lat == 0 && lng == 0 {
				logger.Warn("Skipping location with zero coordinates",
					zap.String("walk_id", walkID),
					zap.Int("sequence", i))
				continue
			}
			if ts == nil {
				// timestampがない場合は現在時刻を使用
				now := time.Now()
				ts = &now
			}

			_, err = db.ExecContext(ctx, `
				INSERT INTO walk_locations (walk_id, sequence_number, latitude, longitude,
					altitude, timestamp, horizontal_accuracy, vertical_accuracy, speed, course)
				VALUES ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, $10)
				ON CONFLICT (walk_id, sequence_number) DO UPDATE SET
					latitude = EXCLUDED.latitude,
					longitude = EXCLUDED.longitude,
					altitude = EXCLUDED.altitude,
					timestamp = EXCLUDED.timestamp,
					horizontal_accuracy = EXCLUDED.horizontal_accuracy,
					vertical_accuracy = EXCLUDED.vertical_accuracy,
					speed = EXCLUDED.speed,
					course = EXCLUDED.course
			`,
				walkID,
				i,
				lat,
				lng,
				getFloatOrNil(loc, "altitude"),
				ts,
				getFloatOrNil(loc, "horizontal_accuracy"),
				getFloatOrNil(loc, "vertical_accuracy"),
				getFloatOrNil(loc, "speed"),
				getFloatOrNil(loc, "course"),
			)
			if err != nil {
				return fmt.Errorf("failed to upsert location %s[%d]: %w", walkID, i, err)
			}

			count++
		}

		if count%1000 == 0 {
			logger.Info("Progress", zap.Int("locations", count))
		}
	}

	logger.Info("Completed", zap.Int("total_locations", count))
	return nil
}

// runMigrateConsents はconsents → consentsテーブル
func runMigrateConsents(ctx context.Context, db *sql.DB, client *firestore.Client, logger *zap.Logger) error {
	logger.Info("Migrating consents → consents")

	usersIter := client.Collection("users").Documents(ctx)
	count := 0

	for {
		userDoc, err := usersIter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return fmt.Errorf("failed to fetch user: %w", err)
		}

		consentsIter := userDoc.Ref.Collection("consents").Documents(ctx)
		for {
			consentDoc, err := consentsIter.Next()
			if err == iterator.Done {
				break
			}
			if err != nil {
				return fmt.Errorf("failed to fetch consent: %w", err)
			}

			data := consentDoc.Data()

			_, err = db.ExecContext(ctx, `
				INSERT INTO consents (id, user_id, policy_version, consent_type, consented_at, platform, os_version, app_version)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
				ON CONFLICT (id) DO UPDATE SET
					policy_version = EXCLUDED.policy_version,
					consent_type = EXCLUDED.consent_type,
					consented_at = EXCLUDED.consented_at,
					platform = EXCLUDED.platform,
					os_version = EXCLUDED.os_version,
					app_version = EXCLUDED.app_version
			`,
				consentDoc.Ref.ID,
				userDoc.Ref.ID,
				getString(data, "policy_version"),
				getString(data, "consent_type"),
				getTime(data, "consented_at"),
				getString(data, "platform"),
				getString(data, "os_version"),
				getString(data, "app_version"),
			)
			if err != nil {
				return fmt.Errorf("failed to upsert consent %s: %w", consentDoc.Ref.ID, err)
			}

			count++
		}
	}

	logger.Info("Completed", zap.Int("total_consents", count))
	return nil
}

// ヘルパー関数
func getString(data map[string]interface{}, key string) string {
	if v, ok := data[key].(string); ok {
		return v
	}
	return ""
}

func getFloat(data map[string]interface{}, key string) float64 {
	if v, ok := data[key].(float64); ok {
		return v
	}
	return 0
}

func getInt(data map[string]interface{}, key string) int {
	if v, ok := data[key].(int64); ok {
		return int(v)
	}
	if v, ok := data[key].(float64); ok {
		return int(v)
	}
	return 0
}

func getTime(data map[string]interface{}, key string) *time.Time {
	switch v := data[key].(type) {
	case time.Time:
		return &v
	case *time.Time:
		return v
	}
	return nil
}

func getStringOrNil(data map[string]interface{}, key string) *string {
	if v, ok := data[key].(string); ok && v != "" {
		return &v
	}
	return nil
}

func getFloatOrNil(data map[string]interface{}, key string) *float64 {
	if v, ok := data[key].(float64); ok {
		return &v
	}
	return nil
}
