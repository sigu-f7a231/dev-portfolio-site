# CLAUDE.md — dev-portfolio-site

> Claude は作業開始時にまずこのファイルを読み、ここを起点にプロジェクトを把握すること。
> 構成や方針が変わったら、このファイルも更新する。

## 1. プロジェクト概要

- **目的**: 履歴書を補完する開発者ポートフォリオ（SPA）。Work（業務）/ Private（個人）プロジェクトとスキル構成を可視化する。
- **技術**: Flutter Web / Dart（SDK `^3.9.2`）、Material。
- **公開先**: GitHub Pages（`/dev-portfolio-site/` 配下）
- **リポジトリ**: `git@github.com:sigu-f7a231/dev-portfolio-site.git`
- **ブランチ**: `develop`（作業・デプロイ対象）、`main`
- **言語**: UI 文言・コメント・ドキュメントは日本語が基本。

## 2. ディレクトリ構成

```
dev-portfolio-site/
├── .github/workflows/deploy.yml   # develop への push で GitHub Pages にデプロイ
├── README.md                      # 英日併記の紹介文
└── dev_portfolio/                 # Flutter アプリ本体（コマンドはここで実行）
    ├── pubspec.yaml
    ├── assets/data/
    │   ├── format_work.yaml       # Work 用のデフォルトデータ兼フォーマット定義
    │   ├── format_private.yaml    # Private 用のデフォルトデータ兼フォーマット定義
    │   ├── format_profile.yaml    # プロフィール（Home / About）のひな形
    │   └── format_skill_sheet.xlsx # スキルシート（Excel）のひな形（入力画面の「Excel テンプレートを保存」・［ダウンロード］の書き込み先）
    ├── assets/fonts/ipagp.ttf     # PDF に埋め込む日本語フォント（IPA P ゴシック。IPA フォントライセンス v1.0、同じフォルダーに条文）
    ├── assets/profile/            # tool/run.dart がコピーするプロフィール（profile.yaml は Git 管理外）
    ├── tool/run.dart              # プロフィール YAML を指定して flutter run -d chrome する
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
    │   ├── theme/                 # ★色・テーマ・共通スタイル（§7 参照）
    │   │   ├── app_colors.dart    #   色の定義（M3：seed → ColorScheme → トークン）。Colors.xxx を書いてよい唯一の場所
    │   │   ├── app_theme.dart     #   ThemeController（切替）・ThemeData・context.colors / context.isDark
    │   │   └── app_styles.dart    #   共通スタイル（CSS 相当）：文字・角丸・カード・タグ・ボタン・グラフ文字・モーダル・ダイアログ
    │   ├── constants/             # ★ウィジェットに直接書かない値（§7 参照）
    │   │   ├── app_sizes.dart     #   余白スケール（space4〜48）・時間（Duration）・ダイアログ幅などの数値
    │   │   └── app_texts.dart     #   画面の文言すべて（AppTexts）＋ Home / About の内容（HeroContent / AboutContent）
    │   ├── widgets/               # 複数セクションで使う部品（app_segment.dart = 切替セグメント、filter_chips_section.dart = 見出し付きチップ群）
    │   ├── widgets/               # 共通部品：app_segment / app_filter_modal（ポップアップ）/ profile_setup_dialog（入力画面）/ upload_parts（手順・ファイル状態・確認画面・全画面ローディング）/ settled_reveal / app_loading_indicator
    │   └── utils/                 # YAML ローダー、profile_store、file_saver、app_ready、文字列分割、workflow 日本語化など
    └── test/
        ├── widget_test.dart                   # テーマ（ThemeController / context.colors）
        ├── profile_yaml_test.dart             # プロフィール YAML の検証（Profile.parse・テンプレートが通るか）
        ├── projects_yaml_validator_test.dart  # Work / Private YAML の検証（isValidProjectsYaml・テンプレートが通るか）
        ├── browser_storage_test.dart          # sessionStorage（メモリで代用）・Work / Private ローダー・ProfileStore
        ├── project_detail_navigation_test.dart # 詳細ダイアログの ‹ › / ← → での前後移動・全画面表示
        ├── min_width_scaler_test.dart         # 320px より狭い画面での縮小表示
        ├── upload_paste_test.dart             # テキストの貼り付け画面・テンプレートのコピー・読み込みボタン群
        ├── upload_dialogs_test.dart           # Work / Private / 入力画面：貼り付け（YAML / Markdown）→ 確認画面 → OK で反映、弾くデータ、閉じられない
        ├── data_format_test.dart              # YAML / Markdown の見分け・Markdown の変換・行番号付きのエラー
        ├── profile_bundle_test.dart           # プロフィールに Work / Private も一緒に書いたとき
        ├── skill_name_test.dart               # 技術名の表記ゆれ（末尾の記号・大文字小文字・全角）と Skills の集計
        ├── project_data_test.dart             # ［データ］：テキストの読み取り・追加・入力フォーム・画面の流れ
        ├── project_sort_test.dart             # Projects の並び替え
        ├── tech_catalog_test.dart             # Skills・Tools に書かれた技術の振り分け
        ├── skill_sheet_test.dart              # スキルシート（Excel）→ YAML：テンプレート・振り分け・エラー・YAML の書き出し
        ├── project_role_scale_test.dart       # 役割・規模（Excel からの読み分け・人数の区分・フィルター）とプロフィールの sheet
        ├── skill_sheet_writer_test.dart       # ［ダウンロード］の Excel：セルごとの中身・結合 / 入力規則 / 行・個人の項目・開発経験の文章・0 件・読み直すと同じ
        ├── skill_sheet_pdf_test.dart          # PDF：縮める倍率・ページの分け方（行の切れ目・長い行）・フッター・出力
        ├── xlsx_layout_test.dart              # Excel の見た目の読み取り（番地・列幅・行の高さ・結合・書式・余白・フッター）
        ├── download_menu_test.dart            # ［ダウンロード］のボタン・メニュー・名前を付けて保存・ローディング・知らせ・失敗
        ├── test_xlsx.dart                     # テスト用の小さな .xlsx を作る（テストではない）
        └── projects_diff_test.dart            # 上書きの確認に使う違いの判定・テンプレートがそろっているか
```

