# TekuToko ネットワーク設計

## 概要

GKE Autopilot向けのVPC-Native Private Cluster構成。

## VPC設計

### 基本方針

- **1プロジェクト1 VPC**: 環境ごとに独立したVPC
- **VPC-Native**: GKE用にIP aliasを使用
- **Private Cluster**: ノードは外部IPなし、Cloud NATでegress

### VPC命名規約

```
vpc-tekutoko-{env}
```

例:
- `vpc-tekutoko-dev`
- `vpc-tekutoko-staging`
- `vpc-tekutoko-prod`

## サブネット設計

### リージョン

- **プライマリリージョン**: `asia-northeast1` (東京)
- **セカンダリリージョン**: `asia-northeast2` (大阪) ※将来対応

### CIDR割り当て

| 環境 | Primary CIDR | Pods CIDR | Services CIDR |
|------|--------------|-----------|---------------|
| dev | 10.0.0.0/20 (4,096 IPs) | 10.4.0.0/17 (32,768 IPs) | 10.8.0.0/22 (1,024 IPs) |
| staging | 10.16.0.0/20 (4,096 IPs) | 10.20.0.0/17 (32,768 IPs) | 10.24.0.0/22 (1,024 IPs) |
| prod | 10.32.0.0/20 (4,096 IPs) | 10.36.0.0/17 (32,768 IPs) | 10.40.0.0/22 (1,024 IPs) |

### サブネット命名規約

**Primary Subnet**:
```
subnet-{region}-{env}-primary
```

**Secondary Ranges**:
- Pods: `range-{env}-pods`
- Services: `range-{env}-svc`

例（dev環境）:
- Primary: `subnet-asia-northeast1-dev-primary` (10.0.0.0/20)
- Pods: `range-dev-pods` (10.4.0.0/17)
- Services: `range-dev-svc` (10.8.0.0/22)

## Cloud Router & NAT設計

### 設計方針

- リージョンごとに1 Router + 1 NAT
- Private Cluster egress用に必須
- NAT IPアドレスは自動割り当て

### 命名規約

**Cloud Router**:
```
router-{region}-{env}
```

**Cloud NAT**:
```
nat-{region}-{env}
```

例:
- `router-asia-northeast1-dev`
- `nat-asia-northeast1-dev`

### NAT設定

- `min_ports_per_vm`: 128（Autopilot Pod密度対応）
- `endpoint_independent_mapping`: 有効
- ログ: Cloud Loggingへ出力

## Firewall Rules設計

### 基本方針

- **デフォルト**: deny all
- **最小権限**: 必要な通信のみ許可
- **ログ有効化**: 全ルールでログ記録

### ルール定義

| 名前 | Priority | Direction | Target | Source | Protocol/Port | 用途 |
|------|----------|-----------|--------|--------|---------------|------|
| `fw-{env}-allow-gke-control-plane` | 1000 | INGRESS | gke-nodes | GKE Master CIDR | TCP/443,10250 | GKE Control Plane通信 |
| `fw-{env}-allow-internal-pods` | 1100 | INGRESS | gke-pods | Pods CIDR | ALL | Pod間通信 |
| `fw-{env}-allow-health-checks` | 1200 | INGRESS | gke-nodes | 35.191.0.0/16, 130.211.0.0/22 | TCP/80,443 | GCP Health Checks |
| `fw-{env}-allow-iap-ssh` | 2000 | INGRESS | iap-ssh | 35.235.240.0/20 | TCP/22 | IAP経由SSH |
| `fw-{env}-deny-all` | 65534 | INGRESS | all | 0.0.0.0/0 | ALL | 明示的deny |

### ネットワークタグ

- `gke-nodes`: GKEノード
- `gke-pods`: GKE Pods（自動付与）
- `iap-ssh`: IAP SSH許可ノード

## Secret Manager設計

### 命名規約

```
sm-{env}-{app}-{purpose}
```

例:
- `sm-dev-api-db-password`
- `sm-prod-api-firebase-key`
- `sm-staging-backend-jwt-secret`

### レプリケーション戦略

| 環境 | レプリケーション | ローテーション | 有効期限 |
|------|-----------------|---------------|---------|
| dev | 単一リージョン | 手動 | 90日 |
| staging | 単一リージョン | 手動 | 180日 |
| prod | マルチリージョン | 自動（年1回） | なし |

### IAM設計

- **最小権限**: Service Account単位で`roles/secretmanager.secretAccessor`
- **Workload Identity**: GKE PodからSecret Manager CSI Driver経由でアクセス

## セキュリティ考慮事項

### Private Cluster

- ノードは外部IP不要
- Master Authorized Networksで管理元を制限
- Private Google Accessで内部通信のみ

### VPC Service Controls（将来対応）

- GCPサービス間の境界制御
- データ流出防止

### Network Policy

- Kubernetes NetworkPolicyでPod間通信を細かく制御
- Namespace単位での分離

## 監視・ログ

### VPC Flow Logs

- 有効化: staging/prod
- サンプリングレート: 50%
- メタデータ: 全情報記録

### Firewall Logs

- 全ルールでログ有効化
- Cloud Loggingへ出力
- 定期的な監査

### Cloud NAT Logs

- 接続ログ: 有効
- エラーログ: 有効
- Translation allocation failures: アラート設定

## 参考資料

- [GKE Private Clusters](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)
- [VPC-native clusters](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips)
- [Cloud NAT](https://cloud.google.com/nat/docs/overview)
- [VPC Firewall Rules](https://cloud.google.com/vpc/docs/firewalls)
- [Secret Manager Best Practices](https://cloud.google.com/secret-manager/docs/best-practices)
