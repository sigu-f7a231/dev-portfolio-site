# DevPortfolio

履歴書を補うための、開発者ポートフォリオサイトです。
業務（Work）と個人開発（Private）のプロジェクト、そこで使った技術の割合を 1 ページで見られます。
Flutter Web で作った SPA で、GitHub Pages で公開しています。

公開ページ: https://sigu-f7a231.github.io/dev-portfolio-site/

> **English summary**
> A single-page developer portfolio built with Flutter Web and hosted on GitHub Pages, designed to complement a résumé.
> It shows work and personal projects, and charts the technologies used across them.
> All content is driven by YAML files: the profile (Home / About) is loaded at startup (`dart run tool/run.dart my_profile.yaml`) or uploaded in the first-run dialog, and project data can be uploaded from the header.

---

## できること

### 画面

| セクション | 内容 |
|---|---|
| **Home** | 名前・職種・紹介文（プロフィール YAML から）。ボタンで Skills / Projects へ移動できます。右側にはプロフィールのカードを YAML 風に表示します |
| **About** | 自己紹介と、得意な領域・強み・開発スタイル・締めの一言（プロフィール YAML から。書いていない項目は表示しません） |
| **Skills** | プロジェクトで使った技術の割合を、棒グラフ／円グラフで表示します。Work / Private の切り替えと、カテゴリ（OS・DB・Backend・AWS・工程など）の選択（ポップアップ）ができます |
| **Projects** | プロジェクトの一覧です。**List**（年表：開始の年月・期間・長さ）と **Collection**（カバー付きカード）を切り替えられ、技術・工程・期間（年の範囲、進行中のみ）で絞り込めます（ポップアップ）。カードを押すと詳細が開きます |

- **ヘッダー**：Material 3 のトップアプリバー。ナビは表示中のセクションが強調され、スクロールに合わせて切り替わります
- **ダークモード**：ヘッダーのスイッチ（☀️ / 🌙）でライト／ダークを切り替えられます（スマホはアイコンボタン）
- **レスポンシブ**：スマホではメニューがドロワーになり、フィルターは下から出るシートで開きます。Collection は画面幅に合わせて 1〜4 列、ページネーションは幅に応じて「1 … 4 5 6 … 10」「‹ 3 / 10 ›」と省略表示になります

### 使い方（自分のデータで表示する）

このサイトは、**リポジトリをローカルに落として、自分の YAML を読み込んで使う**ことを想定しています。
公開ページを開くと、最初に「あなたのことを教えてください」（プロフィールの入力画面）が出ます。

#### 1. プロフィール（Home / About）

起動時に YAML を指定すると、その内容で Home と About を表示します（入力画面は出ません）。

```bash
cd dev_portfolio
dart run tool/run.dart my_profile.yaml
```

- `flutter run -d chrome my_profile.yaml` のように flutter run へ直接 YAML は渡せない（引数は起動する Dart ファイルとして扱われる）ため、このスクリプトを使います。中で `flutter run -d chrome` を実行するので、`r`（ホットリロード）などもそのまま使えます。2 つ目以降の引数は flutter run に渡します（例：`dart run tool/run.dart my_profile.yaml --release`）
- YAML を指定しない（`dart run tool/run.dart` や `flutter run -d chrome`）と、起動後に入力画面が出ます。**正しい YAML を読み込むまで閉じられません**
- 指定した YAML は `assets/profile/profile.yaml` にコピーされます。個人情報なので Git には含めません（`.gitignore` 済み）

#### 2. プロジェクト（Work / Private）

ヘッダーの 💼 Work ／ 🔒 Private ボタンから YAML ファイルを読み込むと、そのデータで Skills と Projects を表示し直します。
何も読み込まない場合は、リポジトリにある `assets/data/format_*.yaml`（サンプル）を表示します。

#### アップロード画面の流れ（プロフィール / Work / Private 共通）

1. **テンプレートを保存**：ひな形を「名前を付けて保存」（Chrome / Edge は保存ダイアログ、そのほかのブラウザは通常のダウンロード）。ⓘ で書き方の説明を開けます
2. **ファイルを選択**：`.yaml` / `.yml` だけ選べます。選んだ時点で形式を確かめ、間違っていれば理由を表示します（このときは「アップロード」を押せません）
3. **アップロード**：確認画面で中身（プロフィールの各項目 / プロジェクトの一覧）を確認し、**OK のときだけ**反映します
4. 反映中は全画面のローディングを数秒（5〜8 秒）表示し、描き直しが終わってから画面に戻ります

