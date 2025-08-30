#!/bin/bash

echo "🧪 リファクタリング検証テスト実行開始"
echo "============================================"

# 1. NavigationBarStyleManagerの単体テスト
echo "📱 NavigationBarStyleManagerのテスト実行中..."
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:TokoTokoTests/NavigationBarStyleManagerTests 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ NavigationBarStyleManagerのテスト: 成功"
else
    echo "❌ NavigationBarStyleManagerのテスト: 失敗"
fi

# 2. LocationAccuracySettingsViewのテスト
echo "📱 LocationAccuracySettingsViewのテスト実行中..."
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:TokoTokoTests/LocationAccuracySettingsViewTests 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ LocationAccuracySettingsViewのテスト: 成功"
else
    echo "❌ LocationAccuracySettingsViewのテスト: 失敗"
fi

# 3. ダークモード一貫性のUIテスト
echo "📱 ダークモード一貫性のUIテスト実行中..."
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:TokoTokoUITests/DarkModeConsistencyTests 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ ダークモード一貫性のUIテスト: 成功"
else
    echo "❌ ダークモード一貫性のUIテスト: 失敗"
fi

# 4. 既存のNavigation Barテスト（デグレチェック）
echo "📱 既存Navigation Barテスト実行中..."
xcodebuild test -project TokoToko.xcodeproj -scheme TokoToko -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:TokoTokoTests/NavigationBarStyleManagerTests 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ 既存Navigation Barテスト: 成功"
else
    echo "❌ 既存Navigation Barテスト: 失敗"
fi

echo "============================================"
echo "🎯 リファクタリング検証テスト完了"
echo ""
echo "手動検証が必要な項目については MANUAL_VERIFICATION_CHECKLIST.md を確認してください。"