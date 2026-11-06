# コーディング規約・方針

> 色・テーマ・値の置き場所・部品の選び方・レスポンシブ。UI を書く前に読む。
> 人向けのまとめ（トークンの一覧・ブレークポイントの表・UX の決まり・待ち時間）は `docs/design-system.md`・`docs/ui-ux.md`・`docs/performance.md`。値を変えたらそちらも直す。

## 全般

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
  - 切替は `ref.read(themeModeProvider.notifier).toggle(bool)`（Riverpod、`lib/state/providers.dart`）。`main.dart` が `ref.watch(themeModeProvider)` で MaterialApp を再構築する。
  - 何度も使う見た目（文字・角丸・カード・タグ・切替ボタン・グラフ文字・モーダル・ダイアログ・Hero / About）は `AppStyles` に置く。
  - 新しい色は `AppColors` にフィールドを追加し、light と dark の両方に値を入れる。
- **値の置き場所（ウィジェットのファイルに数値や文言を直接書かない）**
  - 画面の文言 → `lib/constants/app_texts.dart`（`AppTexts.xxx`。変数を埋め込む文言は関数、例: `AppTexts.uploadSaved(dataType)`）
  - 余白・時間・汎用サイズ → `lib/constants/app_sizes.dart`（`AppSizes.space8` / `AppSizes.scrollDuration` など）
  - セクション固有のまとまったレイアウト値（グラフ半径・カード幅・ブレークポイントなど） → `sections/config/**/*_config.dart`
  - ロジック上の数値（ページ計算の 0 / 1、% の 100 など）と YAML のキー名は対象外
- 状態管理は `setState` / `ValueNotifier` のみ（外部ライブラリは使っていない）。
- ファイルは機能ごとに分ける（logic / state / ui / views / data / models）。

## レスポンシブ（スマホ対応）の方針（2026-11-03）

- **対応する最小の幅は 320px**（`AppSizes.minSupportedWidth`）。320px で崩れないように作る。それより狭い画面は `MinWidthScaler`（`main.dart` の MaterialApp の builder）が 320px のレイアウトを画面幅に合わせて縮小する（はみ出しエラー防止。ダイアログも含む）。
- **スクロールはページ全体（HomePage の SingleChildScrollView）の 1 つだけ。** セクションに画面の高さを固定したり、内側に ListView / GridView のスクロールを作ったりしない（スマホで内側だけスクロールされ、ページが動かなくなるため）。一覧は `shrinkWrap: true` と `NeverScrollableScrollPhysics` にする。
- Projects Collection の 1 ページの件数は「列数 × 行数」で、どちらも**画面幅**で決める（`ProjectsCollectionConfig.columnsFor` / `rowsFor`）。
- ページネーションは幅に合わせて「全部表示 → 1 … 4 5 6 … 10 → ‹ 3 / 10 ›」と切り替える（`ProjectsPaginationUI`）。
- Skills のカードは最大幅 800・高さは中身なり。カード内の幅が `SkillsCardConfig.stackBreakpoint` 未満なら、グラフと凡例を縦に並べ、円グラフは幅に合わせて縮める（`PieGraph.size`）。
- ツールバー類は `Row` ではなく `Wrap` にして、狭い画面では折り返す。
- **ヘッダーは M3 の Small top app bar**（`sections/header/header_parts.dart`）：ナビは表示中のセクションに丸いインジケーター（`SectionScrollController.active` がスクロール位置から更新、Drawer も同じ値で選択表示）。テーマ切替は PC が太陽／月アイコン付き Switch、スマホがトグル式 IconButton。幅 900 未満でナビはアイコンのみ、760 未満でタイトルを隠す。Work / Private のアップロードは M3 の Filled tonal ボタン（`HeaderUploadButton`、幅 1100 以上で文字付き、それ未満とスマホはアイコンのみ）。
- **Projects のフィルター・Skills のカテゴリはポップアップで開く**（`lib/widgets/app_filter_modal.dart` の `showAppFilterModal`）：幅 600 以上は中央のダイアログ、未満は下から出るシート。パネルは見出しとフッターを固定し、本文だけスクロールする。「反映」で反映、×・キャンセル・外側タップでは変えない。
- **List と Collection は役割で見た目を分ける**：List＝年表（1 枚の面に行を並べ、左に開始の年・月と縦線＋点、説明文なし）／Collection＝カバー付きカードのギャラリー（色は `projectColorSeed` でタイトルから決める、頭文字・期間の長さ・説明 2 行）。
