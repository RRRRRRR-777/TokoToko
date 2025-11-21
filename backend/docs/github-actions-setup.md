# GitHub Actions CI/CD セットアップガイド

## 📋 概要

このガイドでは、TekuToko バックエンドの GitHub Actions CI/CD パイプラインを動作させるために必要な設定手順を説明します。

### 前提条件

- ✅ GCP プロジェクトが作成済み（例: `tokotoko-ea308`）
- ✅ GKE クラスターが作成済み（Staging: `tekutoko-staging`, Production: `tekutoko-production`）
- ✅ Artifact Registry リポジトリが作成済み（`tekutoko`）
- ✅ GitHub リポジトリへの管理者アクセス権限

### 必要な作業時間

- **Workload Identity 設定**: 15-20分
- **GitHub Secrets 登録**: 5分

---

## 🔐 Step 1: Workload Identity の設定（15-20分）

Workload Identity を使用することで、GitHub Actions から GCP リソースへ安全にアクセスできます。

### 1-1. サービスアカウントの作成

#### Staging 用サービスアカウント

```bash
# プロジェクト設定
export GCP_PROJECT_ID="tokotoko-ea308"
gcloud config set project ${GCP_PROJECT_ID}

# Staging用サービスアカウント作成
gcloud iam service-accounts create github-actions-staging \
  --display-name="GitHub Actions for Staging" \
  --description="Service account for GitHub Actions to deploy to Staging environment"
```

#### Dev 用サービスアカウント

```bash
# Dev用サービスアカウント作成
gcloud iam service-accounts create github-actions-dev \
  --display-name="GitHub Actions for Dev" \
  --description="Service account for GitHub Actions to deploy to Dev environment"
```

#### Production 用サービスアカウント

```bash
# Production用サービスアカウント作成
gcloud iam service-accounts create github-actions-production \
  --display-name="GitHub Actions for Production" \
  --description="Service account for GitHub Actions to deploy to Production environment"
```

### 1-2. サービスアカウントへの権限付与

#### Staging 用の権限

```bash
# サービスアカウントのメールアドレスを変数に設定
export SA_STAGING="github-actions-staging@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

# Artifact Registry への書き込み権限
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_STAGING}" \
  --role="roles/artifactregistry.writer"

# GKE クラスターへのアクセス権限
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_STAGING}" \
  --role="roles/container.developer"

# Cloud SQL への接続権限（必要に応じて）
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_STAGING}" \
  --role="roles/cloudsql.client"
```

#### Dev 用の権限

```bash
# サービスアカウントのメールアドレスを変数に設定
export SA_DEV="github-actions-dev@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

# Artifact Registry への書き込み権限
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_DEV}" \
  --role="roles/artifactregistry.writer"

# GKE クラスターへのアクセス権限
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_DEV}" \
  --role="roles/container.developer"

# Cloud SQL への接続権限（必要に応じて）
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_DEV}" \
  --role="roles/cloudsql.client"
```

#### Production 用の権限

```bash
# サービスアカウントのメールアドレスを変数に設定
export SA_PRODUCTION="github-actions-production@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

# Artifact Registry への書き込み権限
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_PRODUCTION}" \
  --role="roles/artifactregistry.writer"

# GKE クラスターへのアクセス権限
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_PRODUCTION}" \
  --role="roles/container.developer"

# Cloud SQL への接続権限（必要に応じて）
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:${SA_PRODUCTION}" \
  --role="roles/cloudsql.client"
```

### 1-3. Workload Identity Pool の作成

```bash
# Workload Identity Pool 作成
gcloud iam workload-identity-pools create "github-actions-pool" \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  --description="Workload Identity Pool for GitHub Actions"

# 作成確認
gcloud iam workload-identity-pools describe "github-actions-pool" \
  --location="global"
```

### 1-4. Workload Identity Provider の作成

```bash
# GitHub リポジトリ情報を設定（要変更）
export GITHUB_ORG="RRRRRRR-777"
export GITHUB_REPO="TokoToko"

# Workload Identity Provider 作成
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Provider の完全な名前を取得（後で使用）
gcloud iam workload-identity-pools providers describe "github-provider" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --format="value(name)"
```

