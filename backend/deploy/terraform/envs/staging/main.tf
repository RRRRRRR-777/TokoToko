# TekuTokoステージング環境のTerraform設定

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
  backend "gcs" {
    bucket = "tokotoko-terraform-state"
    prefix = "state/staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # デフォルトラベル（全リソースに自動付与）
  default_labels = {
    environment = "staging"
    managed_by  = "terraform"
    project     = "tekutoko"
  }
}
