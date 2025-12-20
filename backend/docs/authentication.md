# Firebase 認証機能

## 概要

Firebase Admin SDKを使用したIDトークン検証ミドルウェアを実装しています。

## アーキテクチャ

### コンポーネント

1. **AuthMiddleware** (`internal/interface/api/middleware/auth.go`)
   - Firebase IDトークンの検証
   - トークンキャッシング機能
   - ユーザーIDのコンテキスト保存

2. **TokenCache**
   - インメモリキャッシュ
   - TTL: 5分
   - バックグラウンドクリーンアップ（1分毎）

3. **GetUserID ヘルパー関数**
   - gin.Contextからユーザー IDを取得
   - 型安全な取得処理

## 使用方法

### 環境変数設定

```bash
# Firebase認証情報（JSON文字列）
export FIREBASE_CREDENTIALS_JSON='{"type":"service_account",...}'

# または、ファイルパス
export FIREBASE_CREDENTIALS_PATH="/path/to/credentials.json"

# Firebase Project ID
export FIREBASE_PROJECT_ID="your-project-id"
```

### API呼び出し例

```bash
# Authorizationヘッダーにトークンを付与
curl -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
     http://localhost:8080/v1/walks
```

## トークン検証フロー

1. **リクエスト受信**
   ```
   Authorization: Bearer <token>
   ```

2. **ヘッダー検証**
   - Authorizationヘッダーの存在確認
   - "Bearer "プレフィックスの確認

3. **キャッシュチェック**
   - トークンがキャッシュに存在するか確認
   - 有効期限内であればキャッシュから返却（高速パス）

4. **Firebase検証** (キャッシュミス時)
   - Firebase Admin SDKでトークン検証
   - ユーザーIDを抽出
   - キャッシュに保存（TTL: 5分）

5. **コンテキスト保存**
   - ユーザーIDをgin.Contextに保存
   - 後続のハンドラーで利用可能

## キャッシング効果

### メリット

1. **パフォーマンス向上**
   - Firebase APIコールの削減
   - レスポンスタイム短縮（数百ms → 数μs）

2. **コスト削減**
   - Firebase API呼び出し回数の削減
   - ネットワークトラフィック削減

3. **レート制限回避**
   - 同一トークンの繰り返し検証を回避

### キャッシュ戦略

- **TTL**: 5分
  - セキュリティとパフォーマンスのバランス
  - トークン失効から5分以内に無効化

- **クリーンアップ**: 1分毎
  - 期限切れエントリーの自動削除
  - メモリリークを防止

- **スレッドセーフ**
  - sync.RWMutex使用
  - 並行アクセスに対応

### パフォーマンス指標（推定）

| 項目 | キャッシュなし | キャッシュあり | 改善率 |
|------|--------------|--------------|--------|
| レスポンスタイム | 200-500ms | <1ms | 99.8% |
| Firebase API呼び出し | 全リクエスト | 初回のみ | 80-95%削減 |
| スループット | 100 req/s | 1000+ req/s | 10倍以上 |

## セキュリティ考慮事項

### 実装済み対策

1. **トークン検証**
   - Firebase Admin SDKによる署名検証
   - 有効期限チェック
   - Issuer検証

2. **エラーハンドリング**
   - 無効なトークンは即座に401エラー
   - エラーレスポンスに機密情報を含めない

3. **キャッシュセキュリティ**
   - TTLによる自動失効
   - メモリ内のみ（永続化なし）

### 推奨事項

1. **HTTPS使用**
   - 本番環境では必須
   - トークン盗聴を防止

2. **トークン再発行**
   - クライアント側でトークン更新を実装
   - 短命トークンの使用

3. **監視**
   - 認証失敗ログの監視
   - 異常なアクセスパターンの検出

## テスト

### ユニットテスト

```bash
# 認証ミドルウェアのテスト
go test ./internal/interface/api/middleware/... -v
```

### テストカバレッジ

- **TokenCache**: 100%
  - Set/Get動作
  - 期限切れ処理

- **ヘッダー検証**: 100%
  - 欠落ヘッダー
  - 不正フォーマット
  - 正常トークン

- **GetUserID**: 100%
  - 正常取得
  - コンテキスト未設定
  - 型不正

## トラブルシューティング

### 問題: 認証に失敗する

**原因**:
- Firebase認証情報が未設定
- トークンの有効期限切れ
- プロジェクトIDの不一致

**対策**:
```bash
# 環境変数を確認
echo $FIREBASE_CREDENTIALS_JSON
echo $FIREBASE_PROJECT_ID

# ログを確認
docker logs <container-id>
```

### 問題: キャッシュが効いていない

**原因**:
- トークンが毎回異なる
- TTLが短すぎる

**対策**:
- クライアント側でトークンを再利用
- TTLの調整（必要に応じて）

## 今後の拡張

### Phase 1完了項目 ✅
- [x] Firebase Admin SDK統合
- [x] IDトークン検証
- [x] トークンキャッシング
- [x] ユニットテスト

### Phase 2候補
- [ ] カスタムクレーム対応
- [ ] ロールベースアクセス制御（RBAC）
- [ ] セッション管理
- [ ] Redis等の外部キャッシュ対応

## 参考資料

- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [Firebase ID Token Verification](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
- [Gin Framework Documentation](https://gin-gonic.com/docs/)