**出力例**:
```
projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
```

この値を `GCP_WORKLOAD_IDENTITY_PROVIDER` として後で GitHub Secrets に登録します。

### 1-5. サービスアカウントと GitHub リポジトリのバインディング

まず、プロジェクト番号を取得します：

```bash
# プロジェクト番号を取得して変数に設定
export PROJECT_NUMBER=$(gcloud projects describe ${GCP_PROJECT_ID} --format="value(projectNumber)")
echo "PROJECT_NUMBER: ${PROJECT_NUMBER}"
```

#### Staging 用バインディング

```bash
# Staging サービスアカウントに GitHub Actions からのアクセスを許可
gcloud iam service-accounts add-iam-policy-binding ${SA_STAGING} \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"
```

#### Dev 用バインディング

```bash
# Dev サービスアカウントに GitHub Actions からのアクセスを許可
gcloud iam service-accounts add-iam-policy-binding ${SA_DEV} \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"
```

#### Production 用バインディング

```bash
# Production サービスアカウントに GitHub Actions からのアクセスを許可
gcloud iam service-accounts add-iam-policy-binding ${SA_PRODUCTION} \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"
```

**注意**: `${PROJECT_NUMBER}` は以下のコマンドで取得できます：

```bash
gcloud projects describe ${GCP_PROJECT_ID} --format="value(projectNumber)"
```

### 1-6. 設定値の確認とメモ

以下の値を確認してメモしてください（Step 2で使用）：

```bash
# 1. GCP プロジェクト ID
echo "GCP_PROJECT_ID: ${GCP_PROJECT_ID}"

# 2. Workload Identity Provider（完全な名前）
gcloud iam workload-identity-pools providers describe "github-provider" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --format="value(name)"

# 3. Dev サービスアカウント
echo "GCP_SERVICE_ACCOUNT_DEV: ${SA_DEV}"

# 4. Staging サービスアカウント
echo "GCP_SERVICE_ACCOUNT: ${SA_STAGING}"

# 5. Production サービスアカウント
echo "GCP_SERVICE_ACCOUNT_PROD: ${SA_PRODUCTION}"
```

**出力例**:
```
GCP_PROJECT_ID: tokotoko-ea308
projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
GCP_SERVICE_ACCOUNT_DEV: github-actions-dev@tokotoko-ea308.iam.gserviceaccount.com
GCP_SERVICE_ACCOUNT: github-actions-staging@tokotoko-ea308.iam.gserviceaccount.com
GCP_SERVICE_ACCOUNT_PROD: github-actions-production@tokotoko-ea308.iam.gserviceaccount.com
```

---

## 🔑 Step 2: GitHub Secrets の登録（5分）

### 2-1. GitHub リポジトリの Settings にアクセス

1. https://github.com/RRRRRRR-777/TokoToko にアクセス
2. 「Settings」タブをクリック
3. 左サイドバーから「Secrets and variables」→「Actions」をクリック

### 2-2. Repository Secrets の追加

「New repository secret」ボタンをクリックして、以下の Secrets を順次追加します：

#### 1. GCP_PROJECT_ID

- **Name**: `GCP_PROJECT_ID`
- **Secret**: `tokotoko-ea308`（実際のプロジェクトIDに置き換え）

#### 2. GCP_WORKLOAD_IDENTITY_PROVIDER

- **Name**: `GCP_WORKLOAD_IDENTITY_PROVIDER`
- **Secret**: Step 1-6 で確認した Workload Identity Provider の完全な名前
  ```
  projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
  ```

#### 3. GCP_SERVICE_ACCOUNT_DEV（Dev用）

- **Name**: `GCP_SERVICE_ACCOUNT_DEV`
- **Secret**: Step 1-6 で確認した Dev サービスアカウント
  ```
  github-actions-dev@tokotoko-ea308.iam.gserviceaccount.com
  ```

#### 4. GCP_SERVICE_ACCOUNT（Staging用）

- **Name**: `GCP_SERVICE_ACCOUNT`
- **Secret**: Step 1-6 で確認した Staging サービスアカウント
  ```
  github-actions-staging@tokotoko-ea308.iam.gserviceaccount.com
  ```

