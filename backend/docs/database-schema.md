# データベーススキーマ設計

## ER図

```mermaid
erDiagram
    users ||--o{ walks : "records"
    walks ||--o{ walk_locations : "captures"
    users ||--o{ consents : "grants"

    users {
        string id PK "Firebase Auth UID"
        string display_name "nullable"
        string auth_provider "nullable"
        datetime created_at
        datetime updated_at
    }

    walks {
        uuid id PK
        string user_id FK "nullable"
        string title
        text description
        datetime start_time "nullable"
        datetime end_time "nullable"
        double total_distance
        int total_steps
        text polyline_data "nullable"
        string thumbnail_image_url "nullable"
        string status "not_started/in_progress/paused/completed"
        datetime paused_at "nullable"
        double total_paused_duration "seconds"
        datetime created_at
        datetime updated_at
    }

    walk_locations {
        bigint id PK
        uuid walk_id FK
        int sequence_number
        double latitude
        double longitude
        double altitude
        datetime timestamp
        double horizontal_accuracy
        double vertical_accuracy
        double speed
        double course
    }

    consents {
        uuid id PK
        string user_id FK
        string policy_version
        string consent_type "initial/update"
        datetime consented_at
        string platform "nullable"
        string os_version "nullable"
        string app_version "nullable"
    }
```

## PostgreSQLスキーマ定義

### 1. ENUM型定義

```sql
-- 散歩ステータス
CREATE TYPE walk_status AS ENUM (
  'not_started',
  'in_progress',
  'paused',
  'completed'
);

-- 同意タイプ
CREATE TYPE consent_type AS ENUM (
  'initial',
  'update'
);
```

### 2. テーブル定義

#### users テーブル
```sql
CREATE TABLE users (
  id VARCHAR(255) PRIMARY KEY,  -- Firebase Auth UID
  display_name VARCHAR(255),
  auth_provider VARCHAR(50),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_created_at ON users(created_at DESC);
```

#### walks テーブル
```sql
CREATE TABLE walks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(255) REFERENCES users(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT '',
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  total_distance DOUBLE PRECISION DEFAULT 0.0,
  total_steps INTEGER DEFAULT 0,
  polyline_data TEXT,
  thumbnail_image_url VARCHAR(500),
  status walk_status NOT NULL DEFAULT 'not_started',
  paused_at TIMESTAMP,
  total_paused_duration DOUBLE PRECISION DEFAULT 0.0,  -- seconds
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_walk_times CHECK (
    (start_time IS NULL AND end_time IS NULL) OR
    (start_time IS NOT NULL AND (end_time IS NULL OR end_time >= start_time))
  ),
  CONSTRAINT chk_total_distance CHECK (total_distance >= 0),
  CONSTRAINT chk_total_steps CHECK (total_steps >= 0),
  CONSTRAINT chk_total_paused_duration CHECK (total_paused_duration >= 0)
);

-- インデックス設計
CREATE INDEX idx_walks_user_created_at ON walks(user_id, created_at DESC)
  WHERE user_id IS NOT NULL;
CREATE INDEX idx_walks_status ON walks(status) WHERE status != 'completed';
CREATE INDEX idx_walks_created_at ON walks(created_at DESC);
```

#### walk_locations テーブル
```sql
CREATE TABLE walk_locations (
  id BIGSERIAL PRIMARY KEY,
  walk_id UUID NOT NULL REFERENCES walks(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  altitude DOUBLE PRECISION,
  timestamp TIMESTAMP NOT NULL,
  horizontal_accuracy DOUBLE PRECISION,
  vertical_accuracy DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  course DOUBLE PRECISION,
  sequence_number INTEGER NOT NULL,

  CONSTRAINT chk_latitude CHECK (latitude BETWEEN -90 AND 90),
  CONSTRAINT chk_longitude CHECK (longitude BETWEEN -180 AND 180),
  CONSTRAINT uq_walk_sequence UNIQUE (walk_id, sequence_number)
);

-- インデックス設計
CREATE INDEX idx_walk_locations_walk_seq ON walk_locations(walk_id, sequence_number);
CREATE INDEX idx_walk_locations_walk_time ON walk_locations(walk_id, timestamp);
```

#### consents テーブル
```sql
CREATE TABLE consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  policy_version VARCHAR(50) NOT NULL,
  consent_type consent_type NOT NULL,
  consented_at TIMESTAMP NOT NULL DEFAULT NOW(),
  platform VARCHAR(50),
  os_version VARCHAR(100),
  app_version VARCHAR(50)
);

CREATE INDEX idx_consents_user_consented ON consents(user_id, consented_at DESC);
CREATE INDEX idx_consents_policy_version ON consents(policy_version);
```

### 3. トリガー定義

#### updated_at自動更新トリガー
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_walks_updated_at
  BEFORE UPDATE ON walks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 設計判断の根拠

### 1. 分離テーブル vs JSONB

**walk_locations を分離テーブルとして設計した理由:**
- ✅ 位置情報の個別クエリ・フィルタリングが容易
- ✅ sequence_numberによる順序保証
- ✅ 時系列クエリのパフォーマンス最適化
- ✅ 将来的なPostGIS拡張の可能性

**JSONB型を採用しなかった理由:**
- ❌ 全体の再書き込みが必要（部分更新が困難）
- ❌ 個別ポイントのインデックス化が複雑
- ❌ 大量の位置データでパフォーマンス低下

### 2. インデックス戦略

| テーブル | インデックス | 目的 |
|---------|-------------|------|
| walks | `(user_id, created_at DESC)` | ユーザー別散歩一覧（最新順） |
| walks | `(status)` | ステータスフィルタリング |
| walk_locations | `(walk_id, sequence_number)` | 位置情報の順序取得 |

### 3. 制約設計

- **CHECK制約**: データ整合性保証（緯度経度範囲）
- **UNIQUE制約**: 重複防止（walk_id + sequence_number）
- **FK制約**: 参照整合性（ON DELETE CASCADE）

## マイグレーション戦略

### Phase 2で実施（一括移行）
1. **エクスポート**: Firestore → JSON
2. **変換**: JSON → PostgreSQL INSERT文生成
3. **インポート**: PostgreSQLへバッチインサート
4. **検証**: データ整合性チェック、カウント比較
5. **切り替え**: アプリケーション設定変更

### マイグレーションファイル構成

Phase 2では段階的なロールバックとテーブルごとの管理を可能にするため、マイグレーションファイルを分割する：

```
backend/
  migrations/
    001_create_enums.sql           # ENUM型定義
    002_create_users.sql           # usersテーブル
    003_create_walks.sql           # walksテーブル
    004_create_walk_locations.sql  # walk_locationsテーブル
    005_create_consents.sql        # consentsテーブル
    006_create_triggers.sql        # updated_at自動更新トリガー
    007_create_indexes.sql         # 全インデックス（オプション）
```

**分割の利点**:
- 段階的なロールバックが可能
- テーブルごとの再作成が容易
- 複数人開発時のコンフリクト回避
- マイグレーション履歴の追跡が明確

**実行順序**:
ファイル名の番号順に実行される（Docker Composeの`/docker-entrypoint-initdb.d`）

## 関連ドキュメント
- [要件定義書](./requirements.md)
- [通信プロトコル決定書](./communication-protocol.md)
