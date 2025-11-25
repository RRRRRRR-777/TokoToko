# GKE Autopilot セットアップガイド

## クラスタ作成

```bash
# クラスタ作成（Cloud SQLと同じネットワークを指定）
gcloud container clusters create-auto gke-tekutoko-dev \
  --region=asia-northeast1 \
  --project=tokotoko-ea308 \
  --network=vpc-tekutoko-dev \
  --subnetwork=subnet-asia-northeast1-dev-primary

# 認証情報取得
gcloud container clusters get-credentials gke-tekutoko-dev \
  --region=asia-northeast1 \
  --project=tokotoko-ea308
```

## Secretの作成

GKE AutopilotではSecrets Store CSI DriverのGCP Providerがインストールできないため、Kubernetes Secretを手動作成します。

```bash
# namespace作成
kubectl create namespace tekutoko-dev

# Secret Managerから取得してSecretを作成
DB_PASSWORD=$(gcloud secrets versions access latest --secret=db-password --project=tokotoko-ea308)
FIREBASE_JSON=$(gcloud secrets versions access latest --secret=firebase-service-account --project=tokotoko-ea308)

kubectl create secret generic app-secret \
  --from-literal=db_password="$DB_PASSWORD" \
  --from-literal=firebase_service_account_json="$FIREBASE_JSON" \
  --namespace=tekutoko-dev

# 確認
kubectl get secret app-secret -n tekutoko-dev
```

## デプロイ

```bash
# コミットをプッシュ
git push origin HEAD

# GitHub Actionsで「Deploy to GKE Dev」ワークフローを手動実行
# https://github.com/RRRRRRR-777/TokoToko/actions/workflows/backend-cd-dev.yml

# デプロイ完了後、状態確認
kubectl get pods -n tekutoko-dev
kubectl logs -n tekutoko-dev -l app=tekutoko-api -c api --tail=50
```

## 動作確認

```bash
# サービスIP取得
EXTERNAL_IP=$(kubectl get service -n tekutoko-dev tekutoko-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# ヘルスチェック
curl http://$EXTERNAL_IP/health
```

### GCPコンソールで確認

- **Cloud Logging**: ログに`trace_id`、`span_id`が含まれることを確認
- **Cloud Trace**: HTTPリクエストのトレースが記録されていることを確認
- **Cloud Monitoring**: OpenTelemetryメトリクス（`http.server.request.*`）を確認

## トラブルシューティング

### Pod起動失敗

```bash
kubectl describe pod -n tekutoko-dev -l app=tekutoko-api
kubectl logs -n tekutoko-dev -l app=tekutoko-api -c api --tail=100
kubectl logs -n tekutoko-dev -l app=tekutoko-api -c cloud-sql-proxy
```

### GitHub Actions失敗時

CSI Driverチェックで失敗する場合は、上記手順でSecretを手動作成後、GitHub Actionsを再実行してください。

## クリーンアップ

```bash
# リソース削除
kubectl delete -k backend/deploy/kubernetes/overlays/dev

# クラスタ削除
gcloud container clusters delete gke-tekutoko-dev \
  --region=asia-northeast1 \
  --project=tokotoko-ea308
```
