# GKEモジュールの変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "cluster_name" {
  description = "GKEクラスタ名"
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

# ネットワーク設定
variable "network_self_link" {
  description = "VPC self link"
  type        = string
}

variable "subnet_self_link" {
  description = "サブネット self link"
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

# Private Cluster設定
variable "master_ipv4_cidr_block" {
  description = "GKE Master CIDR（/28推奨）"
  type        = string
}

variable "enable_private_endpoint" {
  description = "Master APIを完全プライベートにするか"
  type        = bool
  default     = false
}

variable "master_global_access" {
  description = "グローバルアクセスを許可するか"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "Master APIへのアクセスを許可するCIDRリスト"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

# リリースチャネル
variable "release_channel" {
  description = "リリースチャネル（RAPID/REGULAR/STABLE）"
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, or STABLE"
  }
}

# セキュリティ設定
variable "enable_binary_authorization" {
  description = "Binary Authorizationを有効化するか"
  type        = bool
  default     = false
}

# ログ・モニタリング
variable "logging_components" {
  description = "ログ収集コンポーネント"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_components" {
  description = "モニタリング収集コンポーネント"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_managed_prometheus" {
  description = "Managed Prometheusを有効化するか"
  type        = bool
  default     = false
}

# その他
variable "additional_labels" {
  description = "追加のリソースラベル"
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "削除保護を有効化するか（prodで推奨）"
  type        = bool
  default     = false
}
