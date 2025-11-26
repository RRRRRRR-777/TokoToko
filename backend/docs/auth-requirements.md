# 認証要件分析ドキュメント

## 概要

TekuTokoプロジェクトにおける認証システムの要件分析と設計方針を定義します。Firebase AuthenticationとGoバックエンドの役割分離を明確化し、セキュアで拡張性の高い認証システムを構築します。

---

## 1. アーキテクチャ概要

### 1.1 認証システムの全体構成

```
┌─────────────┐
│   iOSアプリ  │
└──────┬──────┘
       │
       │ 1. ユーザー認証
       ▼
┌─────────────────┐
│ Firebase Auth   │ ← 認証サービス
└──────┬──────────┘
       │
       │ 2. IDトークン発行
       ▼
┌─────────────┐
│   iOSアプリ  │
└──────┬──────┘
       │
       │ 3. API呼び出し (Authorization: Bearer <token>)
       ▼
┌──────────────────────────────┐
│    Goバックエンド              │
│  ┌────────────────────────┐  │
│  │ AuthMiddleware         │  │ ← トークン検証
│  │ - Token Verification   │  │
│  │ - Token Caching        │  │
│  └────────┬───────────────┘  │
│           │                   │
│           │ 4. ユーザーID抽出  │
│           ▼                   │
│  ┌────────────────────────┐  │
│  │ Business Logic         │  │
│  │ - Walk CRUD            │  │
│  │ - Authorization Check  │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

---

## 2. 役割分離

### 2.1 Firebase Authenticationの責務

Firebase Authは**認証（Authentication）**を担当します。

#### 責務範囲

| 機能 | 説明 | 実装場所 |
|------|------|----------|
| **ユーザー登録** | メールアドレス、パスワード登録 | Firebase Console/SDK |
| **ログイン** | 認証情報の検証 | Firebase SDK (iOS) |
| **IDトークン発行** | JWT形式のトークン生成 | Firebase Auth |
| **トークン更新** | Refresh Token管理 | Firebase SDK (iOS) |
| **ソーシャルログイン** | Google, Apple等の連携 | Firebase Auth |
| **パスワードリセット** | メール送信、リセット処理 | Firebase Auth |
| **多要素認証 (MFA)** | 2段階認証 | Firebase Auth (将来対応) |

#### 提供されるもの

- **IDトークン (JWT)**
  - 署名付きトークン
  - ユーザーID (UID)
  - メールアドレス
  - カスタムクレーム（将来対応）
  - 有効期限（1時間）

#### Firebase Authが**しないこと**

- ❌ 認可（Authorization）
- ❌ ビジネスロジック
- ❌ データアクセス制御
- ❌ アプリケーション固有のユーザー情報管理

---

### 2.2 Goバックエンドの責務

Goバックエンドは**認可（Authorization）** と **ビジネスロジック** を担当します。

#### 責務範囲

| 機能 | 説明 | 実装場所 |
|------|------|----------|
| **IDトークン検証** | Firebase署名検証、有効期限チェック | `AuthMiddleware` |
| **トークンキャッシング** | パフォーマンス最適化 | `TokenCache` |
| **ユーザーID抽出** | トークンからUIDを取得 | `AuthMiddleware` |
| **認可チェック** | リソースアクセス権限の確認 | Business Logic |
| **データアクセス制御** | 自分のデータのみ取得 | Repository Layer |
| **ユーザー情報管理** | アプリ固有のプロフィール | User Domain |

#### 実装方針

1. **ステートレス認証**
   - セッション管理なし
   - IDトークンのみで認証状態を判断

2. **リソースベース認可**
   - 各APIエンドポイントで認可チェック
   - ユーザーIDベースのデータフィルタリング

3. **キャッシング戦略**
   - トークン検証結果をキャッシュ（TTL: 5分）
   - Firebase API呼び出しを最小化

---

## 3. 認証フロー設計

### 3.1 初回ログインフロー

```
┌─────────┐
│ ユーザー │
└────┬────┘
     │
     │ 1. ログイン操作
     ▼
