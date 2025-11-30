# GKE Module

GKE Autopilot Private Cluster + Workload Identity構成を提供するモジュール

## 概要

このモジュールは、Google Kubernetes Engine (GKE) のAutopilotクラスタを作成します。
Private Cluster構成とWorkload Identityによるセキュアな構成になっています。

## 機能

- GKE Autopilot Clusterの作成
- Private Cluster構成（Private Nodes/Endpoint）
- VPC-Native（IP Alias）設定
- Workload Identity有効化
- Master Authorized Networks設定
- Binary Authorization対応（オプション）
- リリースチャネル選択（RAPID/REGULAR/STABLE）
- ログ・モニタリング設定
- 削除保護機能

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
| [google_container_cluster.autopilot](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_labels"></a> [additional\_labels](#input\_additional\_labels) | 追加のリソースラベル | `map(string)` | `{}` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | GKEクラスタ名 | `string` | n/a | yes |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | 削除保護を有効化するか（prodで推奨） | `bool` | `false` | no |
| <a name="input_enable_binary_authorization"></a> [enable\_binary\_authorization](#input\_enable\_binary\_authorization) | Binary Authorizationを有効化するか | `bool` | `false` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Master APIを完全プライベートにするか | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | 環境名（dev/staging/prod） | `string` | n/a | yes |
| <a name="input_logging_components"></a> [logging\_components](#input\_logging\_components) | ログ収集コンポーネント | `list(string)` | <pre>[<br>  "SYSTEM_COMPONENTS",<br>  "WORKLOADS"<br>]</pre> | no |
| <a name="input_master_authorized_networks"></a> [master\_authorized\_networks](#input\_master\_authorized\_networks) | Master APIへのアクセスを許可するCIDRリスト | <pre>list(object({<br>    cidr_block   = string<br>    display_name = string<br>  }))</pre> | `[]` | no |
| <a name="input_master_global_access"></a> [master\_global\_access](#input\_master\_global\_access) | グローバルアクセスを許可するか | `bool` | `false` | no |
| <a name="input_master_ipv4_cidr_block"></a> [master\_ipv4\_cidr\_block](#input\_master\_ipv4\_cidr\_block) | GKE Master CIDR（/28推奨） | `string` | n/a | yes |
| <a name="input_monitoring_components"></a> [monitoring\_components](#input\_monitoring\_components) | モニタリング収集コンポーネント | `list(string)` | <pre>[<br>  "SYSTEM_COMPONENTS"<br>]</pre> | no |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | VPC self link | `string` | n/a | yes |
| <a name="input_pods_range_name"></a> [pods\_range\_name](#input\_pods\_range\_name) | Pods用 Secondary Range名 | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCPプロジェクトID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | リージョン | `string` | n/a | yes |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | リリースチャネル（RAPID/REGULAR/STABLE） | `string` | `"REGULAR"` | no |
| <a name="input_services_range_name"></a> [services\_range\_name](#input\_services\_range\_name) | Services用 Secondary Range名 | `string` | n/a | yes |
| <a name="input_subnet_self_link"></a> [subnet\_self\_link](#input\_subnet\_self\_link) | サブネット self link | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | クラスタCA証明書 |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | クラスタAPIエンドポイント |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | クラスタID |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | クラスタ名 |
| <a name="output_master_ipv4_cidr_block"></a> [master\_ipv4\_cidr\_block](#output\_master\_ipv4\_cidr\_block) | Master CIDR |
| <a name="output_workload_identity_pool"></a> [workload\_identity\_pool](#output\_workload\_identity\_pool) | Workload Identityプール |
<!-- END_TF_DOCS -->
