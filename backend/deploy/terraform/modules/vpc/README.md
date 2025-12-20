# VPC Module

GKE Autopilot用のVPC-Native構成を提供するモジュール

## 概要

このモジュールは、Google Cloud PlatformのVPCとサブネットを作成します。
GKE用のSecondary IP Range（Pod/Service用）を含む構成になっています。

## 機能

- VPC（Regional Routing）の作成
- Primary Subnetの作成
- GKE用Secondary IP Range（Pods/Services）の設定
- Private Google Accessの有効化
- VPC Flow Logs（オプション）

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
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.primary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | VPC Flow Logsを有効化するか | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | 環境名（dev/staging/prod） | `string` | n/a | yes |
| <a name="input_pods_cidr"></a> [pods\_cidr](#input\_pods\_cidr) | Pods用 Secondary CIDR | `string` | n/a | yes |
| <a name="input_pods_range_name"></a> [pods\_range\_name](#input\_pods\_range\_name) | Pods用 Secondary Range名 | `string` | n/a | yes |
| <a name="input_primary_cidr"></a> [primary\_cidr](#input\_primary\_cidr) | Primary CIDR（ノード用） | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCPプロジェクトID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | リージョン | `string` | n/a | yes |
| <a name="input_services_cidr"></a> [services\_cidr](#input\_services\_cidr) | Services用 Secondary CIDR | `string` | n/a | yes |
| <a name="input_services_range_name"></a> [services\_range\_name](#input\_services\_range\_name) | Services用 Secondary Range名 | `string` | n/a | yes |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | サブネット名 | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | VPC名 | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pods_range_name"></a> [pods\_range\_name](#output\_pods\_range\_name) | Pods用 Secondary Range名 |
| <a name="output_services_range_name"></a> [services\_range\_name](#output\_services\_range\_name) | Services用 Secondary Range名 |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | サブネットID |
| <a name="output_subnet_name"></a> [subnet\_name](#output\_subnet\_name) | サブネット名 |
| <a name="output_subnet_self_link"></a> [subnet\_self\_link](#output\_subnet\_self\_link) | サブネット self link |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC名 |
| <a name="output_vpc_self_link"></a> [vpc\_self\_link](#output\_vpc\_self\_link) | VPC self link |
<!-- END_TF_DOCS -->
