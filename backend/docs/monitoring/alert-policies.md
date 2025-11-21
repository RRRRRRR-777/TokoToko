# Cloud Monitoring アラートポリシー設定ガイド

GCP Cloud Monitoringでアラートポリシーを設定する手順

## 前提条件

- GKE Autopilotクラスターが起動している
- Cloud Monitoringが有効化されている（GKE標準で有効）
- 通知先のメールアドレスまたはSlackワークスペース

---

## 1. Error Rate Alert（HTTPエラーレート監視）

### 目的
HTTPエラーレスポンス（5xx）の割合が高い場合にアラート

### 設定方法

```bash
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="TekuToko API - High Error Rate" \
  --condition-display-name="HTTP Error Rate > 5%" \
  --condition-threshold-value=5 \
  --condition-threshold-duration=300s \
  --condition-filter='
    resource.type="k8s_container"
    AND resource.labels.cluster_name="gke-tekutoko-dev"
    AND resource.labels.namespace_name="default"
    AND resource.labels.container_name="api"
    AND metric.type="logging.googleapis.com/user/http_response_count"
    AND metric.labels.status_code >= "500"' \
  --aggregation='{"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_RATE", "crossSeriesReducer": "REDUCE_SUM"}' \
  --comparison=COMPARISON_GT
```

### 条件
- **閾値**: 5%
- **期間**: 5分間継続
- **重大度**: WARNING

### 対応手順
1. `/runbook/high-error-rate.md` を参照
2. ログでエラー内容を確認
3. 直近のデプロイをロールバック検討

---

## 2. High Latency Alert（レイテンシ監視）

### 目的
APIレスポンスのP95レイテンシが1秒を超えた場合にアラート

### 設定方法

```bash
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="TekuToko API - High Latency" \
  --condition-display-name="P95 Latency > 1s" \
  --condition-threshold-value=1000 \
  --condition-threshold-duration=300s \
  --condition-filter='
    resource.type="k8s_container"
    AND resource.labels.cluster_name="gke-tekutoko-dev"
    AND resource.labels.namespace_name="default"
    AND resource.labels.container_name="api"
    AND metric.type="logging.googleapis.com/user/http_request_duration_milliseconds"' \
  --aggregation='{"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_PERCENTILE_95"}' \
  --comparison=COMPARISON_GT
```

### 条件
- **閾値**: 1000ms（1秒）
- **期間**: 5分間継続
- **重大度**: WARNING

### 対応手順
1. `/runbook/high-latency.md` を参照
2. スロークエリログを確認
3. HPAによる自動スケールアウトを確認

---

## 3. Pod Restart Alert（Pod再起動監視）

### 目的
Podが頻繁に再起動している場合にアラート（OOMKill、CrashLoopBackOff等）

### 設定方法

```bash
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="TekuToko API - Frequent Pod Restarts" \
  --condition-display-name="Pod Restarts > 3 times in 10 minutes" \
  --condition-threshold-value=3 \
  --condition-threshold-duration=600s \
  --condition-filter='
    resource.type="k8s_pod"
    AND resource.labels.cluster_name="gke-tekutoko-dev"
    AND resource.labels.namespace_name="default"
    AND resource.labels.pod_name=starts_with("tekutoko-api")
    AND metric.type="kubernetes.io/container/restart_count"' \
  --aggregation='{"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_RATE", "crossSeriesReducer": "REDUCE_SUM"}' \
  --comparison=COMPARISON_GT
```

### 条件
- **閾値**: 3回
- **期間**: 10分間
- **重大度**: CRITICAL

### 対応手順
1. `/runbook/pod-restart.md` を参照
2. `kubectl describe pod` でイベント確認
3. OOMKillの場合はリソース制限を見直し

---

## 4. Resource Usage Alert（リソース使用率監視）

### 目的
CPU/Memory使用率が高い場合にアラート

### 設定方法（CPU）

```bash
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="TekuToko API - High CPU Usage" \
  --condition-display-name="CPU Usage > 85%" \
  --condition-threshold-value=0.85 \
  --condition-threshold-duration=300s \
  --condition-filter='
    resource.type="k8s_container"
    AND resource.labels.cluster_name="gke-tekutoko-dev"
    AND resource.labels.namespace_name="default"
    AND resource.labels.container_name="api"
    AND metric.type="kubernetes.io/container/cpu/core_usage_time"' \
  --aggregation='{"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_RATE", "crossSeriesReducer": "REDUCE_MEAN"}' \
  --comparison=COMPARISON_GT
```

### 設定方法（Memory）

```bash
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="TekuToko API - High Memory Usage" \
  --condition-display-name="Memory Usage > 90%" \
  --condition-threshold-value=0.90 \
  --condition-threshold-duration=300s \
  --condition-filter='
    resource.type="k8s_container"
    AND resource.labels.cluster_name="gke-tekutoko-dev"
    AND resource.labels.namespace_name="default"
    AND resource.labels.container_name="api"
    AND metric.type="kubernetes.io/container/memory/used_bytes"' \
  --aggregation='{"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_MEAN"}' \
  --comparison=COMPARISON_GT
```

### 条件
- **CPU閾値**: 85%
- **Memory閾値**: 90%
- **期間**: 5分間継続
- **重大度**: WARNING

### 対応手順
1. HPAが自動スケールアウトを実施
2. リソース制限が適切か確認
3. メモリリークの可能性を調査

---

## 通知チャネル設定

### Email通知

```bash
# 通知チャネル作成
gcloud alpha monitoring channels create \
  --display-name="TekuToko Dev Team Email" \
  --type=email \
  --channel-labels=email_address=dev-team@example.com
```

### Slack通知

```bash
# Slack Webhookを事前に取得: https://api.slack.com/messaging/webhooks

gcloud alpha monitoring channels create \
  --display-name="TekuToko Dev Team Slack" \
  --type=slack \
  --channel-labels=url=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### 通知チャネルID確認

```bash
gcloud alpha monitoring channels list
```

---

## アラートポリシー一覧確認

```bash
# 全ポリシー確認
gcloud alpha monitoring policies list

# 特定ポリシーの詳細
gcloud alpha monitoring policies describe POLICY_ID
```

---

## アラート無効化/削除

```bash
# 一時的に無効化
gcloud alpha monitoring policies update POLICY_ID --no-enabled

# 削除
gcloud alpha monitoring policies delete POLICY_ID
```

---

## Phase 2実装時の追加設定

Phase 2でAPIが実装された後、以下のカスタムメトリクスを追加：

1. **Request Rate監視**
   - 条件: リクエスト数 > 100 req/s
   - 目的: トラフィック急増の検知

2. **Database Connection Pool監視**
   - 条件: アクティブ接続数 > 80%
   - 目的: DB接続枯渇の予防

3. **External API Error Rate**
   - 条件: Firebase API失敗率 > 5%
   - 目的: 外部サービス障害の検知

---

## 参考リンク

- [Cloud Monitoring Documentation](https://cloud.google.com/monitoring/docs)
- [Alert Policy Configuration](https://cloud.google.com/monitoring/alerts)
- [Notification Channels](https://cloud.google.com/monitoring/support/notification-options)