`android/ ios/ macos/ linux/ windows/` は `dev_portfolio/.gitignore` で **Git 管理外**。`web/` はローディング表示を入れた `index.html` を管理するため Git に含める（CI の `flutter create . --platforms web` は既存ファイルを上書きせず、足りないファイルだけ作る）。

## 3. 画面構成

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

## 4. データフロー（重要）

```
assets/data/format_*.yaml ─┐
                           ├─> WorkYamlLoader / PrivateYamlLoader (utils/*_yaml_loader.dart)
sessionStorage['work'|'private'] ─┘   優先順位: sessionStorage > メモリ > assets
        │
        ├─> projects/data/projects_{work,private}.dart → Project.fromMap → List<Project>
        └─> skills/data/skills_{work,private}.dart → skills_aggregator.dart → Map<カテゴリ, Map<項目, %>>
```

- **YAML のアップロード**: Header のダイアログでファイルを選択 → `_validateAgainstTemplate` で検証（`projects` 配列、各要素に `title` が必須、Work は `workflow` 必須、Private は `workflow` があると NG）→ `html.window.sessionStorage[dataType]` に保存 → `onYamlStateChanged` → `HomePage` が `ValueKey` を増やして Skills/Projects を作り直し、再読込させる。
- **スキル集計**: カテゴリごとに出現回数を数え、合計に対する % にする。`利用なし` は除外。`workflow` は true の割合（%）。
- **Skills・Tools の振り分け**（`utils/tech_catalog.dart` の `redistributeProject`）：読み込んだ Work / Private の skills / tools に書かれた、よく知られた技術（`_known`・`_languages`。表記ゆれは無視）は本来の分類へ移してから使う（React → frontend_frameworks、Django → backend_frameworks、Docker → container、tools の Python → skills、Lambda → aws_services ＋ cloud_platforms に AWS）。`Project.fromMap` と Skills の集計（`skills_{work,private}.dart` の `redistributeProjects`）の両方で行う。保存されている YAML 自体は書き換えない。移した先の「利用なし」は外し、空になった分類は「利用なし」。Excel からの振り分け（`skill_sheet.dart`）も同じ一覧（`classifyTech`）を使う。
- **Tools のグループ分け**（`tech_catalog.dart` の `ToolGroup` / `toolGroupOf`）：Tools は名前から推測して バージョン管理・エディタ / 開発ツール・環境 / ミドルウェア・CI/CD / 構成管理・プロジェクト管理 / 連絡・デザイン・その他 に分ける（よく知られた名前の一覧 `_toolNames` → なければ名前に含まれる言葉 `_toolHints` → その他）。Skills のカテゴリは `tools_vcs` などグループごと（`splitToolGroups` で数える。パネルでは「ツール」の見出しの下）、Projects のフィルターも Tools をグループごとの見出しに分ける（選んだ値は同じ `tools` のキーで絞り込む）。YAML には書かない（表示のときに推測）。
- **Skills のグループ分け**（`tech_catalog.dart` の `SkillGroup` / `skillGroupOf`）：Tools と同じく名前から推測して プログラミング言語・マークアップ / スタイルシート・データ形式 / クエリ・アーキテクチャ / 設計・ライブラリ・その他 に分ける（一覧 `_skillNames` → 版付きの言語（python3 など）→ 含まれる言葉 `_skillHints` → 小文字の `_` `-` 区切りや `○○.js` はライブラリ → その他）。Skills のカテゴリは `skills_lang` などグループごと（`splitSkillGroups`。パネルでは「スキル」の見出しの下）、Projects のフィルターも Skills をグループごとに分ける（書いたままの名前で見分ける）。
- Skills・Tools のグループ分けは、案件の詳細ダイアログ（「Skills：プログラミング言語」などの見出しごとにタグ）と、［データ］の 1 件の入力フォーム（Skills・Tools をグループごとのボタンに分け、候補もグループごと。保存するときに skills / tools に 1 つにまとめる）でも同じ。
- **技術名の表記ゆれ**（`utils/skill_name.dart`）：Skills の集計と Projects のフィルター（候補・絞り込み）では、全角→半角、前後の余分な記号（`;` `:` `.` `/` など。先頭の `.` は .NET のため残す）を外し、大文字・小文字と空白を無視して同じものにまとめる（MAC / mac / mac. / mac/、PYTHON3 / Python３ は同じ。Python と Python3 のように数字が違えば別）。キャメルケース・スネークケースの違い（`_` `-` `.` も無視）もまとめる。aws_services / azure_services / gcp_services では先頭の AWS / Amazon / Azure / GCP / Google Cloud なども無視し、外した名前で表示する（AWS Lambda / Lambda）。表示はよく知られた名前なら正式な書き方（`_officialNames`）、それ以外は大文字と小文字が混ざった書き方 → 多い書き方の順（小文字だけなら単語の頭を大文字、`_` は空白）。プロジェクト詳細のタグは書いたまま表示する。
- **プロジェクトのフィルタ**: `ProjectFilterState`（`selectedFilters`：キーは camelCase、例: `serverOS`, `backendFrameworks`／`fromYear`・`toYear`：期間（年）／`ongoingOnly`：進行中のみ）。`ProjectFilterLogic.apply` は選択した値をすべて含むか（AND、部分一致）で判定する。workflow は日本語ラベルを英語キーに変換してから照合する。
- 一覧の並びはツールバーの［並び替え］（`sections/projects/sort/project_sort.dart` の `ProjectSort`：開始が古い順（はじめ）/ 新しい順・終了が新しい順・期間が長い / 短い順・名前順）。期間が読めないものは最後、同じ値は名前順。詳細の ‹ › も同じ順。Work / Private を切り替えても並びはそのまま、変えたら 1 ページ目に戻る。
- 期間（`Project.periodStart` / `periodEnd` / `hasValidPeriod`）は文字の中の年月を順に読む（`2020-03`・`2020/3`・`2020年3月`・全角の数字も可）。終わりが読めなければ進行中ではなく開始と同じ月とみなす（進行中は「現在」/ present のときだけ）。

