# GKEモジュールの出力値

output "cluster_id" {
  description = "クラスタID"
  value       = google_container_cluster.autopilot.id
}

output "cluster_name" {
  description = "クラスタ名"
  value       = google_container_cluster.autopilot.name
}

output "cluster_endpoint" {
  description = "クラスタAPIエンドポイント"
  value       = google_container_cluster.autopilot.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "クラスタCA証明書"
  value       = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identityプール"
  value       = "${var.project_id}.svc.id.goog"
}

output "master_ipv4_cidr_block" {
  description = "Master CIDR"
  value       = google_container_cluster.autopilot.private_cluster_config[0].master_ipv4_cidr_block
}
