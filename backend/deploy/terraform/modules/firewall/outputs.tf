# Firewallモジュールの出力値

output "firewall_rule_names" {
  description = "作成されたファイアウォールルール名のリスト"
  value = [
    google_compute_firewall.allow_gke_control_plane.name,
    google_compute_firewall.allow_internal_pods.name,
    google_compute_firewall.allow_health_checks.name,
    google_compute_firewall.allow_iap_ssh.name,
  ]
}
