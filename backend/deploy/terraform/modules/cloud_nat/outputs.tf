# Cloud NATモジュールの出力値

output "router_id" {
  description = "Cloud Router ID"
  value       = google_compute_router.router.id
}

output "router_name" {
  description = "Cloud Router名"
  value       = google_compute_router.router.name
}

output "nat_id" {
  description = "Cloud NAT ID"
  value       = google_compute_router_nat.nat.id
}

output "nat_name" {
  description = "Cloud NAT名"
  value       = google_compute_router_nat.nat.name
}
