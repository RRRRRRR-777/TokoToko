# Phase1: 要件・制約条件定義書

## 1. 非機能要件

### 1.1 パフォーマンス目標
| 項目 | 目標値 | 備考 |
|------|--------|------|
| 同時接続ユーザー数 | 500人 | 初期リリース想定 |
| API レスポンスタイム | 500ms以内 | 散歩データ保存・取得 |
| スループット | 50 req/sec | ピーク時想定 |

### 1.2 可用性目標
| 項目 | 目標値 | 備考 |
|------|--------|------|
| 稼働率 (SLO) | 99.9% | 月間ダウンタイム43分まで許容 |
| メンテナンス時間 | 夜間1時間以内 | データ移行時 |

## 2. 認証・セキュリティ

### 2.1 認証方式
- **方針**: Firebase ID Token検証を継続
- **理由**: 既存の仕組みを活用し、移行コストを最小化
- **実装方針**:
  - クライアントは引き続きFirebase Authentication SDKでログイン
  - GoバックエンドはFirebase Admin SDKでID Tokenを検証
  - 検証後、セッション情報をサーバー側で管理（オプション）

### 2.2 API認証
- **方式**: Bearer Token（Firebase ID Token）
- **ヘッダー形式**: `Authorization: Bearer <firebase_id_token>`
- **トークン有効期限**: Firebase標準（1時間）

### 2.3 OAuth統合
- **Apple Sign-In**: 継続利用（FirebaseAuthService経由）
- **Google Sign-In**: 継続利用（FirebaseAuthService経由）

## 3. データ移行制約

### 3.1 移行方式
- **方針**: 段階的移行（Firebase/Go両バックエンド並行稼働）
- **理由**:
  - 安全な移行（問題発生時の即時ロールバック）
  - 機能ごとの段階的切り替え
  - A/Bテストによる検証

### 3.2 移行フェーズ

#### Phase 2-3: 並行稼働期間
| フェーズ | 期間 | 作業内容 |
|----------|------|----------|
| **準備** | Phase2 | Goバックエンド実装、iOS側Repository抽象化 |
| **初期移行** | 事前 | 既存Firestore→PostgreSQL初期データコピー |
| **並行稼働開始** | Phase3 | iOS側Feature Flag追加、10%ユーザーでテスト |
| **段階的拡大** | 1-2週間 | 10% → 50% → 100% へ段階的に切り替え |
| **Firebase停止** | Phase4 | 全ユーザーGoバックエンド移行後、Firebase書き込み停止 |

#### 並行稼働中のデータ同期
- **方針**: Goバックエンドをマスター、Firebaseは読み取り専用（バックアップ）
- **同期方向**: Go → Firebase（一方向同期、オプション）
- **切り戻し**: Feature Flagで即座にFirebaseへ戻せる

### 3.3 iOS側切り替え機構

#### Repository抽象化
```swift
protocol WalkRepository {
    func create(_ walk: Walk) async throws -> Walk
    func fetch(id: UUID) async throws -> Walk
}

// 既存実装を維持
class FirebaseWalkRepository: WalkRepository { ... }

// 新規実装
class GoBackendWalkRepository: WalkRepository { ... }

// Feature Flagで切り替え
class WalkRepositoryFactory {
    static func create() -> WalkRepository {
        return FeatureFlags.useGoBackend
            ? GoBackendWalkRepository()
            : FirebaseWalkRepository()
    }
}
```

#### Feature Flag管理
- **開発環境**: UserDefaultsで手動切り替え
- **本番環境**: Firebase Remote Configで動的切り替え
- **機能単位**: Walk / Photo / Share ごとに個別制御可能

### 3.4 データ互換性
- **既存データ**: 完全互換を保証
- **スキーマ移行**: Firestore DocumentID → PostgreSQL UUID変換
- **ロールバック**: Firebase実装を2ヶ月間保持（即時切り戻し可能）
- **データ整合性**: 並行稼働期間中はGoバックエンドの書き込みのみ有効

## 4. モバイルアプリ特有要件

### 4.1 オフライン対応
- **方針**: ローカル保存→復帰後同期
- **実装方針**:
  - 散歩中の位置情報・写真はローカルストレージに保存
  - ネットワーク復帰時、バックグラウンドでサーバーに同期
  - 同期失敗時はリトライキューで管理

### 4.2 バックグラウンド位置追跡
- **要件**: iOSバックグラウンドモードでも位置更新を受信
- **API通信**: 位置データはバッチ送信（10秒～1分間隔）
- **バッテリー考慮**: 精度と更新頻度のバランス調整

### 4.3 画像アップロード
- **容量制限**: 1枚あたり5MB以内
- **枚数制限**: 散歩あたり最大10枚（無料プラン）
- **形式**: JPEG/HEIC（サーバー側でJPEG変換）
- **アップロード方式**: 署名付きURL（Cloud Storage）

## 5. 運用・監視（Phase1では方針のみ）

### 5.1 ログ収集
- **方針**: 構造化ログ（JSON形式）
- **ツール**: Cloud Logging（初期）、将来的にOTEL検討

### 5.2 メトリクス監視
- **方針**: Cloud Monitoring
- **監視項目**: レスポンスタイム、エラー率、リクエスト数、DB接続数

### 5.3 アラート（詳細はPhase4で設計）
- エラー率 > 5%
- レスポンスタイム > 1秒
- 可用性 < 99.9%

## 6. 技術的制約

### 6.1 Firebase依存
- **継続利用**: Authentication（ID Token検証）
- **段階的移行**: Firestore → PostgreSQL（Phase2）
- **継続利用**: Firebase Storage SDK（Phase6でアクセス方式最適化検討）

### 6.2 クライアント互換性
- **iOS最低バージョン**: iOS 15.0+
- **API バージョニング**: `/v1/` プレフィックス
- **後方互換性**: マイナーバージョンアップは互換性保持

## 7. Phase1決定事項サマリ

| カテゴリ | 決定事項 |
|----------|----------|
| 認証 | Firebase ID Token検証継続 |
| データ移行 | 一括移行（夜間1時間メンテナンス） |
| オフライン | ローカル保存→復帰後同期 |
| レイテンシ | 500ms以内 |
| 同時接続 | 500人 |
| 可用性 | 99.9% (SLO) |
| 画像制限 | 5MB/枚、10枚/散歩 |

## 8. 次ステップ（Step2以降）

- [ ] REST vs gRPC の通信方式決定
- [ ] データモデル設計（ER図）
- [ ] API設計書作成（OpenAPI Spec）
- [ ] デプロイ環境選定（Cloud Run vs GKE）
- [ ] ネットワーク構成設計
- [ ] Goプロジェクト構成設計
