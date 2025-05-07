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
## シミュレータ起動方法
* `make xcode-run`
    * xcodegen生成
    * ビルド
    * シミュレータの起動
* `build`のあとに`test`を加えると全体のテストも実行されます
```makefile
// Makefile
xcode-run:
	mint run xcodegen xcodegen generate
	xcodebuild \
		-scheme $(PRODUCT_NAME) \
		-destination "platform=iOS Simulator,name=$(DEVICE_NAME),OS=$(OS_VERSION)" \
		-configuration Debug \
		build

	APP_PATH=$$HOME/Library/Developer/Xcode/DerivedData/$(PRODUCT_NAME)-*/Build/Products/Debug-iphonesimulator/$(PRODUCT_NAME).app && \
	xcrun simctl boot "$(DEVICE_NAME)" || true && \
	xcrun simctl install booted $$APP_PATH && \
	xcrun simctl launch booted $(BUNDLE_ID)
```
# ERD

```mermaid

erDiagram
  User {
    string id PK
    string email
    string display_name
    string photo_url
    string auth_provider
    datetime created_at
    datetime updated_at
  }

  Walk {
    string id PK
    string user_id FK
    datetime start_time
    datetime end_time
    float total_distance
    int total_steps
    string polyline_data
    datetime created_at
    datetime updated_at
  }

  Photo {
    string id PK
    string walk_id FK
    string image_url
    float latitude
    float longitude
    datetime timestamp
    int order
    datetime created_at
    datetime updated_at
  }

  SharedLink {
    string id PK
    string walk_id FK
    string url_token
    datetime created_at
    datetime updated_at
  }

  User ||--o{ Walk : has
  Walk ||--o{ Photo : includes
  Walk ||--|| SharedLink : generates
```

- User
    - テーブル概要
        - ユーザーに関連する情報を格納するテーブル。
    - 属性
        - id (PK): ユーザーを一意に識別するID（主キー）
        - email: ユーザーのメールアドレス
        - display_name: アプリ内で表示されるユーザーの名前
        - photo_url: ユーザーのプロフィール画像URL
        - auth_provider: 認証の方法(GoogleやEmailなどの認証サービス)
- Walk
    - テーブル概要
        - 散歩記録に関する情報を格納するテーブル。ユーザーが行った散歩の詳細情報を保存する。
    - 属性
        - id (PK): 散歩の一意識別子
        - user_id (FK): 散歩を記録したユーザーのID（外部キー)
        - start_time: 散歩の開始時刻
        - end_time: 散歩の終了時刻
        - total_distance: 散歩した総距離
        - total_steps: 散歩中に歩いた総歩数
        - polyline_data: 散歩ルートを表すデータ（地図上に表示する線の情報）
- Photo
    - テーブル概要
        - ユーザーが散歩中に撮影した写真に関する情報を格納するテーブル。
    - 属性
        - id (PK): 写真の一意識別子
        - walk_id (FK): この写真が関連する散歩のID（外部キー）
        - image_url: 写真が保存されているURL
        - latitude: 写真が撮影された場所の緯度
        - longitude: 写真が撮影された場所の経度
        - timestamp: 写真が撮影された時刻
        - rder: 複数枚の写真がある場合の表示順（1～10の番号など）
- SharedLink
    - テーブル概要
        - 散歩記録を共有するためのリンク情報を格納するテーブル。これによりユーザーはリンクを生成して他の人と散歩記録を共有できる。
    - 属性
        - id (PK): 共有リンクの一意識別子
        - walk_id (FK): 共有される散歩のID（外部キー）
        - url_token: 共有リンクを一意に識別するためのトークン

# FlowChart

```mermaid
flowchart TD
    A[アプリ起動] --> B{ログイン済みか？}
    B -- はい --> C[ホーム画面へ]
    B -- いいえ --> B1[ログイン画面]
    B1 --> B1a{アカウントを持っている？}
    B1a -- はい --> B2[ログイン（Firebase Auth）]
    B1a -- いいえ --> B3[アカウント作成画面]
    B3 --> B2
    B2 --> C

    %% ホーム画面
    C --> C1[履歴タブを開く]
    C1 --> C1a[散歩一覧を表示]
    C1a --> C1b[散歩詳細を表示]
    C1b --> C1c[ルート・写真・リンク表示・コピー]

    C --> C2[設定タブを開く]
    C2 --> C2a[プロフィール・通知設定]
    C2 --> C2b[ログアウト]
    C2 --> C2c[退会（Firebase Auth削除）]

    C --> D[「新しい散歩を開始」ボタン]
    D --> E[散歩開始・位置情報記録]
    E --> F[散歩中画面表示]
    F --> F1[現在地・歩数・時間表示]
    F --> F2[写真選択（最大10枚）]
    F --> G{「散歩終了」ボタン押下}

    G --> H[散歩終了]
    H --> H1[散歩ルート表示・情報確認]
    H1 --> H2{写真を選択する？}
    H2 -- はい --> H3[写真選択（最大10枚）]
    H2 -- いいえ --> H4[スキップ]

    H3 --> I[保存処理（Firestore＋Storage）]
    H4 --> I
    I --> J[共有リンク生成（Firestore＋Hosting）]
    J --> K[完了画面（リンク表示）]
    K --> L[ホーム画面に戻る]

```

