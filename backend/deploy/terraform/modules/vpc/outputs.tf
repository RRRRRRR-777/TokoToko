# VPCモジュールの出力値

output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC名"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "VPC self link"
  value       = google_compute_network.vpc.self_link
}

output "subnet_id" {
  description = "サブネットID"
  value       = google_compute_subnetwork.primary.id
}

output "subnet_name" {
  description = "サブネット名"
  value       = google_compute_subnetwork.primary.name
}

output "subnet_self_link" {
  description = "サブネット self link"
  value       = google_compute_subnetwork.primary.self_link
}

output "pods_range_name" {
  description = "Pods用 Secondary Range名"
  value       = var.pods_range_name
}

output "services_range_name" {
  description = "Services用 Secondary Range名"
  value       = var.services_range_name
}
