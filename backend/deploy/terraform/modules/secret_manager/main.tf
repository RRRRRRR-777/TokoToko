# Secret Managerモジュール
# 環境ごとのシークレット管理

resource "google_secret_manager_secret" "secret" {
  secret_id = var.secret_id
  project   = var.project_id

  labels = {
    environment = var.environment
    app         = var.app_name
    managed_by  = "terraform"
  }

  # レプリケーション設定
  replication {
    dynamic "auto" {
      for_each = var.replication_type == "auto" ? [1] : []
      content {}
    }

    dynamic "user_managed" {
      for_each = var.replication_type == "user_managed" ? [1] : []
      content {
        dynamic "replicas" {
          for_each = var.replication_locations
          content {
            location = replicas.value
          }
        }
      }
    }
  }

  # TTL設定（dev/staging用）
  dynamic "ttl" {
    for_each = var.ttl_seconds > 0 ? [1] : []
    content {
      seconds = var.ttl_seconds
    }
  }

  # ローテーション設定（prodで推奨）
  dynamic "rotation" {
    for_each = var.rotation_period != null ? [1] : []
    content {
      next_rotation_time = timeadd(timestamp(), var.rotation_period)
      rotation_period    = var.rotation_period
    }
  }
}

# シークレットバージョン（初期値）
resource "google_secret_manager_secret_version" "version" {
  count = var.create_initial_version ? 1 : 0

  secret      = google_secret_manager_secret.secret.id
  secret_data = var.initial_value

  enabled = true
}

# IAMバインディング（Service Account用）
resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = toset(var.accessor_service_accounts)

  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value}"
  project   = var.project_id
}