### Work / Private YAML のアップロード画面

- `sections/header/yaml_upload_dialog.dart` の `showYamlUploadDialog`（PC / スマホのヘッダーで共通。検証は `isValidProjectsYaml`）。
- 見た目と流れはプロフィール入力画面と同じ（部品は `widgets/upload_parts.dart`）：見出し＋ⓘ ／ 説明 ／ 番号付きの手順 ／ 選んだファイルの状態 ／［テンプレートを保存］［ファイルを選択］［アップロード］。
  1. 「ファイルを選択」でその場で検証。間違っていれば理由を出し、「アップロード」は押せない。
  2. 「アップロード」→ `confirmUpload` で中身（プロジェクト一覧 / プロフィールの各項目）を確認し、OK のときだけ反映。
  3. 反映中は `runReloading`：起動時と同じ全画面ローディング（M3 Circular）を最低 `AppSizes.reloadMinDuration`（5 秒）、最大 `reloadMaxDuration`（8 秒）出してから画面に戻す。
- **上書きの確認**（`utils/projects_diff.dart` の `diffProjects`、画面は `upload_parts.dart` の `confirmOverwrite`）：Work / Private のアップロードと、入力画面で一緒に書いた Work / Private は、確認画面の OK のあと、今表示している内容（ローダーが返すもの。サンプルも含む）と比べ、違いがあれば「上書きされます」と追加・削除・変更のタイトルを出し、［上書きしてアップロード］のときだけ反映する。比べるときはタイトル（同名は出てきた順）で対応づけ、書き方だけの違い（YAML / JSON、末尾の改行、数値と文字列、空のリンク、キーの順番、並び順）は無視する。
- **テンプレートはそろえておく**：プロフィールのテンプレートに入れた Work / Private と、単独の Work / Private のテンプレート（YAML / Markdown）は同じ内容にする（`projects_diff_test` などで確認。片方を変えたら全部そろえる）。
- **プロフィールのファイルに Work / Private も書ける**（`utils/profile_bundle.dart` の `readProfileBundle`、分け方は `data_format.dart` の `normalizeProfileBundle`）：YAML はトップの `work:` / `private:`（プロジェクトの並び、または `projects:` を持つ形）、Markdown は `# work` / `# private` の下に見出しを 1 段深くして（`##` プロジェクト、`###` details）書く。プロフィールのテンプレート（`format_profile.yaml` / `.md`）には Work / Private のテンプレートと同じ全項目のサンプルを最初から入れてある（中身が単独のテンプレートと一致することをテストで確認）。入力画面は 1 回のアップロードでプロフィール・Work・Private を反映し、`onProjectsChanged`（HomePage が Skills / Projects を作り直す）を呼ぶ。`tool/run.dart` は `assets/profile/work.yaml` / `private.yaml` に書き出し（なければ前回分を消す）、ローダーは「セッション → 起動時の指定（`ProfileStore.startupProjects`）→ メモリ → サンプル」の順に読む。Markdown のエラーの行番号は元のファイルのまま（ほかの区切りを空行にして読む）。
- **YAML と Markdown の両方に対応**（`utils/data_format.dart`。Flutter に依存しないので `tool/run.dart` からも使う）：`normalizeInput` が形式を見分け（拡張子 → なければ中身。YAML の「キー: 値」として読める・行頭に `projects:` などがある → YAML、`# 見出し` がある → Markdown）、Markdown は同じ中身の **JSON 文字列**（＝YAML として読める）に変換する。以降の検証・保存（sessionStorage）・表示は YAML と同じ処理。Markdown の書き方の誤りは `MarkdownTexts`（行番号付き）。テンプレートは `assets/data/format_*.md`（YAML 版と同じ中身になることをテストで確認）。アップロード画面のテンプレートは形式（YAML / Markdown）を切り替えて保存・コピーできる。
- **ファイルを保存・選択できない人向けに、テキストでも使える**（3 画面共通、`UploadSourcePanel`）：テンプレートは［保存］か［コピー］（クリップボード）、データは［ファイルを選択］か［テキストを貼り付け］（`showPasteYamlDialog`。クリアボタン・入力欄の × 付き）。貼り付けたテキストもファイルと同じ検証 → 確認画面 → 反映の流れ。ボタンは本文に置き、下のボタンは［キャンセル］［アップロード］だけ。
- **テンプレートの保存ボタンは各画面に 1 か所だけ**（ⓘ の説明画面には置かない。Work / Private・プロフィールとも）。

### スキルシート（Excel）からの入力（2026-11-05〜）

