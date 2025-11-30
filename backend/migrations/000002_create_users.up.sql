-- usersテーブル

CREATE TABLE users (
  id VARCHAR(255) PRIMARY KEY,  -- Firebase Auth UID
  display_name VARCHAR(255),
  auth_provider VARCHAR(50),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- インデックス
CREATE INDEX idx_users_created_at ON users(created_at DESC);