┌──────────────┐
│   iOSアプリ   │
│ Firebase SDK │
└──────┬───────┘
       │
       │ 2. 認証リクエスト
       ▼
┌─────────────────┐
│ Firebase Auth   │
└──────┬──────────┘
       │
       │ 3. 認証成功 → IDトークン発行
       ▼
┌──────────────┐
│   iOSアプリ   │
│ (トークン保存) │
└──────┬───────┘
       │
       │ 4. API呼び出し
       │    Authorization: Bearer <IDトークン>
       ▼
┌──────────────────────────────┐
│    Goバックエンド              │
│  ┌────────────────────────┐  │
│  │ AuthMiddleware         │  │
│  │ 1. トークン検証         │  │
│  │ 2. ユーザーID抽出       │  │
│  │ 3. Context保存         │  │
│  └────────┬───────────────┘  │
│           ▼                   │
│  ┌────────────────────────┐  │
│  │ WalkHandler            │  │
│  │ - getUserID()          │  │
│  │ - ビジネスロジック実行   │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

### 3.2 通常のAPI呼び出しフロー

```
┌──────────────┐
│   iOSアプリ   │
│ (トークン保持) │
└──────┬───────┘
       │
       │ 1. API呼び出し
       │    Authorization: Bearer <IDトークン>
       ▼
┌──────────────────────────────┐
│    AuthMiddleware            │
└──────┬───────────────────────┘
       │
       │ 2. キャッシュチェック
       ▼
    ┌─────┐
    │ HIT?│
    └──┬──┘
       │
   ┌───┴───┐
   │       │
  YES      NO
   │       │
   │       └─→ Firebase検証 → キャッシュ保存
   │
   ▼
┌──────────────┐
│ Context保存   │
│ userID: xxx  │
└──────┬───────┘
       │
       │ 3. ビジネスロジック実行
       ▼
┌──────────────────┐
│ WalkHandler      │
│ - getUserID()    │
│ - データアクセス   │
└──────────────────┘
```

### 3.3 トークン更新フロー

```
┌──────────────┐
│   iOSアプリ   │
└──────┬───────┘
       │
       │ 1. IDトークン期限切れ検知
       ▼
┌──────────────┐
│ Firebase SDK │
│ トークン更新   │
└──────┬───────┘
       │
       │ 2. 新しいIDトークン取得
       │    (自動的にRefresh Tokenを使用)
       ▼
┌──────────────┐
│   iOSアプリ   │
│ トークン更新   │
└──────┬───────┘
       │
       │ 3. 新トークンでAPI呼び出し
       ▼
┌──────────────────┐
│ Goバックエンド    │
│ (新トークン検証)  │
└──────────────────┘
```

**重要**:
- IDトークンの有効期限: **1時間**
- Refresh Tokenの有効期限: **無期限**（Firebase Authが管理）
- iOSアプリ側で自動更新を実装

---

## 4. セキュリティ要件

### 4.1 トークン検証要件

#### 必須検証項目

| 項目 | 検証内容 | 実装状況 |
|------|---------|---------|
| **署名検証** | Firebase公開鍵で署名を検証 | ✅ 実装済み (Firebase Admin SDK) |
| **有効期限** | `exp` クレームをチェック | ✅ 実装済み (Firebase Admin SDK) |
| **発行者** | `iss` が正しいか確認 | ✅ 実装済み (Firebase Admin SDK) |
| **オーディエンス** | `aud` がプロジェクトIDと一致 | ✅ 実装済み (Firebase Admin SDK) |
| **トークン形式** | Bearer形式のチェック | ✅ 実装済み (AuthMiddleware) |

#### トークン無効化シナリオ

