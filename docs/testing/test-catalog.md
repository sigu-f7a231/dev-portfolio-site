# テスト一覧

> どのテストが何を確かめているか。テストを足すときの置き場所と、補助ファイル・差し替えの入口。方針と合格の基準は [テスト計画書](test-plan.md)。
> 2026-11-06 時点。「件数」はテストの定義の数（表で回すものは 1 と数える）。観点は 正：正常系、異：異常系・空・境界、組：組み合わせ。

---

## 実行の仕方（`frontend/` で）

```bash
flutter test                                  # すべて（約 20 秒）
flutter test test/home_page_test.dart         # 1 ファイル
flutter test --plain-name '0 件でも落ちない'   # 名前で絞る
flutter test --coverage --branch-coverage && dart run tool/coverage_check.dart   # 網羅率
```

backend は `backend/` で `dart test`。

---

## frontend

### 画面全体

| ファイル | 件数 | 観点 | 確かめていること |
|---|---|---|---|
| `home_page_test.dart` | 10 | 正・異・組 | テーマ × 幅 × データの 18 通りの描画（はみ出し・例外なし）、ナビで各セクションへ、Skills の切替、Projects の表示・並び替え 6 通り・ページ送り・フィルター、テーマ切替、スマホのメニュー。0 件（3 つの幅）・項目のない案件・プロフィールなし |
| `all_files_loaded_test.dart` | 1 | ― | lib/ の全ファイルを読み込む（集計の漏れを防ぐ。`coverage_check.dart --update-imports` で作る） |
| `min_width_scaler_test.dart` | 3 | 正・組 | 320px より狭い画面での縮小表示 |
| `widget_test.dart` | 4 | 正 | テーマの切替、`context.colors` |

### Home / About

| ファイル | 件数 | 観点 | 確かめていること |
|---|---|---|---|
| `hero_section_test.dart` | 12 | 正・異・組 | まとめ（開発経験・件数・直近）の計算、中央寄せ、広い / 狭い画面の並び、押したとき、案件を変えたら（dataRevisionProvider）作り直す、プロフィールが変わったら名前も変わる、Work / Private が読めなければまとめを出さない、案件なし・期間なし |
| `about_section_test.dart` | 10 | 正・異・組 | 全部書いた・自己紹介だけ・1 つだけ・技術だけ / 文章だけ・プロフィールなし、「領域：説明」の太字（全角・半角の `:`）、広い / 狭い画面、ダーク |

### Skills・技術名

| ファイル | 件数 | 観点 | 確かめていること |
|---|---|---|---|
| `skills_aggregator_test.dart` | 15 | 正・異 | 分類ごとの割合（合計 100%）、表記ゆれのまとめ、1 件の中の重複、AWS などの先頭、「利用なし」・空、0 件（0 で割らない）、YAML のまま渡す、工程の担当率（true 以外は担当していない扱い） |
| `skills_charts_test.dart` | 11 | 正・異・組 | 円・棒グラフの「その他」へのまとめ（10 件より多い / 以下 / 1 件 / 0 件）、凡例を押して選ぶ・外す、マウスを乗せる・離す、扇を押す・真ん中を押す、縦横の並び、ダーク |
| `skill_name_test.dart` | 16 | 正・異 | 表記ゆれ（末尾の記号・大文字小文字・全角・キャメル / スネーク・AWS などの先頭）、Skills の集計、Projects のフィルター |
| `tech_catalog_test.dart` | 13 | 正 | Skills・Tools に書かれた技術の振り分け（React → Frontend など）、Tools / Skills のグループ分け |

### Projects

| ファイル | 件数 | 観点 | 確かめていること |
|---|---|---|---|
| `projects_model_test.dart` | 23 | 正・異 | YAML の 1 件 → Project：値の形（並び・文字・数・null）、`tools_fw`、期間の書き方 7 通り（全角・「年月」・年またぎ）、月 0 / 13、開始だけ、期間なし、進行中（現在 / present の大文字小文字）、月数 |
| `project_filter_logic_test.dart` | 26 | 正・異 | 16 分類がそれぞれの項目だけを見る、AND、部分一致、表記ゆれ 6 通り、クラウドの先頭、工程（日本語 / 英語のキー）、期間の境目（範囲の最初の月・最後の月）、片方だけの期間、進行中、0 件 |
| `project_filter_state_test.dart` | 16 | 正・異 | 条件の数の数え方、期間が片方だけ、条件を外しても元が変わらない、知らない分類 |
| `project_sort_test.dart` | 13 | 正・異 | 並び替え 6 通り、同じ値は名前順、0 件・1 件、期間がすべてない、開始だけの期間、進行中が複数（20 回続けて同じ結果） |
| `projects_pagination_logic_test.dart` | 10 | 正・異 | ページ数（0 件・ちょうど・1 件はみ出す）、ページの中身、範囲外のページ、全ページをつなぐと抜けも重なりもない |
| `project_detail_navigation_test.dart` | 13 | 正・異・組 | 詳細の ‹ › / ← →、端では押せない、PC はダイアログ・スマホは全画面、画面共有向けの拡大、⌘ / Ctrl ＋ 0（Mac / Windows） |
| `project_role_scale_test.dart` | 36 | 正・異 | 役割・規模（Excel からの読み分け・人数の区分・フィルター・詳細・入力フォーム）、プロフィールの `sheet` |
| `coverage_extra_test.dart` | 22 | 正・異・組 | ページ番号の出し方（先頭・真ん中・末尾で「…」の位置、狭いとき、スマホでどの幅・位置でもはみ出さない）、起動時の読み込み・「準備できた」の知らせ、起動時に YAML を指定したとき（正しい・誤り・ファイルなし）、詳細の拡大の上限・下限・キー操作・下の ‹ ›・公開ページ（開けない・なし）・技術のグループ |

