# Firewallモジュール
# GKE Autopilot用のファイアウォールルール

# GKE Control Plane → Nodes通信許可
resource "google_compute_firewall" "allow_gke_control_plane" {
  name    = "${var.environment}-allow-gke-control-plane"
  network = var.network_name
  project = var.project_id

  priority  = 1000
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }

  # GKE Master CIDRからの通信を許可（実際のCIDRは環境ごとに設定）
  source_ranges = var.gke_master_cidr != "" ? [var.gke_master_cidr] : []
  target_tags   = ["gke-nodes"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow GKE control plane to nodes communication"
}

# Pod間通信許可
resource "google_compute_firewall" "allow_internal_pods" {
  name    = "${var.environment}-allow-internal-pods"
  network = var.network_name
  project = var.project_id

  priority  = 1100
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.pods_cidr]
  target_tags   = ["gke-pods", "gke-nodes"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow internal pod-to-pod communication"
}

# GCP Health Checks許可
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.environment}-allow-health-checks"
  network = var.network_name
  project = var.project_id

  priority  = 1200
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  # GCP Health Checkソースレンジ
  source_ranges = [
    "35.191.0.0/16",  # Global HTTP(S) LB
    "130.211.0.0/22", # Legacy HTTP(S) LB
  ]

  target_tags = ["gke-nodes"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow GCP health checks"
}

# IAP経由SSH許可（管理用）
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.environment}-allow-iap-ssh"
  network = var.network_name
  project = var.project_id

  priority  = 2000
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP forwardingソースレンジ
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow SSH via Identity-Aware Proxy"
}

# Cloud SQL Private IP接続許可（EGRESS）
resource "google_compute_firewall" "allow_cloudsql_egress" {
  count = var.cloud_sql_cidr != "" ? 1 : 0

  name    = "${var.environment}-allow-cloudsql-egress"
  network = var.network_name
  project = var.project_id

  priority  = 1000
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3307", "5432"]
  }

  destination_ranges = [var.cloud_sql_cidr]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Allow GKE pods to connect to Cloud SQL via private IP"
}

# 明示的なDeny All（最低優先度）
resource "google_compute_firewall" "deny_all" {
  count = var.enable_deny_all ? 1 : 0

  name    = "${var.environment}-deny-all"
  network = var.network_name
  project = var.project_id

  priority  = 65534
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  description = "Explicit deny all traffic (lowest priority)"
}
