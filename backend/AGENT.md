# AGENTハンドブック

TekuToko/backend リポジトリで作業するエージェント向けの行動指針と、`backend/docs` 配下ドキュメントの要点を1ファイルに集約しました。タスク着手前の状況把握と、作業・コミュニケーション時の共通認識づくりに活用してください。

## 🔴 最重要ルール

### 1. タスク確認ルール

**タスクがわからなくなった場合は必ず `~/RRRRRRR777/Repositories/TekuToko/TODO.md` を確認する**：

- 現在のフェーズ
- 完了済みタスク
- 残タスク
- 次のアクション

タスクを見失った場合や、何をすべきか迷った場合は、TODO.mdを読み直してから作業を再開してください。

## backend/docs 各資料の要約

### requirements.md （要件・制約）
- パフォーマンス: 同時接続500人、レスポンス500ms以内、スループット50 req/sec。
- 可用性: 月間稼働率99.9%、計画メンテは夜間1時間。
- 認証・セキュリティ: Firebase ID Tokenを継続利用、Bearer認証ヘッダー統一。
- データ移行: Phase2-3でFirebaseとGoバックエンドを並行稼働。Feature Flagで段階的に切り替え、Go側をマスターとする。
- モバイル要件: オフライン保存→復帰時同期、位置情報はバッチ送信、画像は5MB/枚×10枚。

### communication-protocol.md （通信プロトコル）
- 採用: REST API (HTTP/1.1 + JSON)、Chi routerベース。
- 選定理由: モバイルクライアント親和性、デバッグ容易性、運用コスト低さ、Autopilot/Gatewayとの互換性。
- API設計: ベースURL `https://api.tekutoko.app/v1`、リソース指向エンドポイント、統一レスポンス/エラーフォーマット、Firebase ID Tokenをミドルウェアで検証、limit+offsetページネーション。
- 将来: リアルタイム機能はWebSocket/SSEで補完し、必要に応じてgRPCを再検討。

### database-schema.md （データベーススキーマ）
- 主要テーブル: `users`, `walks`, `walk_locations`, `consents`。walk_locationsは分離テーブルで時系列性能とPostGIS拡張性を確保。
- 制約: walk statusやconsent typeはENUM、緯度経度CHECK、walk_id+sequence_numberのUNIQUEで順序保証。
- インデックス: ユーザー別walks、statusフィルタ、walk_locationsの順序・時刻アクセス用。
- トリガー: users / walks の updated_at はトリガーで自動更新。
- マイグレーション: `migrations/001-007_*.sql` でENUM→テーブル→トリガー→インデックスの順に適用。

### openapi.yaml （API仕様）
- OpenAPI 3.1でWalks/Locations 6エンドポイントを定義（一覧、作成、詳細、更新、削除、位置情報バッチ追加）。
- 共通レスポンス: `data` + `meta`（request_id, timestamp, pagination）。
- エラー: RFC 7807準拠の`error.code`, `message`, `details`を返却。
- 認証: `Authorization: Bearer <firebase_id_token>` を全エンドポイントに必須指定。
- バリデーション: Walk作成は title 必須、locationバッチは配列長や緯度経度範囲を仕様化。

### deployment-architecture.md （デプロイ構成）
- プラットフォーム: GKE Autopilot（asia-northeast1）、レプリカ2-10、500mCPU/512Miを基準。
- インフラ構成: LoadBalancer Serviceで公開、Cloud SQL + Cloud SQL Proxyサイドカー、Firebase Storage/Auth、Secret Manager連携。
- マニフェスト: `deploy/kubernetes/base/` に Deployment / Service / ServiceAccount / ConfigMap / Secret / HPA / PodDisruptionBudget（Phase4でNetworkPolicy, Ingress）。
- 運用: gcloud + kubectlでクラスタ管理、負荷試験/監視/コスト/SLO計画をTODOリスト化。
- Phase別ロードマップ: Phase2でTerraform・CI/CD・監視を整備、Phase4以降でIngress/Cloud Armor等を追加。