### データの読み込み・検証・保存

| ファイル | 件数 | 観点 | 確かめていること |
|---|---|---|---|
| `data_format_test.dart` | 21 | 正・異 | YAML / Markdown の見分けと変換、テンプレートが同じ中身、行番号付きのエラー、アセットの登録 |
| `profile_yaml_test.dart` | 16 | 正・異 | プロフィールの検証（テンプレートが通る、必須・知らないキー・型の違い） |
| `projects_yaml_validator_test.dart` | 9 | 正・異 | Work / Private の検証 |
| `profile_bundle_test.dart` | 15 | 正・異 | プロフィールに Work / Private も書いたとき（YAML / Markdown） |
| `browser_storage_test.dart` | 17 | 正・異 | sessionStorage（メモリ）、ローダー、ProfileStore |
| `yaml_loaders_test.dart` | 9 | 正・異 | 読む順番（セッション → サンプル）の全通りを Work / Private で、YAML の誤り、先頭が Map でない |
| `portfolio_repository_test.dart` | 33 | 正・異 | 構造のデータ（`records.dart`）と YAML の行き来・壊れたデータ。`LocalPortfolioRepository` の文字（元の文字を保つ・保存 → 起動時の指定 → サンプル・サンプルかの判定）と構造のデータの読み書き、プロフィール（起動時の指定の成功 / 失敗 / なし、壊れた保存）。**構造のデータの 5 つだけを書いた偽物**に差し替えると、文字の読み書き・サンプル・ローダー・ProfileStore がそのまま動く（Firestore の実装の代わり） |
| `app_state_test.dart` | 15 | 正・異 | Riverpod の Provider（Repository・データが変わった回数・テーマ・プロフィール・Work / Private・Skills の集計・Projects の一覧、読めないときは繰り返さない）、go_router（`/`、ない URL は `/` へ、`ENABLE_ACCOUNT` なしではログイン・マイページは `/` へ、ありなら空の画面、戻るボタン）、データが変わると画面を作り直して新しいデータを出す、テーマで画面がダークになる |
| `project_append_test.dart` | 22 | 正・異 | 追加するプロジェクトの読み取り（3 つの書き方 / 見つからない 8 通り / 項目の形でない / title・workflow の過不足と番号）、今の一覧の後ろに足す、同じ名前、入力の候補 |
| `project_data_test.dart` | 25 | 正・異 | ［データ］の画面の流れ（追加・更新・戻る）、入力フォーム、タグ入力、年月の選択、複数件のサンプル |
| `projects_diff_test.dart` | 8 | 正 | 上書きの確認の違いの判定、テンプレートがそろっているか |
| `yaml_writer_test.dart` | 14 | 正・異 | 書いた YAML を読み直すと同じ、誤読されうる文字列 31 種類を囲む、ブロックにすると中身が変わる複数行、null・空 |

### アップロード画面

| ファイル | 件数 | 観点 | 確かめていること |
|---|---|---|---|
| `upload_dialogs_test.dart` | 27 | 正・異 | 貼り付け（YAML / Markdown）→ 確認 → 反映、弾くデータ、閉じられない、まとめて反映、上書きの確認（やめる / 上書き / 同じ内容なら出さない） |
| `upload_paste_test.dart` | 13 | 正・異 | 貼り付け画面、テンプレートのコピー、形式の切替 |
| `file_pick_dialogs_test.dart` | 17 | 正・異・組 | ファイルを選ぶ流れ：YAML / Markdown / Excel を選んでアップロード、キャンセル・中身なし・拡張子違い・選ぶ途中のエラー・UTF-8 でない中身・壊れた Excel・テンプレートを読めない、起動時のエラー表示、入力方法の切替、ダーク |
| `yaml_format_help_test.dart` | 7 | 正・異・組 | 書き方の説明（Work / Private の違い、サンプルの中身）、読み込み中・読めない、ダーク |

