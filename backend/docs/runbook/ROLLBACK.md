# ロールバック手順 Runbook

## 目的
本番環境でデプロイ後に問題が発生した場合、迅速に前のバージョンに戻す。

## ロールバックが必要なケース

### 即座にロールバック（5分以内）
- ✅ サービスが完全に停止している
- ✅ エラー率が50%を超えている
- ✅ データ破損のリスクがある
- ✅ セキュリティインシデントが発生

### 調査後にロールバック（15分以内）
- ⚠️ エラー率が10%を超えている
- ⚠️ レスポンス時間が通常の3倍以上
- ⚠️ 特定機能が動作していない
- ⚠️ Pod再起動が頻発している

---

## ロールバック手順

### 方法1: Kubernetes ロールバック（推奨）

#### 1-1. デプロイ履歴確認
```bash
# ロールアウト履歴を確認
kubectl rollout history deployment/tekutoko-api -n default

# 出力例:
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         Update to version 1.2.0
# 3         Update to version 1.3.0 (現在)
```

#### 1-2. 特定リビジョンの詳細確認
```bash
# リビジョン2の詳細確認
kubectl rollout history deployment/tekutoko-api -n default --revision=2

# イメージタグ確認
kubectl get deployment tekutoko-api -n default -o jsonpath='{.spec.template.spec.containers[0].image}'
```

#### 1-3. ロールバック実行
```bash
# 直前のリビジョンにロールバック
kubectl rollout undo deployment/tekutoko-api -n default

# 特定のリビジョンにロールバック（推奨）
kubectl rollout undo deployment/tekutoko-api -n default --to-revision=2
```

#### 1-4. ロールバック完了確認
```bash
# ロールアウト状態確認（完了まで待機）
kubectl rollout status deployment/tekutoko-api -n default

# Pod状態確認
kubectl get pods -l app=tekutoko-api -n default

# 新しいPodのログ確認
kubectl logs -l app=tekutoko-api -n default --tail=50
```

#### 1-5. 動作確認
```bash
# ヘルスチェック
EXTERNAL_IP=$(kubectl get service tekutoko-api -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -f http://$EXTERNAL_IP/health || echo "Health check failed"

# レディネスチェック
curl -f http://$EXTERNAL_IP/ready || echo "Ready check failed"

# サンプルAPIリクエスト
curl -f http://$EXTERNAL_IP/v1/walks || echo "API request failed"
```

---

### 方法2: GitHub Actions経由でロールバック

#### 2-1. GitHub Actions UIでデプロイ
1. GitHub リポジトリ > Actions > "CD - Production"
2. "Run workflow" をクリック
3. 前回の正常なイメージタグを入力（例: `abc1234`）
4. 承認者に承認依頼
5. デプロイ完了を確認

#### 2-2. イメージタグの確認方法
```bash
# Artifact Registryのイメージタグ一覧
gcloud artifacts docker images list \
  asia-northeast1-docker.pkg.dev/PROJECT_ID/tekutoko/tekutoko-api \
  --include-tags \
  --format="table(version,tags,update_time)" \
  --sort-by=~update_time \
  --limit=10
```

---

### 方法3: デプロイメント定義ファイルから復元

#### 3-1. バックアップファイル取得
GitHub Actionsの「deployment-backup」アーティファクトをダウンロード：
1. GitHub > Actions > 該当のProduction デプロイワークフロー
2. Artifacts > `deployment-backup-XXXXXX` をダウンロード
3. 解凍

#### 3-2. バックアップから復元
```bash
# バックアップファイルを適用
kubectl apply -f deployment-backup-20250116-120000.yaml

# ロールアウト完了確認
kubectl rollout status deployment/tekutoko-api -n default
```

---

## データベースロールバック

### 重要な注意事項
⚠️ **データベースロールバックは慎重に実施すること**
- データ損失のリスクがある
- ダウンタイムが発生する可能性がある
- 必ず事前にバックアップを確認

### マイグレーションロールバック

#### 1. マイグレーション履歴確認
```bash
# 現在のマイグレーションバージョン確認
kubectl exec -it deployment/tekutoko-api -n default -- \
  /api migrate version

# マイグレーション履歴確認
kubectl exec -it deployment/tekutoko-api -n default -- \
  /api migrate history
```

#### 2. マイグレーションダウン実行
```bash
# 1ステップダウン
kubectl exec -it deployment/tekutoko-api -n default -- \
  /api migrate down 1

# 特定バージョンまでダウン
kubectl exec -it deployment/tekutoko-api -n default -- \
  /api migrate down-to 000005
```

#### 3. データベース状態確認
```bash
# テーブル一覧確認
kubectl exec -it deployment/tekutoko-api -n default -- \
  psql -h localhost -U tekutoko -d tekutoko_production -c "\dt"

# データ整合性確認
kubectl exec -it deployment/tekutoko-api -n default -- \
  psql -h localhost -U tekutoko -d tekutoko_production -c "SELECT count(*) FROM users;"
```

### ポイントインタイムリカバリ

重大なデータ破損が発生した場合：

#### 1. 復元ポイント確認
```bash
# 利用可能な復元ポイント確認
gcloud sql backups list --instance=tekutoko-production
```

