# Cloud NAT Module

Private ClusterからのEgress用NAT構成を提供するモジュール

## 概要

このモジュールは、Google Cloud PlatformのCloud RouterとCloud NATを作成します。
Private GKE ClusterからインターネットへのEgress通信を可能にします。

## 機能

- Cloud Routerの作成
- Cloud NATの作成
- 自動IPアドレス割り当て
- 全サブネット対応（Primary + Secondary Range）
- Endpoint Independent Mappingサポート
- NATログ機能（オプション）
- タイムアウト設定（TCP/UDP）

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
| [google_compute_router.router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | NATログを有効化するか | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | 環境名（dev/staging/prod） | `string` | n/a | yes |
| <a name="input_min_ports_per_vm"></a> [min\_ports\_per\_vm](#input\_min\_ports\_per\_vm) | VM/Pod当たりの最小ポート数 | `number` | `128` | no |
| <a name="input_nat_name"></a> [nat\_name](#input\_nat\_name) | Cloud NAT名 | `string` | n/a | yes |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | VPC self link | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCPプロジェクトID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | リージョン | `string` | n/a | yes |
| <a name="input_router_name"></a> [router\_name](#input\_router\_name) | Cloud Router名 | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nat_id"></a> [nat\_id](#output\_nat\_id) | Cloud NAT ID |
| <a name="output_nat_name"></a> [nat\_name](#output\_nat\_name) | Cloud NAT名 |
| <a name="output_router_id"></a> [router\_id](#output\_router\_id) | Cloud Router ID |
| <a name="output_router_name"></a> [router\_name](#output\_router\_name) | Cloud Router名 |
<!-- END_TF_DOCS -->
