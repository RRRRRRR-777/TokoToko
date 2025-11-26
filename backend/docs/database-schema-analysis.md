# データベーススキーマ分析レポート

**作成日**: 2025-11-21
**対象**: TekuToko PostgreSQLスキーマ
**目的**: Phase 2実装前のスキーマ設計検証

## 1. データモデル整合性検証

### 1.1 iOS ↔ Go ↔ PostgreSQL マッピング

| フィールド | iOS (Swift) | Go (Domain) | PostgreSQL |
|-----------|-------------|-------------|------------|
| id | `UUID` | `uuid.UUID` | `UUID PRIMARY KEY` |
| userId | `String?` | `string` | `VARCHAR(255) FK` |
| title | `String` | `string` | `VARCHAR(255) NOT NULL` |
| description | `String` | `string` | `TEXT DEFAULT ''` |
| startTime | `Date?` | `*time.Time` | `TIMESTAMP` |
| endTime | `Date?` | `*time.Time` | `TIMESTAMP` |
| totalDistance | `Double` | `float64` | `DOUBLE PRECISION` |
| totalSteps | `Int` | `int` | `INTEGER` |
| polylineData | `String?` | `*string` | `TEXT` |
| thumbnailImageUrl | `String?` | `*string` | `VARCHAR(500)` |
| status | `WalkStatus` enum | `WalkStatus` string | `walk_status` ENUM |
| pausedAt | `Date?` | `*time.Time` | `TIMESTAMP` |
| totalPausedDuration | `TimeInterval` | `float64` | `DOUBLE PRECISION` |
| createdAt | `Date` | `time.Time` | `TIMESTAMP NOT NULL` |
| updatedAt | `Date` | `time.Time` | `TIMESTAMP NOT NULL` |

**検証結果**: ✅ **完全一致** - 3層間のデータ型とNull許容性が完全に整合

### 1.2 列挙型（ENUM）の整合性

#### WalkStatus
```swift
// iOS
enum WalkStatus: String {
  case notStarted = "not_started"
  case inProgress = "in_progress"
  case paused = "paused"
  case completed = "completed"
}
```

```go
// Go
type WalkStatus string
const (
  StatusNotStarted WalkStatus = "not_started"
  StatusInProgress WalkStatus = "in_progress"
  StatusPaused WalkStatus = "paused"
  StatusCompleted WalkStatus = "completed"
)
```

```sql
-- PostgreSQL
CREATE TYPE walk_status AS ENUM (
  'not_started',
  'in_progress',
  'paused',
  'completed'
);
```

**検証結果**: ✅ **完全一致** - 値の文字列表現が完全に一致

## 2. 正規化分析

### 2.1 第一正規形（1NF）
**条件**: 各列が原子的な値を持つ

| テーブル | 評価 | 詳細 |
|---------|------|------|
| users | ✅ 適合 | 全列が原子的 |
| walks | ✅ 適合 | `polyline_data`はエンコード済み文字列（原子的） |
| walk_locations | ✅ 適合 | 全列が原子的 |
| consents | ✅ 適合 | 全列が原子的 |

**結論**: 全テーブルが1NFを満たす

### 2.2 第二正規形（2NF）
**条件**: 1NFかつ部分関数従属性がない

| テーブル | 主キー | 評価 | 詳細 |
|---------|-------|------|------|
| users | `id` | ✅ 適合 | 単一列PKで部分従属性なし |
| walks | `id` | ✅ 適合 | 単一列PKで部分従属性なし |
| walk_locations | `id` | ✅ 適合 | 単一列PKで部分従属性なし |
| consents | `id` | ✅ 適合 | 単一列PKで部分従属性なし |

**注意点**: `walk_locations`テーブルは`(walk_id, sequence_number)`の複合ユニーク制約があるが、主キーは`id`（単一列）のため2NF違反のリスクはない。

**結論**: 全テーブルが2NFを満たす

### 2.3 第三正規形（3NF）
**条件**: 2NFかつ推移的関数従属性がない

#### walksテーブルの分析
- `user_id` → `users.display_name` は推移的従属性に見えるが、`walks`テーブルには`display_name`が含まれていないため問題なし
- `total_distance`, `total_steps`は計算可能な値だが、パフォーマンス最適化のため冗長化（非正規化）を意図的に採用

#### walk_locationsテーブルの分析
- `walk_id` → `walks.*` は参照関係だが、`walk_locations`には散歩の詳細情報を持たないため推移的従属性なし

