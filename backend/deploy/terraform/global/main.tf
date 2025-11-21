# Terraform State管理用のGCSバケット作成
# このファイルは初回のみローカルstateで実行し、その後リモートstateに移行する

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Terraform State保存用GCSバケット
resource "google_storage_bucket" "terraform_state" {
  name     = "${var.project_id}-terraform-state"
  location = var.region

  # バージョニング有効化（誤削除・上書き防止）
  versioning {
    enabled = true
  }

  # 均一なバケットレベルアクセス制御
  uniform_bucket_level_access {
    enabled = true
  }

  # ライフサイクル管理（古いバージョンの自動削除）
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  # 暗号化設定（Google管理キー使用）
  encryption {
    default_kms_key_name = null
  }

  # パブリックアクセス防止
  public_access_prevention = "enforced"

  labels = {
    environment = "global"
    managed_by  = "terraform"
    purpose     = "terraform-state"
  }
}

# 出力値
output "state_bucket_name" {
  description = "Terraform State保存用バケット名"
  value       = google_storage_bucket.terraform_state.name
}

output "state_bucket_url" {
  description = "Terraform State保存用バケットURL"
  value       = google_storage_bucket.terraform_state.url
}
