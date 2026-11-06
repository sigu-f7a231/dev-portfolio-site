# テスト

> テストの実行・網羅率の基準・書き方の決まり・補助ファイル・テストの一覧。テストを足す・直すときに読む。
> 人向けの計画と一覧は `docs/testing/test-plan.md`・`docs/testing/test-catalog.md`、CI は `docs/ci/`。テストを足したら test-catalog.md も直す。

## 実行（`frontend/` で）

```bash
flutter analyze
flutter test                                  # すべて
flutter test test/home_page_test.dart         # 1 ファイルだけ
flutter test --coverage --branch-coverage     # 網羅率も記録（coverage/lcov.info。分岐の情報は --branch-coverage のときだけ）
dart run tool/coverage_check.dart             # 行（C0）・分岐（C1）の網羅率と、基準に届かないファイル
dart run tool/coverage_check.dart --update-imports   # lib/ にファイルを足したら（下の「集計の漏れを防ぐ」）
```

backend は `backend/` で `dart test`。

- Claude の作業環境には Flutter がない。静的解析・テスト・画面での確認はオーナーの手元で行い、結果（失敗の出力・網羅率の表示）を貼ってもらう。`coverage/lcov.info` と `coverage/uncovered.txt` は手元のフォルダーにできるので、Claude はそれを直接読める。

## 網羅率の基準

- **行（C0）・分岐（C1）とも 90% 以上**。`.github/workflows/test.yml` で push・PR ごとに確かめ、届かなければ失敗にする。
- 2026-11-06 時点：行 96.2%・分岐 90.4%（95 ファイル）。
- `tool/coverage_check.dart`：lcov.info を読み、全体の網羅率・基準に届かないファイル（通っていない分岐が多い順）を出し、通っていない行・分岐の行番号を `coverage/uncovered.txt` に書く。基準に届かない・分岐の情報がない・集計に入っていないファイルがあると終了コード 1（または 2）。
- **集計の漏れを防ぐ**：flutter test は、テストから読み込まれたファイルしか lcov.info に入れない（テストのないファイルが集計から漏れ、網羅率が高く出る）。`test/all_files_loaded_test.dart` が lib/ の全ファイルを読み込む。これは `--update-imports` で作るので手で直さない。lib/ にファイルを足したら作り直す（作り直していないと coverage_check が「集計に入っていないファイル」として失敗にする）。
- **集計から除くもの**：`lib/main.dart`（runApp だけ）と `*_web.dart`（Web 専用。テストでは `*_stub.dart` が使われる）。`tool/coverage_check.dart` の `_excluded` に、理由と一緒に書く。
- 1 行・一部だけ除くとき：その行に `// coverage:ignore-line`、範囲は `// coverage:ignore-start` 〜 `// coverage:ignore-end`。**印は行の最後に置き、後ろに説明を書かない**（説明があると印として認識されず、ignore-end だけが残ってテストがエラーになる。2026-11-06 に一度起きた）。理由は印の前に書く：
  ```dart
  AppTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line
  ```
  除くのは「テストでは本当に通れないもの」だけ（呼ばれない private コンストラクタ、ブラウザのダイアログを開くだけの数行など）。通せるのに網羅率のために除かない。

## 書き方の決まり

- 関数・画面ごとに**正常系と異常系**（壊れた入力・空・0 件・境界・キャンセル・失敗）の両方を書く。
- 表で回せるものは `for (final (入力, 期待) in cases)` の形にする（バリエーションを増やしやすく、失敗したときにどの組み合わせかが分かる）。
- 画面は**組み合わせ**で確かめる：テーマ（ライト / ダーク）× 幅（スマホ 360 / タブレット 800 / PC 1280）× データ（サンプル / たくさん / 1 件 / 0 件）。はみ出し（overflow）はテストの失敗になる。
- 網羅率のためだけに、使われていないコードをテストしない（使われていなければ消す）。
- テストのファイルの先頭に、対象のファイル・見ているところ・実行のコマンドを書く（既存のテストと同じ形）。

## 補助ファイル・差し替えの入口

