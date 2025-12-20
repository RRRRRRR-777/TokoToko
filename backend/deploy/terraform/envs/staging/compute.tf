# ステージング環境のコンピューティングリソース設定

locals {
  # GKE設定
  cluster_name           = "gke-tekutoko-${local.environment}"
  master_ipv4_cidr_block = "172.17.0.0/28"

  # Cloud SQL設定
  sql_instance_name = "tekutoko-${local.environment}-db"
  database_name     = "tekutoko_${local.environment}"
  db_user_name      = "tekutoko"
}

# GKE Autopilotクラスタ
module "gke" {
  source = "../../modules/gke"

  project_id   = var.project_id
  cluster_name = local.cluster_name
  region       = local.region
  environment  = local.environment

  # ネットワーク設定
  network_self_link      = module.vpc.vpc_self_link
  subnet_self_link       = module.vpc.subnet_self_link
  pods_range_name        = module.vpc.pods_range_name
  services_range_name    = module.vpc.services_range_name
  master_ipv4_cidr_block = local.master_ipv4_cidr_block

  # Private Cluster設定
  enable_private_endpoint = false # ステージング環境はパブリックエンドポイント有効
  master_global_access    = true

  # リリースチャネル
  release_channel = "REGULAR"

  # セキュリティ設定
  enable_binary_authorization = false # ステージング環境では無効

  # ログ・モニタリング
  logging_components    = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  monitoring_components = ["SYSTEM_COMPONENTS"]

  # 削除保護
  deletion_protection = false # ステージング環境では無効
}

# Cloud SQL（PostgreSQL）
module "cloud_sql" {
  source = "../../modules/cloud_sql"

  project_id    = var.project_id
  instance_name = local.sql_instance_name
  region        = local.region
  environment   = local.environment

  # データベース設定
  database_version = "POSTGRES_15"
  database_name    = local.database_name
  db_user_name     = local.db_user_name
  db_user_password = data.google_secret_manager_secret_version.db_password.secret_data

  # インスタンス設定（ステージング環境は本番に近いスペック）
  tier              = "db-custom-2-7680" # 2 vCPU, 7.5GB RAM
  availability_type = "REGIONAL"         # ステージング環境はREGIONAL（HA）
  disk_type         = "PD_SSD"
  disk_size         = 20
  disk_autoresize   = true

  # ネットワーク設定
  network_self_link = module.vpc.vpc_self_link
  enable_public_ip  = false # Private IPのみ
  ssl_mode          = "ENCRYPTED_ONLY"

  # バックアップ設定（本番に近い設定）
  enable_backup                  = true
  backup_start_time              = "03:00"
  enable_pitr                    = true # ステージング環境では有効
  transaction_log_retention_days = 7
  retained_backups               = 7

  # メンテナンスウィンドウ
  maintenance_window = {
    day          = 7  # 日曜日
    hour         = 15 # UTC 15:00 = JST 00:00（月曜深夜）
    update_track = "stable"
  }

  # データベースフラグ（7.5GB RAM に適した設定）
  database_flags = [
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "shared_buffers"
      value = "491520" # 480MB (RAM 7.5GB の約6.25%)
    },
    {
      name  = "effective_cache_size"
      value = "655360" # 640MB (許容最大値 672MB の約93%)
    },
    {
      name  = "work_mem"
      value = "10240" # 10MB
    }
  ]

  # その他
  enable_query_insights = true  # ステージング環境では有効
  deletion_protection   = false # ステージング環境では無効

  depends_on = [module.vpc]
}

# 出力値
output "gke_cluster_name" {
  description = "GKEクラスタ名"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKEクラスタエンドポイント"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cloud_sql_instance_name" {
  description = "Cloud SQLインスタンス名"
  value       = module.cloud_sql.instance_name
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL プライベートIP"
  value       = module.cloud_sql.private_ip_address
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL 接続名"
  value       = module.cloud_sql.instance_connection_name
}
