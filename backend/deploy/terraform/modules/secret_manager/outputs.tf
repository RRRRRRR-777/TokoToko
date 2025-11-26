# Secret Managerモジュールの出力値

output "secret_id" {
  description = "Secret ID"
  value       = google_secret_manager_secret.secret.secret_id
}

output "secret_name" {
  description = "Secret名（フルパス）"
  value       = google_secret_manager_secret.secret.name
}
