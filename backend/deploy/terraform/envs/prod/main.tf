# TekuToko本番環境のTerraform設定

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
    bucket = "tokotoko-terraform-state"
    prefix = "state/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = {
    environment = "prod"
    managed_by  = "terraform"
    project     = "tekutoko"
  }
}