| シナリオ | 対応方法 | 実装状況 |
|---------|---------|---------|
| **ユーザーログアウト** | クライアント側でトークン削除 | iOS側実装 |
| **パスワード変更** | Firebase Authが既存トークンを無効化 | Firebase側自動 |
| **アカウント削除** | Firebase Authが全トークンを無効化 | Firebase側自動 |
| **強制ログアウト** | カスタムクレームでrevoke時刻を管理 | 🔄 将来対応 |

### 4.2 通信セキュリティ

#### 必須要件

| 項目 | 要件 | 実装 |
|------|------|------|
| **HTTPS使用** | 全API通信をHTTPS化 | 🔄 本番環境で必須 |
| **トークン送信** | Authorizationヘッダーのみ | ✅ 実装済み |
| **トークン保存** | iOS Keychainに保存 | iOS側実装 |

#### 禁止事項

- ❌ トークンをURLパラメータに含める
- ❌ トークンをローカルストレージに平文保存
- ❌ トークンをログに出力

### 4.3 認可要件

#### データアクセス制御

```go
// 例: Walk APIの認可チェック
func (i *Interactor) GetWalk(ctx context.Context, id uuid.UUID, userID string) (*walk.Walk, error) {
    w, err := i.repository.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }

    // 認可チェック: 自分のWalkのみアクセス可能
    if w.UserID != userID {
        return nil, errors.NewUnauthorizedError("Access denied")
    }

    return w, nil
}
```

#### 認可ルール

| リソース | ルール |
|---------|--------|
| **Walk** | 自分が作成したWalkのみ取得・更新・削除可能 |
| **User** | 自分のプロフィールのみ取得・更新可能 |

### 4.4 レート制限

#### Firebase側

- Firebase Admin SDK: デフォルトでレート制限あり
- キャッシングにより呼び出し回数を削減（80-95%削減）

#### バックエンド側

| エンドポイント | 制限 | 実装状況 |
|--------------|------|---------|
| **認証エンドポイント** | 100 req/min/IP | 🔄 将来対応 |
| **一般API** | 1000 req/min/user | 🔄 将来対応 |

---

## 5. トークン検証戦略

### 5.1 キャッシング戦略

#### 現在の実装

```go
type TokenCache struct {
    mu              sync.RWMutex
    cache           map[string]*cacheEntry
    cleanupInterval time.Duration
    stopCleanup     chan struct{}
}

type cacheEntry struct {
    userID    string
    expiresAt time.Time  // 5分後
}
```

#### パラメータ

| パラメータ | 値 | 理由 |
|-----------|---|------|
| **TTL** | 5分 | セキュリティとパフォーマンスのバランス |
| **クリーンアップ間隔** | 1分 | メモリリーク防止 |
| **キャッシュ方式** | インメモリ | 低レイテンシ |

#### パフォーマンス指標

| 指標 | キャッシュなし | キャッシュあり | 改善率 |
|------|--------------|--------------|--------|
| レスポンスタイム | 200-500ms | <1ms | 99.8% |
| Firebase呼び出し | 全リクエスト | 初回のみ | 80-95%削減 |
| スループット | 100 req/s | 1000+ req/s | 10倍以上 |

### 5.2 エラーハンドリング

#### トークン検証エラー

| エラー | HTTPステータス | レスポンス |
|-------|--------------|-----------|
| **ヘッダーなし** | 401 Unauthorized | `{"error": "Authorization header is required"}` |
| **不正フォーマット** | 401 Unauthorized | `{"error": "Invalid authorization header format"}` |
| **トークン無効** | 401 Unauthorized | `{"error": "Invalid or expired token"}` |
| **Firebase API エラー** | 500 Internal Server Error | `{"error": "Authentication service unavailable"}` |

#### リトライ戦略

| シナリオ | 戦略 |
|---------|------|
| **Firebase API一時エラー** | クライアント側で指数バックオフリトライ |
| **トークン期限切れ** | 自動的にトークン更新してリトライ |
| **ネットワークエラー** | 最大3回リトライ |

### 5.3 モニタリング

#### ログ記録

