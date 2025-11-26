# Cloud NATモジュールの変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "router_name" {
  description = "Cloud Router名"
  type        = string
}

variable "nat_name" {
  description = "Cloud NAT名"
  type        = string
}

variable "region" {
  description = "リージョン"
  type        = string
}

variable "network_self_link" {
  description = "VPC self link"
  type        = string
}

variable "environment" {
  description = "環境名（dev/staging/prod）"
  type        = string
}

variable "min_ports_per_vm" {
  description = "VM/Pod当たりの最小ポート数"
  type        = number
  default     = 128
}

variable "enable_logging" {
  description = "NATログを有効化するか"
  type        = bool
  default     = true
}
