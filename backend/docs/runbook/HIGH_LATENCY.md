# 高レイテンシ対応 Runbook

## アラート条件
- **p95レスポンス時間 > 1秒** が5分間継続
- **深刻度**: WARNING

## 初動対応

### 1. 現在のレイテンシ確認
```bash
# Cloud Monitoringダッシュボード確認
# または、アプリケーションログから確認
kubectl logs -l app=tekutoko-api -n default --tail=100 | grep "duration_ms"
```

### 2. 原因の特定

#### パターンA: データベーススロークエリ
```bash
# スロークエリログ確認（Cloud SQLで有効化必要）
gcloud sql instances patch tekutoko-production \
  --database-flags=log_min_duration_statement=1000

# アプリケーションログからDB処理時間確認
kubectl logs -l app=tekutoko-api -n default | grep "database query"
```

**対処**:
- インデックス追加
- クエリの最適化
- データベース接続プール調整

#### パターンB: 高負荷
```bash
# CPU使用率確認
kubectl top pods -l app=tekutoko-api -n default

# HPA状態確認
kubectl get hpa -n default
```

**対処**:
```bash
# 手動スケールアウト
kubectl scale deployment tekutoko-api --replicas=8 -n default

# HPA設定調整（CPU閾値を下げる）
kubectl patch hpa tekutoko-api -n default --patch '{"spec":{"metrics":[{"type":"Resource","resource":{"name":"cpu","target":{"type":"Utilization","averageUtilization":50}}}]}}'
```

#### パターンC: 外部API遅延
```bash
# 外部API呼び出しログ確認
kubectl logs -l app=tekutoko-api -n default | grep -i "firebase\|external"
```

**対処**:
- タイムアウト設定の見直し
- キャッシング導入
- サーキットブレーカー実装

## 復旧確認
- [ ] p95レスポンス時間 < 500ms
- [ ] ユーザー影響なし
- [ ] CPU/メモリ正常

## 再発防止策
- [ ] スロークエリのインデックス最適化
- [ ] キャッシング戦略の見直し
- [ ] HPA設定の最適化

## 関連リンク
- [データベースメンテナンス](./DB_MAINTENANCE.md)
- [ポストモーテムテンプレート](./POSTMORTEM_TEMPLATE.md)
