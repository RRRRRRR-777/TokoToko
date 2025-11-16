# TekuToko インフラ構築ガイド（本番想定・学習用）

## 📋 概要

このガイドでは、TekuTokoのインフラを**既存Firebaseプロジェクト（tokotoko-ea308）上に本番を想定して構築**する手順を説明します。
学習目的ですが、実際の本番運用を見据えた構成で構築します。

### 想定コスト
- **構築期間**: 3-4時間
- **費用**: 環境によって異なります（下記参照）
- **注意**: GKE/Cloud SQLは継続課金されます（学習後に削除可能）

### 構築する環境
- ✅ Dev環境（開発用）
- ✅ Staging環境（検証用）
- ✅ Production環境（本番用）

---

## 🚀 Step 1: 既存Firebaseプロジェクト設定確認（10分）

### 1-1. プロジェクト設定

```bash
# 既存Firebaseプロジェクトを使用
gcloud config set project tokotoko-ea308

# 設定確認
gcloud config get-value project
# 出力例: tokotoko-ea308
```

### 1-2. 課金有効化確認

```bash
# 課金状態確認
gcloud beta billing projects describe tokotoko-ea308

# 課金が有効になっていればOK（billingEnabled: true）
# 無効の場合は以下で有効化:
# 1. https://console.cloud.google.com/billing にアクセス
# 2. 「プロジェクトをリンク」をクリック
# 3. tokotoko-ea308 を選択してリンク
```

### 1-3. 必要なAPI有効化

```bash
# 全て一度に有効化
gcloud services enable \
  container.googleapis.com \
  sqladmin.googleapis.com \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com

# 完了まで2-3分待つ
# "Operation finished successfully" と表示されればOK
```

---

## 📦 Step 2: Terraform State準備（5分）

### 2-1. GCSバケット作成（GUIで実施）

**GCPコンソールから実施:**

1. https://console.cloud.google.com/storage/browser にアクセス
2. **プロジェクトを切り替え**:
   - 画面上部のプロジェクト名をクリック
   - プロジェクト選択ダイアログで `tokotoko-ea308` を検索して選択
   - または直接 https://console.cloud.google.com/storage/browser?project=tokotoko-ea308 にアクセス
3. 「バケットを作成」をクリック
4. 以下の設定を入力:
   - **バケット名**: `tokotoko-terraform-state`
   - **ロケーションタイプ**: `Region`
   - **ロケーション**: `asia-northeast1 (Tokyo)`
   - **デフォルトのストレージクラス**: `Standard`
   - **アクセス制御**: `均一`
5. 「作成」をクリック

### 2-2. バージョニング有効化

1. 作成したバケット `tokotoko-terraform-state` をクリック
2. 「保護」タブを選択
3. 「オブジェクトのバージョニング」セクションで「有効にする」をクリック
4. 確認ダイアログで「有効にする」をクリック

### 2-3. 作成確認（CLI）

```bash
# バケット一覧確認
gsutil ls
# 出力例: gs://tokotoko-terraform-state/

# バージョニング確認
gsutil versioning get gs://tokotoko-terraform-state
# 出力例: gs://tokotoko-terraform-state: Enabled
```

---

## 🏗️ Step 3: Dev環境構築（30分）

### 3-1. 変数ファイル作成

```bash
# Dev環境ディレクトリに移動
cd deploy/terraform/envs/dev

# terraform.tfvars作成
cat > terraform.tfvars <<'EOF'
# 既存Firebaseプロジェクト
project_id = "tokotoko-ea308"
region     = "asia-northeast1"
zone       = "asia-northeast1-a"

# 開発用パスワード
# ⚠️ 学習用の仮パスワード。本番運用前にSecret Managerへ移行必須
db_password = "dev-password-12345"
EOF

# 作成確認
cat terraform.tfvars
```

### 3-2. Terraform初期化

```bash
# 初期化（プラグインダウンロード）
terraform init

# 成功すると以下のように表示される:
# Terraform has been successfully initialized!
```

### 3-3. プラン確認

```bash
# 作成されるリソースを確認
terraform plan

# 出力例:
# Plan: 15 to add, 0 to change, 0 to destroy.
```

**確認ポイント:**
- ✅ GKE Autopilotクラスタ: `tekutoko-dev`
- ✅ Cloud SQL インスタンス: `tekutoko-dev`
- ✅ VPC ネットワーク: `tekutoko-vpc-dev`
- ✅ Artifact Registry: `tekutoko`

### 3-4. 適用（実際にリソース作成）

