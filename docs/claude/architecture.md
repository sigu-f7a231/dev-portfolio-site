# 構成と画面

> ディレクトリ構成・主なファイルの役割・画面の構成。新しいファイルや画面を足したら、ここも直す。
> 画面ごとの項目・文言・動きの一覧（人向け）は `docs/screens/`（画面 ID 付き）。画面を変えたらそちらも直す。

## ディレクトリ構成

```
dev-portfolio-site/
├── .github/workflows/
│   ├── test.yml                   # push・PR ごとに analyze・テスト・網羅率（行・分岐 90% 以上）。backend のテストも
│   └── deploy.yml                 # develop への push で GitHub Pages にデプロイ
├── README.md                      # プロジェクトの紹介（人向けの詳しい説明は docs/ の manual / design / structure / development へ案内）
├── CLAUDE.md                      # Claude 向けの入口（ここから docs/claude/ を読む）
├── docs/claude/                   # 開発メモ（構成・データの流れ・規約・テスト・運用・課題）
├── compose.yaml                   # frontend（nginx :8000）と backend（:8080）を起動。docker compose up --build
├── backend/                       # API サーバー（shelf + shelf_router。Flutter に依存しない Dart）
│   ├── bin/server.dart            # 起動（PORT / DATA_DIR / ALLOWED_ORIGIN）・SIGTERM で停止・`server healthcheck`
│   ├── lib/src/app.dart           # ルーティング（/healthz・/api/profile・/api/projects/<work|private>）・エラーの JSON・CORS
│   ├── lib/src/data_store.dart    # data/*.yaml を読んで確かめる（アップロード時と同じ必須項目）。更新日時が変わったら読み直す
│   ├── lib/src/logging.dart       # 1 リクエスト 1 行の JSON ログ（severity・httpRequest。Cloud Logging 向け）
│   ├── data/                      # 返す YAML（profile / work / private。最初は frontend のひな形のコピー）
│   ├── test/app_test.dart         # dart test
│   └── Dockerfile                 # dart compile exe → scratch
└── frontend/                      # Flutter アプリ本体（コマンドはここで実行。パッケージ名は dev_portfolio のまま）
    ├── Dockerfile                 # flutter build web → nginx（nginx/default.conf.template。/api/ と /healthz を backend へ転送）
    ├── .dockerignore              # assets/profile/ の個人のプロフィールをイメージに入れない
    ├── pubspec.yaml
    ├── assets/data/
    │   ├── format_work.yaml       # Work 用のデフォルトデータ兼フォーマット定義
    │   ├── format_private.yaml    # Private 用のデフォルトデータ兼フォーマット定義
    │   ├── format_profile.yaml    # プロフィール（Home / About）のひな形
    │   └── format_skill_sheet.xlsx # スキルシート（Excel）のひな形（入力画面の「Excel テンプレートを保存」・［ダウンロード］の書き込み先）
    ├── assets/fonts/ipagp.ttf     # PDF に埋め込む日本語フォント（IPA P ゴシック。IPA フォントライセンス v1.0、同じフォルダーに条文）
    ├── assets/profile/            # tool/run.dart がコピーするプロフィール（profile.yaml は Git 管理外）
    ├── tool/run.dart              # プロフィール YAML を指定して flutter run -d chrome する
    ├── tool/coverage_check.dart   # 網羅率（行・分岐）の集計と基準の確認。--update-imports で test/all_files_loaded_test.dart を作り直す
    ├── web/index.html             # 起動時のローディング表示（Git 管理）
    ├── lib/
    │   ├── main.dart              # DevPortfolioApp（ライト/ダーク切替を保持）
    │   ├── pages/home_page.dart   # 縦スクロール 1 ページ + Drawer + Header。プロフィールがなければ入力画面を出す
    │   ├── models/profile.dart    # プロフィールのモデルと検証（Profile.parse）
    │   ├── controllers/scroll_controller.dart  # セクションへのスクロール（GlobalKey）＋表示中セクション（active）
    │   ├── sections/
    │   │   ├── header/            # header.dart（600px で desktop/mobile を切替）、header_parts.dart（ナビ・テーマ切替・アップロードボタン）、yaml_upload_dialog.dart（Work/Private のアップロード画面）
    │   │   ├── hero_section.dart  # 中身は ProfileStore から
    │   │   ├── about_section.dart # 中身は ProfileStore から
    │   │   ├── skills/            # スキル集計 + 棒/円グラフ（fl_chart）
    │   │   ├── projects/          # プロジェクト一覧・フィルタ・ページング・詳細モーダル
    │   │   └── config/            # セクション固有のレイアウト値（*_config.dart）※色・文言は置かない
    │   ├── theme/                 # ★色・テーマ・共通スタイル（conventions.md 参照）
    │   │   ├── app_colors.dart    #   色の定義（M3：seed → ColorScheme → トークン）。Colors.xxx を書いてよい唯一の場所
    │   │   ├── app_theme.dart     #   ThemeData・context.colors / context.isDark（切替は state/providers.dart の themeModeProvider）
    │   │   └── app_styles.dart    #   共通スタイル（CSS 相当）：文字・角丸・カード・タグ・ボタン・グラフ文字・モーダル・ダイアログ
    │   ├── constants/             # ★ウィジェットに直接書かない値（conventions.md 参照）
    │   │   ├── app_sizes.dart     #   余白スケール（space4〜48）・時間（Duration）・ダイアログ幅などの数値
    │   │   └── app_texts.dart     #   画面の文言すべて（AppTexts）＋ Home / About の内容（HeroContent / AboutContent）
    │   ├── widgets/               # 共通部品：app_segment / app_filter_modal（ポップアップ）/ profile_setup_dialog（入力画面）/ upload_parts（手順・ファイル状態・確認画面・全画面ローディング）/ settled_reveal / app_loading_indicator
    │   ├── data/                  # Repository（入口 PortfolioRepository・今の実装 LocalPortfolioRepository・構造のデータ records.dart）
    │   ├── state/                 # Riverpod の Provider（テーマ・Repository・データが変わった回数・プロフィール・Work / Private・Skills・Projects）
    │   ├── router/                # go_router の URL（/。ENABLE_ACCOUNT のときだけ /login・/me・/me/edit。ない URL は / へ）
    │   └── utils/                 # YAML ローダー（中身は Repository）、profile_store、file_saver / file_pick（保存・選択。テストでは差し替え）、app_ready、文字列分割、workflow 日本語化など
    └── test/                      # テスト（一覧・書き方・補助ファイルは docs/claude/testing.md）
```

