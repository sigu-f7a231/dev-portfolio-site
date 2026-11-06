# 現状と課題

> 今の状態、直した不具合、残っている課題（優先度順）。大きな変更の前に読み、片づいたら消す・増えたら足す。

## 現状（2026-11-06）

- `flutter test`：全件成功（オーナーの手元で確認）。網羅率は行 96.2%・分岐 90.4%（基準 90%。`testing.md`）。
  - 2026-11-06 にページ送りのはみ出しを直し、`coverage_extra_test` にスマホで確かめるテストを足した。この 2 つはオーナーの手元で**未実行**。
- `docker compose up --build` で frontend と backend が起動する（オーナーの手元で確認）。
- 2026-11-06 にフォルダーを `frontend/` / `backend/` に分け、Docker・backend（shelf）・テスト・CI（`test.yml`）を足した。Git へのコミットはオーナーが行う。
- 非推奨 API は置き換え済み（Flutter stable 2026-10 のソースで `@Deprecated` を照合）:
  - `dart:html` → `package:web`（`web: ^1.1.1`）。sessionStorage とイベント送信は `utils/browser/browser.dart` 経由（Web は `browser_web.dart`、flutter test は `browser_stub.dart` のメモリ実装を条件付き export で自動選択）。ファイル保存も同じく `utils/file_saver.dart`（Web は `file_saver_web.dart`、テストは `file_saver_stub.dart`）。**`dart:html` / `package:web` を直接 import しない**（`*_web.dart` だけが使う）。
  - `Color.withOpacity` → `withValues(alpha: …)`。
  - 例外：`ProgressIndicatorThemeData.year2023` / `SliderThemeData.year2023`（`app_theme.dart`）は非推奨だが、既定値がまだ true（旧デザイン）で、M3 2024 版の見た目にする方法がこれしかないため `// ignore: deprecated_member_use` 付きで残す。既定値が false になったら消す。
- Claude の作業環境には Flutter がない。静的解析・テスト・画面での確認はオーナーの手元で行う。

## テストで見つけて直した不具合（2026-11-06）

- **円グラフの扇を押しても選べなかった**：fl_chart 1.2 の touchCallback は `FlTouchEvent`（`FlTapDownEvent` など）を渡すのに、Flutter の `PointerDownEvent` で判定していた。扇のない所（真ん中の穴）は -1 が来るので「なし」にそろえた（`pie_graph.dart`）。
- **並び替えが毎回揺れた**：期間のない案件・進行中の案件は `periodEnd` が呼ぶたびに今の時刻になり、比べるたびに結果が変わっていた。期間のないもの同士は名前順、「終了が新しい順」の進行中同士は同じ扱いにした（`project_sort.dart`）。
- **スマホ幅のはみ出し**：カードの期間・長さ（コレクション表示のカード幅 160px で最大 85px）、Work / Private の切替のラベル（`project_card_parts.dart` / `app_segment.dart`。幅が足りないときだけ折り返す・「…」）。
- **ページ送りの › が画面の外に出た**：スマホでは Material のボタンが当たり判定を 48px に広げる（padded）のに、40px として番号の数を数えていた。番号ボタンを `MaterialTapTargetSize.shrinkWrap` にした（`projects_pagination_ui.dart`）。

## 課題：優先度 高（不具合・データの安全に関わる）

1. **画面での動作確認がまだ**：レスポンシブ・M3 ヘッダー・ポップアップのフィルター・List / Collection・入力画面・アップロードの確認画面と全画面ローディング・`tool/run.dart` は、テストは通っているが、PC 幅とスマホ幅での見た目・操作（特にキーボード操作・日本語入力・ブラウザの拡大との兼ね合い）は実機で未確認。
2. **ローカルで `flutter build web` するとプロフィールが成果物に入る**：`assets/profile/` をアセットとして宣言しているため、`profile.yaml`（と一緒に指定した `work.yaml` / `private.yaml`）が残っていると `build/web/assets` に含まれる（表示はしないが個人情報）。Docker のビルドは `.dockerignore` で防いでいるが、`flutter build web` を直接使うときは防げていない。
3. **Work / Private の検証が浅い**（`isValidProjectsYaml`）：`projects` 配列・`title`・`workflow` の有無だけ。各項目の型（List / 文字列）や `period` の形式は見ていないので、崩れた YAML でも通って表示がおかしくなる可能性がある。プロフィール（`Profile.parse`）と同じく項目単位のエラーを出す形にしたい。