### network-architecture.md （ネットワーク設計）
- トポロジ: Public LB → tekutoko-api Pods（Cloud SQL Proxyサイドカー）→ Cloud SQL / Firebase各種サービス。
- 接続: Kubernetes LoadBalancer ServiceがExternal IPを払い出し、PodはWorkload Identity + Secret Managerで資格情報取得。
- Cloud SQL: 各PodにProxyサイドカー、localhost:5432経由で暗号化済み接続。
- DNS/セキュリティ: Phase4で静的IP、Cloud DNS `api.tekutoko.com`, Cloud Armor, NetworkPolicyを段階導入。
- モニタリング: Cloud MonitoringでLBレイテンシ/帯域、Cloud LoggingでLB・アプリ・Proxyログを収集。

### go-project-structure.md （Goプロジェクト構成）
- アーキテクチャ: Clean Architecture + DDD。`internal/` 下に domain / usecase / interface / infrastructure / pkg を配置。
- 主要依存: chi, pgx + sqlx, golang-migrate, Firebase Admin SDK, Cloud client libs, testify など。
- API層: handler/middleware/router/presenterでREST I/Oを統一。ミドルウェアはauth/logging/recovery/request_id。
- インフラ層: config, database, auth, logger, telemetryなど横断的関心ごとを担当。
- iOS連携: WalkRepositoryプロトコル、Goバックエンド実装、Factory + Feature FlagでFirebase版と切り替え、DIを通じて導入。
- テスト: domain/usecaseのユニットテスト、interface層はhttptest、integrationはdocker-compose + migrator想定。

### phase1-summary.md （Phase1サマリー）
- 2025-10-20にPhase1（設計）を6時間で完了。Step1〜7の成果物が docs ディレクトリに格納済み。
- Phase2のスコープ: Goバックエンド実装、Terraform/IaC、マニフェスト、データ移行スクリプト、iOS側Repository抽象化。
- 優先度: Phase2で高優先度8項目、iOS側5項目、中長期のバックログも列挙。
- リスク: 現時点で致命的懸念なし。将来拡張（WebSocket, GKE Standard, PostGIS, Redis, Ingress）を検討事項として整理。
- 次アクション: Phase1成果コミット、Issue #148更新、Phase2タスク分解、GCPリソース準備。

## 自動コミット実行プロンプト

ユーザーが以下のように指示した場合、確認なしで順次コミットを実行する：

```
変更されたファイルを、ファイル単位で細かくコミットしてください。
コミット確認は不要です。
```

- `git status`で変更ファイルを確認
- ファイル単位または論理単位で`git add`と`git commit`を順次実行
- 適切なコミットメッセージを自動生成

## コミット実行ルール

### 基本方針
ユーザーから「コミットして」と指示された場合：

1. **コミット前検査を実施**: 必ず検査を実行し、結果をユーザーに報告
2. **承認確認**: 検査結果を提示し、ユーザーの承認を得る
3. **コマンド確認は不要**: 承認後、コミットコマンドの確認なしで即座に実行
4. **適切なコミットメッセージ**: CLAUDE.mdのコミット規約に従ったメッセージを自動生成

### 実行方法
- `git add <file>` と `git commit -m "..."` を連続で実行
- `git commit -a` は使用しない（明示的に `git add` でファイル指定）

## コミット前検査ルール

**🔴 絶対遵守**: コミット前に必ず検査を実行し、ユーザーに報告・承認を得る

### 検査内容

1. **Goコードの場合**
   ```bash
   go vet ./...          # 構文チェック
   gofmt -l <files>      # フォーマット確認
   gofmt -w <files>      # エラーがあれば自動修正
   ```

2. **Terraformコードの場合**
   ```bash
   terraform fmt -check  # フォーマット確認
   terraform fmt         # エラーがあれば自動修正
   terraform validate    # 構文検証
   ```

3. **YAMLファイルの場合**
   - 構文エラーがないか確認
   - 主要な変更点を説明

4. **ドキュメント・その他の場合**
   - 主要な変更点を説明

### 承認フロー
1. 検査実行 → 結果報告
2. 主要な変更点を箇条書きで提示
3. ユーザー承認待ち
4. 承認後、コマンド確認なしで即座にコミット実行
5. 承認が得られない場合は修正を実施

### 報告フォーマット
```markdown
## コミット前確認項目

### 1. コード検査
- go vet: OK / エラー自動修正済み
- gofmt: OK / フォーマット修正済み

### 2. 主要な変更点
1. [変更内容1]
2. [変更内容2]
...

### 3. テスト確認（該当する場合）
- 動作確認コマンド
- 期待される結果
```

