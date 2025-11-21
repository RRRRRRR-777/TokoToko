# TekuToko API Operations Runbook

本番環境運用のための手順書です。

## 目次

### 障害対応
- [高エラー率対応](#高エラー率対応) - [ERROR_RATE.md](./ERROR_RATE.md)
- [高レイテンシ対応](#高レイテンシ対応) - [HIGH_LATENCY.md](./HIGH_LATENCY.md)
- [Pod再起動頻発対応](#pod再起動頻発対応) - [POD_RESTARTS.md](./POD_RESTARTS.md)
- [高CPU使用率対応](#高cpu使用率対応) - [HIGH_CPU.md](./HIGH_CPU.md)
- [高メモリ使用率対応](#高メモリ使用率対応) - [HIGH_MEMORY.md](./HIGH_MEMORY.md)
- [DB接続エラー対応](#db接続エラー対応) - [DB_CONNECTION_ERROR.md](./DB_CONNECTION_ERROR.md)

### 定期メンテナンス
- [ロールバック手順](#ロールバック手順) - [ROLLBACK.md](./ROLLBACK.md)
- [データベースメンテナンス](#データベースメンテナンス) - [DB_MAINTENANCE.md](./DB_MAINTENANCE.md)
- [セキュリティパッチ適用](#セキュリティパッチ適用) - [SECURITY_PATCH.md](./SECURITY_PATCH.md)

### ポストモーテム
- [障害報告テンプレート](#障害報告テンプレート) - [POSTMORTEM_TEMPLATE.md](./POSTMORTEM_TEMPLATE.md)

---

## クイックリファレンス

### 緊急連絡先
| 役割 | 担当者 | 連絡先 |
|------|--------|--------|
| オンコール担当 | TBD | Slack: #oncall |
| バックエンドリード | TBD | Slack: @backend-lead |
| インフラ担当 | TBD | Slack: @infra-lead |

### 重要リンク
| リソース | URL |
|---------|-----|
| GCP Console | https://console.cloud.google.com/home/dashboard?project=PROJECT_ID |
| Cloud Monitoring | https://console.cloud.google.com/monitoring?project=PROJECT_ID |
| GKE Clusters | https://console.cloud.google.com/kubernetes/list?project=PROJECT_ID |
| Cloud SQL | https://console.cloud.google.com/sql/instances?project=PROJECT_ID |
| GitHub Actions | https://github.com/RRRRRRR-777/TokoToko/actions |
| Slack Alerts | https://tekutoko.slack.com/archives/CHANNEL_ID |

---

## 基本コマンド

### Kubernetes操作

#### Pod状態確認
```bash
# 全Pod確認
kubectl get pods -n default -l app=tekutoko-api

# 詳細確認
kubectl describe pod <POD_NAME> -n default

# ログ確認
kubectl logs <POD_NAME> -n default -c api --tail=100 --follow
```

#### デプロイ管理
```bash
# デプロイ状態確認
kubectl get deployment tekutoko-api -n default

# ロールアウト履歴
kubectl rollout history deployment/tekutoko-api -n default

# ロールアウト状態
kubectl rollout status deployment/tekutoko-api -n default
```

#### スケーリング
```bash
# 手動スケールアウト
kubectl scale deployment tekutoko-api --replicas=5 -n default

# HPA状態確認
kubectl get hpa -n default
```

### Cloud SQL操作

#### 接続確認
```bash
# Cloud SQL Proxy経由で接続
cloud-sql-proxy PROJECT_ID:REGION:INSTANCE_NAME

# psql接続
psql "host=localhost port=5432 dbname=tekutoko_production user=tekutoko sslmode=disable"
```

#### インスタンス状態確認
```bash
# インスタンス一覧
gcloud sql instances list

# インスタンス詳細
gcloud sql instances describe INSTANCE_NAME
```

### ログ確認

#### Cloud Logging
```bash
# エラーログ検索
gcloud logging read "resource.type=k8s_container AND resource.labels.container_name=api AND severity>=ERROR" --limit=50 --format=json

# 特定時間範囲のログ
gcloud logging read "resource.type=k8s_container AND resource.labels.container_name=api" \
  --limit=100 \
  --format=json \
  --freshness=1h
```

---

## エスカレーションフロー

### レベル1: 自動対応
- HPA による自動スケーリング
- Kubernetes による自動再起動（Liveness Probe失敗時）
- Cloud Monitoring によるアラート送信

### レベル2: オンコール対応
- Runbook に従った初動対応
- 15分以内の初動完了目標
- Slackで状況報告

### レベル3: エンジニアエスカレーション
- オンコール担当者が解決できない場合
- バックエンドリード/インフラ担当へエスカレーション
- 30分以内のエスカレーション判断

### レベル4: 全体エスカレーション
- サービス全停止の可能性
- CTO/経営層への報告
- 公式アナウンス準備

---

## SLI/SLO

### Service Level Indicators (SLI)
| 指標 | 測定方法 |
|------|---------|
| Availability | 成功リクエスト / 全リクエスト |
| Latency | p95レスポンス時間 |
| Error Rate | 5xxエラー / 全リクエスト |

### Service Level Objectives (SLO)
| 指標 | 目標値 | 測定期間 |
|------|--------|---------|
| Availability | 99.9% | 30日間 |
| Latency (p95) | < 500ms | 30日間 |
| Error Rate | < 1% | 30日間 |

### Error Budget
- **30日間のError Budget**: 0.1% = 43.2分のダウンタイム許容
- Error Budget消費率の監視が必要

---

## 変更管理

### デプロイ承認フロー

#### Staging環境
- **トリガー**: mainブランチへのマージ
- **承認**: 不要（自動デプロイ）
- **検証**: 自動スモークテスト

#### Production環境
- **トリガー**: 手動実行のみ
- **承認**: 必須（GitHub Environment Protection）
- **検証**: 手動スモークテスト + モニタリング

### メンテナンスウィンドウ
- **定期メンテナンス**: 毎週日曜 02:00-04:00 JST
- **緊急メンテナンス**: 随時（事前通知1時間以上）

---

## セキュリティインシデント対応

### フロー
1. **検知**: セキュリティアラート or 報告受領
2. **初動確認**: 影響範囲の特定（15分以内）
3. **隔離**: 影響範囲の隔離・アクセス遮断
4. **調査**: ログ解析・原因特定
5. **修正**: 脆弱性修正・パッチ適用
6. **報告**: インシデントレポート作成

### エスカレーション
- セキュリティインシデントは即座にCTOへ報告
- 個人情報漏洩の可能性がある場合は法務部門へ報告

---

## 監視とアラート

### アラートの優先度

#### CRITICAL（即座対応）
- Pod再起動頻発
- データベース接続エラー
- Availability < 99%

#### ERROR（30分以内）
- 高エラー率（> 5%）
- ディスク使用率 > 90%

#### WARNING（2時間以内）
- 高レイテンシ（p95 > 1秒）
- 高CPU/メモリ使用率（> 80%）

### アラート対応の基本
1. アラート受信後、即座にSlackで受領確認
2. Runbook参照、初動対応開始
3. 15分ごとに状況更新
4. 解決後、ポストモーテム作成

---

## バックアップとリカバリ

### データベースバックアップ
- **自動バックアップ**: 毎日 03:00 JST
- **保持期間**: 30日間
- **ポイントインタイムリカバリ**: 7日間

### リカバリ手順
詳細は [DB_MAINTENANCE.md](./DB_MAINTENANCE.md#リカバリ手順) 参照

---

## 参考資料
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Cloud SQL Best Practices](https://cloud.google.com/sql/docs/postgres/best-practices)
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/)
