# Secret Managerモジュールの変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "secret_id" {
  description = "Secret ID（例: sm-dev-api-db-password）"
  type        = string
}

variable "environment" {
  description = "環境名（dev/staging/prod）"
  type        = string
}

variable "app_name" {
  description = "アプリケーション名"
  type        = string
  default     = "tekutoko"
}

variable "replication_type" {
  description = "レプリケーションタイプ（auto or user_managed）"
  type        = string
  default     = "auto"

  validation {
    condition     = contains(["auto", "user_managed"], var.replication_type)
    error_message = "replication_type must be 'auto' or 'user_managed'"
  }
}

variable "replication_locations" {
  description = "user_managed時のレプリケーションロケーションリスト"
  type        = list(string)
  default     = []
}

variable "ttl_seconds" {
  description = "シークレットのTTL（秒）。0の場合は無期限"
  type        = number
  default     = 0
}

variable "rotation_period" {
  description = "ローテーション期間（例: 7776000s = 90日）"
  type        = string
  default     = null
}

variable "create_initial_version" {
  description = "初期バージョンを作成するか"
  type        = bool
  default     = false
}

variable "initial_value" {
  description = "初期シークレット値（create_initial_version=trueの場合）"
  type        = string
  default     = ""
  sensitive   = true
}

variable "accessor_service_accounts" {
  description = "アクセス権を付与するService Accountのリスト"
  type        = list(string)
  default     = []
}
