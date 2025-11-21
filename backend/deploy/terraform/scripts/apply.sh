#!/bin/bash
# Terraform適用スクリプト

set -e

# 色付き出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 使用方法
usage() {
  echo "使用方法: $0 <environment> [options]"
  echo "  environment: dev, staging, prod のいずれか"
  echo "  options:"
  echo "    --auto-approve  確認なしで自動適用（本番環境では非推奨）"
  echo ""
  echo "例:"
  echo "  $0 dev"
  echo "  $0 staging --auto-approve"
  exit 1
}

# 引数チェック
if [ $# -lt 1 ]; then
  usage
fi

ENV=$1
AUTO_APPROVE=""

# オプション解析
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --auto-approve)
      AUTO_APPROVE="-auto-approve"
      shift
      ;;
    *)
      echo -e "${RED}エラー: 不明なオプション: $1${NC}"
      usage
      ;;
  esac
done

# 環境の妥当性チェック
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo -e "${RED}エラー: 環境は dev, staging, prod のいずれかを指定してください${NC}"
  usage
fi

# 本番環境での自動承認警告
if [ "$ENV" = "prod" ] && [ -n "$AUTO_APPROVE" ]; then
  echo -e "${RED}警告: 本番環境で --auto-approve は推奨されません${NC}"
  read -p "続行しますか? (yes/no): " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo "キャンセルしました"
    exit 0
  fi
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

echo -e "${GREEN}=== Terraform適用 ($ENV環境) ===${NC}"
echo "ディレクトリ: $ENV_DIR"
echo ""

# 環境ディレクトリに移動
cd "$ENV_DIR"

# Terraform Plan実行
echo -e "${GREEN}変更内容を確認中...${NC}"
terraform plan

echo ""
echo -e "${YELLOW}=== 上記の変更を適用します ===${NC}"
echo ""

# Terraform Apply実行
if [ -n "$AUTO_APPROVE" ]; then
  echo -e "${GREEN}自動適用モードで実行中...${NC}"
  terraform apply $AUTO_APPROVE
else
  terraform apply
fi

echo ""
echo -e "${GREEN}✓ 適用が完了しました${NC}"