読み込んだデータはブラウザの **sessionStorage** にだけ保存されます。サーバーには送信されず、タブを閉じると消えます。

---

## データの書き方

### プロフィール（Home / About）

ひな形：`dev_portfolio/assets/data/format_profile.yaml`。★ は必須、それ以外は書かなければ表示しません。

```yaml
home:
  name: 山田 太郎                # ★ 名前
  role: Web / モバイルエンジニア   # ★ 職種
  tagline: |                    # ★ 紹介文
    Flutter と Dart を中心に開発しています。
  card:                         # 右側のカード（「キー: 値」か「キー: - 箇条書き」で自由に）
    stack:
      - Flutter
      - Dart
about:
  intro: |                      # ★ 自己紹介
    受託開発の会社で Web アプリの設計から実装までを担当しています。
  domains: [Web, モバイル]       # 得意な領域（タグで表示）
  strengths: チーム開発、テスト設計  # 強み
  style: コード品質を重視しています  # 開発スタイル
  closing: ユーザー視点を大切に     # 締めの一言
```

知らない項目・必須の空欄・型の違い（文章の場所に箇条書きなど）はエラーになり、読み込みません。

### プロジェクト（Work / Private）

Work 用と Private 用でファイルが分かれています。

| ファイル | 用途 |
|---|---|
| `dev_portfolio/assets/data/format_work.yaml` | 業務のプロジェクト（`workflow` が必須） |
| `dev_portfolio/assets/data/format_private.yaml` | 個人開発のプロジェクト（`workflow` は書かない） |

```yaml
projects:
  - title: プロジェクト名            # 必須
    description: 一覧に出る一言説明
    details: |
      詳細モーダルに出る説明（複数行）
    period:
      - 2024-04                      # 開始（YYYY-MM）
      - 現在                         # 終了（YYYY-MM）。進行中なら「現在」
    link: https://example.com        # なければ ""
    server_os: [Linux]
    db: [PostgreSQL]
    tools: [Git, VSCode]
    backend_frameworks: [Django]
    frontend_frameworks: [React]
    ui_frameworks: [利用なし]        # 該当しない項目は「利用なし」（集計から除外）
    testing_frameworks: [利用なし]
    cloud_platforms: [AWS]
    aws_services: [EC2, S3]
    azure_services: [利用なし]
    gcp_services: [利用なし]
    container: [Docker]
    container_orchestration: [利用なし]
    ai_services: [利用なし]
    skills: [Python, TypeScript]
    workflow:                        # Work 用のみ。担当した工程を true に
      requirements: false            # 要件定義
      basic_design: true             # 基本設計
      detailed_design: true          # 詳細設計
      implementation_unit_test: true # 実装・単体テスト
      integration_test: true         # 結合テスト
      system_test: false             # 総合テスト
      maintenance_operation: false   # 保守・運用
```

- インデントは半角スペース 2 つです（タブは使えません）
- リストは `[a, b]` の形でも、1 行に 1 つ `- a` と書く形でもかまいません
- Skills のグラフは、全プロジェクトでの各技術の出現割合です。`workflow` は true の割合を表示します

---

## 技術スタック

