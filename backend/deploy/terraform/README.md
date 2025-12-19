# TekuToko Terraform Infrastructure

TekuTokoプロジェクトのインフラストラクチャをTerraformで管理します。

## 📁 ディレクトリ構成

```
terraform/
├── global/              # GCS Stateバケット等のグローバルリソース
├── envs/                # 環境別設定
│   ├── dev/            # 開発環境
│   ├── staging/        # ステージング環境
│   └── prod/           # 本番環境
├── modules/            # 共通モジュール
│   ├── vpc/            # VPCネットワーク
│   ├── cloud_nat/      # Cloud NAT
│   ├── firewall/       # Firewallルール
│   ├── cloud_armor/    # Cloud Armor (WAF/DDoS)
│   ├── gke/            # GKE Autopilot
│   ├── cloud_sql/      # Cloud SQL PostgreSQL
│   └── secret_manager/ # Secret Manager
├── scripts/            # ヘルパースクリプト
│   ├── init.sh        # Terraform初期化
│   └── apply.sh       # Terraform適用
├── docs/               # ドキュメント
└── README.md          # このファイル
```

## 🚀 クイックスタート

### 前提条件

1. **Terraformのインストール**
   ```bash
   brew install terraform
   # または
   # https://www.terraform.io/downloads
   ```

2. **GCP認証設定**
   ```bash
   # Application Default Credentials (ADC) を設定
   gcloud auth application-default login

   # または、サービスアカウントキーを使用
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
   ```

3. **GCPプロジェクトの準備**
   - GCPプロジェクトを作成
   - 必要なAPIを有効化（Storage API, Compute Engine API等）

### 初回セットアップ手順

#### ステップ1: GCS Stateバケットの作成

Terraformのstate管理用バケットを作成します。

```bash
# 1. global/ディレクトリに移動
cd backend/deploy/terraform/global

# 2. terraform.tfvarsを作成
cp terraform.tfvars.example terraform.tfvars

# 3. terraform.tfvarsを編集してプロジェクトIDを設定
vi terraform.tfvars
# project_id = "your-actual-gcp-project-id" に変更

# 4. Terraform初期化（ローカルstate使用）
terraform init

# 5. 変更内容を確認
terraform plan

# 6. バケットを作成
terraform apply
```

**重要**:
- この作業は**1回のみ**実行します
- 作成されたバケット名をメモしてください（例: `your-project-id-terraform-state`）

#### ステップ2: 環境設定の初期化

開発環境を例に説明します（staging/prodも同様）。

```bash
# 1. 開発環境ディレクトリに移動
cd backend/deploy/terraform/envs/dev

# 2. terraform.tfvarsを作成
cp terraform.tfvars.example terraform.tfvars

# 3. terraform.tfvarsを編集
vi terraform.tfvars
# project_id を設定

# 4. main.tf内のbackend設定を更新
vi main.tf
# backend "gcs" { bucket = "..." } の bucket を実際のバケット名に変更

# 5. ヘルパースクリプトで初期化
cd ../../  # terraform/ディレクトリに戻る
./scripts/init.sh dev
```

## 📝 使用方法

### 環境の初期化

```bash
# 開発環境
./scripts/init.sh dev

# ステージング環境
./scripts/init.sh staging

# 本番環境
./scripts/init.sh prod
```

### 変更の適用

```bash
# 開発環境（手動承認あり）
./scripts/apply.sh dev

# ステージング環境（自動承認）
./scripts/apply.sh staging --auto-approve

# 本番環境（手動承認を推奨）
./scripts/apply.sh prod
```

### 手動でのTerraform操作

```bash
# 環境ディレクトリに移動
cd envs/dev

# 初期化
terraform init

# 変更内容確認
terraform plan

# 変更適用
terraform apply

# リソース一覧表示
terraform state list

# 特定リソースの詳細表示
terraform state show <resource_name>
```

## 📦 モジュール詳細

### VPC（modules/vpc）
- **機能**: VPCネットワークとサブネット作成
- **特徴**:
  - セカンダリIP範囲（GKE Pods/Services用）
  - Flow Logs対応
  - Private Google Access有効化