```bash
# 適用実行
terraform apply

# "Do you want to perform these actions?" と聞かれたら
# "yes" と入力してEnter

# 完了まで20-30分かかります（GKEクラスタ作成に時間がかかる）
# Apply complete! Resources: 15 added, 0 changed, 0 destroyed. と表示されればOK
```

### 3-5. 動作確認

```bash
# GKEクラスタ確認
gcloud container clusters list
# 出力例: tekutoko-dev  asia-northeast1  ...  RUNNING

# Cloud SQL確認
gcloud sql instances list
# 出力例: tekutoko-dev  POSTGRES_15  ...  RUNNABLE

# クラスタ認証情報取得
gcloud container clusters get-credentials tekutoko-dev \
  --region=asia-northeast1

# ノード確認
kubectl get nodes
# 出力例: gk3-tekutoko-dev-...  Ready  ...
```

---

## 🔄 Step 4: Staging環境構築（30分）

### 4-1. 変数ファイル作成

```bash
# Staging環境ディレクトリに移動
cd ../staging

# terraform.tfvars作成
cat > terraform.tfvars <<'EOF'
project_id = "tokotoko-ea308"
region     = "asia-northeast1"
zone       = "asia-northeast1-a"
db_password = "staging-password-12345"
EOF
```

### 4-2. Terraform実行

```bash
terraform init
terraform plan
terraform apply
# "yes" と入力してEnter

# 完了まで20-30分
```

### 4-3. 動作確認

```bash
gcloud container clusters get-credentials tekutoko-staging \
  --region=asia-northeast1

kubectl get nodes
```

---

## 🚀 Step 5: Production環境構築（30分）

### 5-1. 変数ファイル作成

```bash
cd ../production

cat > terraform.tfvars <<'EOF'
project_id = "tokotoko-ea308"
region     = "asia-northeast1"
zone       = "asia-northeast1-a"
db_password = "prod-password-12345"
EOF
```

### 5-2. Terraform実行

```bash
terraform init
terraform plan
terraform apply
# "yes" と入力してEnter

# 完了まで30-40分（HA構成のため少し時間がかかる）
```

### 5-3. 動作確認

```bash
gcloud container clusters get-credentials tekutoko-production \
  --region=asia-northeast1

kubectl get nodes
```

---

## ✅ Step 6: 全環境の確認（10分）

### 6-1. リソース一覧確認

```bash
# GKEクラスタ一覧
gcloud container clusters list
# 出力例:
# tekutoko-dev        asia-northeast1  ...  RUNNING
# tekutoko-staging    asia-northeast1  ...  RUNNING
# tekutoko-production asia-northeast1  ...  RUNNING

# Cloud SQL一覧
gcloud sql instances list
# 出力例:
# tekutoko-dev        POSTGRES_15  ...  RUNNABLE
# tekutoko-staging    POSTGRES_15  ...  RUNNABLE
# tekutoko-production POSTGRES_15  ...  RUNNABLE

# VPCネットワーク一覧
gcloud compute networks list
# 出力例:
# tekutoko-vpc-dev
# tekutoko-vpc-staging
# tekutoko-vpc-production
```

### 6-2. 環境別の違い確認

| 項目 | Dev | Staging | Production |
|------|-----|---------|------------|
| **GKE** | 2 Pods | 2-5 Pods | 2-10 Pods（HA） |
| **Cloud SQL** | db-f1-micro | db-g1-small | db-custom-2-7680（HA） |
| **ディスク** | 10GB | 20GB | 50GB |
| **バックアップ** | なし | あり（7日） | あり（30日） |
| **コスト/月** | ~\$80 | ~\$150 | ~\$370 |

---

## 🗑️ Step 7: 環境削除（学習完了後）

### ⚠️ 注意事項

**本番想定の学習環境のため:**
- プロジェクト全削除は実施しない（Firebaseデータ保護）
- 学習完了後、不要な環境（Dev/Staging）を削除可能
- Production環境は本番運用開始まで維持または削除を慎重に判断

### 7-1. Dev環境削除（学習完了後）

```bash
cd deploy/terraform/envs/dev

# 削除実行
terraform destroy

# "Do you really want to destroy all resources?" と聞かれたら
# "yes" と入力してEnter

# 完了まで10-15分
```

### 7-2. Staging環境削除（学習完了後）

```bash
cd ../staging
terraform destroy
# "yes" と入力

# 完了まで10-15分
```

### 7-3. Production環境削除（本番運用しない場合のみ）

```bash
cd ../production
terraform destroy
# "yes" と入力

# 完了まで10-15分
# ⚠️ 本番運用を開始する場合は削除しないこと
```