| もの | 使い方 |
|---|---|
| `test/test_assets.dart` の `useFileAssets` | `setUp(useFileAssets)`。アセットを rootBundle ではなくファイルから直接読む（下の注意）。終わったら自動で元に戻す |
| `test/test_assets.dart` の `loadAppFont` | `setUpAll(loadAppFont)`。同梱の IPA P ゴシックを既定のフォント（Roboto）として読み込む。flutter test の既定のフォントは英字も全角に近い幅で描くので、実際には収まる文字が「はみ出し」になるのを防ぐ。画面の幅・はみ出しを見るテストでは必ず使う |
| `test/test_xlsx.dart` の `testXlsx` | テスト用の小さな .xlsx を作る（セルはすべて文字） |
| `lib/utils/asset_text.dart` の `loadAssetText` / `loadAssetBytes` | アセットの読み方。テストで差し替えて、読めない・読み込み中を作れる（`resetAssetTextLoader` で戻す） |
| `lib/utils/file_pick.dart` の `pickFile` | ファイル選択のダイアログ。テストで関数を入れて、選んだ・キャンセル・中身なし・拡張子違い・エラーを作る（`resetFilePicker` で戻す）。アプリのコードは `FilePicker` を直接使わない |
| `lib/utils/file_saver_stub.dart` の `FileSaver.lastSaved` | 保存したもの（名前・中身）が残る。保存は「ダウンロードした」扱い |
| `lib/utils/browser/browser_stub.dart` | `SessionStore`（メモリ。`clear()` で空に）、`dispatchedEvents`（ブラウザに送ったイベントの名前） |
| `ProfileStore.fromArg` | テストでだけ書き換えられる（`@visibleForTesting`）。`tool/run.dart` で YAML を指定して起動したときの読み込みを確かめる。終わったら false に戻す |
| `ProjectDetailView.reset` | 詳細の表示の大きさ（static）を戻す。`tearDown(ProjectDetailView.reset)` |
| `ThemeController.instance.toggle(false)` | テーマを戻す。テーマを切り替えるテストは、アプリと同じく `ValueListenableBuilder` で MaterialApp を作る（`home_page_test` の `_pumpHome`） |

## テストを書くときの注意

- `flutter test` は VM で動くため、ブラウザの機能は `utils/browser/browser.dart` 経由にし、検証ロジックは Web に依存しないファイルに置く（`utils/projects_yaml_validator.dart` / `models/profile.dart`）。`main.dart` は Web の機能を間接的に読み込むので、テストから import しない。
- MaterialApp のテーマ切り替えはアニメーションするので、テーマを変えたあとは `pumpAndSettle()` してから確かめる。
- **アセットは `utils/asset_text.dart` の `loadAssetText` で読む（rootBundle を直接使わない）**：testWidgets の仮の時間の中では rootBundle の読み込みが終わらないことがあり、テンプレートのコピーや上書きの確認（ローダーがサンプルを読む）が止まる。アセットに頼る画面を開くテストは `setUp(useFileAssets)` を使う。先に読んでおく（キャッシュに頼る）方法では直らなかった。
- アセットを足したら `pubspec.yaml` にも書く（`data_format_test` の「アセットとして登録されている」で書き忘れを見つける）。
- 読み込み中の表示（`AppLoadingIndicator`）は終わらないアニメーションなので、出ている間は `pumpAndSettle()` が終わらない。`pump(Duration)` を何回か呼んで進める（`home_page_test` の `_settle`）。
- ボタンを続けて押すテストは、1 回ごとに `pump` して結果を確かめる（どれが届かなかったかが分かる）。
- スマホ（Android / iOS）では Material のボタンが当たり判定を 48px に広げる（`MaterialTapTargetSize.padded`）。幅を計算して並べる部品は `variant: TargetPlatformVariant.mobile()` でも確かめる（ページ送りの不具合はこれで見つかった）。
- マウスの操作（乗せる・離す）は `tester.createGesture(kind: PointerDeviceKind.mouse)`。「外」へ動かす座標は、画面の左上（部品がある）ではなく、部品の外の何もない所にする。
- fl_chart の円グラフを押すテストは、扇の位置を計算して `tapAt` する（扇は 3 時の向きから時計回り。`skills_charts_test`）。

## テストの一覧（frontend）

