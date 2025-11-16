# TekuToko Kubernetes Manifests

GKE Autopilot上でTekuToko APIを稼働させるためのKubernetesマニフェスト集です。

## 📁 ファイル構成

| ファイル | 説明 | 必須 |
|---------|------|------|
| `deployment.yaml` | メインアプリケーション + Cloud SQL Proxyサイドカー | ✅ Phase2 |
| `service.yaml` | LoadBalancer（外部公開） | ✅ Phase2 |
| `serviceaccount.yaml` | Workload Identity設定 | ✅ Phase2 |
| `configmap.yaml` | 環境変数（DB接続情報等） | ✅ Phase2 |
| `secret.yaml` | 機密情報（パスワード、認証情報）テンプレート | ✅ Phase2 |
| `hpa.yaml` | Horizontal Pod Autoscaler（2-10レプリカ） | ✅ Phase2 |
| `poddisruptionbudget.yaml` | 可用性担保設定 | ✅ Phase2 |
| `networkpolicy.yaml` | ネットワークセキュリティ | ⏳ Phase4 |
| `ingress.yaml` | HTTPS終端・静的IP | ⏳ Phase4 |

## 🚀 デプロイ手順

### 前提条件

1. **GKEクラスタが作成済み**
   ```bash
   # Terraformで作成済みの場合
   cd ../../terraform/envs/prod
   terraform output gke_cluster_name
   ```

2. **kubectlでクラスタに接続**
   ```bash
   gcloud container clusters get-credentials gke-tekutoko-prod \
     --region asia-northeast1 \
     --project PROJECT_ID
   ```

3. **Workload Identity設定完了**
   - GCPサービスアカウント作成
   - IAMロール付与
   - Workload Identityバインディング
   （詳細は `serviceaccount.yaml` 参照）

### ステップ1: プレースホルダー置換

以下のファイル内のプレースホルダーを実際の値に置換：

```bash
# deployment.yaml
PROJECT_ID → 実際のGCPプロジェクトID
REGION → asia-northeast1
INSTANCE_NAME → Cloud SQLインスタンス名（例: tekutoko-prod-db）

# serviceaccount.yaml
PROJECT_ID → 実際のGCPプロジェクトID

# configmap.yaml
firebase_project_id → FirebaseプロジェクトID
db_name → 環境に応じたDB名（tekutoko_production等）
```

### ステップ2: Secretの作成

Secret ManagerまたはkubectlコマンドでSecretを作成：

```bash
# 方法1: kubectlで直接作成（推奨）
kubectl create secret generic app-secret \
  --from-literal=db_password='YOUR_DB_PASSWORD' \
  --from-file=firebase_service_account_json=./path/to/firebase-sa.json

# 方法2: Secret Managerから取得
gcloud secrets versions access latest --secret="db-password" | \
  kubectl create secret generic app-secret \
    --from-file=db_password=/dev/stdin \
    --dry-run=client -o yaml | kubectl apply -f -
```

### ステップ3: マニフェスト適用

```bash
# 順番に適用（依存関係を考慮）
kubectl apply -f serviceaccount.yaml
kubectl apply -f configmap.yaml
# secret.yamlは使用せず、上記のkubectl create secretで作成済み
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
kubectl apply -f poddisruptionbudget.yaml
```

### ステップ4: デプロイ確認

```bash
# Pod状態確認
kubectl get pods -l app=tekutoko-api

# Service確認（External IPが割り当てられるまで数分かかる）
kubectl get service tekutoko-api

# HPA状態確認
kubectl get hpa tekutoko-api-hpa

# ログ確認
kubectl logs -l app=tekutoko-api -c api --tail=100 -f
```

## 🔧 運用コマンド

### スケーリング

```bash
# 手動でレプリカ数を変更（HPAが無効な場合）
kubectl scale deployment tekutoko-api --replicas=5

# HPA無効化
kubectl delete hpa tekutoko-api-hpa

# HPA再有効化
kubectl apply -f hpa.yaml
```

### ローリングアップデート

```bash
# 新しいイメージでアップデート
kubectl set image deployment/tekutoko-api \
  api=gcr.io/PROJECT_ID/tekutoko-api:v1.1.0

# ロールアウト状態確認
kubectl rollout status deployment/tekutoko-api

# ロールバック
kubectl rollout undo deployment/tekutoko-api
```

### デバッグ

```bash
# Pod内でコマンド実行
kubectl exec -it deployment/tekutoko-api -- /bin/sh

# 特定Podのログ確認
kubectl logs POD_NAME -c api

# Cloud SQL Proxyのログ確認
kubectl logs POD_NAME -c cloud-sql-proxy

# イベント確認
kubectl get events --sort-by='.lastTimestamp'
```

### ConfigMap/Secret更新

```bash
# ConfigMap更新
kubectl edit configmap app-config

# Secret更新
kubectl create secret generic app-secret \
  --from-literal=db_password='NEW_PASSWORD' \
  --dry-run=client -o yaml | kubectl apply -f -

# Podを再起動して変更を反映
kubectl rollout restart deployment/tekutoko-api
```

## 📊 リソース設定

### Pod仕様

| リソース | Request | Limit |
|---------|---------|-------|
| **API Container** | 500m CPU, 512Mi RAM | 1000m CPU, 1Gi RAM |
| **Cloud SQL Proxy** | 100m CPU, 128Mi RAM | 200m CPU, 256Mi RAM |
| **合計/Pod** | 600m CPU, 640Mi RAM | 1200m CPU, 1.25Gi RAM |

### Auto Scaling

- **最小レプリカ**: 2（冗長性確保）
- **最大レプリカ**: 10
- **スケールアップ条件**: CPU 70% または メモリ 80%
- **スケールダウン**: 5分間安定後、最大50%ずつ縮小

## ⚠️ 注意事項

1. **Secret管理**
   - `secret.yaml`に実際の認証情報を含めない
   - Gitにコミットしない（`.gitignore`で除外済み）
   - Secret Managerまたはkubectlで作成

2. **Workload Identity**
   - GCP側のIAM設定が必須
   - サービスアカウントに適切な権限を付与

3. **Cloud SQL Proxy**
   - 接続名（PROJECT_ID:REGION:INSTANCE_NAME）を正確に設定
   - Proxyが起動しないとアプリケーションもDB接続できない

4. **LoadBalancer**
   - External IP割り当てに数分かかる
   - コスト発生に注意（静的IP化はPhase4）

## 🔄 次のステップ

- [ ] Phase4でIngress + 静的IP導入
- [ ] Phase4でNetworkPolicy追加
- [ ] カスタムメトリクス（レイテンシ、リクエストレート）でHPA拡張
- [ ] Cloud Armorでセキュリティ強化
- [ ] CI/CDパイプラインでデプロイ自動化
