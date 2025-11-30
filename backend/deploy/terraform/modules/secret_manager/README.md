# Secret Manager Module

環境ごとのシークレット管理を提供するモジュール

## 概要

このモジュールは、Google Secret Managerのシークレットを作成します。
レプリケーション設定、TTL、ローテーション、IAMバインディングをサポートします。

## 機能

- Secret Managerシークレットの作成
- 自動レプリケーション or ユーザー管理レプリケーション
- シークレットバージョン管理
- TTL設定（dev/staging用）
- 自動ローテーション設定（prod推奨）
- Service AccountへのIAMバインディング
- ラベル管理

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
| [google_secret_manager_secret.secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_version.version](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accessor_service_accounts"></a> [accessor\_service\_accounts](#input\_accessor\_service\_accounts) | アクセス権を付与するService Accountのリスト | `list(string)` | `[]` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | アプリケーション名 | `string` | `"tekutoko"` | no |
| <a name="input_create_initial_version"></a> [create\_initial\_version](#input\_create\_initial\_version) | 初期バージョンを作成するか | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | 環境名（dev/staging/prod） | `string` | n/a | yes |
| <a name="input_initial_value"></a> [initial\_value](#input\_initial\_value) | 初期シークレット値（create\_initial\_version=trueの場合） | `string` | `""` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCPプロジェクトID | `string` | n/a | yes |
| <a name="input_replication_locations"></a> [replication\_locations](#input\_replication\_locations) | user\_managed時のレプリケーションロケーションリスト | `list(string)` | `[]` | no |
| <a name="input_replication_type"></a> [replication\_type](#input\_replication\_type) | レプリケーションタイプ（auto or user\_managed） | `string` | `"auto"` | no |
| <a name="input_rotation_period"></a> [rotation\_period](#input\_rotation\_period) | ローテーション期間（例: 7776000s = 90日） | `string` | `null` | no |
| <a name="input_secret_id"></a> [secret\_id](#input\_secret\_id) | Secret ID（例: sm-dev-api-db-password） | `string` | n/a | yes |
| <a name="input_ttl_seconds"></a> [ttl\_seconds](#input\_ttl\_seconds) | シークレットのTTL（秒）。0の場合は無期限 | `number` | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | Secret ID |
| <a name="output_secret_name"></a> [secret\_name](#output\_secret\_name) | Secret名（フルパス） |
<!-- END_TF_DOCS -->
