# Cloud Armorモジュールの出力値

output "policy_name" {
  description = "作成されたセキュリティポリシー名"
  value       = google_compute_security_policy.policy.name
}

output "policy_self_link" {
  description = "セキュリティポリシーのself_link"
  value       = google_compute_security_policy.policy.self_link
}

output "policy_id" {
  description = "セキュリティポリシーのID"
  value       = google_compute_security_policy.policy.id
}
