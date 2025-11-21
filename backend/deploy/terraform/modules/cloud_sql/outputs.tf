# Cloud SQLモジュールの出力値

output "instance_name" {
  description = "Cloud SQLインスタンス名"
  value       = google_sql_database_instance.postgres.name
}

output "instance_connection_name" {
  description = "インスタンス接続名（project:region:instance形式）"
  value       = google_sql_database_instance.postgres.connection_name
}

output "private_ip_address" {
  description = "プライベートIPアドレス"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "public_ip_address" {
  description = "パブリックIPアドレス"
  value       = google_sql_database_instance.postgres.public_ip_address
  sensitive   = true
}

output "database_name" {
  description = "データベース名"
  value       = google_sql_database.database.name
}

output "db_user_name" {
  description = "データベースユーザー名"
  value       = google_sql_user.default_user.name
}