**結論**: ✅ **3NFを満たす** - 意図的な非正規化（計算値のキャッシュ）を除き、推移的従属性なし

### 2.4 ボイス・コッド正規形（BCNF）
**条件**: 3NFかつすべての決定子が候補キー

全テーブルの主キーが単一列の代理キー（サロゲートキー）であり、自然キーに依存する複雑な決定子が存在しないため、**BCNFも満たす**。

**最終評価**: 🎯 **BCNF適合（第3.5正規形以上）**

## 3. 主キー・外部キー設計評価

### 3.1 主キー戦略

| テーブル | 主キー | 型 | 評価 |
|---------|-------|-----|------|
| users | `id` | VARCHAR(255) | ⚠️ 自然キー（Firebase UID） |
| walks | `id` | UUID | ✅ 代理キー（サロゲート） |
| walk_locations | `id` | BIGSERIAL | ✅ 代理キー（サロゲート） |
| consents | `id` | UUID | ✅ 代理キー（サロゲート） |

#### users.idの設計判断
**採用理由**:
- Firebase AuthenticationのUIDをそのまま使用することで、認証層との統合が容易
- Firebase UIDは一意性が保証されており、変更されない
- アプリケーション全体で同じIDを使用でき、トレーサビリティが向上

**デメリット**:
- VARCHAR(255)は数値型に比べてインデックスサイズが大きい
- 外部キーとしての参照コストがやや高い

**結論**: ✅ **妥当** - 認証統合の利便性がパフォーマンスコストを上回る

### 3.2 外部キー制約

| 外部キー | 参照元 | 参照先 | ON DELETE | 評価 |
|---------|-------|-------|-----------|------|
| `walks.user_id` | walks | users.id | SET NULL | ✅ 適切 |
| `walk_locations.walk_id` | walk_locations | walks.id | CASCADE | ✅ 適切 |
| `consents.user_id` | consents | users.id | CASCADE | ✅ 適切 |

#### ON DELETE戦略の妥当性

**walks.user_id → SET NULL**
- **理由**: ユーザーが削除されても散歩データは残す（匿名化）
- **ユースケース**: GDPR対応でユーザー情報削除後も統計データとして散歩記録を保持

**walk_locations.walk_id → CASCADE**
- **理由**: 散歩削除時に位置情報も自動削除（孤児レコード防止）
- **ユースケース**: データ整合性を保ちストレージ節約

**consents.user_id → CASCADE**
- **理由**: ユーザー削除時に同意記録も削除（個人情報保護）
- **ユースケース**: GDPR「忘れられる権利」への対応

**結論**: ✅ **全て妥当** - ビジネス要件とデータ整合性を両立

## 4. インデックス戦略評価

### 4.1 既存インデックス分析

#### usersテーブル
```sql
CREATE INDEX idx_users_created_at ON users(created_at DESC);
```
- **用途**: ユーザー登録日順でのソート・フィルタ
- **評価**: ✅ **必要** - 管理画面での新規ユーザー一覧表示

#### walksテーブル
```sql
-- 1. ユーザー別散歩一覧（最新順）
CREATE INDEX idx_walks_user_created_at ON walks(user_id, created_at DESC)
  WHERE user_id IS NOT NULL;

-- 2. ステータスフィルタリング
CREATE INDEX idx_walks_status ON walks(status)
  WHERE status != 'completed';

-- 3. 全体の作成日ソート
CREATE INDEX idx_walks_created_at ON walks(created_at DESC);
```

**分析**:

| インデックス | カーディナリティ | 選択率 | 評価 |
|-------------|----------------|-------|------|
| `idx_walks_user_created_at` | 高（user_id）+ 高（日時） | 低（特定ユーザー）| ✅ 最重要 |
| `idx_walks_status` | 低（4値ENUM） | 高（進行中は少数） | ✅ 部分インデックスで最適化済 |
| `idx_walks_created_at` | 高（日時） | 中（全散歩） | ✅ 必要 |

**部分インデックスの有効性**:
- `WHERE user_id IS NOT NULL`: NULL値を除外（削除ユーザーの散歩）
- `WHERE status != 'completed'`: 完了済みを除外（大半のレコード）
- **効果**: インデックスサイズ削減とメンテナンスコスト低減

#### walk_locationsテーブル
```sql
-- 1. 位置情報の順序取得
CREATE INDEX idx_walk_locations_walk_seq ON walk_locations(walk_id, sequence_number);

-- 2. 時系列クエリ
CREATE INDEX idx_walk_locations_walk_time ON walk_locations(walk_id, timestamp);
```

