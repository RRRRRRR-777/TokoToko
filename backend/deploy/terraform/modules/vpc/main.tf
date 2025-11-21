# VPCモジュール
# GKE Autopilot用のVPC-Native構成

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id

  description = "VPC for ${var.environment} environment"
}

resource "google_compute_subnetwork" "primary" {
  name          = var.subnet_name
  ip_cidr_range = var.primary_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  # Private Google Access有効化（Cloud APIへの内部通信）
  private_ip_google_access = true

  # VPC Flow Logs（staging/prod推奨）
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }

  # Secondary IP ranges for GKE
  secondary_ip_range {
    range_name    = var.pods_range_name
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = var.services_range_name
    ip_cidr_range = var.services_cidr
  }

  description = "Primary subnet for ${var.environment} environment"
}
