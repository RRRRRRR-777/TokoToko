package walk_test

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/domain/walk"
)

func TestNewWalkLocation(t *testing.T) {
	// 期待値: 有効なパラメータで WalkLocation が生成される
	walkID := uuid.New()
	timestamp := time.Now()

	location := walk.NewWalkLocation(
		walkID,
		35.6812,  // latitude: 東京駅
		139.7671, // longitude
		40.5,     // altitude
		timestamp,
		5.0,  // horizontalAccuracy
		3.0,  // verticalAccuracy
		1.2,  // speed
		90.0, // course
		0,    // sequenceNumber
	)

	assert.Equal(t, walkID, location.WalkID)
	assert.Equal(t, 35.6812, location.Latitude)
	assert.Equal(t, 139.7671, location.Longitude)
	assert.Equal(t, 40.5, *location.Altitude)
	assert.Equal(t, timestamp, location.Timestamp)
	assert.Equal(t, 5.0, *location.HorizontalAccuracy)
	assert.Equal(t, 3.0, *location.VerticalAccuracy)
	assert.Equal(t, 1.2, *location.Speed)
	assert.Equal(t, 90.0, *location.Course)
	assert.Equal(t, 0, location.SequenceNumber)
}

func TestNewWalkLocation_WithNilOptionalFields(t *testing.T) {
	// 期待値: オプションフィールドがnilでも WalkLocation が生成される
	walkID := uuid.New()
	timestamp := time.Now()

	location := walk.NewWalkLocationWithOptionals(
		walkID,
		35.6812,
		139.7671,
		nil, // altitude
		timestamp,
		nil, // horizontalAccuracy
		nil, // verticalAccuracy
		nil, // speed
		nil, // course
		0,
	)

	assert.Equal(t, walkID, location.WalkID)
	assert.Equal(t, 35.6812, location.Latitude)
	assert.Equal(t, 139.7671, location.Longitude)
	assert.Nil(t, location.Altitude)
	assert.Nil(t, location.HorizontalAccuracy)
	assert.Nil(t, location.VerticalAccuracy)
	assert.Nil(t, location.Speed)
	assert.Nil(t, location.Course)
}

func TestWalkLocation_Validate(t *testing.T) {
	walkID := uuid.New()
	timestamp := time.Now()

	tests := []struct {
		name      string
		latitude  float64
		longitude float64
		wantErr   bool
		errMsg    string
	}{
		{
			// 期待値: 有効な座標でエラーなし
			name:      "valid coordinates",
			latitude:  35.6812,
			longitude: 139.7671,
			wantErr:   false,
		},
		{
			// 期待値: 緯度が-90未満でエラー
			name:      "latitude too low",
			latitude:  -91.0,
			longitude: 139.7671,
			wantErr:   true,
			errMsg:    "latitude must be between -90 and 90",
		},
		{
			// 期待値: 緯度が90超でエラー
			name:      "latitude too high",
			latitude:  91.0,
			longitude: 139.7671,
			wantErr:   true,
			errMsg:    "latitude must be between -90 and 90",
		},
		{
			// 期待値: 経度が-180未満でエラー
			name:      "longitude too low",
			latitude:  35.6812,
			longitude: -181.0,
			wantErr:   true,
			errMsg:    "longitude must be between -180 and 180",
		},
		{
			// 期待値: 経度が180超でエラー
			name:      "longitude too high",
			latitude:  35.6812,
			longitude: 181.0,
			wantErr:   true,
			errMsg:    "longitude must be between -180 and 180",
		},
		{
			// 期待値: 境界値（緯度-90）でエラーなし
			name:      "latitude at lower boundary",
			latitude:  -90.0,
			longitude: 0.0,
			wantErr:   false,
		},
		{
			// 期待値: 境界値（緯度90）でエラーなし
			name:      "latitude at upper boundary",
			latitude:  90.0,
			longitude: 0.0,
			wantErr:   false,
		},
		{
			// 期待値: 境界値（経度-180）でエラーなし
			name:      "longitude at lower boundary",
			latitude:  0.0,
			longitude: -180.0,
			wantErr:   false,
		},
		{
			// 期待値: 境界値（経度180）でエラーなし
			name:      "longitude at upper boundary",
			latitude:  0.0,
			longitude: 180.0,
			wantErr:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			location := walk.NewWalkLocation(
				walkID,
				tt.latitude,
				tt.longitude,
				0.0,
				timestamp,
				0.0,
				0.0,
				0.0,
				0.0,
				0,
			)

			err := location.Validate()

			if tt.wantErr {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.errMsg)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestWalkLocation_ValidateSequenceNumber(t *testing.T) {
	walkID := uuid.New()
	timestamp := time.Now()

	// 期待値: 負のシーケンス番号でエラー
	location := walk.NewWalkLocation(
		walkID,
		35.6812,
		139.7671,
		0.0,
		timestamp,
		0.0,
		0.0,
		0.0,
		0.0,
		-1,
	)

	err := location.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "sequence number must be non-negative")
}
