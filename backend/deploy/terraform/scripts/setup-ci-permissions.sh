#!/bin/bash

# Terraform CI用のGCP権限設定スクリプト
# Usage: ./setup-ci-permissions.sh

set -e

PROJECT_ID="${GCP_PROJECT_ID:-tokotoko-ea308}"
SERVICE_ACCOUNT="${GCP_SERVICE_ACCOUNT_DEV:-terraform-ci@${PROJECT_ID}.iam.gserviceaccount.com}"
STATE_BUCKET="tokotoko-terraform-state"

echo "🔧 Setting up Terraform CI permissions..."
echo "Project ID: ${PROJECT_ID}"
echo "Service Account: ${SERVICE_ACCOUNT}"
echo "State Bucket: ${STATE_BUCKET}"

# 1. GCSバケットへの読み取り権限を付与
echo ""
echo "📦 Granting Storage Object Viewer role to service account..."
gcloud storage buckets add-iam-policy-binding "gs://${STATE_BUCKET}" \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/storage.objectViewer" \
  --project="${PROJECT_ID}"

# 2. プロジェクトレベルの閲覧権限（Terraform planに必要）
echo ""
echo "👁️  Granting Viewer role at project level..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/viewer"

# 3. 権限確認
echo ""
echo "✅ Permissions granted successfully!"
echo ""
echo "📋 Verifying bucket IAM policy..."
gcloud storage buckets get-iam-policy "gs://${STATE_BUCKET}" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${SERVICE_ACCOUNT}"

echo ""
echo "📋 Verifying project IAM policy..."
gcloud projects get-iam-policy "${PROJECT_ID}" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${SERVICE_ACCOUNT}" \
  --format="table(bindings.role)"

echo ""
echo "🎉 Setup completed!"