- 最初の入力画面で「入力方法」を選ぶ（`AppSegment`。はじめは YAML / Markdown。切り替えると選択中のファイルは取り消す）。
- Excel のとき：［Excel テンプレートを保存］（`assets/data/format_skill_sheet.xlsx` を `FileSaver.saveBytesAs` で名前を付けて保存。アセットは `loadAssetBytes`）／［Excel を選択］（`.xlsx` / `.xlsm`）→ `convertSkillSheet`（`utils/skill_sheet.dart`）が YAML（プロフィール＋work / private）を作る → `readProfileBundle` で YAML と同じく確かめる → 確認画面 → 上書きの確認 → 反映。［作った YAML を保存］で次回の起動用に保存できる。`tool/run.dart` も `.xlsx` を受け付ける。
- 読み取り（`utils/xlsx_reader.dart`）：`archive` で zip を開き `xml` で読む最小限の実装（共有文字列・インライン文字列・数式の計算結果。ふりがな `rPh` は除く。書式・結合は見ない）。
- 変換のルール（見出しの文字で探す。セル番地に依存しない）：
  - 氏名＝「氏名」の右のセル。経験＝「過去の開発経験」「直近の開発経験」を含むセル（表の見出しより上）。それぞれ「領域：説明」の行 → `about.past` / `about.recent`、「主な使用技術・開発環境：」以降の「分類：A、B」→ `about.past_tech` / `recent_tech`。
  - Excel にない Home の項目は作る：`role`＝`ExcelTexts.defaultRole`、`tagline`＝直近の「言語」、`card`＝直近の技術（`SkillSheetLimits`）、`intro`・`domains`＝経験の領域。
  - 個人の項目：「ふりがな」「性別」「年齢」「生年月日」「国籍」「配偶者」「最寄駅」「学歴」（`ExcelTexts.sheetLabels`）の右の値 → プロフィールの `sheet:`（右が次の見出しなら空。年齢は生年月日が読めないときだけ持つ）。画面には出さず、［ダウンロード］で書く。
  - 役割・規模（「役割」「規模」を含む見出しの列。`roleAndScaleOf`）：枠の中のセルを行ごとに見て、「役割：」「規模：」などの見出しがあればそれに従い、なければ人数（「10名」「5人」）や「規模」「体制」を含む行を規模（`scale`、複数行は「 / 」でつなぐ）、ほかを役割（`role`。「 / 」「・」「、」で分ける）。
  - プロジェクト＝「プロジェクト名」で始まる見出しの行（作業工程の小見出しは次の行）。「No.」の列に値がある行から次の番号の前までが 1 件。名前の列の 1 行目＝title、2 行目以降＝業務概要（description は「概要：」の 1 行目、details は全体、link は URL）。期間は最初の 2 つの年月（全角の数字・1 つのセルに「2020/03～2020/10」も可。終わりがなければ `現在`）。
  - 技術：セル内の見出し（「使用言語：」「FW・MW・ツール等：」「AI：」「AWS Service;」など。区切りは `：` `:` `；` `;`。`;` はわかる見出しのときだけ見出し扱いで、「Git; GitHub」は 2 項目。`_modeOfLabel`）で分類を切り替える（見出しの下の項目のあとの空行で元に戻る）。見出しのない項目は、`_known` の名前は各分類へ（クラウドのサービスは `cloud_platforms` にも足す）。知らない名前は使用言語の列 → `skills`、それ以外 → `tools`。「（補足）」は外す（サーバ OS・DB は残す）。空の分類は `利用なし`。
  - プロジェクト名に「プライベート」「個人開発」（`ExcelTexts.privateMarkers`）が入っていれば Private（印はタイトルから外し、workflow は書かない）。
- テンプレートの中身（氏名・経験・プロジェクト 2 件）は、プロフィール / Work / Private のテンプレートのサンプルと同じ内容にしてある（`skill_sheet_test` で、作った Work / Private が `format_work.yaml` / `format_private.yaml` と details 以外一致するかを確認）。テンプレートを変えたらそろえる。
- 作った YAML は `utils/yaml_writer.dart`（`toYaml`）で人が読める形に書く。

### ［ダウンロード］：スキルシートを Excel / PDF で保存（2026-11-05〜、`sections/header/download_menu.dart`）

- メニューで Excel / PDF を選ぶ → **先に**「名前を付けて保存」のダイアログ（`FileSaver.saveGeneratedBytesAs`。showSaveFilePicker はボタンを押した直後でないと開けないので、作る前に開く）→ 保存先が決まったら全画面ローディングで作って書き込む（`buildSkillSheetBytes`。名前は `skill_sheet_YYYYMMDD.xlsx|pdf`）→ 画面の下に SnackBar（保存した／ダウンロードした／やめた／失敗）。ダイアログが使えないブラウザ（Firefox / Safari）は作ってから通常のダウンロード。テスト用の `file_saver_stub.dart` は `make` を呼び、保存した中身を `FileSaver.lastSaved` に残す。
- 書く中身（`currentSkillSheetData`）：今のプロフィール（`ProfileStore`）の氏名と、過去・直近の開発経験（`experienceTextOf`）、今の Work と Private（`loadYamlString` → `redistributeProjects`、開始の古い順。Work が先、No. は通し番号）。
- Excel（`utils/skill_sheet_writer.dart` の `fillSkillSheet`）：テンプレートの zip の sheet XML だけを書き換え、ほかのファイル（スタイル・印刷設定など）はそのまま。
  - プロジェクトの表は見出しの文字で探し、1 件目のブロック（11〜15 行）をひな形として件数分複製する。後ろの行は行数の差だけずらし、結合・入力規則（`dataValidation` の sqref）も付け直す。表の中のハイパーリンクは外す。
  - 値はインライン文字列で書く。ブロックの最後の行は、文字が入りきらないときだけ高さを足す（`estimateTextHeight`）。日付の数式（YEAR / MONTH / DAY(TODAY())）は表示用の値を出力日にする。
  - Private は案件名に【個人開発】を付け、作業工程の ● は書かない（読み込み `convertSkillSheet` で同じ中身に戻る。`skill_sheet_writer_test` で確認）。
  - ふりがな・性別・年齢・生年月日・国籍・配偶者・最寄駅・学歴：プロフィールの `sheet`（読み込んだ Excel に書かれていたもの）をそのまま、見出しの結合の右隣に書く。ないものは空（テンプレートのサンプルは残さない）。生年月日が読めれば、生年月日と年齢はテンプレートと同じ数式（`"1990"&"年"&…`・`DATEDIF(DATE(…),TODAY(),"Y")`）にして、表示用の値は出力日で計算する（オーナーの指定、2026-11-05）。
  - 業務概要（`skillSheetSummary`）：ふつうは「概要：説明」「内容：詳細」「URL：リンク」。詳細が Excel から読み込んだもの（「概要：」の行がある＝セル全体）なら詳細をそのまま書き、見出しを重ねない。リンクが詳細にすでにあれば「URL：」を足さない（2026-11-05、URL・概要が二重になる不具合を修正）。
  - 役割・規模：枠の 2 行目の大きいセル（テンプレートの「PG」の場所）に「PL / SE」、次の行に「規模：20名」。1 行目のセルは空にする。
