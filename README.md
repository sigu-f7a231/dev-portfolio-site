# DevPortfolio

履歴書を補うための、開発者ポートフォリオサイトです。
業務（Work）と個人開発（Private）のプロジェクト、そこで使った技術の割合を 1 ページで見られます。
Flutter Web で作った SPA で、GitHub Pages で公開しています。API サーバー（Dart / shelf）と Docker Compose での起動、テスト（網羅率 90% 以上）と CI もそろえています。

公開ページ: https://sigu-f7a231.github.io/dev-portfolio-site/

> **English summary**
> A single-page developer portfolio built with Flutter Web and hosted on GitHub Pages, designed to complement a résumé.
> It shows work and personal projects, and charts the technologies used across them.
> All content is driven by YAML / Markdown files or an Excel skill sheet: the profile (Home / About) is loaded at startup (`dart run tool/run.dart my_profile.yaml`) or in the first-run dialog, and projects can be added or replaced from the header's **Data** button (on-screen form, pasted text, or files).
> The header's **Download** button exports everything as a skill sheet in the template's Excel layout, or as a PDF that looks the same.
> The repository is split into `frontend/` (Flutter) and `backend/` (a small Dart API built with shelf + shelf_router), and `docker compose up --build` starts both (nginx serves the app and proxies `/api/`).
> Tests cover both normal and error cases with ≥ 90% line and branch coverage, enforced by GitHub Actions.

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [操作説明書](docs/manual.md) | 使い方（プロフィール・Excel・［データ］・［ダウンロード］・アップロードの流れ）、データの書き方（YAML / Markdown）、カスタマイズ |
| [設計](docs/design.md) | 構成、データの流れ、backend の API、技術スタック、現状と課題、今後の計画 |
| [ファイル構成](docs/structure.md) | ディレクトリ構成、コンポーネントごとのファイルと中身 |
| [ライブラリとスタイリング](docs/libraries-and-styling.md) | CSS・CSS フレームワークを使っていない理由、ライブラリの一覧（版・用途・ファイル）、画面ごとにどの部品・ライブラリをどう使っているか |
| [デザインシステム](docs/design-system.md) | 色・文字・角丸・余白・動きのトークン、部品の選び方、スタイル（CSS に当たるもの）を書く場所、ダークモード |
| [画面仕様書](docs/screens/README.md) | 画面の一覧（ID）と遷移図、画面ごとの項目・操作・条件・メッセージ（メイン画面・ダイアログ） |
| [UI / UX](docs/ui-ux.md) | 画面の組み立てとブレークポイント、操作の流れ、UX の決まり、状態ごとの表示、アクセシビリティ、課題 |
| [パフォーマンス](docs/performance.md) | 起動の流れ、待ち時間の設計、重い処理、配信の設定、測り方と目標（案） |
| [開発ガイド](docs/development.md) | 起動（Docker / Flutter / backend）、テスト・CI のコマンドと案内 |
| [テスト計画書](docs/testing/test-plan.md) ／ [テスト一覧](docs/testing/test-catalog.md) | テストの目的・範囲・観点・合格の基準／各テストが確かめていること |
| [CI の設計](docs/ci/ci-design.md) ／ [CI の状況](docs/ci/ci-status.md) | GitHub Actions の流れと失敗の条件／今の状態と注意点 |
| [今後の動き](docs/roadmap.md) | テスト・CI・アプリ・インフラのこれからの段階 |
| [次の構成の計画](docs/plan/README.md) | ログイン・マイページ・クラウド（Phoenix・Hono・FastAPI・Firebase、費用ゼロ）の要件定義・画面設計・データ設計・決めること |
| [更新履歴](CHANGELOG.md) | いつ・何を追加 / 変更 / 修正したか（コミットごと） |
| [backend/README.md](backend/README.md) | API サーバーの詳細 |
| [CLAUDE.md](CLAUDE.md) | AI（Claude）向けの開発メモの入口（詳細は `docs/claude/`） |

---

## できること

### 画面

