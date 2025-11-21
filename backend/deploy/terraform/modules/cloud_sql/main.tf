# Cloud SQLモジュール
# PostgreSQL Regional HA構成

resource "google_sql_database_instance" "postgres" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize

    # Private IP設定
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.network_self_link
      ssl_mode        = var.ssl_mode

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # バックアップ設定
    backup_configuration {
      enabled                        = var.enable_backup
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.enable_pitr
      transaction_log_retention_days = var.transaction_log_retention_days
      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # メンテナンスウィンドウ
    dynamic "maintenance_window" {
      for_each = var.maintenance_window != null ? [1] : []
      content {
        day          = var.maintenance_window.day
        hour         = var.maintenance_window.hour
        update_track = var.maintenance_window.update_track
      }
    }

    # データベースフラグ
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # インサイト設定
    insights_config {
      query_insights_enabled  = var.enable_query_insights
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
    }

    user_labels = merge(
      {
        environment = var.environment
        managed_by  = "terraform"
      },
      var.additional_labels
    )
  }

  # 削除保護
  deletion_protection = var.deletion_protection

  # 依存関係（Private Service Connection）
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# データベース作成
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
}

# デフォルトユーザー（パスワードはSecret Managerで管理）
resource "google_sql_user" "default_user" {
  name     = var.db_user_name
  instance = google_sql_database_instance.postgres.name
  password = var.db_user_password
  project  = var.project_id
}
