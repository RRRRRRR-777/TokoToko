# 開発環境のネットワーク設定

locals {
  environment = "dev"
  region      = var.region

  # CIDR設計（docs/networking.md参照）
  primary_cidr  = "10.0.0.0/20" # 4,096 IPs
  pods_cidr     = "10.4.0.0/17" # 32,768 IPs
  services_cidr = "10.8.0.0/22" # 1,024 IPs

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

  # 開発環境ではFlow Logsを無効化（コスト削減）
  enable_flow_logs = false
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
# GKE Master CIDRを含む完全なFirewall設定
module "firewall" {
  source = "../../modules/firewall"

  project_id   = var.project_id
  network_name = module.vpc.vpc_name
  environment  = local.environment
  pods_cidr    = local.pods_cidr

  # GKE Master CIDR（compute.tfのlocalと同じ値）
  gke_master_cidr = "172.16.0.0/28"

  # 開発環境ではdeny allを無効化（デバッグ容易性）
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
