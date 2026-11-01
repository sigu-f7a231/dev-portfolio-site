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
    │   └── format_private.yaml    # Private 用のデフォルトデータ兼フォーマット定義
    ├── lib/
    │   ├── main.dart              # DevPortfolioApp（ライト/ダーク切替を保持）
    │   ├── pages/home_page.dart   # 縦スクロール 1 ページ + Drawer + Header
    │   ├── controllers/scroll_controller.dart  # セクションへのスクロール（GlobalKey）
    │   ├── sections/
    │   │   ├── header/            # header.dart（600px で desktop/mobile を切替）
    │   │   ├── hero_section.dart
    │   │   ├── about_section.dart # 自己紹介（中身は現状プレースホルダ文言）
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
    │   └── utils/                 # YAML ローダー、文字列分割、workflow 日本語化など
    └── test/widget_test.dart      # ※テンプレのまま（後述の既知の問題を参照）
```

`android/ ios/ macos/ linux/ windows/` は `dev_portfolio/.gitignore` で **Git 管理外**。`web/` はローディング表示を入れた `index.html` を管理するため Git に含める（CI の `flutter create . --platforms web` は既存ファイルを上書きせず、足りないファイルだけ作る）。

## 3. 画面構成

`HomePage` に Header（固定）＋ `SingleChildScrollView` で以下を縦に並べる:

1. **Hero（Home）** — 職種・名前・紹介文・「スキルを見る／プロジェクトを見る」ボタン＋右にプロフィール YAML カード（幅 900 以上で 2 カラム、600 未満でカード非表示）
2. **About** — 自己紹介＋「得意な領域／強み／開発スタイル」の定義リスト＋締めの一言
   - 表示する文言は `constants/app_texts.dart` の `HeroContent` / `AboutContent` にまとめてある
3. **Skills** — ツールバー（Work/Private セグメント・「カテゴリ」ボタン＝今のカテゴリ名を表示・Bar/Pie アイコン切替）→ カテゴリパネル（Projects のフィルターと同じ作り。インフラ／開発／クラウド・AI／工程のグループから 1 つだけ選び「反映」でグラフ切替。データのないカテゴリは出さない）→ グラフ
   - セグメントは `lib/widgets/app_segment.dart`（`AppSegment`）を Projects と共通で使う
4. **Projects** — ツールバー（Work/Private セグメント＋件数・フィルターボタン＋適用数バッジ・List/Collection アイコン切替）→ フィルターパネル（開閉式。先頭に「期間」＝年の範囲スライダー（指定範囲に少しでも重なるプロジェクトを残す）と「進行中のみ」、その下に技術・工程のチップ群。グループは幅 720 以上で 2 列）→ 適用中フィルター（× で個別解除・すべて解除）→ 一覧（List は 5 件ずつ、Collection は「列数 × 表示エリアに収まる行数」ずつページング＝行がそろう。`ProjectsCollectionConfig.itemsPerPage`）→ 詳細モーダル（`url_launcher`）
   - 状態（Work/Private・表示形式・フィルター）は `ProjectsSection` が持つ。タブ切替でフィルターはリセット
   - Collection は幅で列数が変わる（520 未満 1 / 520〜 2 / 820〜 3 / 1100〜 4 列、`ProjectsCollectionConfig.columnBreakpoints`）。カードは高さ固定で、タグは 3 つ＋「+N」

Header: ナビボタン、**Work / Private 用 YAML のアップロード**（`file_picker`）、ダークモードのスイッチ。
アップロードダイアログには、フォーマット（`format_*.yaml`）を「名前を付けて保存」するボタン（`utils/file_saver.dart`：Chrome/Edge は `showSaveFilePicker` の保存ダイアログ、他は通常ダウンロード）と、書き方の説明を開く ⓘ ボタンがある（`sections/header/yaml_format_help.dart`。デスクトップ用とモバイル用で共通）。

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
flutter run -d chrome                 # ローカルで動作確認（Web 専用。dart:html を使っているため）
flutter analyze
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

## 8. 既知の問題・技術的負債（2026-10-31 時点の調査）

- **`test/widget_test.dart` が壊れている**: 存在しない `MyApp` を参照しているため、`flutter test` は失敗する。
- **Web 専用**: `dart:html` を直接 import しているため（ローダー、両 Header）、Web 以外ではビルドできない。`dart:html` は非推奨なので、将来は `package:web` に移行することを検討する。
- **アップロード処理の重複**: `desktop_header.dart` と `mobile_header.dart` に検証とダイアログがほぼ同じ形でコピーされている。また sessionStorage に直接書き込んでいて、`*YamlLoader.setCustomYaml` を使っていない。
- **CSV 分割処理が複数ある**: `Project._split` / `ProjectFilterLogic.split` は `,` で分割、`utils/string_utils.parseToList` は `,`・`、`・空白で分割（スペースを含む値が分かれてしまう恐れ）。`utils/project_utils.parseList` もあるが未使用。
- **未使用（と思われる）コード**: `skills/skills_tabs.dart`, `skills/models/skill_model.dart`, `skills/widgets/skills_tab_bar.dart`, `projects/project_detail_format.dart`, `projects/views/project_list/project_list_view.dart`（＋`project_list_sort.dart`、こちらは期間の形式が現在のデータと合っていない）, `config/projects/projects_tab_config.dart`, `config/skills/skills_section_config.dart`（古い `tools_fw` キー）, `utils/project_utils.dart`。依存パッケージの `shared_preferences` も未使用。
- `lib/utils/theme_colors.dart` は不要（どこからも import されていない）なので削除してよい。
- ローダーのコメントに `projects_*.yaml` とあるが、実際に読んでいるのは `format_*.yaml`。
- `web/index.html` と `pubspec.yaml` の description / title が Flutter テンプレートのまま。`HeroContent` / `AboutContent`（`constants/app_texts.dart`）の名前・文言はまだ仮のもの。

## 9. Claude の作業メモ

- 開発者本人（オーナー）とのやり取りが前提。回答は日本語で行う。
- 大きな変更の前には、このファイルの「データフロー」と「既知の問題」を確認する。
- 変更が構成・スキーマ・既知の問題に関わるときは、このファイルも一緒に更新する。