- PDF（`utils/skill_sheet_pdf.dart` の `skillSheetPdf`、`pdf` パッケージ）：書き込んだ Excel の列幅・行の高さ・結合・罫線・塗り・フォント・配置・折り返し・縮小・余白・水平中央・フッター（&P/&N）を `utils/xlsx_layout.dart` で読み、A4 にそのまま描く（幅が入らなければ縮小）。改ページは行の境目。フォントは `assets/fonts/ipagp.ttf`（太字は塗り＋線で表す）。
- 保存ダイアログが開けなかったとき（SecurityError など）も通常のダウンロードにする（`file_saver_web.dart`）。
- PDF では空白（半角・全角スペース・タブ）は描かずに幅だけ空ける（`isSkillSheetBlank`。IPA P ゴシックの全角スペースが「、」の形で出て、タイトルが「、Skill Sheet、」になっていた）。
- PDF の折り返しは `skillSheetWrap`：禁則処理あり（「、」「。」「）」・小さい仮名・長音は行の先頭に置かず前の行にぶら下げる。「（」「「」は行の最後に置かず次の行へ）。2026-11-05、行の先頭に「、」が来るとの指摘で追加。
- PDF の配置（縮める倍率・ページの分け方）は `SkillSheetPdfGeometry`、フッターの文字は `skillSheetFooterText` に分けてあり、テストで確かめる。
- 案件が 0 件なら、作業工程の選択肢（dataValidation）も外す（空の sqref は Excel が「修復」を出す）。

### プロフィール YAML（Home / About、2026-11-03〜）

- ひな形：`assets/data/format_profile.yaml`（`home:` name★ / role★ / tagline★ / card、`about:` intro★ / domains / strengths / style / closing。★は必須、ほかは空なら表示しない）。
- トップの `sheet:`（任意）：スキルシートだけの個人の項目（furigana / gender / age / birthday / nationality / spouse / station / education。`ExcelTexts.sheetLabels`）。画面には出さず、［ダウンロード］のスキルシートに書く。Excel から読むと入る。テンプレート（format_profile.*）にはサンプルを入れてある。
- `about:` には、ほかに recent / past（直近 / 過去の開発経験。複数行）・recent_tech / past_tech（分類 → 技術の並び）も書ける（Excel から作ると入る。About に「直近の開発経験」「過去の開発経験」の行として表示）。テンプレート（format_profile.*）には入れていない。Markdown の `## recent_tech` の下は「- キー: 値」のキーが英数字だけなので、日本語の分類名は書けない（YAML なら書ける）。
- 読み込み順（`utils/profile_store.dart` の `ProfileStore`）：
  1. `dart run tool/run.dart xxx.yaml` で起動 → スクリプトが `assets/profile/profile.yaml` にコピーし `--dart-define=PROFILE_FROM_ARG=true` を付けて `flutter run -d chrome` を実行 → アプリはこの印があるときだけそのファイルを読む。
  2. 入力画面でアップロード済み → `sessionStorage['profile']`。
  3. どちらもない → `HomePage` が最初に `showProfileSetupDialog`（`widgets/profile_setup_dialog.dart`）を出す。正しい YAML を読み込むまで閉じられない（barrierDismissible: false / PopScope）。ⓘ で書き方の説明とテンプレートの保存。
- 検証は `Profile.parse`（`models/profile.dart`）。知らないキー・必須の空・型違いはエラー（Work / Private の YAML を選んでも弾く）。
- `assets/profile/profile.yaml` は個人情報なので `.gitignore` 済み（フォルダは `.gitkeep` で保持）。
- `flutter run -d chrome xxx.yaml` のように flutter run へ直接 YAML は渡せない（引数は起動する Dart ファイル扱い）ため、`tool/run.dart` を使う。
- 注意：CI（GitHub Pages）は印なしでビルドするので、公開サイトでは入力画面が出る。

### YAML スキーマ（1 プロジェクト）

| キー | 型 | 備考 |
|---|---|---|
| title / description / details / link | String | `details` は複数行 `\|` |
| role | List<String> | 役割（PM・PL・SE・PG など）。詳細に表示、フィルター「役割」（選んだものをすべて担当） |
| scale | String | 規模（例：全体 20名（チーム 5名））。詳細に文章で表示。最初の「N名 / N人」で区分（`AppTexts.scaleBuckets`）し、フィルター「規模（人数）」（選んだ区分のどれか） |
| server_os, db, tools, backend_frameworks, frontend_frameworks, ui_frameworks, testing_frameworks, cloud_platforms, aws_services, azure_services, gcp_services, container, container_orchestration, ai_services, skills | List<String> | 該当しない場合は `- 利用なし` |
| period | `[YYYY-MM, YYYY-MM]` | 終わりに `現在` / `present` を書くと進行中扱い |
| workflow（**Work のみ**） | Map<String,bool> | requirements, basic_design, detailed_design, implementation_unit_test, integration_test, system_test, maintenance_operation |

