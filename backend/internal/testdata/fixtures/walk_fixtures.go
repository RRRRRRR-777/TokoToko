package fixtures

import (
	"time"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/google/uuid"
)

// WalkFixtures はテスト用の固定Walkデータセット
type WalkFixtures struct {
	NotStartedWalk    *walk.Walk
	InProgressWalk    *walk.Walk
	PausedWalk        *walk.Walk
	CompletedWalk     *walk.Walk
	CompletedWithData *walk.Walk
}

// NewWalkFixtures は新しいWalkFixturesを生成する
func NewWalkFixtures(userID string) *WalkFixtures {
	now := time.Now()

	// 未開始の散歩
	notStartedWalk := &walk.Walk{
		ID:                  uuid.MustParse("00000000-0000-0000-0000-000000000001"),
		UserID:              userID,
		Title:               "Test Not Started Walk",
		Description:         "This is a test walk that has not started",
		StartTime:           nil,
		EndTime:             nil,
		TotalDistance:       0,
		TotalSteps:          0,
		PolylineData:        nil,
		ThumbnailImageURL:   nil,
		Status:              walk.StatusNotStarted,
		PausedAt:            nil,
		TotalPausedDuration: 0,
		CreatedAt:           now.Add(-10 * time.Minute),
		UpdatedAt:           now.Add(-10 * time.Minute),
	}

	// 進行中の散歩
	startTime := now.Add(-30 * time.Minute)
	polyline := "encoded_polyline_test_data"
	inProgressWalk := &walk.Walk{
		ID:                  uuid.MustParse("00000000-0000-0000-0000-000000000002"),
		UserID:              userID,
		Title:               "Test In Progress Walk",
		Description:         "This is a test walk in progress",
		StartTime:           &startTime,
		EndTime:             nil,
		TotalDistance:       1200.5,
		TotalSteps:          1500,
		PolylineData:        &polyline,
		ThumbnailImageURL:   nil,
		Status:              walk.StatusInProgress,
		PausedAt:            nil,
		TotalPausedDuration: 0,
		CreatedAt:           startTime,
		UpdatedAt:           now,
	}

	// 一時停止中の散歩
	pausedStartTime := now.Add(-45 * time.Minute)
	pausedAt := now.Add(-5 * time.Minute)
	pausedWalk := &walk.Walk{
		ID:                  uuid.MustParse("00000000-0000-0000-0000-000000000003"),
		UserID:              userID,
		Title:               "Test Paused Walk",
		Description:         "This is a test walk that is paused",
		StartTime:           &pausedStartTime,
		EndTime:             nil,
		TotalDistance:       800.0,
		TotalSteps:          1000,
		PolylineData:        nil,
		ThumbnailImageURL:   nil,
		Status:              walk.StatusPaused,
		PausedAt:            &pausedAt,
		TotalPausedDuration: 120.0, // 2分
		CreatedAt:           pausedStartTime,
		UpdatedAt:           pausedAt,
	}

	// 完了した散歩（データなし）
	completedStartTime := now.Add(-2 * time.Hour)
	completedEndTime := now.Add(-1 * time.Hour)
	completedWalk := &walk.Walk{
		ID:                  uuid.MustParse("00000000-0000-0000-0000-000000000004"),
		UserID:              userID,
		Title:               "Test Completed Walk",
		Description:         "This is a test completed walk",
		StartTime:           &completedStartTime,
		EndTime:             &completedEndTime,
		TotalDistance:       2500.0,
		TotalSteps:          3000,
		PolylineData:        nil,
		ThumbnailImageURL:   nil,
		Status:              walk.StatusCompleted,
		PausedAt:            nil,
		TotalPausedDuration: 0,
		CreatedAt:           completedStartTime,
		UpdatedAt:           completedEndTime,
	}

	// 完了した散歩（全データあり）
	completedWithDataStartTime := now.Add(-24 * time.Hour)
	completedWithDataEndTime := now.Add(-23 * time.Hour)
	thumbnail := "https://example.com/test-thumbnail.jpg"
	fullPolyline := "test_encoded_polyline_with_full_data"
	completedWithData := &walk.Walk{
		ID:                  uuid.MustParse("00000000-0000-0000-0000-000000000005"),
		UserID:              userID,
		Title:               "Test Completed Walk with Full Data",
		Description:         "This is a test completed walk with all data",
		StartTime:           &completedWithDataStartTime,
		EndTime:             &completedWithDataEndTime,
		TotalDistance:       5000.0,
		TotalSteps:          6500,
		PolylineData:        &fullPolyline,
		ThumbnailImageURL:   &thumbnail,
		Status:              walk.StatusCompleted,
		PausedAt:            nil,
		TotalPausedDuration: 300.0, // 5分
		CreatedAt:           completedWithDataStartTime,
		UpdatedAt:           completedWithDataEndTime,
	}

	return &WalkFixtures{
		NotStartedWalk:    notStartedWalk,
		InProgressWalk:    inProgressWalk,
		PausedWalk:        pausedWalk,
		CompletedWalk:     completedWalk,
		CompletedWithData: completedWithData,
	}
}

// AllWalks はすべてのFixtureをスライスで返す
func (f *WalkFixtures) AllWalks() []*walk.Walk {
	return []*walk.Walk{
		f.NotStartedWalk,
		f.InProgressWalk,
		f.PausedWalk,
		f.CompletedWalk,
		f.CompletedWithData,
	}
}

// NewMinimalWalk はテスト用の最小限のWalkを生成する
func NewMinimalWalk(userID string) *walk.Walk {
	now := time.Now()
	return &walk.Walk{
		ID:                  uuid.New(),
		UserID:              userID,
		Title:               "Minimal Test Walk",
		Description:         "Minimal test walk",
		StartTime:           nil,
		EndTime:             nil,
		TotalDistance:       0,
		TotalSteps:          0,
		PolylineData:        nil,
		ThumbnailImageURL:   nil,
		Status:              walk.StatusNotStarted,
		PausedAt:            nil,
		TotalPausedDuration: 0,
		CreatedAt:           now,
		UpdatedAt:           now,
	}
}

// NewCompletedWalk はテスト用の完了済みWalkを生成する
func NewCompletedWalk(userID string, distance float64, steps int) *walk.Walk {
	now := time.Now()
	startTime := now.Add(-1 * time.Hour)
	endTime := now

	return &walk.Walk{
		ID:                  uuid.New(),
		UserID:              userID,
		Title:               "Completed Test Walk",
		Description:         "Completed test walk",
		StartTime:           &startTime,
		EndTime:             &endTime,
		TotalDistance:       distance,
		TotalSteps:          steps,
		PolylineData:        nil,
		ThumbnailImageURL:   nil,
		Status:              walk.StatusCompleted,
		PausedAt:            nil,
		TotalPausedDuration: 0,
		CreatedAt:           startTime,
		UpdatedAt:           endTime,
	}
}