## 課題：優先度 中（使い勝手・保守性）

4. **期間で絞り込むと、期間を書いていない案件が必ず残る**：期間がない案件は開始 1970 年・終わり今日とみなされ、どの年を指定しても重なる。オーナーに直すか確認中（2026-11-06）。
5. **CSV 分割処理が複数ある**：`Project._split` / `ProjectFilterLogic.split` は `,` で分割、`utils/string_utils.parseToList`（Skills の集計）は `,`・`、`・空白で分割。値を文字で書くと、グラフでは「Ruby on Rails」が 3 つに分かれる。1 つにまとめたい。オーナーに直すか確認中（2026-11-06）。
6. **ページ移動でスクロール位置が残る**：ページ全体でスクロールするので、Projects のページを切り替えて一覧の長さが変わっても位置はそのまま（一覧の先頭へ戻す処理がない）。
7. **スマホでのグラフ操作**：棒グラフの強調は `MouseRegion` だけなのでタップに反応しない。
8. **`tool/run.dart` は起動時に 1 回コピーするだけ**：YAML を書き換えたら起動し直す必要がある（ホットリロードでは反映されない）。`frontend/` で実行する前提。
9. **全画面ローディングは時間で待っている**：アップロード後は最低 5 秒（`AppSizes.reloadMinDuration`）、最大 8 秒。描画完了を厳密に検知しているわけではない。
10. **Android で Google Drive のファイルを選べないことがある**：Android のファイル選択画面は MIME タイプで絞り込み、Drive 側の種類（`application/octet-stream` など）が `.yaml` と合わないと選べない。テキストの貼り付けで回避できる。根本的に直すなら、Android では `FileType.any` にして選んだ後に拡張子を確かめる（`utils/file_pick.dart` の 1 か所で直せる）。
11. **アップロード画面（Work / Private）は拡張子を確かめていない**：ファイル選択のダイアログで絞っているだけで、コードでは見ていない（入力画面は確かめる）。上の 10 を直すなら、ここでも確かめる。
12. **frontend がまだ API を呼ばない**：backend はあるが、表示は assets と sessionStorage から。API から読むようにするのは次の段階（状態管理を Riverpod にし、Repository 層で読み先を切り替える案）。
13. **deploy.yml がテストを待たない**：test.yml とつないでいないので、テストが落ちていても develop に push すれば公開される。

## 課題：優先度 低（仕様として受け入れているもの・整理）

14. **公開ページ（GitHub Pages）では必ずプロフィールの入力画面が出る**：CI は YAML なしでビルドする。ローカルに落として使う前提なので仕様。
15. **アップロードしたデータは sessionStorage だけ**：タブを閉じると消える（仕様）。
16. **Web 専用**：`file_saver.dart`（`dart:js_interop` / `package:web`）と `main.dart` 経由のため、Web 以外ではビルドできない（テストは VM で動く）。
17. **未使用の依存パッケージ**：`shared_preferences`（未使用のファイル 9 つは 2026-11-06 に削除済み）。
18. **未使用の定数・スタイル**（作り直しで使わなくなったもの。参照 0 件を確認済み）：`AppSizes.filterPanelDuration`、`AppStyles.filterPanel` / `toggle` / `toggleText`、`AppTexts.selectYamlFile` / `uploadYaml` / `workUploadNote` / `privateUploadNote` / `darkMode` / `save`、`ProfileTexts.upload`、`ProjectsListConfig.separator` / `cardPadding`、`SkillsHeaderConfig.panelMargin`、`PieChartLayout.pieInactiveBorderWidth`、ローダーの `setCustomYaml`（テストからのみ使用）。
19. `pubspec.yaml` の `description` が Flutter テンプレートのまま（`"A new Flutter project."`）。
20. `graph_utils.dart` の `mapIndexed` は 2 回繰り返すと番号が 0 に戻らない（今の使い方では問題ない）。`ProjectsPaginationLogic.getPaginatedProjects` は 0 以下のページを渡すとエラー（画面からは起きない）。
