# 本番環境の変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "region" {
  description = "デフォルトリージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "デフォルトゾーン"
  type        = string
  default     = "asia-northeast1-a"
}

variable "db_password" {
  description = "Cloud SQLデータベースパスワード"
  type        = string
  sensitive   = true
}