`android/ ios/ macos/ linux/ windows/` は `frontend/.gitignore` で **Git 管理外**。`web/` はローディング表示を入れた `index.html` を管理するため Git に含める（CI の `flutter create . --platforms web` は既存ファイルを上書きせず、足りないファイルだけ作る）。

## 画面構成

`HomePage` に Header（固定）＋ `SingleChildScrollView`（**スクロールはこの 1 本だけ**）で以下を縦に並べる:

1. **Hero（Home）** — すべて中央寄せで、職種・名前・紹介文・「スキルを見る／プロジェクトを見る」ボタン → その下にまとめ 3 枚（開発経験＝業務のいちばん古い開始から今日まで／プロジェクトの件数＝業務・個人開発の内訳。押すと Projects へ／直近のプロジェクト＝開始がいちばん新しい案件と期間。押すとその詳細）。幅 720 以上で横に 3 つ、未満は縦に積む。計算は `utils/hero_summary.dart`（`HeroSummary.of`）。［データ］で案件を変えると `refreshKey` で作り直す。
   - 2026-11-05 に、右側の YAML 風のカード（`home.card`）は表示をやめた（Skills・Projects と同じことを書いていて「なぜここに？」となるため。オーナーの指摘）。`home.card` は今までの YAML が読めるよう、書いてもエラーにはしない（表示には使わない）
