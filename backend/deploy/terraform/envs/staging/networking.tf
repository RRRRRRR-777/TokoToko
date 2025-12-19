# ステージング環境のネットワーク設定

locals {
  environment = "staging"
  region      = var.region

  # CIDR設計（docs/networking.md参照）
  primary_cidr  = "10.1.0.0/20" # 4,096 IPs
  pods_cidr     = "10.5.0.0/17" # 32,768 IPs
  services_cidr = "10.9.0.0/22" # 1,024 IPs

  # 命名規約
  vpc_name            = "vpc-tekutoko-${local.environment}"
  subnet_name         = "subnet-${local.region}-${local.environment}-primary"
  pods_range_name     = "range-${local.environment}-pods"
  services_range_name = "range-${local.environment}-svc"
  router_name         = "router-${local.region}-${local.environment}"
  nat_name            = "nat-${local.region}-${local.environment}"
}

# VPC作成
module "vpc" {
  source = "../../modules/vpc"

  project_id  = var.project_id
  vpc_name    = local.vpc_name
  subnet_name = local.subnet_name
  region      = local.region
  environment = local.environment

  primary_cidr        = local.primary_cidr
  pods_cidr           = local.pods_cidr
  services_cidr       = local.services_cidr
  pods_range_name     = local.pods_range_name
  services_range_name = local.services_range_name

  # ステージング環境ではFlow Logsを有効化
  enable_flow_logs = true
}

# Cloud NAT作成
module "cloud_nat" {
  source = "../../modules/cloud_nat"

  project_id        = var.project_id
  router_name       = local.router_name
  nat_name          = local.nat_name
  region            = local.region
  network_self_link = module.vpc.vpc_self_link
  environment       = local.environment

  min_ports_per_vm = 256
  enable_logging   = true
}

# Firewall Rules作成
module "firewall" {
  source = "../../modules/firewall"

  project_id   = var.project_id
  network_name = module.vpc.vpc_name
  environment  = local.environment
  pods_cidr    = local.pods_cidr

  # GKE Master CIDR（compute.tfのlocalと同じ値）
  gke_master_cidr = "172.17.0.0/28"

  # Cloud SQL Private IP CIDR（Private Service Connection用）
  cloud_sql_cidr = "10.219.0.0/24"

  # ステージング環境では本番同様にdeny allを有効化
  enable_deny_all = true
}

# Cloud Armor Security Policy作成
module "cloud_armor" {
  source = "../../modules/cloud_armor"

  project_id  = var.project_id
  policy_name = "tekutoko-security-policy"
  description = "Cloud Armor security policy for TekuToko API (Staging)"

  # OWASP WAFルールを有効化
  enable_owasp_rules = true
  owasp_rule_action  = "deny(403)"

  # ステージング環境ではレートリミットを有効化（テスト用）
  enable_rate_limiting          = true
  rate_limit_threshold_count    = 1000  # 1000リクエスト
  rate_limit_threshold_interval = 60    # 60秒間
  rate_limit_ban_duration       = 300   # 5分間BAN

  # Adaptive Protection（L7 DDoS防御）を有効化
  enable_adaptive_protection          = true
  adaptive_protection_rule_visibility = "STANDARD"
}

# API用静的外部IP
resource "google_compute_address" "tekutoko_api" {
  name         = "tekutoko-api-${local.environment}-ip"
  project      = var.project_id
  region       = local.region
  address_type = "EXTERNAL"
  description  = "TekuToko API ${local.environment}環境用の静的外部IP"
}

# 出力値
output "vpc_name" {
  description = "VPC名"
  value       = module.vpc.vpc_name
}

output "subnet_name" {
  description = "サブネット名"
  value       = module.vpc.subnet_name
}

output "pods_range_name" {
  description = "Pods Secondary Range名"
  value       = module.vpc.pods_range_name
}

output "services_range_name" {
  description = "Services Secondary Range名"
  value       = module.vpc.services_range_name
}

output "api_static_ip" {
  description = "TekuToko API用の静的外部IP"
  value       = google_compute_address.tekutoko_api.address
}

output "cloud_armor_policy_name" {
  description = "Cloud Armorセキュリティポリシー名"
  value       = module.cloud_armor.policy_name
}