#### 5. GCP_SERVICE_ACCOUNT_PROD（Production用）

- **Name**: `GCP_SERVICE_ACCOUNT_PROD`
- **Secret**: Step 1-6 で確認した Production サービスアカウント
  ```
  github-actions-production@tokotoko-ea308.iam.gserviceaccount.com
  ```

### 2-3. 設定確認

登録後、「Actions secrets」セクションに以下の5つの Secrets が表示されているはずです：

- ✅ `GCP_PROJECT_ID`
- ✅ `GCP_WORKLOAD_IDENTITY_PROVIDER`
- ✅ `GCP_SERVICE_ACCOUNT_DEV`
- ✅ `GCP_SERVICE_ACCOUNT`
- ✅ `GCP_SERVICE_ACCOUNT_PROD`

---

## ✅ Step 3: 動作確認（5分）

### 3-1. CI ワークフローのテスト

```bash
# backend ディレクトリで軽微な変更を加える
cd backend
echo "# Test CI" >> README.md

# コミット & プッシュ
git add README.md
git commit -m "test: CI ワークフローの動作確認"
git push origin ticket/153
```

### 3-2. GitHub Actions の実行確認

1. https://github.com/RRRRRRR-777/TokoToko/actions にアクセス
2. 「Backend CI」ワークフローが実行されていることを確認
3. 以下のジョブが全てパスすることを確認：
   - ✅ Lint
   - ✅ Test
   - ✅ Build
   - ✅ Security Scan

### 3-3. CD ワークフローのテスト（オプション）

**注意**: ticket/** ブランチでは、ビルド・プッシュまで実行されますが、GKE デプロイはスキップされます。

```bash
# backend/internal 配下で変更を加える
cd backend
touch internal/test_file.go

# コミット & プッシュ
git add internal/test_file.go
git commit -m "test: CD ワークフローの動作確認"
git push origin ticket/153
```

**期待される動作**:
- ✅ Backend CD - Staging: `build-and-push` ジョブのみ実行、`deploy-to-gke` はスキップ
- ❌ Backend CD - Production: トリガーなし（手動実行のみ）

### 3-4. main ブランチマージ後のテスト

main ブランチにマージすると、以下が自動実行されます：

1. **Backend CI**: 全ジョブ実行
2. **Backend CD - Staging**: ビルド → プッシュ → GKE Staging デプロイ

Production デプロイは手動実行のみです：

1. https://github.com/RRRRRRR-777/TokoToko/actions にアクセス
2. 「Backend CD - Production」を選択
3. 「Run workflow」ボタンをクリック
4. デプロイする Docker イメージタグを入力（例: `staging-latest`）
5. 「Run workflow」を実行
6. GitHub 環境保護ルールで承認が必要な場合は承認

---

## 🛠 トラブルシューティング

### エラー: "Workload Identity Provider not found"

**原因**: Workload Identity Provider の名前が間違っている

**解決策**:
```bash
# Provider の完全な名前を再確認
gcloud iam workload-identity-pools providers describe "github-provider" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --format="value(name)"

# GitHub Secrets の GCP_WORKLOAD_IDENTITY_PROVIDER を更新
```

### エラー: "Permission denied on Artifact Registry"

**原因**: サービスアカウントに Artifact Registry への書き込み権限がない

**解決策**:
```bash
# Staging用の権限を再付与
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:github-actions-staging@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Production用の権限を再付与
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:github-actions-production@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

### エラー: "GKE cluster not found"

**原因**: GKE クラスターが作成されていない、または名前が間違っている

**解決策**:
```bash
# クラスター一覧確認
gcloud container clusters list --region=asia-northeast1

# クラスター名が違う場合は、ワークフローの env.GKE_CLUSTER を修正
```

---

## 📚 参考資料

- [Workload Identity Federation for GitHub Actions](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-providers#github-actions)
- [GitHub Actions - Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GKE Deployment with GitHub Actions](https://cloud.google.com/kubernetes-engine/docs/tutorials/github-actions)

---

## 🔄 更新履歴

- 2025-01-18: 初版作成（Phase 4 CI/CD 構築）
