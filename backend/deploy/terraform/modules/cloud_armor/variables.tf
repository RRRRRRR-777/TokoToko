# Cloud Armorモジュールの変数定義

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "policy_name" {
  description = "セキュリティポリシー名"
  type        = string
}

variable "description" {
  description = "セキュリティポリシーの説明"
  type        = string
  default     = "Cloud Armor security policy for TekuToko"
}

# OWASP WAFルール設定
variable "enable_owasp_rules" {
  description = "OWASP ModSecurity Core Rule Setを有効化するか"
  type        = bool
  default     = true
}

variable "owasp_rule_action" {
  description = "OWASPルールのアクション（deny(403), deny(404), allow, redirect）"
  type        = string
  default     = "deny(403)"
}

# レートリミット設定
variable "enable_rate_limiting" {
  description = "レートリミットを有効化するか"
  type        = bool
  default     = false
}

variable "rate_limit_threshold_count" {
  description = "レートリミットの閾値（リクエスト数）"
  type        = number
  default     = 1000
}

variable "rate_limit_threshold_interval" {
  description = "レートリミットの閾値（インターバル秒数）"
  type        = number
  default     = 60
}

variable "rate_limit_ban_duration" {
  description = "レートリミット超過時のBAN期間（秒）"
  type        = number
  default     = 300
}

# Adaptive Protection設定
variable "enable_adaptive_protection" {
  description = "Adaptive Protection（L7 DDoS防御）を有効化するか"
  type        = bool
  default     = false
}

variable "adaptive_protection_rule_visibility" {
  description = "Adaptive Protectionのルール可視性（STANDARD, PREMIUM）"
  type        = string
  default     = "STANDARD"
}

# カスタムルール
variable "custom_rules" {
  description = "カスタムルールのリスト"
  type = list(object({
    action      = string
    priority    = number
    expression  = string
    description = string
  }))
  default = []
}
