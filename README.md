# TokoToko
* 「とことこ - おさんぽSNS」のリポジトリ
* このアプリは、「日常の散歩体験を、友人や家族と手軽に共有する」ことを目的としたSNS的な機能を持つサービスです。
* ただ歩くだけの時間を“楽しい体験”に変え、その記録を共有することで、新たな発見や会話が生まれることを目指します。

# 実行方法
## xcodeproj生成方法
* `make generate-xcodeproj`
    * xcodegen生成
    * podのインストール
    * xcodeprojを開く
```makefile
// Makefile
generate-xcodeproj:
    mint run xcodegen xcodegen generate
    pod install
    make open
open:
    open ./${PRODUCT_NAME}.xcworkspace
```
## 実行にSweetPadを使用する
### SweetPadのセットアップ
* [SweetPad](https://marketplace.visualstudio.com/items?itemName=sweetpad.sweetpad)拡張機能をインストールする。
* アクティビティバーでSweetPadを選択から｢TOOLS｣を選択し、必要なツールをインストールする
    * Homebrew
    * swift-format
    * Xcodegen
    * SwiftLint
    * xcbeautify
    * xcode-build-server
### 実行する
* VSCodeの｢実行とデバッグ｣から実行するとシミュレーターが起動する
    * `launch.json`に設定が記載されている
