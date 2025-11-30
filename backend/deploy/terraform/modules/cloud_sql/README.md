# Cloud SQL Module

PostgreSQL Regional HA構成を提供するモジュール

## 概要

このモジュールは、Google Cloud SQLのPostgreSQLインスタンスを作成します。
Regional HA構成とPrivate IP接続によるセキュアな構成になっています。

## 機能

- Cloud SQL PostgreSQLインスタンスの作成
- Regional HA構成対応
- Private IP接続（VPC Peering経由）
- 自動バックアップとPITR（Point-In-Time Recovery）
- SSL/TLS接続強制
- Query Insights対応（オプション）
- メンテナンスウィンドウ設定
- データベースフラグのカスタマイズ
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
| [google_service_networking_connection.private_vpc_connection](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |
| [google_sql_database.database](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | resource |
| [google_sql_database_instance.postgres](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_user.default_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_labels"></a> [additional\_labels](#input\_additional\_labels) | 追加のリソースラベル | `map(string)` | `{}` | no |
| <a name="input_authorized_networks"></a> [authorized\_networks](#input\_authorized\_networks) | パブリックIP接続時の許可ネットワーク | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_availability_type"></a> [availability\_type](#input\_availability\_type) | 可用性タイプ（ZONAL or REGIONAL） | `string` | `"REGIONAL"` | no |
| <a name="input_backup_start_time"></a> [backup\_start\_time](#input\_backup\_start\_time) | バックアップ開始時刻（HH:MM形式、UTC） | `string` | `"03:00"` | no |
| <a name="input_database_flags"></a> [database\_flags](#input\_database\_flags) | データベースフラグ | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | 作成するデータベース名 | `string` | n/a | yes |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | PostgreSQLバージョン | `string` | `"POSTGRES_15"` | no |
| <a name="input_db_user_name"></a> [db\_user\_name](#input\_db\_user\_name) | データベースユーザー名 | `string` | n/a | yes |
| <a name="input_db_user_password"></a> [db\_user\_password](#input\_db\_user\_password) | データベースパスワード（Secret Managerから取得推奨） | `string` | n/a | yes |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | 削除保護を有効化するか（prodで推奨） | `bool` | `false` | no |
| <a name="input_disk_autoresize"></a> [disk\_autoresize](#input\_disk\_autoresize) | ディスク自動拡張を有効化するか | `bool` | `true` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | ディスクサイズ（GB） | `number` | `10` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | ディスクタイプ（PD\_SSD or PD\_HDD） | `string` | `"PD_SSD"` | no |
| <a name="input_enable_backup"></a> [enable\_backup](#input\_enable\_backup) | 自動バックアップを有効化するか | `bool` | `true` | no |
| <a name="input_enable_pitr"></a> [enable\_pitr](#input\_enable\_pitr) | ポイントインタイムリカバリを有効化するか | `bool` | `true` | no |
| <a name="input_enable_public_ip"></a> [enable\_public\_ip](#input\_enable\_public\_ip) | パブリックIPを有効化するか | `bool` | `false` | no |
| <a name="input_enable_query_insights"></a> [enable\_query\_insights](#input\_enable\_query\_insights) | Query Insightsを有効化するか | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | 環境名（dev/staging/prod） | `string` | n/a | yes |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Cloud SQLインスタンス名 | `string` | n/a | yes |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | メンテナンスウィンドウ設定 | <pre>object({<br/>    day          = number<br/>    hour         = number<br/>    update_track = string<br/>  })</pre> | `null` | no |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | VPC self link | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCPプロジェクトID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | リージョン | `string` | n/a | yes |
| <a name="input_retained_backups"></a> [retained\_backups](#input\_retained\_backups) | 保持するバックアップ数 | `number` | `7` | no |
| <a name="input_ssl_mode"></a> [ssl\_mode](#input\_ssl\_mode) | SSL/TLS接続モード (ALLOW\_UNENCRYPTED\_AND\_ENCRYPTED, ENCRYPTED\_ONLY, TRUSTED\_CLIENT\_CERTIFICATE\_REQUIRED) | `string` | `"ENCRYPTED_ONLY"` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | マシンタイプ（例: db-f1-micro, db-custom-2-7680） | `string` | n/a | yes |
| <a name="input_transaction_log_retention_days"></a> [transaction\_log\_retention\_days](#input\_transaction\_log\_retention\_days) | トランザクションログ保持日数 | `number` | `7` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | データベース名 |
| <a name="output_db_user_name"></a> [db\_user\_name](#output\_db\_user\_name) | データベースユーザー名 |
| <a name="output_instance_connection_name"></a> [instance\_connection\_name](#output\_instance\_connection\_name) | インスタンス接続名（project:region:instance形式） |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | Cloud SQLインスタンス名 |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | プライベートIPアドレス |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | パブリックIPアドレス |
<!-- END_TF_DOCS -->
