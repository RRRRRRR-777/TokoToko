# 本番環境のコンピューティングリソース設定

locals {
  # GKE設定
  cluster_name           = "gke-tekutoko-${local.environment}"
  master_ipv4_cidr_block = "172.18.0.0/28"

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
  enable_private_endpoint = false # Cloud Shell/踏み台からアクセス可能にする
  master_global_access    = true

  # Master Authorized Networks（必要に応じて設定）
  master_authorized_networks = [
    # {
    #   cidr_block   = "YOUR_OFFICE_IP/32"
    #   display_name = "Office Network"
    # }
  ]

  # リリースチャネル
  release_channel = "STABLE"

  # セキュリティ設定
  enable_binary_authorization = true # 本番環境では有効化推奨
  enable_network_policy       = true

  # ログ・モニタリング
  logging_components        = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  monitoring_components     = ["SYSTEM_COMPONENTS"]
  enable_managed_prometheus = true

  # 削除保護
  deletion_protection = true # 本番環境では有効化
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
  db_user_password = var.db_password # Secret Managerから取得必須

  # インスタンス設定（本番環境は高スペック）
  tier              = "db-custom-4-15360" # 4 vCPU, 15GB RAM
  availability_type = "REGIONAL"          # HA構成（必須）
  disk_type         = "PD_SSD"
  disk_size         = 50
  disk_autoresize   = true

  # ネットワーク設定
  network_self_link = module.vpc.vpc_self_link
  enable_public_ip  = false # Private IPのみ
  ssl_mode          = "ENCRYPTED_ONLY"

  # バックアップ設定（本番環境は最大限の保護）
  enable_backup                  = true
  backup_start_time              = "03:00"
  enable_pitr                    = true # Point-In-Time Recovery必須
  transaction_log_retention_days = 14   # 14日間保持
  retained_backups               = 14   # 14世代保持

  # メンテナンスウィンドウ
  maintenance_window = {
    day          = 7  # 日曜日
    hour         = 15 # UTC 15:00 = JST 00:00（月曜深夜）
    update_track = "stable"
  }

  # データベースフラグ
  database_flags = [
    {
      name  = "max_connections"
      value = "500"
    },
    {
      name  = "shared_buffers"
      value = "3932160" # 3840MB (RAM 15GB の 25%)
    },
    {
      name  = "effective_cache_size"
      value = "11796480" # 11520MB (RAM 15GB の 75%)
    },
    {
      name  = "work_mem"
      value = "10240" # 10MB
    }
  ]

  # その他
  enable_query_insights = true
  deletion_protection   = true # 本番環境では有効化

  depends_on = [module.vpc]
}

# Firewallルールを更新（GKE Master CIDR追加）
module "firewall_gke_update" {
  source = "../../modules/firewall"

  project_id   = var.project_id
  network_name = module.vpc.vpc_name
  environment  = local.environment
  pods_cidr    = local.pods_cidr

  # GKE Master CIDR設定
  gke_master_cidr = local.master_ipv4_cidr_block

  enable_deny_all = true

  depends_on = [module.gke]
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
