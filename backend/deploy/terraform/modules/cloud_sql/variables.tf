# Cloud SQLモジュールの変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "instance_name" {
  description = "Cloud SQLインスタンス名"
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

# データベース設定
variable "database_version" {
  description = "PostgreSQLバージョン"
  type        = string
  default     = "POSTGRES_15"
}

variable "database_name" {
  description = "作成するデータベース名"
  type        = string
}

variable "db_user_name" {
  description = "データベースユーザー名"
  type        = string
}

variable "db_user_password" {
  description = "データベースパスワード（Secret Managerから取得推奨）"
  type        = string
  sensitive   = true
}

# インスタンス設定
variable "tier" {
  description = "マシンタイプ（例: db-f1-micro, db-custom-2-7680）"
  type        = string
}

variable "availability_type" {
  description = "可用性タイプ（ZONAL or REGIONAL）"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be ZONAL or REGIONAL"
  }
}

variable "disk_type" {
  description = "ディスクタイプ（PD_SSD or PD_HDD）"
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "ディスクサイズ（GB）"
  type        = number
  default     = 10
}

variable "disk_autoresize" {
  description = "ディスク自動拡張を有効化するか"
  type        = bool
  default     = true
}

# ネットワーク設定
variable "network_self_link" {
  description = "VPC self link"
  type        = string
}

variable "enable_public_ip" {
  description = "パブリックIPを有効化するか"
  type        = bool
  default     = false
}

variable "require_ssl" {
  description = "SSL接続を必須にするか"
  type        = bool
  default     = true
}

variable "authorized_networks" {
  description = "パブリックIP接続時の許可ネットワーク"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# バックアップ設定
variable "enable_backup" {
  description = "自動バックアップを有効化するか"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "バックアップ開始時刻（HH:MM形式、UTC）"
  type        = string
  default     = "03:00"
}

variable "enable_pitr" {
  description = "ポイントインタイムリカバリを有効化するか"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "トランザクションログ保持日数"
  type        = number
  default     = 7
}

variable "retained_backups" {
  description = "保持するバックアップ数"
  type        = number
  default     = 7
}

# メンテナンスウィンドウ
variable "maintenance_window" {
  description = "メンテナンスウィンドウ設定"
  type = object({
    day          = number
    hour         = number
    update_track = string
  })
  default = null
}

# データベースフラグ
variable "database_flags" {
  description = "データベースフラグ"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# その他
variable "enable_query_insights" {
  description = "Query Insightsを有効化するか"
  type        = bool
  default     = false
}

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
