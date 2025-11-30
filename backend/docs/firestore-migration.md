# Firestore → PostgreSQL 移行スクリプト

FirestoreからPostgreSQLへのデータ移行ツール。

## 移行対象

| Firestore | PostgreSQL |
|-----------|------------|
| Firebase Auth | users |
| walks/ | walks |
| location_data | walk_locations |
| consents/ | consents |

## 使い方

```bash
# ドライラン（データ数確認）
make migrate-firestore-dry

# 移行実行
make migrate-firestore

# 特定のデータのみ
go run ./cmd/migrate-firestore/main.go -auth=false -walks=true
```

## 環境変数

```bash
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=tekutoko

FIREBASE_CREDENTIALS_PATH=/path/to/credentials.json
```