カテゴリを追加するときに変更が必要な場所: `projects_model.dart`（フィールド・fromMap・getter）、`project_filter_state.dart`、`project_filter_logic.dart`、`skills_{work,private}.dart`、`skills_section.dart`（`_baseCategories` / `_labelOverrides`）、フィルタパネルの UI、両方の YAML。

## 5. コマンド（`dev_portfolio/` で実行）

```bash
flutter pub get
dart run tool/run.dart my_profile.yaml   # プロフィール YAML を指定して起動（Home / About の内容）
dart run tool/run.dart                   # 指定なし → 起動後に「あなたのことを教えてください」を表示
flutter run -d chrome                 # ローカルで動作確認（Web 専用。dart:html を使っているため）
flutter analyze
flutter test                          # テーマ・YAML の検証・sessionStorage / ローダー / ProfileStore
flutter build web --release --base-href "/dev-portfolio-site/"
```

web/ ディレクトリがない環境では、先に `flutter create . --platforms web` を実行する。

## 6. デプロイ

`.github/workflows/deploy.yml`: **`develop` への push**（または手動実行）→ Flutter stable 3.x → `pub get` → `flutter create . --platforms web` → `build web` → `actions/deploy-pages@v4`。
→ develop への push はそのまま本番公開になるので注意する。

## 7. コーディング規約・方針

- `flutter_lints`（デフォルトのルール）。
- **色とテーマ（lib/theme/）— Material 3 準拠**
  - `AppColors.seedColor`（ブランド色）から `ColorScheme.fromSeed` でライト/ダークを作り、各トークンは M3 のカラーロール（surface / primaryContainer / outlineVariant など）から割り当てる。ブランド色を変えるときは seed だけ変える。グラフの系列色と success だけは M3 にロールがないので固定値。
  - 文字は M3 タイプスケール（`Theme.of(context).textTheme` の display / headline / title / body / label）を土台に `AppStyles` で色を付ける。角丸は M3 シェイプスケール（`AppStyles.radiusSm`=4 / `Md`=8 / `Lg`=12 / `Xl`=16 / `Xxl`=28 / `Full`）。
  - 部品は M3 標準を使う：切替＝`SegmentedButton`（`AppSegment`）、主ボタン＝`FilledButton`、副ボタン＝`OutlinedButton` / `TextButton`、選択チップ＝`FilterChip`、適用中の条件＝`InputChip`、件数＝`Badge`、スマホのメニュー＝`NavigationDrawer`、ページ番号＝丸い `FilledButton` / `TextButton`。`ElevatedButton` は使わない。
  - 読み込み中の表示は M3 の **Progress indicator（円形・不確定）**（https://m3.material.io/components/progress-indicators/overview）。`lib/widgets/app_loading_indicator.dart`（`AppLoadingIndicator`）が Flutter 公式の `CircularProgressIndicator(year2023: false)`（最新仕様：トラックとの隙間・丸い端）を包んでいる。形が変わる M3 Expressive の Loading indicator は使わない。
  - 画面内で描画が重いもの（プロジェクト詳細ダイアログ、List/Collection の切替）は `lib/widgets/settled_reveal.dart`（`SettledReveal`）で包む：中身を裏で描き、`AppSizes.settleFrames`（6）フレーム落ち着き＋最低 0.8 秒（`AppSizes.revealMinDuration`）の間は Progress indicator を出し、0.2 秒でフェード表示。
  - 起動時（Flutter エンジン読み込み中）は `web/index.html` の SVG ＋ スクリプトで、Flutter の CircularProgressIndicator と同じ動き（1333ms で伸縮・2222ms で 1 周・fastOutSlowIn）を再現し。消すタイミングはアプリ側の合図：`main.dart` が `AppReady.preload()`（Work/Private の YAML を先読み）→ `runApp` → 描画が `AppSizes.settleFrames`（6）フレーム落ち着いたら `AppReady.notifyWhenSettled()` が `app-ready` イベントを送り、index.html は最低 1.5 秒表示＋0.3 秒待ってからフェード（合図が来なければ最初の描画から 4 秒で消す）。色は seed から作った primary / secondaryContainer / surface の近似値を CSS に直書きしているので、`AppColors.seedColor` を変えたらここも合わせる。
  - 色は `lib/theme/app_colors.dart` の `AppColors.light` / `AppColors.dark` だけで定義する。`Colors.xxx` / `Color(...)` は lib/theme/ の外に書かない。
  - ウィジェットからは `context.colors.<トークン>`、ダーク判定は `context.isDark`（`theme/app_theme.dart`）。**`isDark` を引数でウィジェットに渡して回さない。**
  - 切替は `ThemeController.instance.toggle(bool)`。`main.dart` が `ValueListenableBuilder` で MaterialApp を再構築する。
  - 何度も使う見た目（文字・角丸・カード・タグ・切替ボタン・グラフ文字・モーダル・ダイアログ・Hero / About）は `AppStyles` に置く。
  - 新しい色は `AppColors` にフィールドを追加し、light と dark の両方に値を入れる。
- **値の置き場所（ウィジェットのファイルに数値や文言を直接書かない）**
  - 画面の文言 → `lib/constants/app_texts.dart`（`AppTexts.xxx`。変数を埋め込む文言は関数、例: `AppTexts.uploadSaved(dataType)`）
  - 余白・時間・汎用サイズ → `lib/constants/app_sizes.dart`（`AppSizes.space8` / `AppSizes.scrollDuration` など）
  - セクション固有のまとまったレイアウト値（グラフ半径・カード幅・ブレークポイントなど） → `sections/config/**/*_config.dart`
  - ロジック上の数値（ページ計算の 0 / 1、% の 100 など）と YAML のキー名は対象外