2. **About** — 自己紹介＋「得意な領域／強み／開発スタイル」の定義リスト＋締めの一言（空の項目は出さない）
   - Home / About の中身はプロフィール YAML（`ProfileStore`）。固定の見出しは `AppTexts` の `HeroContent` / `AboutContent`
3. **Skills** — ツールバー（Work/Private セグメント・「カテゴリ」ボタン＝今のカテゴリ名・Bar/Pie 切替）→ カテゴリはポップアップ（1 つ選んで「反映」）→ グラフ（カード最大幅 800、狭いと縦並び）
4. **Projects** — ツールバー（Work/Private セグメント＋件数・フィルターボタン＋適用数バッジ・［並び替え］メニュー・List/Collection 切替）→ フィルターはポップアップ（期間スライダー・進行中のみ・技術／工程チップ。技術は OS・DB・Tools・Backend・Frontend・UI・Testing・Cloud・AWS・Azure・GCP・Container・Orchestration・AI・Skills の全分類。候補のない分類は出さない）→ 適用中フィルター → 一覧 → 詳細モーダル（`url_launcher`）
   - **List** = 年表（左に開始の年・月＋縦線と点、期間の枠＋長さの札、タグ 4 つまで）。5 件ずつ
   - **Collection** = カバー付きカード（`projectColorSeed` でタイトルから色、頭文字・期間の長さ）。1 ページ＝列数 × 行数（どちらも画面幅で決まる）
   - 状態（Work/Private・表示形式・フィルター）は `ProjectsSection` が持つ。タブ切替でフィルターはリセット
   - **詳細ダイアログ**（`showProjectDetailModal(context, p, projects: 絞り込み後の全件)`）：PC（幅 1024 以上）は最大幅 760 のダイアログで ‹ › を左右に。タブレット・スマホ（1024 未満）は M3 の Full-screen dialog のように画面いっぱいで開き、文字を `ProjectsListConfig.fullscreenTextScale`（1.15 倍）に、‹ › は下に。← → キーでも移れる。前・次がないときはボタンを押せない（薄い表示）。ページをまたいで移れ、閉じると最後に見ていた案件のページに一覧を合わせる。ヘッダーに「3 / 12」。
   - **画面共有向けの表示の大きさ**（Google Meet・Teams・Slack ハドルなどで小さく見える対策）：ヘッダーに［A−］［100%］（押すと既定に戻す）［A＋］と、PC だけ［大きく表示］（PC でも全画面のレイアウトにする）。文字の倍率は `ProjectsListConfig.modalZoomLevels`（1.0〜2.5）、PC のダイアログは最大の幅・高さも同じ倍率で広げる。キーボードは − ＋ 0（文字だけ戻す）F、⌘（Mac）/ Ctrl（Windows など）＋ 0 で大きく表示も含めて元に戻す、⌘ / Ctrl ＋ ＋ −（JIS の「;」も）で拡大・縮小（修飾キーは `utils/platform_keys.dart` の `isApplePlatform` で OS に合わせる。ブラウザの拡大と同じキーなので、ダイアログを開いている間は `utils/browser/browser.dart` の `blockBrowserZoomKeys`（window の keydown を capture で受けて preventDefault。閉じると外す）でブラウザ側を止める）。［100%］ボタンも大きく表示を含めて元に戻す。選んだ大きさは `ProjectDetailView`（static）に持ち、ページを開いている間は次に開いたときも引き継ぐ（テストは `tearDown(ProjectDetailView.reset)`）。

Header: M3 の Small top app bar。ナビ（表示中セクションにインジケーター）、［データ］（Filled tonal。Work / Private の追加・更新）、［ダウンロード］（Filled tonal、スマホはアイコン。スキルシートを Excel / PDF で保存）、テーマ切替（☀️/🌙 Switch、スマホは IconButton）。

### ［データ］：プロジェクトの追加・更新（2026-11-05〜、`sections/header/project_data_dialog.dart`）

