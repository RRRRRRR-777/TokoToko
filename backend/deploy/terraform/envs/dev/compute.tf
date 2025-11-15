# 開発環境のコンピューティングリソース設定

locals {
  # GKE設定
  cluster_name           = "gke-tekutoko-${local.environment}"
  master_ipv4_cidr_block = "172.16.0.0/28"

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
  enable_private_endpoint = false # 開発環境はパブリックエンドポイント有効
  master_global_access    = true

  # Master Authorized Networks（開発者IP追加推奨）
  master_authorized_networks = [
    # {
    #   cidr_block   = "YOUR_IP/32"
    #   display_name = "Developer Workstation"
    # }
  ]

  # リリースチャネル
  release_channel = "REGULAR"

  # セキュリティ設定
  enable_binary_authorization = false # 開発環境では無効
  enable_network_policy       = true

  # ログ・モニタリング
  logging_components        = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  monitoring_components     = ["SYSTEM_COMPONENTS"]
  enable_managed_prometheus = false # コスト削減

  # 削除保護
  deletion_protection = false # 開発環境では無効
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
  db_user_password = var.db_password # Secret Managerから取得推奨

  # インスタンス設定（開発環境は小さめ）
  tier              = "db-f1-micro"
  availability_type = "ZONAL" # 開発環境はZONALでコスト削減
  disk_type         = "PD_SSD"
  disk_size         = 10
  disk_autoresize   = true

  # ネットワーク設定
  network_self_link = module.vpc.vpc_self_link
  enable_public_ip  = false # Private IPのみ
  require_ssl       = true

  # バックアップ設定（開発環境は最小限）
  enable_backup                  = true
  backup_start_time              = "03:00"
  enable_pitr                    = false # 開発環境では無効
  transaction_log_retention_days = 3
  retained_backups               = 3

  # データベースフラグ
  database_flags = [
    {
      name  = "max_connections"
      value = "100"
    }
  ]

  # その他
  enable_query_insights = false # 開発環境では無効
  deletion_protection   = false # 開発環境では無効

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

  enable_deny_all = false

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
