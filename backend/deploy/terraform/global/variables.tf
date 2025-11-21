# Terraform State管理用のGCSバケット作成に必要な変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "region" {
  description = "GCSバケットのリージョン（例: asia-northeast1）"
  type        = string
  default     = "asia-northeast1"
}
