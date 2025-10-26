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
  backend "gcs" {
    bucket = "your-project-id-terraform-state" # プロジェクトIDに合わせて変更
    prefix = "state/staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = {
    environment = "staging"
    managed_by  = "terraform"
    project     = "tekutoko"
  }
}