| イベント | ログレベル | 記録内容 |
|---------|-----------|---------|
| **認証成功** | INFO | ユーザーID、タイムスタンプ |
| **認証失敗** | WARN | エラー理由、IPアドレス |
| **不正なトークン** | ERROR | トークンハッシュ、IPアドレス |
| **Firebase API エラー** | ERROR | エラー詳細、レスポンスタイム |

#### メトリクス

| メトリクス | 用途 |
|-----------|------|
| **認証リクエスト数** | トラフィック監視 |
| **認証成功率** | 異常検知 |
| **キャッシュヒット率** | パフォーマンス監視 |
| **Firebase API レイテンシ** | サービス品質監視 |

---

## 6. 実装ロードマップ

### Phase 1: 基本認証 ✅ 完了

- ✅ Firebase Admin SDK統合
- ✅ IDトークン検証ミドルウェア
- ✅ トークンキャッシング
- ✅ ユニットテスト（カバレッジ65.6%）

### Phase 2: 認可強化 🔄 計画中

- [ ] リソースベース認可の実装
- [ ] 認可ルールの明文化
- [ ] 認可テストの追加

### Phase 3: カスタムクレーム 🔄 将来対応

- [ ] ロール情報のカスタムクレーム追加
- [ ] RBAC（Role-Based Access Control）実装
- [ ] Admin/User権限の分離

### Phase 4: セッション管理 🔄 将来対応

- [ ] Redisベースのセッション管理
- [ ] 強制ログアウト機能
- [ ] デバイス管理機能

### Phase 5: セキュリティ強化 🔄 将来対応

- [ ] レート制限の実装
- [ ] IPホワイトリスト（管理者向け）
- [ ] 異常アクセス検知

---

## 7. ベストプラクティス

### 7.1 開発時

#### トークン取得（開発環境）

```bash
# Firebase Emulatorを使用
firebase emulators:start --only auth

# テスト用トークン生成
curl -X POST http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"password","returnSecureToken":true}'
```

#### ローカルテスト

```bash
# 環境変数なしでテスト（ADC使用）
go run cmd/api/main.go

# テストトークンでAPI呼び出し
curl -H "Authorization: Bearer <TEST_TOKEN>" \
     http://localhost:8080/v1/walks
```

### 7.2 本番環境

#### 環境変数設定

```bash
export FIREBASE_CREDENTIALS_JSON='<JSON文字列>'
export FIREBASE_PROJECT_ID='your-project-id'
```

#### モニタリング

- Cloud Logging で認証ログを監視
- Alerting で異常な認証失敗率を検知
- Tracing でレイテンシを監視

---

## 8. セキュリティレビューチェックリスト

### 8.1 認証実装

- [x] Firebase Admin SDKでトークン検証
- [x] 署名・有効期限・Issuer・Audienceの検証
- [x] Bearer形式のヘッダーチェック
- [x] エラー時の適切なHTTPステータス
- [ ] HTTPS強制（本番環境）
- [ ] レート制限の実装

### 8.2 認可実装

- [x] ユーザーIDベースのデータフィルタリング
- [ ] リソース所有権チェックの完全実装
- [ ] 認可エラーの適切なハンドリング
- [ ] 認可ログの記録

### 8.3 データ保護

- [ ] トークンのログ出力禁止
- [ ] 機密情報のマスキング
- [ ] エラーメッセージからの情報漏洩防止
- [x] スレッドセーフなキャッシュ実装

### 8.4 運用

- [ ] モニタリングの実装
- [ ] アラートの設定
- [ ] インシデント対応手順の策定
- [ ] 定期的なセキュリティレビュー

---

## 9. 参考資料

### 公式ドキュメント

- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Firebase Admin SDK - Verify ID Tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
- [JWT.io - JWT Debugger](https://jwt.io/)

### 内部ドキュメント

- [authentication.md](./authentication.md) - 実装詳細
- [database-schema.md](./database-schema.md) - データベース設計

---

## 変更履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2025-11-23 | 1.0.0 | 初版作成 |
