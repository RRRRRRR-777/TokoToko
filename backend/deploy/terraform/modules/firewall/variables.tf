# Firewallモジュールの変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "network_name" {
  description = "VPC名"
  type        = string
}

variable "environment" {
  description = "環境名（dev/staging/prod）"
  type        = string
}

variable "pods_cidr" {
  description = "Pods CIDR"
  type        = string
}

variable "gke_master_cidr" {
  description = "GKE Master CIDR（Private Cluster用）"
  type        = string
  default     = ""
}

variable "enable_deny_all" {
  description = "明示的なDeny Allルールを有効化するか"
  type        = bool
  default     = false
}

variable "cloud_sql_cidr" {
  description = "Cloud SQL Private IP CIDR（Private Service Connection用）"
  type        = string
  default     = ""
}
