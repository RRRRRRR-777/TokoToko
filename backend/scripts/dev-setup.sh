#!/bin/bash

set -e

echo "🚀 TekuToko Backend 開発環境セットアップ"
echo "=========================================="

# .envファイルのチェック
if [ ! -f .env ]; then
    echo "📝 .env ファイルが見つかりません。.env.example からコピーします..."
    cp .env.example .env
    echo "✅ .env ファイルを作成しました。必要に応じて編集してください。"
fi

# Dockerがインストールされているかチェック
if ! command -v docker &> /dev/null; then
    echo "❌ Docker がインストールされていません。"
    echo "   https://docs.docker.com/get-docker/ からインストールしてください。"
    exit 1
fi

# Docker Composeがインストールされているかチェック
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose がインストールされていません。"
    exit 1
fi

# Dockerコンテナの起動
echo ""
echo "🐳 Docker コンテナを起動します..."
docker-compose up -d postgres

# PostgreSQLの起動待機
echo ""
echo "⏳ PostgreSQL の起動を待っています..."
sleep 5

# ヘルスチェック
max_attempts=30
attempt=0
until docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo "❌ PostgreSQL の起動がタイムアウトしました。"
        docker-compose logs postgres
        exit 1
    fi
    echo "   PostgreSQL起動中... (${attempt}/${max_attempts})"
    sleep 1
done

echo "✅ PostgreSQL が起動しました。"

# マイグレーションの実行（migrationファイルが存在する場合）
if [ -d "migrations" ] && [ "$(ls -A migrations)" ]; then
    echo ""
    echo "🔄 データベースマイグレーションを実行します..."
    make migrate-up || echo "⚠️  マイグレーションをスキップしました（migrate コマンドがインストールされていない可能性があります）"
fi

# 開発ツールのインストール確認
echo ""
echo "🔧 開発ツールを確認します..."
if ! command -v air &> /dev/null; then
    echo "📦 air (ホットリロードツール) をインストールします..."
    make tools
fi

echo ""
echo "=========================================="
echo "✅ セットアップ完了！"
echo ""
echo "📚 次のコマンドで開発サーバーを起動できます:"
echo "   make dev         # ホットリロード付きで起動"
echo "   make run         # 通常起動"
echo ""
echo "🐘 PostgreSQL 接続情報:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: tekutoko"
echo "   User: postgres"
echo "   Password: postgres"
echo ""
echo "🎨 pgAdmin (データベース管理UI):"
echo "   docker-compose --profile tools up -d pgadmin"
echo "   http://localhost:5050"
echo ""
echo "🛑 停止するには:"
echo "   docker-compose down"
echo "=========================================="
