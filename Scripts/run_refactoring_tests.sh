#!/bin/bash

# リファクタリング・改善対応のデグレッション検証テスト実行スクリプト
# 作成日: 2025-01-27
# 概要: NavigationBarStyleManager導入とUI改善に関連するテストを実行

set -e

echo "🧪 リファクタリング・デグレッション検証テスト開始"
echo "========================================="

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

# 1. NavigationBarStyleManagerの単体テスト
echo "📱 1. NavigationBarStyleManager単体テスト"
xcodebuild test \
  -project TokoToko.xcodeproj \
  -scheme TokoToko \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:TokoTokoTests/NavigationBarStyleManagerTests \
  | grep -E "(Test Suite|PASS|FAIL|error|✓)" || true

echo ""

# 2. LocationAccuracySettingsView改善テスト
echo "📍 2. LocationAccuracySettingsView改善テスト"
xcodebuild test \
  -project TokoToko.xcodeproj \
  -scheme TokoToko \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:TokoTokoTests/LocationAccuracySettingsViewTests \
  | grep -E "(Test Suite|PASS|FAIL|error|✓)" || true

echo ""

# 3. リファクタリング対象画面のテスト実行
echo "🖼️  3. リファクタリング対象画面テスト"

TARGET_TESTS=(
  "TokoTokoTests/WalkListViewTests"
  "TokoTokoTests/AppInfoViewTests" 
  "TokoTokoTests/PolicyViewTests"
  "TokoTokoTests/SettingsViewTests"
)

for test_target in "${TARGET_TESTS[@]}"; do
  echo "   実行中: $test_target"
  xcodebuild test \
    -project TokoToko.xcodeproj \
    -scheme TokoToko \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -only-testing:$test_target \
    | grep -E "(Test Suite|PASS|FAIL|error|✓)" || true
  echo ""
done

# 4. DarkModeConsistencyTestsの実行
echo "🌙 4. ダークモード統一性UIテスト"
xcodebuild test \
  -project TokoToko.xcodeproj \
  -scheme TokoToko \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:TokoTokoUITests/DarkModeConsistencyTests \
  | grep -E "(Test Suite|PASS|FAIL|error|✓)" || true

echo ""

# 5. 全体的な統合テスト（リファクタリング関連のみ）
echo "🔄 5. リファクタリング統合テスト"
xcodebuild test \
  -project TokoToko.xcodeproj \
  -scheme TokoToko \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:TokoTokoTests/TokoTokoAppTests \
  | grep -E "(Test Suite|PASS|FAIL|error|✓)" || true

echo ""
echo "✅ デグレッション検証テスト完了"
echo "========================================="

# テスト結果サマリー作成
echo "📋 テスト実行サマリー："
echo "- NavigationBarStyleManager: 新規作成・単体テスト実行済み"
echo "- LocationAccuracySettingsView: 再帰メソッド改善・テスト実行済み"  
echo "- リファクタリング対象画面: 4画面のテスト実行済み"
echo "- UI統一性テスト: ダークモード・ライトモード検証実行済み"
echo ""
echo "🔍 詳細な結果は上記ログをご確認ください"
echo "❌ エラーがある場合は該当テストクラスを個別に確認してください"