1 つのダイアログの中で順に選ぶ（上に「追加 › Work › …」、［戻る］で前へ）。反映の前には必ず確認画面を出す。
- **更新** → Work / Private → これまでのアップロード画面（`showYamlUploadDialog`。丸ごと置き換え）
- **追加** → Work / Private →
  - ファイル・貼り付けで追加 → アップロード画面を `append: true` で開く（今の一覧の後ろに足す）
- ［データ］から開いたアップロード画面には［戻る］がある（`onBack`）。押すとアップロード画面を閉じ、［データ］の画面を直前の選択（更新なら Work / Private を選ぶ画面、追加なら追加の方法を選ぶ画面）から開き直す（`_Resume`）。
  - 画面上で入力 → 1 件（入力フォーム `project_form.dart` ／ テキスト・ファイル）
    - 入力フォームの期間（開始・終了）は、欄を押すと `widgets/year_month_picker.dart` の `showYearMonthPicker`（M3 の日付選択と同じ見た目で年と月だけ。‹ › で年、年の部分で年の一覧（12 年ずつ・‹ › で前後の 12 年。スクロールしない）、12 か月のボタン、［キャンセル］［OK］）が開く。直接は打たない（× で消せる）。終了は開始より前、開始は終了より後を選べない。欄には「2024年4月」と出し、保存は「2024-04」。
    - 入力フォームの技術は、項目ごとの小さなボタン（フィルターのボタンと同じ見た目。入れた数をバッジで表示）を並べ、下に「項目：A, B」の一覧を出す。押すと `TagPickerPanel`（`showAppFilterModal`。PC はダイアログ、スマホは下からのシート）が開き、入力欄と、すでにある項目の一覧（FilterChip。押すと追加・もう一度で外す）から入れる。閉じたら打ちかけの文字もタグにする（`commitPending`）。
    - 技術の入力欄はタグ入力（`widgets/tag_input_field.dart` の `TagInputField` / `TagInputController`）：途中まで打つと今の Work / Private にある項目が入力欄の下に候補のチップで出る（Flutter の RawAutocomplete は、選んだあとに入力欄を空にすると次から候補が出なくなるので使わない）（`project_append.dart` の `tagSuggestions`。表記ゆれは 1 つ、AWS などは先頭を外す。↑↓・Enter でも選べる）。カンマ（, 、 ，）か Enter で区切るとそれより前が 1 つのタグ（日本語入力の変換中は区切らない）。空の欄で Backspace 1 回目で直前のタグを強調、2 回目で消す（タグの × でも消せる）。欄から離れたとき・保存のときは打ちかけの文字もタグにする。同じもの（表記ゆれ含む）は 2 つ入らない。か、複数件（テキスト・ファイル → 全部追加 / 選んだものだけ）
- テキストから追加する画面（1 件のテキスト・複数件）は、アップロード画面と同じ `UploadSourcePanel`（テンプレートの形式・保存・コピー、ファイルを選択、テキストを貼り付け）と ⓘ（`showYamlFormatHelp`。入力フォームにも）を持つ。［サンプルを入力欄に入れる］でサンプルをそのまま入力欄に入れて書き換えられる（1 件はテンプレート `format_*`、複数件は 3 件入った `assets/data/sample_{work,private}_multi.{yaml,md}`。1 件目はテンプレートと同じ内容で、YAML と Markdown も同じ中身にそろえる。`project_data_test` で確認）。
- テキストの読み取りは `utils/project_append.dart` の `readProjectsInput`（`projects:` の下・トップの並び・1 件だけ、Markdown も可。何件目かを付けてエラー）。足すのは `appendProjects`。
- 追加の確認と保存は `project_add_confirm.dart` の `confirmAndAppendProjects`：今の件数・追加するもの・同じ名前の注意。今サンプルを表示中なら「サンプルを外す」（はじめは外す）。OK → 全画面ローディング → セッションに保存 → Skills / Projects を作り直す。
