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
    │   └── format_profile.yaml    # プロフィール（Home / About）のひな形
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
        └── upload_dialogs_test.dart           # Work / Private / 入力画面：貼り付け → 確認画面 → OK で反映、弾く YAML、閉じられない
```

`android/ ios/ macos/ linux/ windows/` は `dev_portfolio/.gitignore` で **Git 管理外**。`web/` はローディング表示を入れた `index.html` を管理するため Git に含める（CI の `flutter create . --platforms web` は既存ファイルを上書きせず、足りないファイルだけ作る）。

## 3. 画面構成

`HomePage` に Header（固定）＋ `SingleChildScrollView`（**スクロールはこの 1 本だけ**）で以下を縦に並べる:

1. **Hero（Home）** — 職種・名前・紹介文・「スキルを見る／プロジェクトを見る」ボタン＋右にプロフィールのカード（`home.card`。幅 900 以上で 2 カラム、600 未満でカード非表示）
2. **About** — 自己紹介＋「得意な領域／強み／開発スタイル」の定義リスト＋締めの一言（空の項目は出さない）
   - Home / About の中身はプロフィール YAML（`ProfileStore`）。固定の見出しは `AppTexts` の `HeroContent` / `AboutContent`
3. **Skills** — ツールバー（Work/Private セグメント・「カテゴリ」ボタン＝今のカテゴリ名・Bar/Pie 切替）→ カテゴリはポップアップ（1 つ選んで「反映」）→ グラフ（カード最大幅 800、狭いと縦並び）
4. **Projects** — ツールバー（Work/Private セグメント＋件数・フィルターボタン＋適用数バッジ・List/Collection 切替）→ フィルターはポップアップ（期間スライダー・進行中のみ・技術／工程チップ）→ 適用中フィルター → 一覧 → 詳細モーダル（`url_launcher`）
   - **List** = 年表（左に開始の年・月＋縦線と点、期間の枠＋長さの札、タグ 4 つまで）。5 件ずつ
   - **Collection** = カバー付きカード（`projectColorSeed` でタイトルから色、頭文字・期間の長さ）。1 ページ＝列数 × 行数（どちらも画面幅で決まる）
   - 状態（Work/Private・表示形式・フィルター）は `ProjectsSection` が持つ。タブ切替でフィルターはリセット
   - **詳細ダイアログ**（`showProjectDetailModal(context, p, projects: 絞り込み後の全件)`）：PC（幅 1024 以上）は最大幅 760 のダイアログで ‹ › を左右に。タブレット・スマホ（1024 未満）は M3 の Full-screen dialog のように画面いっぱいで開き、文字を `ProjectsListConfig.fullscreenTextScale`（1.15 倍）に、‹ › は下に。← → キーでも移れる。前・次がないときはボタンを押せない（薄い表示）。ページをまたいで移れ、閉じると最後に見ていた案件のページに一覧を合わせる。ヘッダーに「3 / 12」。

Header: M3 の Small top app bar。ナビ（表示中セクションにインジケーター）、Work / Private の YAML アップロード（Filled tonal）、テーマ切替（☀️/🌙 Switch、スマホは IconButton）。

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
- **プロジェクトのフィルタ**: `ProjectFilterState`（`selectedFilters`：キーは camelCase、例: `serverOS`, `backendFrameworks`／`fromYear`・`toYear`：期間（年）／`ongoingOnly`：進行中のみ）。`ProjectFilterLogic.apply` は選択した値をすべて含むか（AND、部分一致）で判定する。workflow は日本語ラベルを英語キーに変換してから照合する。
- 一覧は `periodStart` の昇順で並ぶ。

### Work / Private YAML のアップロード画面

- `sections/header/yaml_upload_dialog.dart` の `showYamlUploadDialog`（PC / スマホのヘッダーで共通。検証は `isValidProjectsYaml`）。
- 見た目と流れはプロフィール入力画面と同じ（部品は `widgets/upload_parts.dart`）：見出し＋ⓘ ／ 説明 ／ 番号付きの手順 ／ 選んだファイルの状態 ／［テンプレートを保存］［ファイルを選択］［アップロード］。
  1. 「ファイルを選択」でその場で検証。間違っていれば理由を出し、「アップロード」は押せない。
  2. 「アップロード」→ `confirmUpload` で中身（プロジェクト一覧 / プロフィールの各項目）を確認し、OK のときだけ反映。
  3. 反映中は `runReloading`：起動時と同じ全画面ローディング（M3 Circular）を最低 `AppSizes.reloadMinDuration`（5 秒）、最大 `reloadMaxDuration`（8 秒）出してから画面に戻す。
- **ファイルを保存・選択できない人向けに、テキストでも使える**（3 画面共通、`UploadSourcePanel`）：テンプレートは［保存］か［コピー］（クリップボード）、データは［ファイルを選択］か［テキストを貼り付け］（`showPasteYamlDialog`）。貼り付けたテキストもファイルと同じ検証 → 確認画面 → 反映の流れ。ボタンは本文に置き、下のボタンは［キャンセル］［アップロード］だけ。
- **テンプレートの保存ボタンは各画面に 1 か所だけ**（ⓘ の説明画面には置かない。Work / Private・プロフィールとも）。

### プロフィール YAML（Home / About、2026-11-03〜）

- ひな形：`assets/data/format_profile.yaml`（`home:` name★ / role★ / tagline★ / card、`about:` intro★ / domains / strengths / style / closing。★は必須、ほかは空なら表示しない）。
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
- 2026-11-03 時点で `flutter analyze`：指摘 0 件、`flutter test`：全件成功（オーナーの手元で確認）。2026-11-04 に追加した詳細の前後移動・全画面表示・320px 未満の縮小・テキストの貼り付けとそのテスト（`project_detail_navigation_test` / `min_width_scaler_test` / `upload_paste_test` / `upload_dialogs_test`）は**未実行**。
- 非推奨 API は置き換え済み（Flutter stable 2026-10 のソースで `@Deprecated` を照合）:
  - `dart:html` → `package:web`（`web: ^1.1.1`）。sessionStorage とイベント送信は `utils/browser/browser.dart` 経由（Web は `browser_web.dart`、flutter test は `browser_stub.dart` のメモリ実装を条件付き export で自動選択）。ファイル保存も同じく `utils/file_saver.dart`（Web は `file_saver_web.dart`、テストは `file_saver_stub.dart`）。**`dart:html` / `package:web` を直接 import しない**（`*_web.dart` だけが使う）。これでアップロード画面などもテストから開ける。
  - `Color.withOpacity` → `withValues(alpha: …)`。
  - 例外：`ProgressIndicatorThemeData.year2023` / `SliderThemeData.year2023`（`app_theme.dart`）は非推奨だが、既定値がまだ true（旧デザイン）で、M3 2024 版の見た目にする方法がこれしかないため `// ignore: deprecated_member_use` 付きで残す。既定値が false になったら消す。
- Claude の作業環境には Flutter がない。静的解析・テスト・画面での確認はオーナーの手元で行う。

### 課題：優先度 高（不具合・データの安全に関わる）
1. **画面での動作確認がまだ**：コミット `b2bd0ed` 以降の変更（レスポンシブ・M3 ヘッダー・ポップアップのフィルター・List / Collection・プロフィール入力画面・アップロードの確認画面と全画面ローディング・`tool/run.dart`）は、analyze / test は通ったが、PC 幅とスマホ幅での見た目・操作は未確認。
2. **ローカルで `flutter build web` するとプロフィールが成果物に入る**：`assets/profile/` をアセットとして宣言しているため、`profile.yaml` が残っていると `build/web/assets` に含まれる（表示はしないが個人情報）。公開用にビルドする前に消す。ビルド前に自動で消す仕組みはまだない。
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

## 9. Claude の作業メモ

- 開発者本人（オーナー）とのやり取りが前提。回答は日本語で行う。
- 大きな変更の前には、このファイルの「データフロー」と「既知の問題」を確認する。
- 変更が構成・スキーマ・既知の問題に関わるときは、このファイルも一緒に更新する。
