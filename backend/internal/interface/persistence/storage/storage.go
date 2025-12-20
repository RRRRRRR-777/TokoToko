package storage

import (
	"context"
	"io"
)

// Storage はファイルストレージへのインターフェース
type Storage interface {
	// Upload はファイルをアップロードする
	Upload(ctx context.Context, path string, content io.Reader, contentType string) (string, error)

	// Download はファイルをダウンロードする
	Download(ctx context.Context, path string) (io.ReadCloser, error)

	// Delete はファイルを削除する
	Delete(ctx context.Context, path string) error

	// GetURL はファイルの公開URLを取得する
	GetURL(ctx context.Context, path string) (string, error)
}

// CloudStorageClient はCloud Storageのクライアント実装
type CloudStorageClient struct {
	bucketName string
	// TODO: Phase2で実装
	// client *storage.Client
}

// NewCloudStorageClient は新しいCloudStorageClientを生成する
func NewCloudStorageClient(bucketName string) (Storage, error) {
	// TODO: Phase2で実装
	// - Cloud Storage クライアント初期化
	// - バケット存在確認
	return &CloudStorageClient{
		bucketName: bucketName,
	}, nil
}

// Upload はファイルをアップロードする
func (c *CloudStorageClient) Upload(ctx context.Context, path string, content io.Reader, contentType string) (string, error) {
	// TODO: Phase2で実装
	return "", nil
}

// Download はファイルをダウンロードする
func (c *CloudStorageClient) Download(ctx context.Context, path string) (io.ReadCloser, error) {
	// TODO: Phase2で実装
	return nil, nil
}

// Delete はファイルを削除する
func (c *CloudStorageClient) Delete(ctx context.Context, path string) error {
	// TODO: Phase2で実装
	return nil
}

// GetURL はファイルの公開URLを取得する
func (c *CloudStorageClient) GetURL(ctx context.Context, path string) (string, error) {
	// TODO: Phase2で実装
	return "", nil
}
