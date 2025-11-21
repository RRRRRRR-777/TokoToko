# TekuToko API 監視設定ガイド

GCP Cloud Monitoringを使用したTekuToko APIの監視設定

## 概要

TekuToko API（Go Backend）は**GCP Cloud Monitoring**で監視します。

### なぜCloud Monitoringを選択したか

| 項目 | Cloud Monitoring | Prometheus + Grafana |
|------|-----------------|----------------------|
| **セットアップ** | 不要（GKE標準） | 必要（Pod追加） |
| **メトリクス収集** | 自動 | 手動設定 |
| **ログ統合** | Cloud Logging統合 | 別途Loki等が必要 |
| **コスト** | GKE利用料に含まれる | Pod分のコスト増 |
| **運用負荷** | マネージド | 自己運用 |
| **推奨度** | ✅ **推奨** | Phase 5以降で検討 |

---

## 監視の構成要素

### 1. メトリクス収集（自動）

GKE Autopilotで自動的に収集されるメトリクス：

- **リソースメトリクス**: CPU、Memory、Network、Disk I/O
- **Kubernetesメトリクス**: Pod数、Deployment状態、HPA状態
- **GKEメトリクス**: ノード状態、クラスター全体の統計

### 2. ログ収集（自動）

- **標準出力/エラー出力**: 自動的にCloud Loggingに送信
- **構造化ログ**: JSON形式でログ出力すると自動パース
- **ログレベル**: INFO, WARN, ERROR, FATAL

### 3. アラートポリシー（設定必要）

以下の4つのアラートを設定：

| アラート名 | 条件 | 重大度 |
|-----------|------|--------|
| Error Rate Alert | HTTPエラー率 > 5% | WARNING |
| High Latency Alert | P95レイテンシ > 1秒 | WARNING |
| Pod Restart Alert | 再起動 > 3回/10分 | CRITICAL |
| Resource Usage Alert | CPU > 85% or Memory > 90% | WARNING |

設定方法: [`alert-policies.md`](./alert-policies.md)

### 4. ダッシュボード（オプション）

主要メトリクスを可視化するダッシュボード：

- Pod状態とレプリカ数
- CPU/Memory使用率
- ネットワークトラフィック
- 直近のエラーログ

設定方法: [`dashboard-setup.md`](./dashboard-setup.md)

---

## クイックスタート

### 1. 通知チャネル設定

```bash
# Email通知
gcloud alpha monitoring channels create \
  --display-name="TekuToko Dev Team Email" \
  --type=email \
  --channel-labels=email_address=YOUR_EMAIL@example.com

# 作成されたチャネルIDを確認
gcloud alpha monitoring channels list
```

### 2. アラートポリシー作成

`alert-policies.md` の手順に従って4つのアラートを作成

### 3. ダッシュボード作成（オプション）

GCP Console: [Cloud Monitoring Dashboard](https://console.cloud.google.com/monitoring/dashboards?project=tokotoko-ea308)

または `dashboard-setup.md` の手順でCLI作成

---

## 監視の確認方法

### メトリクスの確認

```bash
# Podのリソース使用状況
kubectl top pods -n default

# HPAの状態
kubectl get hpa -n default

# Podのイベント
kubectl describe pod <pod-name> -n default
```

### ログの確認

```bash
# リアルタイムログ
kubectl logs -f deployment/tekutoko-api -n default

# Cloud Loggingでログ検索
gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=default" --limit=50
```

### GCP Console

- **Metrics Explorer**: https://console.cloud.google.com/monitoring/metrics-explorer
- **Logs Explorer**: https://console.cloud.google.com/logs/query
- **Dashboards**: https://console.cloud.google.com/monitoring/dashboards
- **Alerting**: https://console.cloud.google.com/monitoring/alerting

---

## Phase 2以降の拡張

API実装後に以下を追加：

### カスタムメトリクス

1. **HTTPリクエストメトリクス**
   - エンドポイント別リクエスト数
   - レスポンスタイム（P50, P95, P99）
   - ステータスコード別カウント

2. **ビジネスメトリクス**
   - ユーザー登録数
   - API呼び出し成功率
   - データベース接続プール使用率

3. **外部サービスメトリクス**
   - Firebase API呼び出し数
   - Cloud Storage操作数
   - Cloud SQL接続数

### 構造化ログの実装

GoアプリケーションでJSON形式のログ出力：

```go
import "go.uber.org/zap"

logger, _ := zap.NewProduction()
defer logger.Sync()

logger.Info("API request",
    zap.String("method", "GET"),
    zap.String("path", "/api/v1/walks"),
    zap.Int("status", 200),
    zap.Duration("duration", duration),
)
```

Cloud Loggingで自動的にフィールドがパースされ、検索可能になります。

---

## トラブルシューティング

### メトリクスが表示されない

```bash
# メトリクスサーバーのPod確認
kubectl get pods -n kube-system | grep metrics-server

# HPA の状態確認
kubectl get hpa -n default
# TARGETS が <unknown> の場合、メトリクスサーバーが起動していない
```

**解決策**: Podをスケールアップするとノードが自動プロビジョニングされ、メトリクスサーバーも起動します。

### ログが表示されない

```bash
# Podのログ確認
kubectl logs deployment/tekutoko-api -n default

# Cloud Loggingのログ確認
gcloud logging read "resource.type=k8s_container" --limit=10
```

**解決策**: Podが起動していない場合、ログも送信されません。`kubectl get pods` で状態確認。

### アラートが発火しない

Phase 2でAPI実装後、トラフィックが発生してから発火します。テスト用の負荷生成：

```bash
# 簡易負荷テスト
kubectl run load-test --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://tekutoko-api/health; done"
```

---

## 関連ドキュメント

- [alert-policies.md](./alert-policies.md) - アラートポリシー設定詳細
- [dashboard-setup.md](./dashboard-setup.md) - ダッシュボード設定詳細
- [../runbook/](../runbook/) - 障害対応手順
- [GCP Cloud Monitoring Documentation](https://cloud.google.com/monitoring/docs)

---

## 監視設定チェックリスト

Phase 4完了時点：

- [x] メトリクス収集（GKE標準で自動）
- [x] ログ収集（Cloud Logging自動）
- [x] HPA動作確認
- [ ] 通知チャネル作成（Email/Slack）
- [ ] アラートポリシー作成（4種類）
- [ ] ダッシュボード作成（オプション）

Phase 2完了時点：

- [ ] 構造化ログ実装
- [ ] カスタムメトリクス実装
- [ ] HTTPリクエストメトリクス
- [ ] SLI/SLO定義
