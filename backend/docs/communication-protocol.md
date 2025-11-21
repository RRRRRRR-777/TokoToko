# 通信プロトコル決定書（REST vs gRPC）

## 決定事項

**採用プロトコル**: REST API (HTTP/1.1 + JSON)

**Goフレームワーク**: Chi router

## 決定理由

### 1. モバイルクライアント適性 ✅
- **REST優位**:
  - iOSの`URLSession`や`Alamofire`で標準的に扱える
  - オフラインキャッシュとの連携実績が豊富
  - デバッグ・トラブルシューティングが容易
- **gRPCの課題**:
  - Swift gRPCは証明書管理・チャネル再接続の理解が必要
  - オフライン対応との統合が複雑化

### 2. レイテンシ・スループット ✅
- **500ms目標・500同時接続規模ではRESTで十分**
- gRPCのHTTP/2+バイナリによる遅延削減（数十ms）は、モバイル高RTT環境では効果が限定的
- 現在の要件ではRESTのオーバーヘッドは問題にならない

### 3. 開発・運用コスト ✅
- **REST優位**:
  - OpenAPI仕様書からモック・ドキュメント自動生成が標準化
  - `curl`等でのデバッグが容易
  - チーム学習コストが低い
- **gRPCの課題**:
  - IDL管理・コード生成の複雑性
  - バイナリペイロードの可視化が困難

### 4. 将来拡張性 🤔
- **リアルタイム位置共有**: 将来追加の可能性あり
  - gRPC: 双方向ストリーミングで有利
  - REST: WebSocket/SSEで実現可能
  - **判断**: 必要になった時点でWebSocket追加で対応可能

### 5. インフラ互換性 ✅
- **Cloud Run / GKE**: 両方対応
- **REST優位**: 既定のロードバランサーでそのまま利用可能
- **gRPCの課題**: Cloud Endpoints/API GatewayでHTTP/2透過設定が必要

## Chi routerを選択した理由

| フレームワーク | メリット | デメリット |
|--------------|---------|----------|
| **Chi** ✅ | 軽量、柔軟なミドルウェア構築、標準ライブラリ親和性高 | プラグインエコシステムは小規模 |
| Gin | 高性能、豊富なプラグイン | やや重厚、独自APIに慣れが必要 |
| Echo | バッテリー同梱型 | API設計思想の好みが分かれる |
| net/http | 標準ライブラリのみ | ルーティング・ミドルウェアを自前実装 |

**選定基準**:
- 学習目的での柔軟性（ミドルウェア構築を理解したい）
- 標準ライブラリとの親和性（net/httpベース）
- 軽量でシンプル（過剰な機能は不要）

## API設計方針

### エンドポイント命名規則
- ベースURL: `https://api.tekutoko.app/v1`
- リソース指向: `/v1/walks`
- HTTPメソッド: GET（取得）, POST（作成）, PATCH（部分更新）, DELETE（削除）

### レスポンス形式
```json
{
  "data": { ... },
  "meta": {
    "request_id": "uuid",
    "timestamp": "2025-10-20T13:45:00Z"
  }
}
```

### エラーレスポンス
```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Walk ID is required",
    "details": { ... }
  },
  "meta": {
    "request_id": "uuid",
    "timestamp": "2025-10-20T13:45:00Z"
  }
}
```

### 認証
- ヘッダー: `Authorization: Bearer <firebase_id_token>`
- ミドルウェアでFirebase Admin SDKによるトークン検証

### ページネーション
- クエリパラメータ: `?limit=20&offset=0`
- レスポンスに`meta.pagination`を含む

## 将来的な拡張検討

### リアルタイム機能が必要になった場合
1. **WebSocket追加**: `/v1/ws/live-location`
   - RESTと併用可能
   - Chiのミドルウェアで実装可能
2. **Server-Sent Events (SSE)**: 単方向ストリーミングに有効
3. **gRPC移行**: 双方向ストリーミングが中心になる場合に再検討

### gRPC併用パターン（Phase6以降で検討）
- 内部マイクロサービス間通信でgRPC
- 外部API（モバイル）はRESTを維持
- API GatewayでREST→gRPC変換

## 関連ドキュメント
- [要件定義書](./requirements.md)
- [API設計書](./api-spec.yaml)（次ステップで作成）
