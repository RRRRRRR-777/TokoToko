package walk

import (
	"context"
	"fmt"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/google/uuid"
)

// interactor はWalk Usecaseの実装
type interactor struct {
	walkRepo walk.Repository
	// TODO: Phase2で追加
	// logger   logger.Logger
}

// NewInteractor は新しいWalk Interactorを生成する
func NewInteractor(walkRepo walk.Repository) Usecase {
	return &interactor{
		walkRepo: walkRepo,
	}
}

// CreateWalk は新しいWalkを作成する
func (i *interactor) CreateWalk(ctx context.Context, input CreateWalkInput) (*walk.Walk, error) {
	// TODO: バリデーション実装

	// Walkエンティティ生成
	w := walk.NewWalk(input.UserID, input.Title, input.Description)

	// 永続化
	if err := i.walkRepo.Create(ctx, w); err != nil {
		return nil, fmt.Errorf("failed to create walk: %w", err)
	}

	return w, nil
}

// GetWalk はIDでWalkを取得する
func (i *interactor) GetWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	w, err := i.walkRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get walk: %w", err)
	}

	// 権限チェック
	if w.UserID != userID {
		return nil, fmt.Errorf("unauthorized")
	}

	return w, nil
}

// ListWalks はユーザーのWalk一覧を取得する
func (i *interactor) ListWalks(ctx context.Context, userID string, limit, offset int) ([]*walk.Walk, int, error) {
	walks, err := i.walkRepo.FindByUserID(ctx, userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list walks: %w", err)
	}

	count, err := i.walkRepo.Count(ctx, userID)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count walks: %w", err)
	}

	return walks, count, nil
}

// UpdateWalk はWalkを更新または作成する（upsert）
// 存在する場合は更新、存在しない場合は新規作成
func (i *interactor) UpdateWalk(ctx context.Context, input UpdateWalkInput, userID string) (*walk.Walk, error) {
	// 既存のWalkを取得（存在しない場合は新規作成）
	w, err := i.walkRepo.FindByID(ctx, input.ID)
	isNew := false
	if err != nil {
		// 存在しない場合は新規作成
		w = walk.NewWalk(userID, "", "")
		w.ID = input.ID
		isNew = true
	} else {
		// 権限チェック（既存レコードの場合のみ）
		if w.UserID != userID {
			return nil, fmt.Errorf("unauthorized")
		}
	}

	// フィールド更新
	if input.Title != nil {
		w.Title = *input.Title
	}
	if input.Description != nil {
		w.Description = *input.Description
	}
	if input.Status != nil {
		w.Status = *input.Status
	}
	if input.TotalSteps != nil {
		w.UpdateSteps(*input.TotalSteps)
	}
	if input.StartTime != nil {
		w.StartTime = input.StartTime
	}
	if input.EndTime != nil {
		w.EndTime = input.EndTime
	}
	if input.TotalDistance != nil {
		w.TotalDistance = *input.TotalDistance
	}
	if input.PolylineData != nil {
		w.PolylineData = input.PolylineData
	}
	if input.ThumbnailImageURL != nil {
		w.ThumbnailImageURL = input.ThumbnailImageURL
	}
	if input.PausedAt != nil {
		w.PausedAt = input.PausedAt
	}
	if input.TotalPausedDuration != nil {
		w.TotalPausedDuration = *input.TotalPausedDuration
	}

	// 新規作成の場合はUserIDを設定
	if isNew {
		w.UserID = userID
	}

	// Upsertで永続化
	if err := i.walkRepo.Upsert(ctx, w); err != nil {
		return nil, fmt.Errorf("failed to upsert walk: %w", err)
	}

	return w, nil
}

// DeleteWalk はWalkを削除する
func (i *interactor) DeleteWalk(ctx context.Context, id uuid.UUID, userID string) error {
	// 権限チェック
	w, err := i.GetWalk(ctx, id, userID)
	if err != nil {
		return err
	}
	if w.UserID != userID {
		return fmt.Errorf("unauthorized")
	}

	// 削除
	if err := i.walkRepo.Delete(ctx, id); err != nil {
		return fmt.Errorf("failed to delete walk: %w", err)
	}

	return nil
}

// StartWalk は散歩を開始する
func (i *interactor) StartWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	w, err := i.GetWalk(ctx, id, userID)
	if err != nil {
		return nil, err
	}

	if err := w.Start(); err != nil {
		return nil, fmt.Errorf("failed to start walk: %w", err)
	}

	if err := i.walkRepo.Update(ctx, w); err != nil {
		return nil, fmt.Errorf("failed to update walk: %w", err)
	}

	return w, nil
}

// PauseWalk は散歩を一時停止する
func (i *interactor) PauseWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	w, err := i.GetWalk(ctx, id, userID)
	if err != nil {
		return nil, err
	}

	if err := w.Pause(); err != nil {
		return nil, fmt.Errorf("failed to pause walk: %w", err)
	}

	if err := i.walkRepo.Update(ctx, w); err != nil {
		return nil, fmt.Errorf("failed to update walk: %w", err)
	}

	return w, nil
}

// ResumeWalk は散歩を再開する
func (i *interactor) ResumeWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	w, err := i.GetWalk(ctx, id, userID)
	if err != nil {
		return nil, err
	}

	if err := w.Resume(); err != nil {
		return nil, fmt.Errorf("failed to resume walk: %w", err)
	}

	if err := i.walkRepo.Update(ctx, w); err != nil {
		return nil, fmt.Errorf("failed to update walk: %w", err)
	}

	return w, nil
}

// CompleteWalk は散歩を完了する
func (i *interactor) CompleteWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
	w, err := i.GetWalk(ctx, id, userID)
	if err != nil {
		return nil, err
	}

	if err := w.Complete(); err != nil {
		return nil, fmt.Errorf("failed to complete walk: %w", err)
	}

	if err := i.walkRepo.Update(ctx, w); err != nil {
		return nil, fmt.Errorf("failed to update walk: %w", err)
	}

	return w, nil
}
