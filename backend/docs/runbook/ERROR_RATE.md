# 高エラー率対応 Runbook

## アラート条件
- **エラー率 > 5%** が5分間継続
- **深刻度**: ERROR

## 影響
- ユーザーのリクエストが失敗している
- サービス品質の低下
- SLO違反のリスク

---

## 初動対応（15分以内）

### 1. アラート受領確認
```
Slackで受領を報告:
「エラー率アラート受領しました。調査開始します。」
```

### 2. エラー内容の確認
```bash
# 直近のエラーログを確認
kubectl logs -l app=tekutoko-api --tail=100 -n default | grep -i error

# Cloud Loggingで詳細確認
gcloud logging read "resource.type=k8s_container AND resource.labels.container_name=api AND severity>=ERROR" \
  --limit=50 \
  --format=json \
  --freshness=10m
```

### 3. エラーパターンの特定
以下のいずれかを確認：

#### パターンA: 5xx系エラー（サーバー内部エラー）
```bash
# エラー率の推移確認
kubectl logs -l app=tekutoko-api --tail=500 -n default | grep "HTTP" | grep " 5[0-9][0-9] "
```

**原因候補**:
- アプリケーションバグ
- データベース接続エラー
- メモリ不足（OOM）
- 外部API障害

#### パターンB: データベース接続エラー
```bash
# DB接続エラー確認
kubectl logs -l app=tekutoko-api --tail=100 -n default | grep -i "database"
```

**原因候補**:
- Cloud SQL接続数上限
- Cloud SQL Proxyの問題
- ネットワーク障害

#### パターンC: パニック・クラッシュ
```bash
# パニックログ確認
kubectl logs -l app=tekutoko-api --tail=100 -n default | grep -i "panic"
```

**原因候補**:
- nil pointer dereference
- 配列境界外アクセス
- 想定外の入力値

---

## 対応手順

### ケース1: データベース接続エラー
#### 1-1. Cloud SQL Proxy状態確認
```bash
# Cloud SQL Proxyコンテナのログ確認
kubectl logs -l app=tekutoko-api -n default -c cloud-sql-proxy --tail=50

# Proxyが正常に動作しているか確認
kubectl get pods -l app=tekutoko-api -n default -o jsonpath='{.items[*].status.containerStatuses[?(@.name=="cloud-sql-proxy")].ready}'
```

**対処**: Proxyが異常な場合、Podを再起動
```bash
kubectl rollout restart deployment/tekutoko-api -n default
```

#### 1-2. Cloud SQLインスタンス状態確認
```bash
# インスタンス状態確認
gcloud sql instances describe tekutoko-production --format="value(state)"

# 接続数確認
gcloud sql instances describe tekutoko-production --format="value(currentDiskSize,settings.dataDiskSizeGb)"
```

**対処**: インスタンスが停止している場合
```bash
gcloud sql instances patch tekutoko-production --activation-policy=ALWAYS
```

#### 1-3. 接続数上限確認
```bash
# 現在の接続数確認（Cloud SQL接続して実行）
psql -h localhost -U tekutoko -d tekutoko_production -c "SELECT count(*) FROM pg_stat_activity;"

# max_connections確認
gcloud sql instances describe tekutoko-production --format="value(settings.databaseFlags)"
```

**対処**: 接続数が上限に達している場合
```bash
# 一時的にmax_connectionsを増やす
gcloud sql instances patch tekutoko-production \
  --database-flags=max_connections=200

# または、アプリケーションのコネクションプールサイズを減らす
# （config.goの設定変更が必要）
```

### ケース2: アプリケーションバグ
#### 2-1. エラースタックトレース確認
```bash
# 詳細なエラーログ取得
kubectl logs -l app=tekutoko-api -n default --tail=200 | grep -A 10 "ERROR"
```

#### 2-2. 直近のデプロイ確認
```bash
# デプロイ履歴確認
kubectl rollout history deployment/tekutoko-api -n default

# 直近の変更内容確認
git log -5 --oneline
```

**対処**: 直近のデプロイが原因の場合、ロールバック
```bash
# 前回のリビジョンにロールバック
kubectl rollout undo deployment/tekutoko-api -n default

# 特定のリビジョンにロールバック
kubectl rollout undo deployment/tekutoko-api --to-revision=N -n default
```

