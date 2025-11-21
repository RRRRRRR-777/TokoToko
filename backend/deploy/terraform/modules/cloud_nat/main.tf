# Cloud NATモジュール
# Private ClusterからのEgress用NAT

resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = var.network_self_link
  project = var.project_id

  description = "Cloud Router for ${var.environment} environment"
}

resource "google_compute_router_nat" "nat" {
  name    = var.nat_name
  region  = var.region
  router  = google_compute_router.router.name
  project = var.project_id

  # NATアドレス設定（自動割り当て）
  nat_ip_allocate_option = "AUTO_ONLY"

  # 全サブネットのPrimary + Secondaryレンジに適用
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # ポート設定（Autopilot Pod密度対応）
  min_ports_per_vm = var.min_ports_per_vm

  # Endpoint Independent Mapping有効化
  enable_endpoint_independent_mapping = true

  # ログ設定
  log_config {
    enable = var.enable_logging
    filter = "ALL"
  }

  # TCP確立接続のタイムアウト設定
  tcp_established_idle_timeout_sec = 1200 # 20分
  tcp_transitory_idle_timeout_sec  = 30   # 30秒
  udp_idle_timeout_sec             = 60   # 60秒
}
