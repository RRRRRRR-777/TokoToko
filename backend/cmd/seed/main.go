package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/config"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/database"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/interface/persistence/postgres"
	"github.com/google/uuid"
	"github.com/joho/godotenv"
)

func main() {
	// .envファイルを読み込む（開発環境用）
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// 設定読み込み
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// データベース接続
	db, err := database.NewPostgresDB(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	ctx := context.Background()

	// リポジトリの初期化
	walkRepo := postgres.NewWalkRepository(db.DB)

	log.Println("Starting seed data insertion...")

	// テストユーザーのID
	testUsers := []string{
		"test-user-001",
		"test-user-002",
		"test-user-003",
	}

	// ユーザーデータを先に挿入
	for _, userID := range testUsers {
		if err := seedUser(ctx, db, userID); err != nil {
			log.Fatalf("Failed to seed user %s: %v", userID, err)
		}
		log.Printf("Successfully seeded user: %s", userID)
	}

	// 各ユーザーにサンプルデータを作成
	for _, userID := range testUsers {
		if err := seedWalksForUser(ctx, walkRepo, userID); err != nil {
			log.Fatalf("Failed to seed data for user %s: %v", userID, err)
		}
		log.Printf("Successfully seeded walk data for user: %s", userID)
	}

	log.Println("Seed data insertion completed successfully!")
}

func seedUser(ctx context.Context, db *database.PostgresDB, userID string) error {
	query := `
		INSERT INTO users (id, display_name, auth_provider, created_at, updated_at)
		VALUES ($1, $2, $3, NOW(), NOW())
		ON CONFLICT (id) DO NOTHING
	`

	displayName := fmt.Sprintf("Test User %s", userID[len(userID)-3:])
	_, err := db.ExecContext(ctx, query, userID, displayName, "email")
	if err != nil {
		return fmt.Errorf("failed to insert user: %w", err)
	}

	return nil
}

func seedWalksForUser(ctx context.Context, repo walk.Repository, userID string) error {
	// 1. 未開始の散歩
	notStartedWalk := walk.NewWalk(userID, "朝の散歩予定", "今朝の散歩コース")
	if err := repo.Create(ctx, notStartedWalk); err != nil {
		return fmt.Errorf("failed to create not_started walk: %w", err)
	}

	// 2. 進行中の散歩
	inProgressWalk := walk.NewWalk(userID, "公園散歩中", "近所の公園を散歩中")
	if err := inProgressWalk.Start(); err != nil {
		return fmt.Errorf("failed to start walk: %w", err)
	}
	inProgressWalk.UpdateDistance(1500.0)
	inProgressWalk.UpdateSteps(2000)
	polyline := "encoded_polyline_data_example"
	inProgressWalk.PolylineData = &polyline
	if err := repo.Create(ctx, inProgressWalk); err != nil {
		return fmt.Errorf("failed to create in_progress walk: %w", err)
	}

	// 3. 一時停止中の散歩
	pausedWalk := walk.NewWalk(userID, "休憩中の散歩", "途中で休憩中")
	if err := pausedWalk.Start(); err != nil {
		return fmt.Errorf("failed to start paused walk: %w", err)
	}
	pausedWalk.UpdateDistance(800.0)
	pausedWalk.UpdateSteps(1000)
	if err := pausedWalk.Pause(); err != nil {
		return fmt.Errorf("failed to pause walk: %w", err)
	}
	if err := repo.Create(ctx, pausedWalk); err != nil {
		return fmt.Errorf("failed to create paused walk: %w", err)
	}

	// 4. 完了した散歩（今日）
	completedTodayWalk := createCompletedWalk(userID, "今日の散歩", "朝の散歩完了", 0)
	completedTodayWalk.UpdateDistance(3000.0)
	completedTodayWalk.UpdateSteps(4000)
	thumbnail := "https://example.com/thumbnail1.jpg"
	completedTodayWalk.ThumbnailImageURL = &thumbnail
	if err := repo.Create(ctx, completedTodayWalk); err != nil {
		return fmt.Errorf("failed to create completed today walk: %w", err)
	}

	// 5. 完了した散歩（昨日）
	completedYesterdayWalk := createCompletedWalk(userID, "昨日の夕方散歩", "夕方に公園を散歩", 1)
	completedYesterdayWalk.UpdateDistance(2500.0)
	completedYesterdayWalk.UpdateSteps(3200)
	if err := repo.Create(ctx, completedYesterdayWalk); err != nil {
		return fmt.Errorf("failed to create completed yesterday walk: %w", err)
	}

	// 6. 完了した散歩（1週間前）
	completedWeekAgoWalk := createCompletedWalk(userID, "先週の長距離散歩", "公園周辺を長時間散歩", 7)
	completedWeekAgoWalk.UpdateDistance(5000.0)
	completedWeekAgoWalk.UpdateSteps(6500)
	if err := repo.Create(ctx, completedWeekAgoWalk); err != nil {
		return fmt.Errorf("failed to create completed week ago walk: %w", err)
	}

	// 7. 完了した散歩（1ヶ月前）
	completedMonthAgoWalk := createCompletedWalk(userID, "先月の散歩", "ハイキングコース", 30)
	completedMonthAgoWalk.UpdateDistance(8000.0)
	completedMonthAgoWalk.UpdateSteps(10000)
	if err := repo.Create(ctx, completedMonthAgoWalk); err != nil {
		return fmt.Errorf("failed to create completed month ago walk: %w", err)
	}

	return nil
}

// createCompletedWalk は指定日数前に完了した散歩を生成する
func createCompletedWalk(userID, title, description string, daysAgo int) *walk.Walk {
	w := walk.NewWalk(userID, title, description)

	// 指定日数前の時刻を計算
	targetDate := time.Now().AddDate(0, 0, -daysAgo)
	startTime := targetDate.Add(-1 * time.Hour) // 1時間の散歩
	endTime := targetDate

	w.ID = uuid.New()
	w.StartTime = &startTime
	w.EndTime = &endTime
	w.Status = walk.StatusCompleted
	w.CreatedAt = startTime
	w.UpdatedAt = endTime

	return w
}