### 7-4. GCSバケット削除（完全削除時のみ）

```bash
# ⚠️ 全環境削除後のみ実行
# Terraform Stateも削除されるため、再構築時は初期化から必要
# gsutil rm -r gs://tokotoko-terraform-state
```

### 7-5. 本番運用への移行について

**学習完了後、本番運用を開始する場合:**
1. Dev/Staging環境を削除してコスト削減
2. Production環境は維持
3. DB パスワードをSecret Managerへ移行
4. terraform.tfvarsを.gitignoreに追加
5. 監視・アラート設定を確認
6. バックアップ設定を確認

---

## 📊 コスト確認

### リアルタイムコスト確認

```bash
# コンソールでコスト確認
open https://console.cloud.google.com/billing/\$(gcloud config get-value project)
```

または、GCPコンソール:
1. **Billing** > **Cost table**
2. プロジェクト: `tokotoko-ea308`
3. 現在のコストを確認

---

## 🔍 トラブルシューティング

### エラー: "Quota exceeded"

**原因**: GCPの無料枠/クォータ制限

**対処**:
```bash
# クォータ確認
gcloud compute project-info describe --project=tokotoko-ea308

# クォータ増加リクエスト（GCPコンソールから）
open https://console.cloud.google.com/iam-admin/quotas
```

### エラー: "API not enabled"

**対処**:
```bash
# 必要なAPIを再度有効化
gcloud services enable container.googleapis.com
```

### エラー: terraform applyが途中で失敗

**対処**:
```bash
# 再度実行（Terraformは冪等性があるため安全）
terraform apply
```

### Cloud SQLが "RUNNABLE" にならない

**対処**:
```bash
# インスタンス状態確認
gcloud sql instances describe tekutoko-dev

# ログ確認
gcloud sql operations list --instance=tekutoko-dev
```

---

## 📚 参考リンク

- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Autopilot Documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)

---

## ⏱️ 推奨作業スケジュール

| 時間 | 作業内容 |
|------|---------|
| 0:00 - 0:10 | Step 1: GCPプロジェクト作成 |
| 0:10 - 0:15 | Step 2: Terraform State準備 |
| 0:15 - 0:45 | Step 3: Dev環境構築 |
| 0:45 - 1:15 | Step 4: Staging環境構築 |
| 1:15 - 1:55 | Step 5: Production環境構築 |
| 1:55 - 2:05 | Step 6: 全環境確認 |
| 2:05 - 2:30 | 学習・検証 |
| 2:30 - 3:15 | Step 7: 全環境削除 |
| **合計** | **3-4時間** |

---

## ✅ チェックリスト

### 構築前
- [ ] GCPアカウント作成済み
- [ ] クレジットカード登録済み（課金用）
- [ ] gcloud CLI インストール済み
- [ ] terraform インストール済み

### 構築中
- [ ] Step 1: プロジェクト作成
- [ ] Step 2: Terraform State準備
- [ ] Step 3: Dev環境構築
- [ ] Step 4: Staging環境構築
- [ ] Step 5: Production環境構築
- [ ] Step 6: 動作確認

### 削除（重要！）
- [ ] Step 7-1: Production削除
- [ ] Step 7-2: Staging削除
- [ ] Step 7-3: Dev削除
- [ ] Step 7-4: GCSバケット削除
- [ ] Step 7-5: プロジェクト削除
- [ ] コスト確認（\$0になっているか）

---

## 💡 Tips

### 作業を中断する場合
```bash
# 現在の状態を保存
terraform show > terraform.state.backup

# 再開時に確認
terraform plan
```

### コスト管理のポイント
1. **予算アラート設定**（GCPコンソールから推奨）
2. **不要な環境は即座に削除**（Dev/Stagingなど）
3. **Cloud SQLが最もコスト高**（HA構成は特に注意）
4. **定期的なコスト確認**（月次レビュー推奨）

### よくある質問

**Q: Firebaseと共存して問題ないか？**
A: 問題ありません。同一GCPプロジェクト内でFirebaseとGKEは共存できます。

**Q: 途中でエラーが出たら？**
A: `terraform apply` を再実行してください。冪等性があるため安全です。

**Q: 一度削除したら復元できる？**
A: GKE/Cloud SQLリソースは復元不可。Terraform Stateがあれば再構築可能。

**Q: 本番環境で使う場合は？**
A: パスワードをSecret Managerに移行、terraform.tfvarsを.gitignoreに追加してください。

---

**🎉 以上で完了です！**

本番を想定したインフラ構築の学習、頑張ってください！
学習完了後は、本番運用への移行または環境削除を検討してください。
