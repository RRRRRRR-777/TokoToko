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

variable "terraform_state_bucket" {
  description = "Terraform状態ファイルを保存するGCSバケット名"
  type        = string
  default     = "tokotoko-terraform-state"
}

variable "environment" {
  description = "環境名（dev/staging/production）"
  type        = string
  default     = "production"
}
