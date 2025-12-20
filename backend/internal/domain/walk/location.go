package walk

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// WalkLocation は散歩中の位置情報を表すドメインエンティティ
type WalkLocation struct {
	ID                 int64     `json:"id"`
	WalkID             uuid.UUID `json:"walk_id"`
	Latitude           float64   `json:"latitude"`
	Longitude          float64   `json:"longitude"`
	Altitude           *float64  `json:"altitude,omitempty"`
	Timestamp          time.Time `json:"timestamp"`
	HorizontalAccuracy *float64  `json:"horizontal_accuracy,omitempty"`
	VerticalAccuracy   *float64  `json:"vertical_accuracy,omitempty"`
	Speed              *float64  `json:"speed,omitempty"`
	Course             *float64  `json:"course,omitempty"`
	SequenceNumber     int       `json:"sequence_number"`
}

// NewWalkLocation は新しいWalkLocationエンティティを生成する
func NewWalkLocation(
	walkID uuid.UUID,
	latitude, longitude, altitude float64,
	timestamp time.Time,
	horizontalAccuracy, verticalAccuracy, speed, course float64,
	sequenceNumber int,
) *WalkLocation {
	return &WalkLocation{
		WalkID:             walkID,
		Latitude:           latitude,
		Longitude:          longitude,
		Altitude:           &altitude,
		Timestamp:          timestamp,
		HorizontalAccuracy: &horizontalAccuracy,
		VerticalAccuracy:   &verticalAccuracy,
		Speed:              &speed,
		Course:             &course,
		SequenceNumber:     sequenceNumber,
	}
}

// NewWalkLocationWithOptionals はオプションフィールドをポインタで受け取る
func NewWalkLocationWithOptionals(
	walkID uuid.UUID,
	latitude, longitude float64,
	altitude *float64,
	timestamp time.Time,
	horizontalAccuracy, verticalAccuracy, speed, course *float64,
	sequenceNumber int,
) *WalkLocation {
	return &WalkLocation{
		WalkID:             walkID,
		Latitude:           latitude,
		Longitude:          longitude,
		Altitude:           altitude,
		Timestamp:          timestamp,
		HorizontalAccuracy: horizontalAccuracy,
		VerticalAccuracy:   verticalAccuracy,
		Speed:              speed,
		Course:             course,
		SequenceNumber:     sequenceNumber,
	}
}

// Validate はWalkLocationの値が有効かどうかを検証する
func (l *WalkLocation) Validate() error {
	if l.Latitude < -90 || l.Latitude > 90 {
		return errors.New("latitude must be between -90 and 90")
	}
	if l.Longitude < -180 || l.Longitude > 180 {
		return errors.New("longitude must be between -180 and 180")
	}
	if l.SequenceNumber < 0 {
		return errors.New("sequence number must be non-negative")
	}
	return nil
}