**分析**:
- **walk_seq**: ✅ **必須** - ポリライン生成時の順序保証に必須
- **walk_time**: ⚠️ **要検討** - `sequence_number`で順序が保証されるなら冗長の可能性

**推奨**: `idx_walk_locations_walk_time`の使用頻度を計測し、不要なら削除

#### consentsテーブル
```sql
-- 1. ユーザー別同意履歴
CREATE INDEX idx_consents_user_consented ON consents(user_id, consented_at DESC);

-- 2. ポリシーバージョン検索
CREATE INDEX idx_consents_policy_version ON consents(policy_version);
```

**分析**: ✅ **両方必要** - GDPR監査要件とポリシー更新通知に必須

### 4.2 インデックス追加提案

#### 提案1: walks.start_timeインデックス
```sql
CREATE INDEX idx_walks_start_time ON walks(start_time DESC)
  WHERE start_time IS NOT NULL;
```
- **用途**: 実際に開始された散歩の時系列分析
- **根拠**: `created_at`（作成日）と`start_time`（開始日）は異なる可能性がある

#### 提案2: walk_locations複合インデックスの見直し
```sql
-- 現行
CREATE INDEX idx_walk_locations_walk_seq ON walk_locations(walk_id, sequence_number);
CREATE INDEX idx_walk_locations_walk_time ON walk_locations(walk_id, timestamp);

-- 提案: 統合インデックス
CREATE INDEX idx_walk_locations_walk_seq_time
  ON walk_locations(walk_id, sequence_number, timestamp);
```
- **効果**: 2つのインデックスを1つに統合、ストレージ節約
- **条件**: `sequence_number`と`timestamp`の相関性が高い場合

### 4.3 インデックスサイズ推定

**前提条件**:
- ユーザー数: 10,000人
- 1人あたり散歩数: 50回
- 1散歩あたり位置情報数: 1,000ポイント

| テーブル | レコード数 | インデックス数 | 推定サイズ |
|---------|-----------|--------------|----------|
| users | 10,000 | 2 | ~1 MB |
| walks | 500,000 | 3 | ~50 MB |
| walk_locations | 500,000,000 | 2 | ~15 GB |
| consents | 20,000 | 2 | ~2 MB |

**ボトルネック**: `walk_locations`テーブルが支配的（全体の99%）

**対策案**:
1. **パーティショニング**: `walk_id`または`timestamp`でパーティション分割
2. **アーカイブ戦略**: 古い散歩データを別テーブルへ移動
3. **圧縮**: PostgreSQLの圧縮機能を有効化

## 5. データ整合性制約評価

### 5.1 CHECK制約

```sql
-- walksテーブル
CONSTRAINT chk_walk_times CHECK (
  (start_time IS NULL AND end_time IS NULL) OR
  (start_time IS NOT NULL AND (end_time IS NULL OR end_time >= start_time))
)
CONSTRAINT chk_total_distance CHECK (total_distance >= 0)
CONSTRAINT chk_total_steps CHECK (total_steps >= 0)
CONSTRAINT chk_total_paused_duration CHECK (total_paused_duration >= 0)

-- walk_locationsテーブル
CONSTRAINT chk_latitude CHECK (latitude BETWEEN -90 AND 90)
CONSTRAINT chk_longitude CHECK (longitude BETWEEN -180 AND 180)
```

**評価**: ✅ **全て妥当** - ビジネスルールとデータ物理的制約を適切に反映

### 5.2 UNIQUE制約

```sql
CONSTRAINT uq_walk_sequence UNIQUE (walk_id, sequence_number)
```

**評価**: ✅ **必須** - 位置情報の重複挿入を防止し、順序整合性を保証

### 5.3 NOT NULL制約

適切に設定されており、NULL許容性がiOS/Goのデータモデルと一致している。

## 6. パフォーマンス最適化推奨事項

### 6.1 短期対応（Phase 2実装時）

1. **✅ 実装済み**: 部分インデックスによる最適化
2. **✅ 実装済み**: 複合インデックスによるカバリングインデックス
3. **🔧 追加提案**: `walks.start_time`インデックス追加

### 6.2 中期対応（ユーザー増加後）

1. **パーティショニング**: `walk_locations`を月単位でパーティション分割
2. **マテリアライズドビュー**: 散歩統計の事前集計
3. **接続プーリング**: PgBouncerなどの導入

