## TokoToko
* 「てくとこ - おさんぽSNS」のリポジトリ
* このアプリは、「日常の散歩体験を、友人や家族と手軽に共有する」ことを目的としたSNS的な機能を持つサービスです。
* ただ歩くだけの時間を"楽しい体験"に変え、その記録を共有することで、新たな発見や会話が生まれることを目指します。


## ドキュメント
### 📚 [**APIドキュメント**](https://rrrrrrr-777.github.io/TekuToko/documentation/tekutoko/)
> **全SwiftファイルのAPI仕様書をWebサイト形式で確認できます**  
> Apple公式DocCによる美しいドキュメントサイト


**詳細情報**:
* 全Swiftファイルの日本語DocCコメントを自動生成
* GitHub Actionsで自動更新（Swift 6 + Xcode 16対応）
* 主要コンポーネント: [Walk](https://rrrrrrr-777.github.io/TekuToko/documentation/tekutoko/walk/), [WalkManager](https://rrrrrrr-777.github.io/TekuToko/documentation/tekutoko/walkmanager/), [LocationManager](https://rrrrrrr-777.github.io/TekuToko/documentation/tekutoko/locationmanager/)

### 📖 技術ドキュメント
* **[TokoTokoDocs](https://github.com/RRRRRRR-777/TokoTokoDocs)** - 設計・仕様・議事録などの技術ドキュメント管理リポジトリ

## 実行方法
### `brew`コマンドをインストールする
> https://brew.sh/ja/
### `xcodegen`コマンドのインストール
```sh
brew install xcodegen
```

### `xcodeproj`ファイルを生成する
```sh
xcodegen generate
```

### 実行にSweetPadを使用する
#### SweetPadのセットアップ
* [SweetPad](https://marketplace.visualstudio.com/items?itemName=sweetpad.sweetpad)拡張機能をインストールする。
* アクティビティバーでSweetPadを選択から｢TOOLS｣を選択し、必要なツールをインストールする
    * SwiftLint
    * xcbeautify
    * xcode-build-server
#### 実行する
* VSCodeの｢実行とデバッグ｣から実行するとシミュレーターが起動する
    * `launch.json`に設定が記載されている

## ブランチ運用
* main
    * 運用するブランチ
* dev-* (ex. dev-1.0.0)
    * 開発用ブランチ
* ticket/* (ex.ticket/1)
    * 機能開発用ブランチ

## アプリバージョンの運用
* メジャーバージョン（a, X）
    * ユーザーにとって大きな追加や変更、があるリリースの場合に1つ上げる
* マイナーバージョン(b, X.X)
    * ユーザーにとって大きくはないが追加や変更、があるリリースの場合に1つ上げる
* マイナーマイナーバージョン(c, X.X.X)
    * 障害時のパッチ修正や軽微な修正、があるリリースの場合に1つ上げる
* マイナーマイナーマイナーバージョン(d, X.X.X.X)
    * 現状なし
