# データベースメンテナンス Runbook

## 定期メンテナンス

### バックアップ確認（毎週月曜）
```bash
# バックアップ一覧確認
gcloud sql backups list --instance=tekutoko-production

# 最新バックアップの詳細
gcloud sql backups describe BACKUP_ID --instance=tekutoko-production
```

### インデックス最適化（月次）
```bash
# 未使用インデックス確認
kubectl exec -it deployment/tekutoko-api -n default -- \
  psql -h localhost -U tekutoko -d tekutoko_production -c "
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;
"

# VACUUM実行（テーブル最適化）
kubectl exec -it deployment/tekutoko-api -n default -- \
  psql -h localhost -U tekutoko -d tekutoko_production -c "VACUUM ANALYZE;"
```

### 接続数確認（毎日）
```bash
# 現在の接続数
kubectl exec -it deployment/tekutoko-api -n default -- \
  psql -h localhost -U tekutoko -d tekutoko_production -c "
SELECT count(*) as connections,
       state
FROM pg_stat_activity
GROUP BY state;
"

# アイドル接続確認
kubectl exec -it deployment/tekutoko-api -n default -- \
  psql -h localhost -U tekutoko -d tekutoko_production -c "
SELECT pid, usename, application_name, state, state_change
FROM pg_stat_activity
WHERE state = 'idle'
  AND state_change < now() - interval '10 minutes';
"
```

## マイグレーション実行

### 事前準備
```bash
# 1. バックアップ作成
gcloud sql backups create --instance=tekutoko-production

# 2. ステージング環境で検証
kubectl exec -it deployment/tekutoko-api -n staging -- \
  /api migrate up

# 3. ロールバックテスト
kubectl exec -it deployment/tekutoko-api -n staging -- \
  /api migrate down 1
```

### 本番マイグレーション
```bash
# 1. マイグレーション実行
kubectl exec -it deployment/tekutoko-api -n default -- \
  /api migrate up

# 2. 状態確認
kubectl exec -it deployment/tekutoko-api -n default -- \
  /api migrate version

# 3. データ整合性確認
kubectl exec -it deployment/tekutoko-api -n default -- \
  psql -h localhost -U tekutoko -d tekutoko_production -c "\dt"
```

## ポイントインタイムリカバリ

### リカバリ手順
```bash
# 1. 復元ポイント確認
gcloud sql backups list --instance=tekutoko-production

# 2. クローンインスタンス作成
gcloud sql instances clone tekutoko-production tekutoko-restored \
  --point-in-time='2025-01-16T12:00:00.000Z'

# 3. データ検証
gcloud sql connect tekutoko-restored --user=tekutoko

# 4. 本番切り替え（検証完了後）
# - アプリケーションのDB接続先変更
# - Kubernetes Secret更新
```

## トラブルシューティング

### 接続数上限エラー
```bash
# max_connections増加
gcloud sql instances patch tekutoko-production \
  --database-flags=max_connections=200

# アプリケーション側の接続プールサイズ削減も検討
```

### スロークエリ
```bash
# スロークエリログ有効化
gcloud sql instances patch tekutoko-production \
  --database-flags=log_min_duration_statement=1000

# ログ確認
gcloud sql instances logs list --instance=tekutoko-production
```

## 関連リンク
- [Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [ロールバック手順](./ROLLBACK.md)
