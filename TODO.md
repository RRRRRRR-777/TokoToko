# TekuToko バックエンド実装進捗管理

親チケット: [#148 Go言語でのバックエンド実装](https://github.com/RRRRRRR-777/TokoToko/issues/148)

## 全体概要

iOSクライアントの Firebase 直接依存を排除し、Go製BFFバックエンドを構築することで：
- 負荷分散と冗長構成の実現
- クライアント責務の軽量化
- サーバー集中管理への移行

**全体工数**: 約42人日（Phase 0-7）
**優先作業**: Phase 0-5（31人日）

---

## ✅ Phase 0: Firebase依存箇所の棚卸しと移行範囲の明確化（完了）

**チケット**: [#149](https://github.com/RRRRRRR-777/TokoToko/issues/149)
**状態**: CLOSED ✅
**所要時間**: 3日

### 完了内容
- Firebase依存箇所の列挙
- データモデルの洗い出し
- オフラインキャッシュ・テストコードへの影響調査

---

## ✅ Phase 1: Goバックエンドの設計とデプロイ方針の確立（完了）

**チケット**: [#150](https://github.com/RRRRRRR-777/TokoToko/issues/150)
**状態**: OPEN（実質完了）
**所要時間**: 6日

### 完了内容
- API設計書、ER図の作成
- 通信方式（REST/gRPC）の決定
- デプロイ環境の選定（GKE Autopilot）
- ネットワーク構成の設計

---

## 🚧 Phase 2: Walk CRUD APIの実装とデータ移行準備（着手前）

**チケット**: [#151](https://github.com/RRRRRRR-777/TokoToko/issues/151)
**状態**: OPEN
**所要時間**: 8日

### タスク
- [ ] Goで `/v1/walks` API実装
- [ ] PostgreSQL DBスキーマ定義
- [ ] データ移行スクリプト作成
- [ ] iOS側 `WalkRepository` をHTTPクライアントに差し替え
- [ ] 段階的リリース用フラグ追加

---

## 📋 Phase 3: Firebase認証統合とセッションサービスの導入（着手前）

**チケット**: [#152](https://github.com/RRRRRRR-777/TokoToko/issues/152)
**状態**: OPEN
**所要時間**: 5日

### タスク
- [ ] Firebase IDトークン検証の実装
- [ ] サーバーセッション発行のBFF実装
- [ ] クライアントでセッションリフレッシュ/失効処理
- [ ] Firebase SDK依存の縮小

---

## 🔧 Phase 4: 監視・冗長化・CI/CD体制の構築（進行中）

**チケット**: [#153](https://github.com/RRRRRRR-777/TokoToko/issues/153)
**状態**: OPEN ⚠️ **進行中**
**所要時間**: 5日

### ✅ 完了済み
- [x] Terraform によるインフラ構築
  - [x] Dev環境（GKE + Cloud SQL）
  - [x] Staging環境（GKE + Cloud SQL）
  - [x] Production環境（GKE + Cloud SQL）
- [x] GCP制限に準拠した設定調整
- [x] SETUP_GUIDE.md の整備
- [x] リソース起動・停止手順の追加
- [x] コスト管理方法の確立

### 🚧 残タスク
- [ ] ヘルスチェックエンドポイントの実装
- [ ] オートスケール設定
- [ ] CI/CDパイプライン構築
  - [ ] GitHub Actions ワークフロー
  - [ ] Docker イメージビルド
  - [ ] GKE へのデプロイ自動化
- [ ] 監視・アラート設定
  - [ ] Prometheus/Grafana セットアップ
  - [ ] ログ集約（Cloud Logging）
  - [ ] メトリクス収集
- [ ] 運用Runbook作成
  - [ ] 障害対応手順
  - [ ] スケーリング手順
  - [ ] ロールバック手順

---

## 📦 Phase 5: 統合テストと本番切り替え準備（着手前）

**チケット**: [#154](https://github.com/RRRRRRR-777/TokoToko/issues/154)
**状態**: OPEN
**所要時間**: 4日

### タスク
- [ ] 結合テスト実施
- [ ] 負荷テスト実施
- [ ] 段階的ロールアウト準備
  - [ ] Feature Flag 実装
  - [ ] Canary デプロイ設定
- [ ] 本番切り替え計画書作成

---

## 🔮 Phase 6: 画像生成・ログ収集のサーバー移行（低優先度・後回し）

**所要時間**: 7日

### タスク
- [ ] 画像生成ジョブAPI + ワーカー実装
- [ ] 署名URLでアップロード機能
- [ ] ログ集約API → OTEL/Prometheus 送信
- [ ] ダッシュボード雛形作成

---

## 🔮 Phase 7: ポリシー／同意／リモート設定APIの実装（低優先度・後回し）

**所要時間**: 4日

### タスク
- [ ] Consent/Policy/RemoteConfig API実装
- [ ] 履歴管理機能
- [ ] クライアント反映

---

## 📊 進捗サマリー

| Phase | 状態 | 進捗率 | 所要時間 |
|-------|------|--------|----------|
| Phase 0 | ✅ 完了 | 100% | 3日 |
| Phase 1 | ✅ 完了 | 100% | 6日 |
| Phase 2 | 📋 着手前 | 0% | 8日 |
| Phase 3 | 📋 着手前 | 0% | 5日 |
| **Phase 4** | **🚧 進行中** | **60%** | **5日** |
| Phase 5 | 📋 着手前 | 0% | 4日 |
| Phase 6 | 🔮 低優先度 | - | 7日 |
| Phase 7 | 🔮 低優先度 | - | 4日 |

**全体進捗**: Phase 0-5（優先作業）のうち 2.6/5 フェーズ完了（約52%）

---

## 🎯 次のアクション

### 即座に着手すべきタスク（Phase 4 残作業）

1. **CI/CDパイプライン構築**
   - GitHub Actions ワークフロー作成
   - Docker イメージビルド・プッシュ
   - GKE デプロイ自動化

2. **監視・アラート設定**
   - Prometheus/Grafana セットアップ
   - ヘルスチェック実装

3. **運用ドキュメント整備**
   - Runbook 作成

### Phase 4 完了後

- Phase 2（Walk CRUD API実装）に着手
- Phase 3（認証統合）へ進む
- Phase 5（統合テスト）で検証

---

## 📝 備考

- Phase 6・7 は Phase 0-5 が安定した後に着手
- 学習目的のため、バッファ時間を +20% 確保推奨
- インフラは構築済みだが、現在コスト削減のため全環境削除済み
  - 必要時に `terraform apply` で再構築可能