- **Flutter Web / Dart**（Dart SDK ^3.9.2）
- [fl_chart](https://pub.dev/packages/fl_chart)：円グラフ
- [yaml](https://pub.dev/packages/yaml)：データの読み込み
- [file_picker](https://pub.dev/packages/file_picker)：YAML ファイルの選択
- [url_launcher](https://pub.dev/packages/url_launcher)：公開ページへのリンク
- **GitHub Actions + GitHub Pages**：自動デプロイ

> ブラウザの機能（`package:web`：sessionStorage・ファイルの保存）を使っているため、**Web 専用**です。

---

## ローカルでの起動

```bash
cd dev_portfolio
flutter pub get
dart run tool/run.dart my_profile.yaml   # プロフィールを指定して起動（おすすめ）
# または
flutter run -d chrome                    # 起動後にプロフィールの入力画面が出る
```

> `web/index.html`（起動時のローディング表示など）は Git で管理しています。CI の `flutter create . --platforms web` は既存のファイルを上書きしません。

テストの実行：

```bash
flutter test   # テーマ・YAML の検証・データの読み込み順（sessionStorage はメモリで代用）
```

本番と同じ設定でビルドする場合：

```bash
flutter build web --release --base-href "/dev-portfolio-site/"
```

## デプロイ

`develop` ブランチに push すると、GitHub Actions（`.github/workflows/deploy.yml`）がビルドして GitHub Pages に公開します。
Actions の画面から手動で実行することもできます。

---

## カスタマイズ

見た目や文言は、場所を決めて 1 か所で管理しています。ウィジェットのファイルには、色・数値・文言を直接書かないルールです。

| 変えたいもの | ファイル |
|---|---|
| 名前・紹介文・About の内容 | プロフィール YAML（ひな形 `assets/data/format_profile.yaml`） |
| 画面の文言（ボタン名・メッセージなど） | `lib/constants/app_texts.dart`（`AppTexts`） |
| 色（ライト / ダーク） | `lib/theme/app_colors.dart` |
| 文字スタイル・角丸・カードなどの共通の見た目 | `lib/theme/app_styles.dart` |
| 余白・アニメーション時間などの数値 | `lib/constants/app_sizes.dart` |
| セクションごとのレイアウト（グラフの大きさ、Collection の列数など） | `lib/sections/config/` |
| 表示するプロジェクト（サンプル） | `assets/data/format_work.yaml` / `format_private.yaml` |
| 画面の固定の見出し（About の見出し名など） | `lib/constants/app_texts.dart`（`HeroContent` / `AboutContent` / `ProfileTexts`） |

## ディレクトリ構成

```
dev-portfolio-site/
├── .github/workflows/deploy.yml   # GitHub Pages への自動デプロイ
├── CLAUDE.md                      # 開発メモ（構成・データの流れ・規約・既知の課題）
└── dev_portfolio/                 # Flutter アプリ
    ├── assets/
    │   ├── data/                  # ひな形・サンプル（format_profile / format_work / format_private）
    │   └── profile/               # 起動時に指定したプロフィール（Git 管理外）
    ├── tool/run.dart              # プロフィール YAML を指定して起動するスクリプト
    ├── web/index.html             # 起動時のローディング表示
    └── lib/
        ├── main.dart
        ├── pages/                 # HomePage（全セクションを縦に並べる・入力画面を出す）
        ├── models/                # プロフィール（読み込みと検証）
        ├── sections/              # header / hero / about / skills / projects と config
        ├── theme/                 # 色・テーマ切替・共通スタイル
        ├── constants/             # 文言・数値
        ├── controllers/           # セクションへのスクロール・表示中セクション
        ├── widgets/               # 共通部品（セグメント・ポップアップ・入力画面・アップロード部品・ローディング）
        └── utils/                 # YAML ローダー・プロフィールの保持・ファイル保存など
```

---

## 現状と技術的な課題

**現状**（2026-11-03）：`flutter analyze` は指摘なし、`flutter test` は全件成功。非推奨の API（`dart:html`・`Color.withOpacity`）は置き換え済みです。

課題と今後の改善候補です（詳細は [CLAUDE.md](CLAUDE.md) の「現状と課題」）。

**優先度 高**
- **画面での動作確認**：レスポンシブ対応・ヘッダー・アップロード画面などの最近の変更は、PC 幅・スマホ幅での見た目と操作の確認がまだです
- **ローカルでビルドするとプロフィールが入る**：`assets/profile/profile.yaml` が残っていると `flutter build web` の成果物に含まれます（表示はしません）。公開用にビルドする前に消してください
- **Work / Private の検証が浅い**：`projects` と `title`・`workflow` の有無しか確かめていないため、項目の型が違うと表示が崩れる可能性があります

**優先度 中**
- **自動テストがまだ足りない**：フィルター・ページネーション・スキル集計・画面操作のテストはまだありません
- **文字列の分割処理が複数ある**：カンマ区切りの扱いがファイルによって違います
- **Projects のページを切り替えても一覧の先頭に戻らない**
- **スマホでのグラフ操作**：棒グラフの強調表示はマウスを乗せたときだけで、タップには反応しません
- **プロフィール YAML を書き換えたら起動し直しが必要**（`tool/run.dart` は起動時に 1 回読むだけ）

**優先度 低（仕様・整理）**
- **公開ページでは入力画面が出る**：プロフィールは各自がローカルで読み込む前提です
- **データはタブを閉じると消える**：アップロードした内容は sessionStorage にだけ保存しています
- **Web 専用**：ブラウザの機能（`package:web` / `dart:js_interop`）を使うため、Web 以外ではビルドできません
- **使っていないコード・定数が残っている**：古いタブ UI、旧形式のソート処理、作り直しで不要になった文言など

---

## ライセンス

[CC BY-ND 4.0](LICENSE)（Creative Commons Attribution-NoDerivatives 4.0 International）