# Sequence Diagrams

## 散歩の開始〜終了〜保存〜共有までのフロー

```mermaid
sequenceDiagram
    participant User
    participant App
    participant LocationService
    participant PhotoPicker
    participant FirebaseStorage
    participant Firestore
    participant FirebaseHosting

    User ->> App: 「散歩を開始」ボタンタップ
    App ->> LocationService: 位置情報の取得開始（バックグラウンド含む）

    loop 散歩中
        User ->> App: 「写真追加」ボタンタップ（任意）
        App ->> PhotoPicker: アルバムから写真選択（最大10枚）
        PhotoPicker -->> App: 選択した写真（位置情報含む）
    end

    User ->> App: 「散歩終了」ボタンタップ
    App ->> LocationService: 位置情報の記録停止
    App ->> User: 散歩のルートと写真を表示（確認画面）

    Note right of User: 写真追加・削除を調整可能

    User ->> App: 「保存」ボタンタップ
    App ->> FirebaseStorage: 写真をアップロード
    App ->> Firestore: 散歩情報（ルート・写真メタ）を保存
    App ->> FirebaseHosting: 共有用リンク生成リクエスト
    FirebaseHosting -->> App: 共有リンク（URL）

    App ->> User: 「保存完了＋リンクコピー」画面表示

```

## ログインまたはアカウント作成のシーケンス図（Firebase Auth）

```mermaid
sequenceDiagram
    actor User
    participant App
    participant FirebaseAuth

    User ->> App: アプリ起動
    App ->> FirebaseAuth: 現在のログイン状態を確認
    FirebaseAuth -->> App: ログイン済み or 未ログイン

    alt ログイン済み
        App ->> User: ホーム画面へ遷移
    else 未ログイン
        App ->> User: ログイン画面を表示
        User ->> App: 「ログイン」または「アカウント作成」を選択

        alt ログインを選択
            User ->> App: メール＋パスワード入力してログイン
            App ->> FirebaseAuth: サインイン（email + password）
            FirebaseAuth -->> App: 成功 or エラー

            alt 成功
                App ->> User: ホーム画面へ遷移
            else エラー
                App ->> User: エラーメッセージ表示
            end

        else アカウント作成を選択
            User ->> App: メール＋パスワード入力して登録
            App ->> FirebaseAuth: ユーザー作成（email + password）
            FirebaseAuth -->> App: 成功 or エラー

            alt 成功
                App ->> User: ホーム画面へ遷移
            else エラー
                App ->> User: エラーメッセージ表示
            end
        end
    end

```

##  写真の選択と保存処理の連携（最大10枚）

```mermaid
sequenceDiagram
    actor User
    participant App
    participant PhotoPicker
    participant FirebaseStorage
    participant Firestore

    User ->> App: 「写真を選ぶ」ボタンを押す（散歩中または散歩終了後）
    App ->> PhotoPicker: アルバムを開く（最大10枚）
    PhotoPicker -->> User: 写真選択UI表示
    User ->> PhotoPicker: 写真を選択（1〜10枚）
    PhotoPicker -->> App: 選択された写真一覧（ファイル）

    loop 各写真について
        App ->> FirebaseStorage: 写真をアップロード
        FirebaseStorage -->> App: 写真のURL取得
        App ->> Firestore: URL・タイムスタンプ・緯度経度などを保存
        Firestore -->> App: 保存成功
    end

    App ->> User: 保存完了メッセージを表示

```

## 履歴の散歩詳細表示〜共有リンクの再取得

```mermaid
sequenceDiagram
    actor User
    participant App
    participant Firestore
    participant FirebaseHosting

    User ->> App: 履歴タブを開く
    App ->> Firestore: ユーザーの過去の散歩一覧を取得
    Firestore -->> App: 散歩一覧データ
    App ->> User: 散歩一覧を表示

    User ->> App: 特定の散歩をタップ
    App ->> Firestore: 該当の散歩の詳細データを取得
    Firestore -->> App: 散歩の写真・ルート・時間・歩数など
    App ->> User: 散歩詳細画面を表示

    User ->> App: 「共有リンクを表示／コピー」ボタンを押す
    App ->> Firestore: 保存されている共有リンクURLを取得
    Firestore -->> App: 共有リンクURL
    App ->> FirebaseHosting: （※裏側でホストされているページ）
    App ->> User: リンクを表示／コピー可能にするUI表示

```