| セクション | 内容 |
|---|---|
| **Home** | 名前・職種・紹介文（プロフィール YAML から）を中央に。ボタンで Skills / Projects へ移動でき、その下に開発経験（年数）・プロジェクトの件数（業務・個人開発）・直近のプロジェクトのまとめを表示します（件数を押すと Projects、直近を押すとその詳細） |
| **About** | 自己紹介と、得意な領域・直近 / 過去の開発経験と主な技術・強み・開発スタイル・締めの一言（プロフィールから。書いていない項目は表示しません） |
| **Skills** | プロジェクトで使った技術の割合を、棒グラフ／円グラフで表示します。Work / Private の切り替えと、カテゴリの選択（ポップアップ）ができます。Skills・Tools はさらにグループ（プログラミング言語・ライブラリ・バージョン管理・開発ツール・環境など）に分けて表示します |
| **Projects** | プロジェクトの一覧です。**List**（年表）と **Collection**（カバー付きカード）を切り替えられ、全分類の技術・役割・規模（人数）・工程・期間で絞り込み（ポップアップ）、開始・終了・期間の長さ・名前で並べ替えができます。カードを押すと詳細（役割・規模も）が開き、‹ › や ← → キーで前後の案件に移れます |

- **ヘッダー**：Material 3 のトップアプリバー。ナビは表示中のセクションが強調され、スクロールに合わせて切り替わります
- **ダウンロード**：ヘッダーの［ダウンロード］で、プロフィールと Work / Private をスキルシート（Excel のテンプレートの書式のまま）か、同じ見た目の PDF として「名前を付けて保存」できます。保存したかどうかは画面の下に表示します（詳しくは[操作説明書](docs/manual.md#スキルシートのダウンロードヘッダーのダウンロード)）
- **ダークモード**：ヘッダーのスイッチ（☀️ / 🌙）でライト／ダークを切り替えられます（スマホはアイコンボタン）
- **レスポンシブ**：スマホではメニューがドロワーになり、フィルターは下から出るシートで開きます。Collection は画面幅に合わせて 1〜4 列、ページネーションは幅に応じて「1 … 4 5 6 … 10」「‹ 3 / 10 ›」と省略表示になります
- **案件の詳細**：PC（幅 1024px 以上）はダイアログで開き、左右の ‹ › で前後の案件へ。タブレット・スマホは画面いっぱいで開き、文字を一回り大きく（1.15 倍）表示して、‹ › は下に置きます。前・次がないときはボタンを押せません。絞り込み・並び順のまま、ページをまたいで移れます
- **画面共有向けの表示**：詳細のヘッダーの［A−］［100%］［A＋］で文字を 100〜250% に、PC は［大きく表示］で画面いっぱいにできます（Google Meet・Teams・Slack ハドルなどで見やすく）。キーボードは − ＋ 0 F、⌘（Mac）/ Ctrl（Windows）＋ 0 で元の大きさ。開いている間はブラウザ自体の拡大・縮小は止めます
- **技術名の整理**（表示のときだけ。保存したデータは変えません）
  - 表記ゆれをまとめます：大文字・小文字・全角半角・末尾の `;` `:` `.` `/`・キャメルケース / スネークケースの違いは同じものとして扱い、正式な書き方（GitHub Actions、Node.js など）で表示します。数字の違い（Python と Python3）は別のものです。1 つのプロジェクトの中で重なっていても 1 回と数えます
  - AWS / Azure / GCP のサービスは、先頭の「AWS」などを外して同じものにまとめます（AWS Lambda と Lambda）
  - Skills や Tools に書かれたフロントエンド・バックエンドなどの技術は、本来の分類に移します（React → Frontend、Django → Backend、Docker → Container、k8s → Container Orchestration、Red Hat → Cloud など）
  - Skills・Tools は名前から推測してグループに分けます（言語・マークアップ・データ形式・アーキテクチャ・ライブラリ ／ バージョン管理・開発ツール・環境・CI/CD・プロジェクト管理・デザイン）。グラフ・フィルター・詳細・入力フォームで共通です
- **対応する最小の幅は 320px**（iPhone SE など）。それより狭い画面では、320px のレイアウトを画面幅に合わせて縮小して表示します

---

## すぐ試す

```bash
# Docker（frontend + backend）：http://localhost:8000
docker compose up --build

# Flutter で直接：自分のプロフィールを指定して起動
cd frontend
flutter pub get
dart run tool/run.dart my_profile.yaml
```

詳しい起動方法・テスト・CI は [開発ガイド](docs/development.md)、画面の使い方とデータの書き方は [操作説明書](docs/manual.md) を見てください。

---

## 現状

2026-11-06 時点で、リポジトリを `frontend/`（Flutter）と `backend/`（API）に分け、Docker Compose で両方を起動できるようにしました。テストは正常系・異常系の両方を書き、網羅率は行 96.2%・分岐 90.4%（基準 90%。GitHub Actions で確認）です。課題と今後の計画は [設計](docs/design.md#現状と課題) にまとめています。

---

## ライセンス

[CC BY-ND 4.0](LICENSE)（Creative Commons Attribution-NoDerivatives 4.0 International）