- 状態管理は `setState` / `ValueNotifier` のみ（外部ライブラリは使っていない）。
- ファイルは機能ごとに分ける（logic / state / ui / views / data / models）。

### レスポンシブ（スマホ対応）の方針（2026-11-03）

- **対応する最小の幅は 320px**（`AppSizes.minSupportedWidth`）。320px で崩れないように作る。それより狭い画面は `MinWidthScaler`（`main.dart` の MaterialApp の builder）が 320px のレイアウトを画面幅に合わせて縮小する（はみ出しエラー防止。ダイアログも含む）。
- **スクロールはページ全体（HomePage の SingleChildScrollView）の 1 つだけ。** セクションに画面の高さを固定したり、内側に ListView / GridView のスクロールを作ったりしない（スマホで内側だけスクロールされ、ページが動かなくなるため）。一覧は `shrinkWrap: true` と `NeverScrollableScrollPhysics` にする。
- Projects Collection の 1 ページの件数は「列数 × 行数」で、どちらも**画面幅**で決める（`ProjectsCollectionConfig.columnsFor` / `rowsFor`）。
- ページネーションは幅に合わせて「全部表示 → 1 … 4 5 6 … 10 → ‹ 3 / 10 ›」と切り替える（`ProjectsPaginationUI`）。
- Skills のカードは最大幅 800・高さは中身なり。カード内の幅が `SkillsCardConfig.stackBreakpoint` 未満なら、グラフと凡例を縦に並べ、円グラフは幅に合わせて縮める（`PieGraph.size`）。
- ツールバー類は `Row` ではなく `Wrap` にして、狭い画面では折り返す。
- **ヘッダーは M3 の Small top app bar**（`sections/header/header_parts.dart`）：ナビは表示中のセクションに丸いインジケーター（`SectionScrollController.active` がスクロール位置から更新、Drawer も同じ値で選択表示）。テーマ切替は PC が太陽／月アイコン付き Switch、スマホがトグル式 IconButton。幅 900 未満でナビはアイコンのみ、760 未満でタイトルを隠す。Work / Private のアップロードは M3 の Filled tonal ボタン（`HeaderUploadButton`、幅 1100 以上で文字付き、それ未満とスマホはアイコンのみ）。
- **Projects のフィルター・Skills のカテゴリはポップアップで開く**（`lib/widgets/app_filter_modal.dart` の `showAppFilterModal`）：幅 600 以上は中央のダイアログ、未満は下から出るシート。パネルは見出しとフッターを固定し、本文だけスクロールする。「反映」で反映、×・キャンセル・外側タップでは変えない。
- **List と Collection は役割で見た目を分ける**：List＝年表（1 枚の面に行を並べ、左に開始の年・月と縦線＋点、説明文なし）／Collection＝カバー付きカードのギャラリー（色は `projectColorSeed` でタイトルから決める、頭文字・期間の長さ・説明 2 行）。

## 8. 現状と課題（2026-11-03 時点）

### 現状
- 2026-11-03 時点で `flutter analyze`：指摘 0 件、`flutter test`：全件成功（オーナーの手元で確認）。2026-11-04 に追加した詳細の前後移動・全画面表示・320px 未満の縮小・テキストの貼り付け・Markdown 対応とそのテスト（`project_detail_navigation_test` / `min_width_scaler_test` / `upload_paste_test` / `upload_dialogs_test` / `data_format_test`）は**未実行**。
- 非推奨 API は置き換え済み（Flutter stable 2026-10 のソースで `@Deprecated` を照合）:
  - `dart:html` → `package:web`（`web: ^1.1.1`）。sessionStorage とイベント送信は `utils/browser/browser.dart` 経由（Web は `browser_web.dart`、flutter test は `browser_stub.dart` のメモリ実装を条件付き export で自動選択）。ファイル保存も同じく `utils/file_saver.dart`（Web は `file_saver_web.dart`、テストは `file_saver_stub.dart`）。**`dart:html` / `package:web` を直接 import しない**（`*_web.dart` だけが使う）。これでアップロード画面などもテストから開ける。
  - `Color.withOpacity` → `withValues(alpha: …)`。
  - 例外：`ProgressIndicatorThemeData.year2023` / `SliderThemeData.year2023`（`app_theme.dart`）は非推奨だが、既定値がまだ true（旧デザイン）で、M3 2024 版の見た目にする方法がこれしかないため `// ignore: deprecated_member_use` 付きで残す。既定値が false になったら消す。
- Claude の作業環境には Flutter がない。静的解析・テスト・画面での確認はオーナーの手元で行う。
- 2026-11-05 に追加した役割・規模（モデル・フィルター・詳細・入力フォーム・Excel の読み書き）とプロフィールの `sheet`（`project_role_scale_test`）も **analyze / test 未実行**。
- 2026-11-05 に追加した［ダウンロード］（`download_menu.dart` / `skill_sheet_writer.dart` / `skill_sheet_pdf.dart` / `xlsx_layout.dart`・`skill_sheet_writer_test`）は **analyze / test 未実行**。
- 2026-11-05 に追加したスキルシート（Excel）の入力（`skill_sheet.dart` / `xlsx_reader.dart` / `yaml_writer.dart`・入力方法の切り替え・About の開発経験の行・`skill_sheet_test` と `upload_dialogs_test` の追加分）は **analyze / test 未実行**。変換のルールは同じ規則の Python で実際のスキルシートとテンプレートに当てて確認済み。