#### 2. 新しいインスタンスに復元
```bash
# 復元用の新インスタンス作成
gcloud sql instances clone tekutoko-production tekutoko-production-restored \
  --point-in-time='2025-01-16T12:00:00.000Z'
```

#### 3. データ検証後、切り替え
```bash
# 新インスタンスのデータ確認
# 問題なければ、アプリケーションの接続先を切り替え
```

詳細は [DB_MAINTENANCE.md](./DB_MAINTENANCE.md#ポイントインタイムリカバリ) 参照

---

## ロールバック後の確認項目

### 1. サービス正常性
- [ ] ヘルスチェック成功
- [ ] レディネスチェック成功
- [ ] エラー率が1%未満
- [ ] レスポンス時間が正常範囲（p95 < 500ms）

### 2. リソース状態
- [ ] Pod が全て Running 状態
- [ ] CPU/メモリ使用率が正常範囲
- [ ] データベース接続プール正常

### 3. モニタリング
- [ ] Cloud Monitoring ダッシュボードで異常なし
- [ ] アラートが解消されている
- [ ] ログにエラーが出ていない

### 4. ユーザー影響
- [ ] ユーザーからの障害報告がない
- [ ] 主要機能の動作確認完了

---

## 通知とコミュニケーション

### ロールバック開始時
```
【ロールバック開始】

発生時刻: YYYY-MM-DD HH:MM JST
影響: [サービス停止/エラー率上昇 等]
原因: [デプロイに起因する問題]
対応: ロールバックを開始します

予想復旧時刻: HH:MM JST
```

### ロールバック完了時
```
【ロールバック完了・復旧】

復旧時刻: YYYY-MM-DD HH:MM JST
対応内容: リビジョンXXからリビジョンYYにロールバック
確認結果: サービス正常稼働中

次のアクション:
- 問題の原因調査
- ポストモーテム作成
```

---

## ロールバック後のアクション

### 1. 原因調査（24時間以内）
- デプロイで導入された変更の特定
- エラーログの詳細分析
- 再現環境での問題再現

### 2. ポストモーテム作成（48時間以内）
- [POSTMORTEM_TEMPLATE.md](./POSTMORTEM_TEMPLATE.md) を使用
- タイムライン作成
- 根本原因分析（RCA）
- 再発防止策の立案

### 3. 修正とリリース
- 問題の修正
- ステージング環境で十分なテスト
- 段階的なロールアウト計画

---

## ロールバックできない場合

### フォワードフィックス（Forward Fix）
ロールバックが不可能な場合（データベーススキーマ変更後など）：

1. **問題箇所の特定**
   ```bash
   # エラーログから問題を特定
   kubectl logs -l app=tekutoko-api -n default --tail=200
   ```

2. **緊急修正の実装**
   - ホットフィックスブランチ作成
   - 最小限の修正を実装
   - ステージングで検証

3. **緊急デプロイ**
   - GitHub Actions で緊急デプロイ
   - 段階的ロールアウト（Canary デプロイ）

4. **修正確認**
   - エラー率の低下確認
   - 正常性確認

---

## ロールバックチェックリスト

### 事前確認
- [ ] ロールバックの必要性を判断
- [ ] ロールバック先のリビジョンを特定
- [ ] 関係者に通知
- [ ] バックアップ状態確認

### ロールバック実行
- [ ] デプロイ履歴確認
- [ ] ロールバックコマンド実行
- [ ] ロールアウト完了確認
- [ ] Pod状態確認

### 動作確認
- [ ] ヘルスチェック成功
- [ ] API動作確認
- [ ] エラー率確認
- [ ] モニタリング確認

### 事後対応
- [ ] 関係者に完了通知
- [ ] 原因調査開始
- [ ] ポストモーテム作成
- [ ] 再発防止策立案

---

## トラブルシューティング

### ロールバックが失敗する
```bash
# Deploymentの状態確認
kubectl describe deployment tekutoko-api -n default

# イベントログ確認
kubectl get events -n default --sort-by='.lastTimestamp' | tail -20

# Podの詳細確認
kubectl describe pod <POD_NAME> -n default
```

### 古いPodが残り続ける
```bash
# 古いReplicaSetの削除
kubectl delete replicaset <OLD_REPLICASET_NAME> -n default

# または、強制的に再作成
kubectl rollout restart deployment/tekutoko-api -n default
```

### イメージがPullできない
```bash
# イメージ確認
kubectl describe pod <POD_NAME> -n default | grep -A 5 "Events:"

# Artifact Registryの権限確認
gcloud artifacts docker images list \
  asia-northeast1-docker.pkg.dev/PROJECT_ID/tekutoko/tekutoko-api
```

---

## 関連リンク
- [Cloud Monitoring Dashboard](https://console.cloud.google.com/monitoring/dashboards)
- [GKE Deployments](https://console.cloud.google.com/kubernetes/workload)
- [Artifact Registry](https://console.cloud.google.com/artifacts)
- [エラー率対応](./ERROR_RATE.md)
- [データベースメンテナンス](./DB_MAINTENANCE.md)
- [ポストモーテムテンプレート](./POSTMORTEM_TEMPLATE.md)
