package config

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLoadFirebaseCredentials(t *testing.T) {
	t.Run("CredentialsJSONが設定されている場合はそれを返す", func(t *testing.T) {
		// 期待値: CredentialsJSONの値がそのまま返される
		cfg := &Config{
			Firebase: FirebaseConfig{
				CredentialsJSON: `{"type":"service_account"}`,
				CredentialsPath: "/some/path",
			},
		}

		result, err := cfg.LoadFirebaseCredentials()

		assert.NoError(t, err)
		assert.Equal(t, `{"type":"service_account"}`, result)
	})

	t.Run("CredentialsPathが設定されている場合はファイルから読み込む", func(t *testing.T) {
		// 期待値: ファイルの内容が返される
		tmpDir := t.TempDir()
		credFile := filepath.Join(tmpDir, "creds.json")
		expectedContent := `{"type":"service_account","project_id":"test"}`
		err := os.WriteFile(credFile, []byte(expectedContent), 0600)
		require.NoError(t, err)

		cfg := &Config{
			Firebase: FirebaseConfig{
				CredentialsJSON: "",
				CredentialsPath: credFile,
			},
		}

		result, err := cfg.LoadFirebaseCredentials()

		assert.NoError(t, err)
		assert.Equal(t, expectedContent, result)
	})

	t.Run("CredentialsPathのファイルが存在しない場合はエラー", func(t *testing.T) {
		// 期待値: ファイル読み込みエラーが返される
		cfg := &Config{
			Firebase: FirebaseConfig{
				CredentialsJSON: "",
				CredentialsPath: "/nonexistent/path/creds.json",
			},
		}

		result, err := cfg.LoadFirebaseCredentials()

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "failed to read firebase credentials file")
		assert.Empty(t, result)
	})

	t.Run("どちらも設定されていない場合は空文字列を返す", func(t *testing.T) {
		// 期待値: 空文字列が返される（開発環境用）
		cfg := &Config{
			Firebase: FirebaseConfig{
				CredentialsJSON: "",
				CredentialsPath: "",
			},
		}

		result, err := cfg.LoadFirebaseCredentials()

		assert.NoError(t, err)
		assert.Empty(t, result)
	})
}

func TestIsDevelopment(t *testing.T) {
	t.Run("development環境の場合はtrueを返す", func(t *testing.T) {
		cfg := &Config{Environment: "development"}
		assert.True(t, cfg.IsDevelopment())
	})

	t.Run("production環境の場合はfalseを返す", func(t *testing.T) {
		cfg := &Config{Environment: "production"}
		assert.False(t, cfg.IsDevelopment())
	})
}

func TestIsProduction(t *testing.T) {
	t.Run("production環境の場合はtrueを返す", func(t *testing.T) {
		cfg := &Config{Environment: "production"}
		assert.True(t, cfg.IsProduction())
	})

	t.Run("development環境の場合はfalseを返す", func(t *testing.T) {
		cfg := &Config{Environment: "development"}
		assert.False(t, cfg.IsProduction())
	})
}