| 分野 | ファイル | 見ているところ |
|---|---|---|
| 画面全体 | `home_page_test` | テーマ × 幅 × データの組み合わせ（18 通り）、ナビ・グラフ・並び替え・ページ送り・フィルター・テーマ切替・スマホのメニュー、0 件・項目なし・プロフィールなし |
| 画面全体 | `all_files_loaded_test` | lib/ の全ファイルを読み込む（集計の漏れを防ぐ。自動生成） |
| 画面全体 | `min_width_scaler_test` | 320px より狭い画面での縮小 |
| 画面全体 | `widget_test` | テーマ（ThemeController / context.colors） |
| Home / About | `hero_section_test` | Home の中央寄せ・まとめ（開発経験・件数・直近）・押したとき・作り直し |
| Home / About | `about_section_test` | 書いた項目だけを出す、開発経験の行（「領域：説明」の太字）、広い / 狭い画面、ダーク |
| Skills | `skills_aggregator_test` | 割合の集計（表記ゆれ・重複・利用なし・0 件・YAML のまま）、工程の担当率 |
| Skills | `skills_charts_test` | 円・棒グラフの「その他」、凡例・扇・棒を押す / マウスを乗せる、縦横の並び、ダーク |
| Skills / 技術名 | `skill_name_test` / `tech_catalog_test` | 表記ゆれ、振り分け（React → Frontend など）、Tools / Skills のグループ分け |
| Projects | `projects_model_test` | YAML の 1 件 → Project（値の形・期間の書き方・進行中・月数・一覧の表記ゆれ） |
| Projects | `project_filter_logic_test` / `project_filter_state_test` | 16 分類・AND・部分一致・表記ゆれ・工程・期間の境目・進行中、条件の数・外す |
| Projects | `project_sort_test` | 並び替え 6 通り・同じ値・0 件・期間なし・進行中が複数 |
| Projects | `projects_pagination_logic_test` | ページ数・ページの中身・境界 |
| Projects | `project_detail_navigation_test` | 詳細の ‹ › / ← →、PC / スマホ、画面共有向けの拡大、⌘ / Ctrl ＋ 0 |
| Projects | `project_role_scale_test` | 役割・規模（Excel からの読み分け・人数の区分・フィルター）、プロフィールの sheet |
| Projects | `coverage_extra_test` | ページ番号の出し方（「…」の位置・狭いとき・スマホではみ出さない）、起動時の読み込み、起動時に YAML を指定したとき、詳細の拡大の上限・キー操作・下の ‹ ›・公開ページ・技術のグループ |
| データの入出力 | `data_format_test` | YAML / Markdown の見分け・変換・行番号付きのエラー・アセットの登録 |
| データの入出力 | `profile_yaml_test` / `projects_yaml_validator_test` / `profile_bundle_test` | プロフィール・Work / Private の検証、プロフィールに Work / Private も書いたとき |
| データの入出力 | `browser_storage_test` / `yaml_loaders_test` | sessionStorage（メモリ）、読む順番（セッション → 起動時の指定 → メモリ → サンプル）、壊れたデータ |
| データの入出力 | `project_append_test` / `project_data_test` | 追加するプロジェクトの読み取り・足す・同じ名前・候補（正常系・異常系）、［データ］の画面の流れ・入力フォーム・タグ入力・年月の選択 |
| データの入出力 | `projects_diff_test` | 上書きの確認の違いの判定、テンプレートがそろっているか |
| データの入出力 | `yaml_writer_test` | 書いた YAML を読み直すと同じ、誤読されうる文字列（31 種類）を囲む |
| アップロード画面 | `upload_dialogs_test` / `upload_paste_test` | 貼り付け → 確認 → 反映、弾くデータ、閉じられない、上書きの確認、貼り付け画面 |
| アップロード画面 | `file_pick_dialogs_test` | ファイルを選ぶ流れ（YAML / Markdown / Excel、キャンセル・中身なし・拡張子違い・エラー・文字コード・壊れた Excel・保存の失敗） |
| アップロード画面 | `yaml_format_help_test` | 書き方の説明（Work / Private の違い、読み込み中・読めない） |
| スキルシート | `skill_sheet_test` / `xlsx_layout_test` | Excel → YAML、Excel の見た目の読み取り |
| スキルシート | `skill_sheet_writer_test` / `skill_sheet_pdf_test` / `download_menu_test` | ［ダウンロード］の Excel・PDF・メニュー・保存・失敗 |
| 文言・小さな処理 | `app_texts_test` / `small_utils_test` | 期間の長さの表示・差し込む文言、区切り・工程の日本語化・番号付け |

backend：`backend/test/app_test.dart`（各 API の正常系、404・500 のエラー、壊れた YAML、必須項目、ログの形、CORS）。
