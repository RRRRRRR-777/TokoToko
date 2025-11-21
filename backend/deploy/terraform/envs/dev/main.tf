# TekuToko開発環境のTerraform設定

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # リモートバックエンド設定（GCS）
  # 初回実行前に global/ でstateバケットを作成する必要があります
  # 注: backendブロックでは変数を使用できないため、terraform initで-backend-configを使用
  backend "gcs" {
    # bucket = var.terraform_state_bucket  # 変数は使用不可
    # prefix = "state/${var.environment}"   # 変数は使用不可
    # 代わりに terraform init -backend-config="bucket=BUCKET_NAME" を使用
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # デフォルトラベル（全リソースに自動付与）
  default_labels = {
    environment = "dev"
    managed_by  = "terraform"
    project     = "tekutoko"
  }
}

# 将来的にここにGKE, Cloud SQL等のリソースを定義
# 現在はプロジェクト基盤のみ