詳細は [ROLLBACK.md](./ROLLBACK.md) 参照

### ケース3: リソース不足（OOM）
#### 3-1. メモリ使用状況確認
```bash
# Pod のメモリ使用率確認
kubectl top pods -l app=tekutoko-api -n default

# OOMKilledイベント確認
kubectl get events -n default --sort-by='.lastTimestamp' | grep -i oom
```

**対処**: OOMが発生している場合
```bash
# リソースlimitを一時的に増やす（緊急対応）
kubectl set resources deployment tekutoko-api -n default \
  -c=api \
  --limits=memory=2Gi

# または、スケールアウト
kubectl scale deployment tekutoko-api --replicas=5 -n default
```

### ケース4: 外部API障害
#### 4-1. Firebase接続確認
```bash
# Firebase関連のエラーログ確認
kubectl logs -l app=tekutoko-api -n default --tail=100 | grep -i firebase
```

**対処**: Firebase側の障害の場合
- [Firebase Status Dashboard](https://status.firebase.google.com/) 確認
- 一時的にFirebase機能を無効化（フィーチャーフラグ）
- ユーザーへアナウンス

---

## 一時的な緊急対応

### トラフィック制限
エラーが収束しない場合、一時的にトラフィックを制限：

```bash
# レプリカ数を減らして負荷軽減
kubectl scale deployment tekutoko-api --replicas=2 -n default

# または、メンテナンスモードに切り替え
# （要: メンテナンスページの実装）
```

### サーキットブレーカー
特定のエンドポイントでエラーが集中している場合：
- アプリケーション側でサーキットブレーカーを発動
- 該当エンドポイントを一時的に503返却

---

## 復旧確認

### 1. エラー率の確認
```bash
# Cloud Monitoringダッシュボードで確認
# または、ログで確認
kubectl logs -l app=tekutoko-api -n default --tail=100 | grep "HTTP" | awk '{print $NF}' | sort | uniq -c
```

### 2. 正常性確認
```bash
# ヘルスチェック確認
EXTERNAL_IP=$(kubectl get service tekutoko-api -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP/health

# レディネスチェック確認
curl http://$EXTERNAL_IP/ready
```

### 3. ユーザー影響確認
- エラー率が1%未満に戻ったか
- レスポンス時間が正常範囲か
- ユーザーからの報告がないか

---

## 報告

### Slack報告テンプレート
```
【復旧完了】エラー率アラート

■ 発生時刻: YYYY-MM-DD HH:MM JST
■ 復旧時刻: YYYY-MM-DD HH:MM JST
■ 原因: [データベース接続エラー/アプリケーションバグ/リソース不足 等]
■ 対処内容: [具体的な対応内容]
■ 影響範囲: [ユーザー影響の有無]
■ 再発防止策: [TODO]

ポストモーテム作成予定: [URL]
```

---

## ポストモーテム作成

障害対応完了後、必ず作成：
- [POSTMORTEM_TEMPLATE.md](./POSTMORTEM_TEMPLATE.md) を使用
- 24時間以内に初版作成
- 根本原因分析（RCA）実施
- 再発防止策の立案

---

## 再発防止策（例）

### アプリケーションレベル
- [ ] エラーハンドリングの改善
- [ ] リトライロジックの実装
- [ ] サーキットブレーカーの実装
- [ ] 入力バリデーション強化

### インフラレベル
- [ ] リソースlimit の見直し
- [ ] HPA設定の最適化
- [ ] データベース接続プールサイズ調整
- [ ] アラート閾値の調整

### モニタリング
- [ ] エラーパターン別のダッシュボード作成
- [ ] エラーログの構造化改善
- [ ] カスタムメトリクス追加

---

## 関連リンク
- [Cloud Monitoring Dashboard](https://console.cloud.google.com/monitoring/dashboards)
- [ロールバック手順](./ROLLBACK.md)
- [データベースメンテナンス](./DB_MAINTENANCE.md)
- [ポストモーテムテンプレート](./POSTMORTEM_TEMPLATE.md)
