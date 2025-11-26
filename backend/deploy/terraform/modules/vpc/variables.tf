# VPCモジュールの変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "vpc_name" {
  description = "VPC名"
  type        = string
}

variable "subnet_name" {
  description = "サブネット名"
  type        = string
}

variable "region" {
  description = "リージョン"
  type        = string
}

variable "environment" {
  description = "環境名（dev/staging/prod）"
  type        = string
}

variable "primary_cidr" {
  description = "Primary CIDR（ノード用）"
  type        = string
}

variable "pods_cidr" {
  description = "Pods用 Secondary CIDR"
  type        = string
}

variable "services_cidr" {
  description = "Services用 Secondary CIDR"
  type        = string
}

variable "pods_range_name" {
  description = "Pods用 Secondary Range名"
  type        = string
}

variable "services_range_name" {
  description = "Services用 Secondary Range名"
  type        = string
}

variable "enable_flow_logs" {
  description = "VPC Flow Logsを有効化するか"
  type        = bool
  default     = false
}
