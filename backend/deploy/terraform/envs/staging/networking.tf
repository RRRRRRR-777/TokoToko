# ステージング環境のネットワーク設定

locals {
  environment = "staging"
  region      = var.region

  # CIDR設計（docs/networking.md参照）
  primary_cidr  = "10.16.0.0/20" # 4,096 IPs
  pods_cidr     = "10.20.0.0/17" # 32,768 IPs
  services_cidr = "10.24.0.0/22" # 1,024 IPs

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

  min_ports_per_vm = 128
  enable_logging   = true
}

# Firewall Rules作成
module "firewall" {
  source = "../../modules/firewall"

  project_id   = var.project_id
  network_name = module.vpc.vpc_name
  environment  = local.environment
  pods_cidr    = local.pods_cidr

  # GKE Master CIDRは将来GKE作成後に設定
  gke_master_cidr = ""

  enable_deny_all = false
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
