# データベースマイグレーション

## 概要

PostgreSQLデータベースのスキーマ定義ファイル群です。
Docker Composeの`/docker-entrypoint-initdb.d`機能により、ファイル名の番号順に自動実行されます。

## ファイル構成

| ファイル | 内容 | 依存関係 |
|---------|------|---------|
| `001_create_enums.sql` | ENUM型定義（walk_status, consent_type） | なし |
| `002_create_users.sql` | usersテーブル + インデックス | 001 |
| `003_create_walks.sql` | walksテーブル + インデックス | 001, 002 |
| `004_create_walk_locations.sql` | walk_locationsテーブル + インデックス | 003 |
| `005_create_consents.sql` | consentsテーブル + インデックス | 001, 002 |
| `006_create_triggers.sql` | updated_at自動更新トリガー | 002, 003 |

## 実行方法

### ローカル環境（Docker Compose）

```bash
# PostgreSQL起動（初回起動時に自動マイグレーション実行）
docker-compose up -d postgres

# マイグレーション状態確認
docker-compose exec postgres psql -U postgres -d tekutoko -c "\dt"

# ENUM型確認
docker-compose exec postgres psql -U postgres -d tekutoko -c "\dT"

# トリガー確認
docker-compose exec postgres psql -U postgres -d tekutoko -c "SELECT tgname, tgrelid::regclass FROM pg_trigger WHERE tgname LIKE 'update_%';"
```

### データベースリセット

```bash
# コンテナとボリュームを削除（データも削除される）
docker-compose down -v

# 再起動（マイグレーション再実行）
docker-compose up -d postgres
```

## マイグレーション追加ルール

新しいマイグレーションファイルを追加する場合：

1. **ファイル名**: `00X_description.sql`（番号は連番）
2. **依存関係**: 他のテーブルを参照する場合、依存先のファイル番号より大きくする
3. **冪等性**: `CREATE TABLE IF NOT EXISTS`などを使用（推奨）
4. **コメント**: テーブル・カラムの目的を記載

### 例: 新しいテーブル追加

```sql
-- 007_create_photos.sql
CREATE TABLE IF NOT EXISTS photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  walk_id UUID NOT NULL REFERENCES walks(id) ON DELETE CASCADE,
  image_url VARCHAR(500) NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_photos_walk_id ON photos(walk_id);
```

## ロールバック方法

個別テーブルの削除が可能：

```bash
# walk_locationsテーブルのみ削除
docker-compose exec postgres psql -U postgres -d tekutoko -c "DROP TABLE IF EXISTS walk_locations CASCADE;"

# 再マイグレーション（004ファイルのみ手動実行）
docker-compose exec -T postgres psql -U postgres -d tekutoko < migrations/004_create_walk_locations.sql
```

## 注意事項

- **本番環境では手動実行**: Docker Composeの自動実行は開発環境専用
- **バックアップ必須**: 本番マイグレーション前に必ずバックアップ取得
- **段階的実行**: 本番では1ファイルずつ実行して検証
- **外部キー制約**: 依存関係に注意してテーブル削除

## 関連ドキュメント

- [データベーススキーマ設計](../docs/database-schema.md)
- [要件定義書](../docs/requirements.md)