### 課題：優先度 高（不具合・データの安全に関わる）
1. **画面での動作確認がまだ**：コミット `b2bd0ed` 以降の変更（レスポンシブ・M3 ヘッダー・ポップアップのフィルター・List / Collection・プロフィール入力画面・アップロードの確認画面と全画面ローディング・`tool/run.dart`）は、analyze / test は通ったが、PC 幅とスマホ幅での見た目・操作は未確認。
2. **ローカルで `flutter build web` するとプロフィールが成果物に入る**：`assets/profile/` をアセットとして宣言しているため、`profile.yaml`（と一緒に指定した `work.yaml` / `private.yaml`）が残っていると `build/web/assets` に含まれる（表示はしないが個人情報）。公開用にビルドする前に消す。ビルド前に自動で消す仕組みはまだない。
3. **Work / Private の検証が浅い**（`isValidProjectsYaml`）：`projects` 配列・`title`・`workflow` の有無だけ。各項目の型（List / 文字列）や `period` の形式は見ていないので、崩れた YAML でも通って表示がおかしくなる可能性がある。プロフィール（`Profile.parse`）と同じく項目単位のエラーを出す形にしたい。

### 課題：優先度 中（使い勝手・保守性）
4. **テストがまだ足りない**：`ProjectFilterLogic`（技術・工程・期間・進行中）、ページネーションの `_visiblePages`、スキル集計（`skills_aggregator`）、`Project.fromMap`（期間の解釈・進行中）にテストがない。ウィジェットのテスト（入力画面が閉じられない、確認画面で OK のときだけ反映 など）もない。
5. **CSV 分割処理が複数ある**：`Project._split` / `ProjectFilterLogic.split` は `,` で分割、`utils/string_utils.parseToList` は `,`・`、`・空白で分割（スペースを含む値が分かれてしまう恐れ）。1 つにまとめたい。
6. **ページ移動でスクロール位置が残る**：ページ全体でスクロールするので、Projects のページを切り替えて一覧の長さが変わっても位置はそのまま（一覧の先頭へ戻す処理がない）。
7. **スマホでのグラフ操作**：棒グラフの強調は `MouseRegion` だけなのでタップに反応しない。
8. **`tool/run.dart` は起動時に 1 回コピーするだけ**：YAML を書き換えたら起動し直す必要がある（ホットリロードでは反映されない）。`dev_portfolio/` で実行する前提。
9. **全画面ローディングは時間で待っている**：アップロード後は最低 5 秒（`AppSizes.reloadMinDuration`）、最大 8 秒。描画完了を厳密に検知しているわけではない。
10. **Android で Google Drive のファイルを選べないことがある**：Android のファイル選択画面は MIME タイプで絞り込み、Drive 側の種類（`application/octet-stream` など）が `.yaml` と合わないと選べない。テキストの貼り付けで回避できる。根本的に直すなら、Android では `FileType.any` にして選んだ後に拡張子を確かめる。

### 課題：優先度 低（仕様として受け入れているもの・整理）
11. **公開ページ（GitHub Pages）では必ずプロフィールの入力画面が出る**：CI は YAML なしでビルドする。ローカルに落として使う前提なので仕様。
12. **アップロードしたデータは sessionStorage だけ**：タブを閉じると消える（仕様）。
13. **Web 専用**：`file_saver.dart`（`dart:js_interop` / `package:web`）と `main.dart` 経由のため、Web 以外ではビルドできない（テストは VM で動く）。
14. **未使用のファイル**（どこからも import されていない）：`skills/skills_tabs.dart`、`skills/models/skill_model.dart`、`skills/widgets/skills_tab_bar.dart`、`projects/project_detail_format.dart`、`projects/views/project_list/project_list_view.dart`（＋`project_list_sort.dart`）、`config/projects/projects_tab_config.dart`、`config/skills/skills_section_config.dart`、`utils/project_utils.dart`。依存パッケージの `shared_preferences` も未使用。
15. **未使用の定数・スタイル**（作り直しで使わなくなったもの。参照 0 件を確認済み）：`AppSizes.filterPanelDuration`、`AppStyles.filterPanel` / `toggle` / `toggleText`、`AppTexts.selectYamlFile` / `selectedFile` / `uploadYaml` / `workUploadNote` / `privateUploadNote` / `darkMode` / `save`、`ProfileTexts.upload`、`ProjectsListConfig.separator` / `cardPadding`、`SkillsHeaderConfig.panelMargin`、`PieChartLayout.pieInactiveBorderWidth`、ローダーの `setCustomYaml`（テストからのみ使用）。
16. `pubspec.yaml` の `description` が Flutter テンプレートのまま（`"A new Flutter project."`）。

### テストを書くときの注意
- `flutter test` は VM で動くため、ブラウザの機能は `utils/browser/browser.dart` 経由にし、検証ロジックは Web に依存しないファイルに置く（`utils/projects_yaml_validator.dart` / `models/profile.dart`）。
- MaterialApp のテーマ切り替えはアニメーションするので、テーマを変えたあとは `pumpAndSettle()` してから確かめる。
- **アセットは `utils/asset_text.dart` の `loadAssetText` で読む（rootBundle を直接使わない）**：testWidgets の仮の時間の中では rootBundle の読み込みが終わらないことがあり、テンプレートのコピーや上書きの確認（ローダーがサンプルを読む）が止まる。アセットに頼る画面を開くテストは `setUp(useFileAssets)`（`test/test_assets.dart`。ファイルをその場で読む `SynchronousFuture` に差し替え、終わったら元に戻す）を使う。先に読んでおく（キャッシュに頼る）方法では直らなかった。
- アセットを足したら `pubspec.yaml` にも書く（`data_format_test` の「アセットとして登録されている」で書き忘れを見つける）。

## 9. Claude の作業メモ

- 開発者本人（オーナー）とのやり取りが前提。回答は日本語で行う。
- 大きな変更の前には、このファイルの「データフロー」と「既知の問題」を確認する。
- 変更が構成・スキーマ・既知の問題に関わるときは、このファイルも一緒に更新する。