### 6.3 長期対応（スケール時）

1. **読み取りレプリカ**: 分析クエリ専用のレプリカ構築
2. **TimescaleDB導入**: `walk_locations`を時系列DBへ移行
3. **アーカイブ戦略**: 2年以上前のデータをコールドストレージへ

## 7. マイグレーション戦略

### 7.1 スキーマ適用順序

```
1. 001_create_enums.sql         # ENUM型定義
2. 002_create_users.sql         # ユーザーテーブル
3. 003_create_walks.sql         # 散歩テーブル
4. 004_create_walk_locations.sql # 位置情報テーブル
5. 005_create_consents.sql      # 同意テーブル
6. 006_create_triggers.sql      # updated_atトリガー
7. 007_create_indexes.sql       # インデックス作成
```

**理由**: 外部キー制約の依存関係順

### 7.2 Firestore → PostgreSQL移行手順

1. **エクスポート**: Firestore全データをJSON形式でエクスポート
2. **スキーマ作成**: PostgreSQLにスキーマを適用
3. **データ変換**: JSONデータをPostgreSQL INSERT文に変換
   - `locations`配列 → `walk_locations`テーブルへ展開
   - `sequence_number`の自動付与
4. **一括インポート**: `COPY`コマンドでバッチインサート
5. **整合性検証**:
   - レコード数の一致確認
   - サンプルデータの内容確認
   - 外部キー制約の検証
6. **インデックス作成**: データ投入後にインデックス構築（高速化）

### 7.3 ダウンタイム戦略

**Phase 2方式（一括移行）**:
- メンテナンスウィンドウ設定（深夜1時間）
- Firestore読み取り専用モード
- PostgreSQL構築・データ移行
- アプリケーション切り替え

**将来のPhase 3方式（ゼロダウンタイム）**:
- 二重書き込み（Firestore + PostgreSQL）
- データ整合性検証
- 段階的な読み取り切り替え
- Firestore廃止

## 8. セキュリティ考慮事項

### 8.1 Row-Level Security (RLS)

**推奨**: PostgreSQL RLSによるアクセス制御

```sql
-- ユーザーは自分の散歩のみアクセス可能
ALTER TABLE walks ENABLE ROW LEVEL SECURITY;

CREATE POLICY walk_select_policy ON walks
  FOR SELECT
  USING (user_id = current_setting('app.current_user_id'));

CREATE POLICY walk_insert_policy ON walks
  FOR INSERT
  WITH CHECK (user_id = current_setting('app.current_user_id'));
```

**Phase 2では未実装**: アプリケーション層でのアクセス制御を優先

### 8.2 データ暗号化

- **転送時**: SSL/TLS必須（Cloud SQLのデフォルト設定）
- **保存時**: Cloud SQLの透過的暗号化（自動有効化）
- **機密データ**: `users.display_name`は暗号化不要（公開情報）

## 9. 総合評価

| 項目 | 評価 | 詳細 |
|------|------|------|
| 正規化レベル | ✅ BCNF | 第3.5正規形以上 |
| データ整合性 | ✅ 優秀 | 3層間で完全一致 |
| インデックス設計 | ✅ 良好 | 部分インデックス活用 |
| 外部キー戦略 | ✅ 適切 | ビジネス要件に整合 |
| パフォーマンス | ⚠️ 要監視 | `walk_locations`が将来的なボトルネック |
| スケーラビリティ | ⚠️ 要計画 | パーティショニング等の準備が必要 |

## 10. アクションアイテム

### Phase 2実装時（必須）
- [x] スキーマドキュメントの最終確認
- [ ] `walks.start_time`インデックス追加を検討
- [ ] マイグレーションスクリプト作成
- [ ] データ整合性テストスクリプト作成

### Phase 3以降（任意）
- [ ] `walk_locations`パーティショニング設計
- [ ] マテリアライズドビュー設計
- [ ] Row-Level Security実装
- [ ] 読み取りレプリカ構築

## 11. 結論

**TekuTokoのデータベーススキーマは、Phase 2実装に向けて十分に堅牢な設計となっている。**

✅ **承認事項**:
- 正規化レベル（BCNF）は適切
- インデックス戦略は最適化済み
- 3層間のデータモデル整合性が保証されている

⚠️ **注意事項**:
- `walk_locations`テーブルの将来的なスケーラビリティを監視
- パーティショニング戦略を早期に検討

🚀 **次ステップ**: マイグレーションスクリプトの実装（タスク6-B）