### スキルシート（Excel / PDF）

| ファイル | 件数 | 観点 | 確かめていること |
|---|---|---|---|
| `skill_sheet_test.dart` | 22 | 正・異 | Excel → YAML（テンプレート・振り分け・期間・作業工程・読めないときのエラー） |
| `xlsx_layout_test.dart` | 13 | 正 | Excel の見た目の読み取り（番地・列幅・行の高さ・結合・書式・余白・フッター） |
| `skill_sheet_writer_test.dart` | 42 | 正・異 | ［ダウンロード］の Excel（セルの中身・結合・入力規則・個人の項目・0 件・読み直すと同じ） |
| `skill_sheet_pdf_test.dart` | 16 | 正・異 | PDF（縮める倍率・ページの分け方・フッター・出力） |
| `download_menu_test.dart` | 14 | 正・異 | ［ダウンロード］のメニュー・保存・ローディング・知らせ・失敗 |

### 文言・小さな処理

| ファイル | 件数 | 観点 | 確かめていること |
|---|---|---|---|
| `app_texts_test.dart` | 6 | 正・異 | 期間の長さの表示 7 通り、期間の範囲、差し込む文言、0 件 |
| `small_utils_test.dart` | 14 | 正・異 | 区切りの分け方 8 通り、工程の日本語化と合計 100、番号付け |

---

## backend（`backend/test/app_test.dart`、12 件）

| 確かめていること | 観点 |
|---|---|
| `/healthz` は 200 でキャッシュしない | 正 |
| `/api/profile`・`/api/projects/work`・`/api/projects/private` が JSON を返す | 正 |
| 知らない type・知らないパス → 404 | 異 |
| ファイルがない → 404（`data_not_found`） | 異 |
| Work に workflow がない・Private に workflow がある・プロフィールの必須がない・YAML の誤り → 500（`invalid_data`） | 異 |
| ログは 1 リクエスト 1 行の JSON（severity・httpRequest） | 正 |
| `ALLOWED_ORIGIN` を渡すと CORS のヘッダーが付く | 正 |

---

## 補助ファイル・差し替えの入口

| もの | 使い方 |
|---|---|
| `test/test_assets.dart` の `useFileAssets` | `setUp(useFileAssets)`。アセットをファイルから直接読む（testWidgets の中で rootBundle が終わらないことがあるため） |
| `test/test_assets.dart` の `loadAppFont` | `setUpAll(loadAppFont)`。同梱の IPA P ゴシックで描く。画面の幅・はみ出しを見るテストでは必ず使う |
| `test/test_xlsx.dart` の `testXlsx` | テスト用の小さな .xlsx を作る |
| `lib/utils/asset_text.dart` の `loadAssetText` / `loadAssetBytes` | 差し替えて、読めない・読み込み中を作る（`resetAssetTextLoader` で戻す） |
| `lib/utils/file_pick.dart` の `pickFile` | 関数を入れて、選んだ・キャンセル・中身なし・拡張子違い・エラーを作る（`resetFilePicker` で戻す） |
| `FileSaver.lastSaved`（`file_saver_stub.dart`） | 保存したもの（名前・中身）が残る |
| `browser_stub.dart` の `SessionStore.clear()` / `dispatchedEvents` | sessionStorage を空にする、ブラウザに送ったイベントを見る |
| `ProfileStore.fromArg` | 起動時に YAML を指定したときを作る（終わったら false に戻す。`LocalPortfolioRepository.fromArg` と同じもの） |
| `PortfolioRepository.instance` / `reset()` | Repository を偽物に差し替える（`portfolio_repository_test` の `_FakeRepository`）。tearDown で `reset()` |
| `ProviderScope` | `HomePage` は Riverpod を使うので、`ProviderScope(child: MaterialApp(...))` の中で pump する。Provider を差し替えるときは `ProviderScope(overrides: [...])` |
| `ProjectDetailView.reset` | 詳細の表示の大きさを戻す（tearDown で） |
| `themeModeProvider.overrideWith(...)` | 最初のテーマを決める（`ProviderScope(overrides: ...)`。テストごとに新しい ProviderScope なので戻す必要はない） |

## テストを足すときの置き場所

- 対象のファイルと同じ名前の `*_test.dart` があれば、そこに足す。なければ新しく作る（先頭に対象・見ているところ・実行のコマンドを書く）
- 画面全体の組み合わせは `home_page_test.dart`、ファイルを選ぶ流れは `file_pick_dialogs_test.dart`
- lib/ にファイルを足したら `dart run tool/coverage_check.dart --update-imports`
