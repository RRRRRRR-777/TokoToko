package user

import "time"

// User はユーザーのドメインエンティティ
type User struct {
	ID           string    `json:"id"` // Firebase Auth UID
	DisplayName  string    `json:"display_name"`
	AuthProvider string    `json:"auth_provider"` // email, google, apple
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// NewUser は新しいUserエンティティを生成する
func NewUser(id, displayName, authProvider string) *User {
	now := time.Now()
	return &User{
		ID:           id,
		DisplayName:  displayName,
		AuthProvider: authProvider,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
}

// UpdateDisplayName は表示名を更新する
func (u *User) UpdateDisplayName(displayName string) {
	u.DisplayName = displayName
	u.UpdatedAt = time.Now()
}
