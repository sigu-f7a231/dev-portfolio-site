# DevPortfolio

履歴書を補うための、開発者ポートフォリオサイトです。
業務（Work）と個人開発（Private）のプロジェクト、そこで使った技術の割合を 1 ページで見られます。
Flutter Web で作った SPA で、GitHub Pages で公開しています。

公開ページ: https://sigu-f7a231.github.io/dev-portfolio-site/

> **English summary**
> A single-page developer portfolio built with Flutter Web and hosted on GitHub Pages, designed to complement a résumé.
> It shows work and personal projects, and charts the technologies used across them.
> All content is driven by YAML files; visitors can also load their own YAML in the browser to preview their data.

---

## できること

### 画面

| セクション | 内容 |
|---|---|
| **Home** | 名前・職種・紹介文。ボタンで Skills / Projects へ移動できます。右側にはプロフィールを YAML 形式で表示します |
| **About** | 自己紹介と、得意な領域・強み・開発スタイル |
| **Skills** | プロジェクトで使った技術の割合を、棒グラフ／円グラフで表示します。Work / Private の切り替えと、カテゴリ（OS・DB・Backend・AWS・工程など）の選択ができます |
| **Projects** | プロジェクトの一覧です。List / Collection 表示の切り替え、技術や工程での絞り込みができ、カードを押すと詳細が開きます |

- **ダークモード**：ヘッダーのスイッチでライト／ダークを切り替えられます
- **レスポンシブ**：スマホではメニューがドロワーになり、Collection の列数は画面幅に合わせて 1〜4 列に変わります

### 自分のデータで表示する（YAML アップロード）

ヘッダーの 💼（Work）／🔒（Private）ボタンから YAML ファイルを読み込むと、そのデータで Skills と Projects を表示し直します。

- アップロード画面からフォーマット（ひな形）を「名前を付けて保存」できます（Chrome / Edge は保存ダイアログ、そのほかのブラウザは通常のダウンロード）。ⓘ ボタンで書き方の説明を開けます
- 読み込んだデータはブラウザの **sessionStorage** にだけ保存されます。サーバーには送信されず、タブを閉じると消えます
- 何も読み込まない場合は、リポジトリにある `assets/data/format_*.yaml` を表示します

---

## データの書き方

表示内容は YAML で定義します。Work 用と Private 用でファイルが分かれています。

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

> `dart:html`（sessionStorage・ファイルのダウンロード）を使っているため、**Web 専用**です。

---

## ローカルでの起動

```bash
cd dev_portfolio
flutter pub get
flutter create . --platforms web   # web/ が無い場合のみ（web/ は Git 管理外）
flutter run -d chrome
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
| 名前・紹介文・About の内容 | `lib/constants/app_texts.dart`（`HeroContent` / `AboutContent`） |
| 画面の文言（ボタン名・メッセージなど） | `lib/constants/app_texts.dart`（`AppTexts`） |
| 色（ライト / ダーク） | `lib/theme/app_colors.dart` |
| 文字スタイル・角丸・カードなどの共通の見た目 | `lib/theme/app_styles.dart` |
| 余白・アニメーション時間などの数値 | `lib/constants/app_sizes.dart` |
| セクションごとのレイアウト（グラフの大きさ、Collection の列数など） | `lib/sections/config/` |
| 表示するプロジェクト | `assets/data/format_work.yaml` / `format_private.yaml` |

## ディレクトリ構成

```
dev-portfolio-site/
├── .github/workflows/deploy.yml   # GitHub Pages への自動デプロイ
├── CLAUDE.md                      # 開発メモ（構成・データの流れ・規約・既知の課題）
└── dev_portfolio/                 # Flutter アプリ
    ├── assets/data/               # 表示データ（YAML）
    └── lib/
        ├── main.dart
        ├── pages/                 # HomePage（全セクションを縦に並べる）
        ├── sections/              # header / hero / about / skills / projects と config
        ├── theme/                 # 色・テーマ切替・共通スタイル
        ├── constants/             # 文言・数値
        ├── widgets/               # 共通部品（切替セグメント・チップ）
        └── utils/                 # YAML ローダーなど
```

---

## ライセンス

[CC BY-ND 4.0](LICENSE)（Creative Commons Attribution-NoDerivatives 4.0 International）
