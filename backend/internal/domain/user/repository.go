package user

import "context"

// Repository はUserの永続化層へのインターフェース
type Repository interface {
	// FindByID はIDでユーザーを取得する
	FindByID(ctx context.Context, id string) (*User, error)

	// Create は新しいユーザーを作成する
	Create(ctx context.Context, user *User) error

	// CreateIfNotExists はユーザーが存在しない場合のみ作成する
	CreateIfNotExists(ctx context.Context, user *User) error
}
