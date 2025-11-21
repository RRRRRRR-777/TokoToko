# Cloud Monitoring ダッシュボード設定ガイド

GKE Dev環境のメトリクスを可視化するダッシュボード設定

## 基本ダッシュボードの作成

### GCP Console経由（推奨）

1. [Cloud Monitoring Console](https://console.cloud.google.com/monitoring) にアクセス
2. 左メニューから「ダッシュボード」を選択
3. 「ダッシュボードを作成」をクリック
4. 以下のウィジェットを追加

---

## 推奨ウィジェット構成

### 1. Pod Status（Pod状態）

**ウィジェットタイプ**: Scorecard

**メトリクス**:
```
resource.type = "k8s_pod"
resource.labels.cluster_name = "gke-tekutoko-dev"
resource.labels.namespace_name = "default"
metric.type = "kubernetes.io/pod/network/received_bytes_count"
```

**表示**: Pod数とステータス

---

### 2. CPU Usage（CPU使用率）

**ウィジェットタイプ**: Line Chart

**メトリクス**:
```
resource.type = "k8s_container"
resource.labels.cluster_name = "gke-tekutoko-dev"
resource.labels.namespace_name = "default"
resource.labels.container_name = "api"
metric.type = "kubernetes.io/container/cpu/core_usage_time"
```

**集約**: ALIGN_RATE → REDUCE_MEAN

---

### 3. Memory Usage（メモリ使用率）

**ウィジェットタイプ**: Line Chart

**メトリクス**:
```
resource.type = "k8s_container"
resource.labels.cluster_name = "gke-tekutoko-dev"
resource.labels.namespace_name = "default"
resource.labels.container_name = "api"
metric.type = "kubernetes.io/container/memory/used_bytes"
```

**集約**: ALIGN_MEAN

---

### 4. Network Traffic（ネットワークトラフィック）

**ウィジェットタイプ**: Line Chart

**メトリクス（受信）**:
```
resource.type = "k8s_pod"
resource.labels.cluster_name = "gke-tekutoko-dev"
metric.type = "kubernetes.io/pod/network/received_bytes_count"
```

**メトリクス（送信）**:
```
resource.type = "k8s_pod"
resource.labels.cluster_name = "gke-tekutoko-dev"
metric.type = "kubernetes.io/pod/network/sent_bytes_count"
```

---

### 5. HPA Replicas（自動スケーリング）

**ウィジェットタイプ**: Line Chart

**メトリクス**:
```
resource.type = "k8s_deployment"
resource.labels.cluster_name = "gke-tekutoko-dev"
resource.labels.deployment_name = "tekutoko-api"
metric.type = "kubernetes.io/container/restart_count"
```

**表示**: レプリカ数の推移

---

### 6. Log-Based Metrics（ログベースメトリクス）

Phase 2実装後に追加：

- HTTP Request Count
- HTTP Response Time
- Error Count by Status Code

---

## gcloud CLIでのダッシュボード作成

### JSON定義ファイル作成

`dashboard-config.json`:
```json
{
  "displayName": "TekuToko API Dashboard - Dev",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 4,
        "height": 4,
        "widget": {
          "title": "Pod Count",
          "scorecard": {
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=\"k8s_pod\" AND resource.labels.cluster_name=\"gke-tekutoko-dev\" AND resource.labels.namespace_name=\"default\"",
                "aggregation": {
                  "alignmentPeriod": "60s",
                  "perSeriesAligner": "ALIGN_MEAN",
                  "crossSeriesReducer": "REDUCE_COUNT"
                }
              }
            }
          }
        }
      },
      {
        "xPos": 4,
        "width": 8,
        "height": 4,
        "widget": {
          "title": "CPU Usage",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"gke-tekutoko-dev\" AND resource.labels.container_name=\"api\" AND metric.type=\"kubernetes.io/container/cpu/core_usage_time\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_MEAN"
                  }
                }
              },
              "plotType": "LINE"
            }],
            "yAxis": {
              "label": "CPU Cores",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "yPos": 4,
        "width": 12,
        "height": 4,
        "widget": {
          "title": "Memory Usage",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"gke-tekutoko-dev\" AND resource.labels.container_name=\"api\" AND metric.type=\"kubernetes.io/container/memory/used_bytes\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN"
                  }
                }
              },
              "plotType": "LINE"
            }],
            "yAxis": {
              "label": "Memory (Bytes)",
              "scale": "LINEAR"
            }
          }
        }
      }
    ]
  }
}
```

### ダッシュボード作成コマンド

```bash
gcloud monitoring dashboards create --config-from-file=dashboard-config.json
```

---

## ダッシュボードURL

作成後、以下のURLでアクセス可能：

```
https://console.cloud.google.com/monitoring/dashboards/custom/DASHBOARD_ID?project=tokotoko-ea308
```

---

## 既存のGKEダッシュボード活用

GKE Autopilotでは標準でダッシュボードが提供されています：

### アクセス方法

1. [GKE Console](https://console.cloud.google.com/kubernetes/list) にアクセス
2. クラスター `gke-tekutoko-dev` をクリック
3. 「Workloads」タブ → `tekutoko-api` Deploymentを選択
4. 右側パネルで「METRICS」タブを表示

### 表示内容

- CPU使用率
- メモリ使用率
- ネットワークトラフィック
- ディスクI/O
- Pod数の推移

---

## カスタムダッシュボードの推奨レイアウト

```
┌──────────────────────────────────────────────────┐
│ TekuToko API Dashboard - Dev                     │
├──────────────┬───────────────┬───────────────────┤
│ Pod Count    │ CPU Usage     │ Memory Usage      │
│   2          │ ███░░░░ 35%  │ ████░░░ 45%       │
├──────────────┴───────────────┴───────────────────┤
│ HPA Replicas (時系列グラフ)                      │
│ ──────────────────────────────                    │
│        2 ─────────────────                        │
├───────────────────────────────────────────────────┤
│ Network Traffic (In/Out)                          │
│ ↓ In:  ───────────                               │
│ ↑ Out: ────────────────                          │
├───────────────────────────────────────────────────┤
│ Recent Logs (直近のエラーログ)                   │
│ [ERROR] ...                                       │
│ [WARN]  ...                                       │
└───────────────────────────────────────────────────┘
```

---

## Metrics Explorer の活用

カスタムクエリでメトリクスを探索：

1. [Metrics Explorer](https://console.cloud.google.com/monitoring/metrics-explorer) にアクセス
2. 「Resource type」で `k8s_container` を選択
3. 「Metric」で表示したいメトリクスを選択
4. フィルタで `cluster_name = gke-tekutoko-dev` を指定

---

## Phase 2以降の拡張

API実装後に以下を追加：

1. **HTTPリクエストメトリクス**
   - リクエスト数（エンドポイント別）
   - レスポンスタイム分布
   - ステータスコード別カウント

2. **ビジネスメトリクス**
   - API呼び出し成功率
   - ユーザーアクション数
   - データベースクエリ時間

3. **SLI/SLO ダッシュボード**
   - 可用性（Availability）
   - レイテンシ（Latency）
   - エラー率（Error Rate）

---

## 参考リンク

- [Cloud Monitoring Dashboards](https://cloud.google.com/monitoring/dashboards)
- [GKE Observability](https://cloud.google.com/kubernetes-engine/docs/how-to/monitoring)
- [Dashboard Configuration](https://cloud.google.com/monitoring/api/ref_v3/rest/v1/projects.dashboards)
