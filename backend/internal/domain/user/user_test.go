package user

import (
	"testing"
	"time"
)

// TestNewUser は NewUser 関数のテスト
func TestNewUser(t *testing.T) {
	tests := []struct {
		name         string
		id           string
		displayName  string
		authProvider string
	}{
		{
			name:         "Googleプロバイダーでユーザー作成",
			id:           "test-uid-123",
			displayName:  "テストユーザー",
			authProvider: "google",
		},
		{
			name:         "Emailプロバイダーでユーザー作成",
			id:           "test-uid-456",
			displayName:  "山田太郎",
			authProvider: "apple",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			before := time.Now()
			user := NewUser(tt.id, tt.displayName, tt.authProvider)
			after := time.Now()

			// IDの検証
			if user.ID != tt.id {
				t.Errorf("ID = %v, want %v", user.ID, tt.id)
			}

			// DisplayNameの検証
			if user.DisplayName != tt.displayName {
				t.Errorf("DisplayName = %v, want %v", user.DisplayName, tt.displayName)
			}

			// AuthProviderの検証
			if user.AuthProvider != tt.authProvider {
				t.Errorf("AuthProvider = %v, want %v", user.AuthProvider, tt.authProvider)
			}

			// CreatedAtが適切な時刻範囲にあるか検証
			if user.CreatedAt.Before(before) || user.CreatedAt.After(after) {
				t.Errorf("CreatedAt = %v, want between %v and %v", user.CreatedAt, before, after)
			}

			// UpdatedAtが適切な時刻範囲にあるか検証
			if user.UpdatedAt.Before(before) || user.UpdatedAt.After(after) {
				t.Errorf("UpdatedAt = %v, want between %v and %v", user.UpdatedAt, before, after)
			}

			// CreatedAtとUpdatedAtが同じか検証（初期状態）
			if !user.CreatedAt.Equal(user.UpdatedAt) {
				t.Errorf("CreatedAt and UpdatedAt should be equal initially")
			}
		})
	}
}

// TestUpdateDisplayName は UpdateDisplayName メソッドのテスト
func TestUpdateDisplayName(t *testing.T) {
	// 初期ユーザー作成
	user := NewUser("test-uid", "初期名前", "google")
	originalCreatedAt := user.CreatedAt
	originalUpdatedAt := user.UpdatedAt

	// 少し待機してタイムスタンプの違いを確保
	time.Sleep(10 * time.Millisecond)

	// 表示名更新
	newDisplayName := "更新後の名前"
	before := time.Now()
	user.UpdateDisplayName(newDisplayName)
	after := time.Now()

	// DisplayNameが更新されているか検証
	if user.DisplayName != newDisplayName {
		t.Errorf("DisplayName = %v, want %v", user.DisplayName, newDisplayName)
	}

	// CreatedAtが変更されていないか検証
	if !user.CreatedAt.Equal(originalCreatedAt) {
		t.Errorf("CreatedAt should not change on update")
	}

	// UpdatedAtが更新されているか検証
	if user.UpdatedAt.Before(before) || user.UpdatedAt.After(after) {
		t.Errorf("UpdatedAt = %v, want between %v and %v", user.UpdatedAt, before, after)
	}

	// UpdatedAtが元の値より後になっているか検証
	if !user.UpdatedAt.After(originalUpdatedAt) {
		t.Errorf("UpdatedAt should be after original value")
	}
}

// TestUpdateDisplayName_Multiple は複数回の更新テスト
func TestUpdateDisplayName_Multiple(t *testing.T) {
	user := NewUser("test-uid", "初期名前", "email")

	updates := []string{"名前1", "名前2", "名前3"}
	var previousUpdatedAt time.Time

	for i, name := range updates {
		if i > 0 {
			time.Sleep(10 * time.Millisecond)
			previousUpdatedAt = user.UpdatedAt
		}

		user.UpdateDisplayName(name)

		// DisplayNameが正しく更新されているか
		if user.DisplayName != name {
			t.Errorf("iteration %d: DisplayName = %v, want %v", i, user.DisplayName, name)
		}

		// 2回目以降はUpdatedAtが増加しているか確認
		if i > 0 && !user.UpdatedAt.After(previousUpdatedAt) {
			t.Errorf("iteration %d: UpdatedAt should increase", i)
		}
	}
}
