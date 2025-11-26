#!/bin/bash
# Terraform初期化スクリプト

set -e

# 色付き出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 使用方法
usage() {
  echo "使用方法: $0 <environment>"
  echo "  environment: dev, staging, prod のいずれか"
  echo ""
  echo "例:"
  echo "  $0 dev"
  exit 1
}

# 引数チェック
if [ $# -ne 1 ]; then
  usage
fi

ENV=$1

# 環境の妥当性チェック
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo -e "${RED}エラー: 環境は dev, staging, prod のいずれかを指定してください${NC}"
  usage
fi

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_DIR="$TERRAFORM_ROOT/envs/$ENV"

# 環境ディレクトリの存在確認
if [ ! -d "$ENV_DIR" ]; then
  echo -e "${RED}エラー: 環境ディレクトリが存在しません: $ENV_DIR${NC}"
  exit 1
fi

echo -e "${GREEN}=== Terraform初期化 ($ENV環境) ===${NC}"
echo "ディレクトリ: $ENV_DIR"
echo ""

# terraform.tfvarsの存在確認
if [ ! -f "$ENV_DIR/terraform.tfvars" ]; then
  echo -e "${YELLOW}警告: terraform.tfvars が見つかりません${NC}"
  echo -e "${YELLOW}terraform.tfvars.example をコピーして作成してください${NC}"
  echo ""
  echo "  cd $ENV_DIR"
  echo "  cp terraform.tfvars.example terraform.tfvars"
  echo "  # terraform.tfvars を編集してプロジェクトIDを設定"
  echo ""
  exit 1
fi

# 環境ディレクトリに移動
cd "$ENV_DIR"

# Terraform初期化
echo -e "${GREEN}Terraform初期化を実行中...${NC}"
terraform init

echo ""
echo -e "${GREEN}✓ 初期化が完了しました${NC}"
echo ""
echo "次のステップ:"
echo "  1. terraform plan   # 変更内容を確認"
echo "  2. terraform apply  # 変更を適用"
