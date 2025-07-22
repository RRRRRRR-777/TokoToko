# TokoToko

TokoTokoは散歩を記録し、友人や家族と散歩体験を共有できるiOS散歩・SNSアプリです。

## Overview

TokoToko（「とことこ - おさんぽSNS」）は、「散歩」×「記録」×「共有」を組み合わせ、日常の中で見つけた小さな発見を散歩を通じて共有することをコンセプトとしたiOSアプリケーションです。

### 主要機能

- **散歩記録**: ボタンタップで開始・停止、バックグラウンド位置追跡
- **写真連携**: 散歩あたり最大10枚の写真（カメラロールから選択）、位置座標と連動
- **ルート可視化**: 散歩ルート（ポリライン）とマップ上の写真表示
- **共有システム**: 散歩完了後の自動URL生成、SNS/LINE/メール共有
- **ユーザー認証**: Firebase Authentication（メール・Googleログイン）

## Topics

### データモデル

散歩データを表現するためのコアエンティティです。

- <doc:Walk>
- <doc:MapItem>

### サービス層

アプリケーションのビジネスロジックを管理するサービスクラスです。

- ``WalkManager``
- ``LocationManager``
- ``WalkRepository``
- ``GoogleAuthService``
- ``StepCountManager``

### ログ・解析

アプリケーションの動作監視とパフォーマンス分析のためのコンポーネントです。

- ``EnhancedVibeLogger``
- ``PerformanceMetrics``
- ``AnomalyDetection``

### ビュー - 画面

アプリケーションのメイン画面を構成するSwiftUIビューです。

- ``HomeView``
- ``LoginView``
- ``SettingsView``
- ``SplashView``
- ``WalkHistoryView``

### ビュー - 共有コンポーネント

再利用可能なUIコンポーネントです。

- ``MapViewComponent``
- ``WalkControlPanel``
- ``DetailView``
- ``LoadingView``

### テスト用ヘルパー

テストとデバッグのためのユーティリティです。

- ``UITestingHelper``
- ``TestingProtocols``

## システム要件

- iOS 15.0以降
- Xcode 16.1以降
- Swift 5.0以降

## 技術スタック

- **UI フレームワーク**: SwiftUI
- **位置情報**: CoreLocation
- **マップ**: MapKit
- **バックエンド**: Firebase (Authentication, Firestore, Storage)
- **認証**: Google Sign-In

## 開発ガイド

### 継続的インテグレーション

現在、CI/CDパイプラインでの自動ドキュメント生成は実装されていませんが、将来的には以下の実装が予定されています：

- GitHub Actions による自動ドキュメント生成
- Pull Request での差分ドキュメント確認
- 静的サイトへの自動デプロイ

### ドキュメント更新

このドキュメントは段階的に拡張される予定です。各コンポーネントの詳細なAPI仕様は、対応するSwiftファイル内のコメントを参照してください。
