# TekuToko API Monitoring

GCP Cloud Monitoring を使用した監視設定です。

## 構成

### 1. ダッシュボード
**ファイル**: `dashboards/api-overview.json`

#### 監視指標
| 指標名 | 説明 | 閾値 |
|--------|------|------|
| Request Rate | リクエスト数/分 | - |
| Error Rate | エラー率（5xx） | 黄:10/分, 赤:50/分 |
| Response Latency | レスポンス時間（p50/p95/p99） | 黄:500ms, 赤:1000ms |
| CPU Usage | CPU使用率 | 黄:70%, 赤:90% |
| Memory Usage | メモリ使用量 | 黄:400MB, 赤:512MB |
| Pod Count | 稼働Pod数 | - |
| DB Connection Pool | データベース接続数 | - |

#### ダッシュボード作成
```bash
gcloud monitoring dashboards create --config-from-file=dashboards/api-overview.json
```

### 2. アラートポリシー
**ファイル**: `alerts/alert-policies.yaml`

#### アラート一覧
| アラート名 | 条件 | 深刻度 | 通知 |
|-----------|------|--------|------|
| High Error Rate | エラー率 > 5% | ERROR | Slack |
| High Latency | p95 > 1秒 | WARNING | Slack |
| Frequent Pod Restarts | 10分間で3回以上再起動 | CRITICAL | Slack + PagerDuty |
| High CPU Usage | CPU > 80% | WARNING | Slack |
| High Memory Usage | メモリ > 80% | WARNING | Slack |
| Database Connection Errors | DB接続エラー発生 | CRITICAL | Slack + PagerDuty |

#### アラートポリシー作成
```bash
# 各アラートポリシーを個別に作成
gcloud alpha monitoring policies create --policy-from-file=alerts/alert-policies.yaml
```

---

## セットアップ手順

### 1. 通知チャネル設定
Slackへの通知を設定：

```bash
# Slack通知チャネル作成
gcloud alpha monitoring channels create \
  --display-name="TekuToko Slack Alerts" \
  --type=slack \
  --channel-labels=url=SLACK_WEBHOOK_URL

# チャネルID取得
gcloud alpha monitoring channels list
```

PagerDuty通知設定（本番環境のみ）：

```bash
gcloud alpha monitoring channels create \
  --display-name="TekuToko PagerDuty" \
  --type=pagerduty \
  --channel-labels=service_key=PAGERDUTY_SERVICE_KEY
```

### 2. ダッシュボード作成

```bash
cd deploy/monitoring

# PROJECT_IDを実際の値に置換
sed -i '' 's/PROJECT_ID/your-project-id/g' dashboards/api-overview.json

# ダッシュボード作成
gcloud monitoring dashboards create --config-from-file=dashboards/api-overview.json
```

### 3. アラートポリシー作成

```bash
# CHANNEL_IDを実際の値に置換
CHANNEL_ID=$(gcloud alpha monitoring channels list --filter="displayName='TekuToko Slack Alerts'" --format="value(name)")
sed -i '' "s|CHANNEL_ID|${CHANNEL_ID}|g" alerts/alert-policies.yaml
sed -i '' 's/PROJECT_ID/your-project-id/g' alerts/alert-policies.yaml

# アラートポリシー作成（各YAMLドキュメントを個別に適用）
# TODO: スクリプト化が必要
```

### 4. ログベースメトリクス作成
アラートに使用するカスタムメトリクスを作成：

```bash
# HTTP リクエスト総数
gcloud logging metrics create http_requests_total \
  --description="HTTP requests total count" \
  --log-filter='resource.type="k8s_container"
resource.labels.container_name="api"
jsonPayload.message=~".*HTTP.*"'

# エラーカウント
gcloud logging metrics create error_count \
  --description="Error count" \
  --log-filter='resource.type="k8s_container"
resource.labels.container_name="api"
severity>=ERROR'

# HTTP リクエスト時間
gcloud logging metrics create http_request_duration_seconds \
  --description="HTTP request duration" \
  --log-filter='resource.type="k8s_container"
resource.labels.container_name="api"
jsonPayload.duration_ms!=null' \
  --value-extractor='EXTRACT(jsonPayload.duration_ms)'

# DB接続プールアクティブ数
gcloud logging metrics create db_connection_pool_active \
  --description="Active database connections" \
  --log-filter='resource.type="k8s_container"
resource.labels.container_name="api"
jsonPayload.db_connections_active!=null' \
  --value-extractor='EXTRACT(jsonPayload.db_connections_active)'

# DB接続エラー
gcloud logging metrics create db_connection_errors_total \
  --description="Database connection errors" \
  --log-filter='resource.type="k8s_container"
resource.labels.container_name="api"
jsonPayload.message=~".*database connection error.*"'
```

---

## ダッシュボードアクセス

### Cloud Console
1. GCP Console > Monitoring > Dashboards
2. 「TekuToko API - Overview」を選択

### 直リンク
```
https://console.cloud.google.com/monitoring/dashboards/custom/DASHBOARD_ID?project=PROJECT_ID
```

---

## アラート対応

### アラート受信フロー
1. Cloud Monitoring がアラート条件検知
2. Slack/PagerDutyに通知送信
3. 担当者がRunbookに従って対応
4. 対応完了後、アラートが自動クローズ（設定時間経過後）

### Runbook
詳細な対応手順は`docs/runbook/`配下を参照：

- [ERROR_RATE.md](../../docs/runbook/ERROR_RATE.md)
- [HIGH_LATENCY.md](../../docs/runbook/HIGH_LATENCY.md)
- [POD_RESTARTS.md](../../docs/runbook/POD_RESTARTS.md)
- [HIGH_CPU.md](../../docs/runbook/HIGH_CPU.md)
- [HIGH_MEMORY.md](../../docs/runbook/HIGH_MEMORY.md)
- [DB_CONNECTION_ERROR.md](../../docs/runbook/DB_CONNECTION_ERROR.md)

---

## カスタムメトリクス送信

Goアプリケーションから構造化ログでメトリクスを送信：

```go
// HTTP リクエスト時間
log.Info().
    Str("method", "GET").
    Str("path", "/v1/walks").
    Int("status", 200).
    Float64("duration_ms", 123.45).
    Msg("HTTP request completed")

// DB接続プール状態
log.Info().
    Int("db_connections_active", 5).
    Int("db_connections_idle", 3).
    Msg("Database connection pool status")

// エラー
log.Error().
    Str("error", "database connection timeout").
    Msg("database connection error")
```

---

## トラブルシューティング

### ダッシュボードにデータが表示されない
1. ログベースメトリクスが作成されているか確認
   ```bash
   gcloud logging metrics list
   ```
2. アプリケーションが構造化ログを出力しているか確認
   ```bash
   kubectl logs -l app=tekutoko-api --tail=50
   ```

### アラートが発火しない
1. アラートポリシーが有効か確認
   ```bash
   gcloud alpha monitoring policies list
   ```
2. 通知チャネルが正しく設定されているか確認
   ```bash
   gcloud alpha monitoring channels list
   ```
3. メトリクスデータが送信されているか確認

### アラートが頻繁に発火する
1. 閾値の調整が必要か検討
2. アラートポリシーのduration（継続時間）を延長
3. 根本原因の調査・修正

---

## 参考リンク
- [Cloud Monitoring Documentation](https://cloud.google.com/monitoring/docs)
- [Alert Policies](https://cloud.google.com/monitoring/alerts)
- [Dashboards](https://cloud.google.com/monitoring/dashboards)
- [Log-based Metrics](https://cloud.google.com/logging/docs/logs-based-metrics)
