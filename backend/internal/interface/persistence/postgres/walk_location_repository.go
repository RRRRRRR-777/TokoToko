package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
	"github.com/google/uuid"
)

// WalkLocationRepository はPostgreSQLを使用したWalkLocationリポジトリ実装
type WalkLocationRepository struct {
	db *sql.DB
}

// NewWalkLocationRepository は新しいWalkLocationRepositoryを生成する
func NewWalkLocationRepository(db *sql.DB) walk.LocationRepository {
	return &WalkLocationRepository{
		db: db,
	}
}

// BatchCreate は複数のWalkLocationを一括作成する（Upsert）
// ON CONFLICT を使用して既存のレコードは更新する
func (r *WalkLocationRepository) BatchCreate(ctx context.Context, locations []*walk.WalkLocation) error {
	if len(locations) == 0 {
		return nil
	}

	// バッチInsertクエリを構築
	valueStrings := make([]string, 0, len(locations))
	valueArgs := make([]interface{}, 0, len(locations)*10)

	for i, loc := range locations {
		base := i * 10
		valueStrings = append(valueStrings, fmt.Sprintf(
			"($%d, $%d, $%d, $%d, $%d, $%d, $%d, $%d, $%d, $%d)",
			base+1, base+2, base+3, base+4, base+5,
			base+6, base+7, base+8, base+9, base+10,
		))
		valueArgs = append(valueArgs,
			loc.WalkID,
			loc.Latitude,
			loc.Longitude,
			loc.Altitude,
			loc.Timestamp,
			loc.HorizontalAccuracy,
			loc.VerticalAccuracy,
			loc.Speed,
			loc.Course,
			loc.SequenceNumber,
		)
	}

	query := fmt.Sprintf(`
		INSERT INTO walk_locations (
			walk_id, latitude, longitude, altitude, timestamp,
			horizontal_accuracy, vertical_accuracy, speed, course, sequence_number
		) VALUES %s
		ON CONFLICT (walk_id, sequence_number) DO UPDATE SET
			latitude = EXCLUDED.latitude,
			longitude = EXCLUDED.longitude,
			altitude = EXCLUDED.altitude,
			timestamp = EXCLUDED.timestamp,
			horizontal_accuracy = EXCLUDED.horizontal_accuracy,
			vertical_accuracy = EXCLUDED.vertical_accuracy,
			speed = EXCLUDED.speed,
			course = EXCLUDED.course
	`, strings.Join(valueStrings, ","))

	_, err := r.db.ExecContext(ctx, query, valueArgs...)
	return err
}

// FindByWalkID はWalkIDで位置情報を取得する（sequence_number順）
func (r *WalkLocationRepository) FindByWalkID(ctx context.Context, walkID uuid.UUID) ([]*walk.WalkLocation, error) {
	query := `
		SELECT id, walk_id, latitude, longitude, altitude, timestamp,
		       horizontal_accuracy, vertical_accuracy, speed, course, sequence_number
		FROM walk_locations
		WHERE walk_id = $1
		ORDER BY sequence_number ASC
	`

	rows, err := r.db.QueryContext(ctx, query, walkID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	locations := make([]*walk.WalkLocation, 0)
	for rows.Next() {
		loc := &walk.WalkLocation{}
		if err = rows.Scan(
			&loc.ID,
			&loc.WalkID,
			&loc.Latitude,
			&loc.Longitude,
			&loc.Altitude,
			&loc.Timestamp,
			&loc.HorizontalAccuracy,
			&loc.VerticalAccuracy,
			&loc.Speed,
			&loc.Course,
			&loc.SequenceNumber,
		); err != nil {
			return nil, err
		}
		locations = append(locations, loc)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return locations, nil
}

// DeleteByWalkID はWalkIDに紐づく全ての位置情報を削除する
func (r *WalkLocationRepository) DeleteByWalkID(ctx context.Context, walkID uuid.UUID) error {
	query := `DELETE FROM walk_locations WHERE walk_id = $1`
	_, err := r.db.ExecContext(ctx, query, walkID)
	return err
}
