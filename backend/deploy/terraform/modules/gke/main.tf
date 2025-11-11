# GKE Autopilotモジュール
# Private Cluster + Workload Identity構成

resource "google_container_cluster" "autopilot" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  # Autopilot有効化
  enable_autopilot = true

  # リリースチャネル（REGULAR推奨）
  release_channel {
    channel = var.release_channel
  }

  # ネットワーク設定
  network    = var.network_self_link
  subnetwork = var.subnet_self_link

  # VPC-Native（IP Alias）設定
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private Cluster設定
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = var.master_global_access
    }
  }

  # Master Authorized Networks（管理元IPアドレス制限）
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload Identity有効化
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Binary Authorization（セキュリティ強化）
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # メンテナンスウィンドウ
  maintenance_policy {
    dynamic "recurring_window" {
      for_each = var.maintenance_window != null ? [1] : []
      content {
        start_time = var.maintenance_window.start_time
        end_time   = var.maintenance_window.end_time
        recurrence = var.maintenance_window.recurrence
      }
    }
  }

  # Autopilotは自動でaddons管理するため設定不要
  # ただしNetwork Policyは明示的に有効化可能
  network_policy {
    enabled = var.enable_network_policy
  }

  # ログ設定
  logging_config {
    enable_components = var.logging_components
  }

  monitoring_config {
    enable_components = var.monitoring_components
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # リソースラベル
  resource_labels = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
      cluster     = var.cluster_name
    },
    var.additional_labels
  )

  description = "GKE Autopilot cluster for ${var.environment} environment"

  # 削除保護（prodでは有効化推奨）
  deletion_protection = var.deletion_protection
}
