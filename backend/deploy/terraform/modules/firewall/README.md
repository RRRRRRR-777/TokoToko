# Firewall Module

GKE Autopilot用のファイアウォールルール構成を提供するモジュール

## 概要

このモジュールは、Google Cloud PlatformのVPCファイアウォールルールを作成します。
GKEクラスタに必要な通信を許可する設定が含まれています。

## 機能

- GKE Control Plane → Nodes通信許可（443, 10250）
- Pod間内部通信許可（TCP/UDP/ICMP）
- GCP Health Checks許可（80, 443, 8080）
- IAP経由SSH許可（管理用）
- 明示的なDeny Allルール（オプション）
- 全ルールでログ記録を有効化

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.allow_gke_control_plane](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_health_checks](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_iap_ssh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_internal_pods](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.deny_all](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_deny_all"></a> [enable\_deny\_all](#input\_enable\_deny\_all) | 明示的なDeny Allルールを有効化するか | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | 環境名（dev/staging/prod） | `string` | n/a | yes |
| <a name="input_gke_master_cidr"></a> [gke\_master\_cidr](#input\_gke\_master\_cidr) | GKE Master CIDR（Private Cluster用） | `string` | `""` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | VPC名 | `string` | n/a | yes |
| <a name="input_pods_cidr"></a> [pods\_cidr](#input\_pods\_cidr) | Pods CIDR | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCPプロジェクトID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall_rule_names"></a> [firewall\_rule\_names](#output\_firewall\_rule\_names) | 作成されたファイアウォールルール名のリスト |
<!-- END_TF_DOCS -->
