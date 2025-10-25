.PHONY: help
help: ## ヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: tools
tools: ## 開発ツールをインストール
	@echo "Installing development tools..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/cosmtrek/air@latest
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	@echo "Tools installed successfully"

.PHONY: deps
deps: ## 依存パッケージをダウンロード
	@echo "Downloading dependencies..."
	go mod download
	go mod verify
	@echo "Dependencies downloaded"

.PHONY: tidy
tidy: ## go.modを整理
	go mod tidy

.PHONY: build
build: ## バイナリをビルド
	@echo "Building binary..."
	go build -o bin/api ./cmd/api
	@echo "Build complete: bin/api"

.PHONY: run
run: ## APIサーバーを起動
	@echo "Starting API server..."
	go run ./cmd/api/main.go

.PHONY: dev
dev: ## ホットリロード付きでAPIサーバーを起動
	@echo "Starting API server with hot reload..."
	air

.PHONY: test
test: ## テストを実行
	@echo "Running tests..."
	go test -v -race ./...

.PHONY: test-coverage
test-coverage: ## カバレッジ付きテストを実行
	@echo "Running tests with coverage..."
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

.PHONY: lint
lint: ## Lintを実行
	@echo "Running linter..."
	golangci-lint run ./...

.PHONY: fmt
fmt: ## コードフォーマット
	@echo "Formatting code..."
	go fmt ./...
	gofmt -s -w .

.PHONY: clean
clean: ## ビルド成果物を削除
	@echo "Cleaning up..."
	rm -rf bin/
	rm -rf tmp/
	rm -f coverage.out coverage.html
	@echo "Clean complete"

.PHONY: docker-build
docker-build: ## Dockerイメージをビルド
	@echo "Building Docker image..."
	docker build -t tekutoko-api:latest -f deploy/docker/Dockerfile .
	@echo "Docker image built: tekutoko-api:latest"

.PHONY: docker-run
docker-run: ## Dockerコンテナを起動
	@echo "Running Docker container..."
	docker run -p 8080:8080 --env-file .env tekutoko-api:latest

# データベース関連 (TODO: Phase2で実装)
.PHONY: db-up
db-up: ## ローカルDBを起動
	@echo "TODO: docker-compose up -d postgres"

.PHONY: db-down
db-down: ## ローカルDBを停止
	@echo "TODO: docker-compose down"

.PHONY: migrate-up
migrate-up: ## マイグレーションを適用
	@echo "TODO: migrate -path migrations -database ${DATABASE_URL} up"

.PHONY: migrate-down
migrate-down: ## マイグレーションをロールバック
	@echo "TODO: migrate -path migrations -database ${DATABASE_URL} down 1"

.PHONY: migrate-create
migrate-create: ## マイグレーションファイルを作成 (使用例: make migrate-create name=create_walks_table)
	@if [ -z "$(name)" ]; then echo "Error: name is required. Usage: make migrate-create name=your_migration_name"; exit 1; fi
	@echo "TODO: migrate create -ext sql -dir migrations -seq $(name)"

.PHONY: seed
seed: ## シードデータを投入
	@echo "TODO: go run scripts/seed/main.go"