### Cloud NAT（modules/cloud_nat）
- **機能**: アウトバウンド通信用NAT
- **特徴**:
  - Cloud Routerと連携
  - ポート割り当て調整可能
  - ログ出力対応

### Firewall（modules/firewall）
- **機能**: ファイアウォールルール管理
- **特徴**:
  - Pod間通信許可
  - GKE Masterアクセス制御
  - デフォルト拒否ルール（オプション）

### Cloud Armor（modules/cloud_armor）
- **機能**: Cloud Armorセキュリティポリシー（WAF/DDoS防御）
- **特徴**:
  - OWASP ModSecurity Core Rule Set対応
    - SQLインジェクション対策
    - XSS対策
    - LFI/RFI対策
    - RCE対策
    - プロトコル攻撃対策
    - スキャナー検出
  - レートリミット（DDoS防御）
  - Adaptive Protection（L7 DDoS自動防御）
  - カスタムルール対応

### GKE Autopilot（modules/gke）
- **機能**: マネージドKubernetesクラスタ
- **特徴**:
  - Private Cluster対応
  - Workload Identity有効化
  - Binary Authorization対応
  - リリースチャネル選択（RAPID/REGULAR/STABLE）
  - Prometheus監視統合

### Cloud SQL（modules/cloud_sql）
- **機能**: PostgreSQL 15データベース
- **特徴**:
  - REGIONAL HA構成
  - Point-In-Time Recovery（PITR）
  - Private IP接続
  - SSL/TLS強制（ssl_mode: ENCRYPTED_ONLY）
  - 自動バックアップ
  - PostgreSQL最適化設定

### Secret Manager（modules/secret_manager）
- **機能**: シークレット管理
- **特徴**:
  - バージョン管理
  - IAM統合

## 🔐 State管理

### リモートState設定

各環境のstateは以下のように管理されます：

| 環境 | GCSバケット | Prefix |
|------|------------|--------|
| 開発 | `<project-id>-terraform-state` | `state/dev` |
| ステージング | `<project-id>-terraform-state` | `state/staging` |
| 本番 | `<project-id>-terraform-state` | `state/prod` |

### State操作のベストプラクティス

1. **並行実行の禁止**
   - 同じ環境で複数人が同時に `terraform apply` を実行しない
   - CIパイプラインで実行を制御

2. **Stateバックアップ**
   - GCSのバージョニング機能で自動バックアップ
   - 最大5世代まで保持

3. **State操作コマンド**
   ```bash
   # Stateのリフレッシュ
   terraform refresh

   # Stateのバックアップ
   terraform state pull > backup.tfstate

   # Stateのリストア（慎重に！）
   terraform state push backup.tfstate
   ```

## 🔑 認証とアクセス制御

### 推奨IAMロール

| 用途 | ロール |
|------|--------|
| CI/CD（読み書き） | `roles/storage.objectAdmin` |
| 開発者（読み取り） | `roles/storage.objectViewer` |
| Terraform実行 | `roles/editor` または個別権限 |

### サービスアカウント設定例

```bash
# サービスアカウント作成
gcloud iam service-accounts create terraform-deployer \
  --display-name "Terraform Deployer"

# Storage権限付与
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:terraform-deployer@<PROJECT_ID>.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# キー作成
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=terraform-deployer@<PROJECT_ID>.iam.gserviceaccount.com
```

## 🛠 トラブルシューティング

### よくある問題

#### 1. State初期化エラー

```
Error: Failed to get existing workspaces
```

**解決方法**:
- GCSバケットが存在するか確認
- バケット名がmain.tfのbackend設定と一致しているか確認
- GCP認証が有効か確認（`gcloud auth list`）

#### 2. 権限エラー

```
Error: googleapi: Error 403: Forbidden
```

**解決方法**:
- サービスアカウントに適切なIAM権限があるか確認
- `gcloud auth application-default login` を再実行

#### 3. State Lock エラー

```
Error: Error acquiring the state lock
```

**解決方法**:
```bash
# Lockを強制解除（慎重に！）
terraform force-unlock <LOCK_ID>
```

## 📚 参考資料

- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [TekuToko Phase2設計書](../../docs/phase2_design.md)

