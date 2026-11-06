# 開発ガイド

> 起動（Docker / Flutter / backend）、テストと網羅率の基準、CI / デプロイ。
> プロジェクトの紹介は [README](../README.md)。

## 起動

### Docker（frontend + backend）

リポジトリの直下（`frontend/` と `backend/` がある場所）で：

```bash
docker compose up --build    # http://localhost:8000（API は http://localhost:8080）
docker compose up backend    # API だけ
docker compose down          # 止める
```

| サービス | ビルド | 中身 | ポート |
|---|---|---|---|
| `frontend` | `ghcr.io/cirruslabs/flutter:3.41.6` で `flutter build web` → `nginx:1.27-alpine` | Flutter Web を nginx で配信。`/api/` と `/healthz` は backend へ転送（転送先は環境変数 `BACKEND_ORIGIN`）。index.html と Service Worker はキャッシュしない | 8000 |
| `backend` | `dart:3.11` で `dart compile exe` → `scratch`（10MB 前後） | shelf + shelf_router の API。`backend/data/` を読み取り専用でマウント。ヘルスチェックが通ってから frontend を起動 | 8080 |

- 初回は Flutter のイメージの取得とビルドに数分かかります。Flutter のビルドはメモリを使うので、Docker に 6〜8GB 程度割り当ててください
- `backend/data/` の YAML を書き換えると、再起動しなくても API の応答が変わります
- `frontend/assets/profile/` の個人のプロフィールは、イメージに入らないようにしています（`frontend/.dockerignore`）
- ビルドの引数：`FLUTTER_VERSION`（frontend の Flutter の版）、`BASE_HREF`（配信するパス。既定 `/`）、`DART_VERSION`（backend）
- `Cannot connect to the Docker daemon` と出たら、Docker Desktop / Rancher Desktop が起動しているか、`docker context ls` で接続先を確かめてください

### ローカル（Flutter）

```bash
cd frontend
flutter pub get
dart run tool/run.dart my_profile.yaml   # プロフィールを指定して起動（おすすめ）
# または
flutter run -d chrome                    # 起動後にプロフィールの入力画面が出る
```

> `web/index.html`（起動時のローディング表示など）は Git で管理しています。CI の `flutter create . --platforms web` は既存のファイルを上書きしません。

本番と同じ設定でビルドする場合：

```bash
flutter build web --release --base-href "/dev-portfolio-site/"
```

### backend だけ（Dart）

```bash
cd backend
dart pub get
dart run bin/server.dart     # http://localhost:8080
```

---

## テスト

### 実行

```bash
cd frontend
flutter analyze
flutter test                                   # すべて
flutter test test/home_page_test.dart          # 1 ファイルだけ
flutter test --coverage --branch-coverage      # 網羅率も記録（coverage/lcov.info）
dart run tool/coverage_check.dart              # 網羅率の集計と基準の確認

cd ../backend && dart test                     # backend
```

### 網羅率の基準

- **行（C0）・分岐（C1）とも 90% 以上**。GitHub Actions（`test.yml`）が push・プルリクエストのたびに確かめ、届かなければ失敗にします
- 2026-11-06 時点：行 **96.2%**・分岐 **90.4%**（集計の対象 95 ファイル）。テストは frontend 39 ファイル（実行するテスト 約 730 件）、backend 12 件
- `tool/coverage_check.dart` が `coverage/lcov.info` を集計し、全体の網羅率と、基準に届かないファイル（通っていない分岐が多い順）を出します。通っていない行・分岐の行番号は `coverage/uncovered.txt` に書きます

```
網羅率（95 ファイル。除外 0: ）
  行（C0）   96.2%  (5874 / 6107)   基準 90%
  分岐（C1） 90.4%  (2149 / 2377)   基準 90%
基準を満たしています
```

- **集計の漏れを防ぐ**：flutter test は、テストから読み込まれたファイルしか集計しません。`test/all_files_loaded_test.dart` が lib/ のすべてのファイルを読み込むので、テストのないファイルも 0% として数えます。lib/ にファイルを足したら `dart run tool/coverage_check.dart --update-imports` で作り直してください（作り直していないと、集計に入っていないファイルとして失敗になります）
- **集計から除くもの**：`lib/main.dart`（runApp だけ）と `*_web.dart`（Web 専用。テストでは代わりの実装を使う）。テストでは本当に通れない行（呼ばれない private コンストラクタなど）だけ、行の最後に `// coverage:ignore-line` を付けて除きます（印の後ろに説明を書くと認識されないので、理由は印の前に書く）

### テストの書き方

- 関数・画面ごとに**正常系と異常系**（壊れた入力・空・0 件・境界・キャンセル・失敗）の両方を書きます
- 入力と期待の組み合わせは表にして回します（`for (final (入力, 期待) in cases)`）
- 画面は**組み合わせ**で確かめます：テーマ（ライト / ダーク）× 幅（スマホ 360 / タブレット 800 / PC 1280）× データ（サンプル / たくさん / 1 件 / 0 件）。はみ出し（overflow）はテストの失敗になります
- ブラウザの機能・ファイル選択・アセットの読み込みは、テストから差し替えられる入口を通します

| 入口 | テストでの使い方 |
|---|---|
| `lib/utils/browser/browser.dart` | VM では `browser_stub.dart`（sessionStorage はメモリ、送ったイベントは `dispatchedEvents` に残る） |
| `lib/utils/file_saver.dart` | VM では `file_saver_stub.dart`（保存したものは `FileSaver.lastSaved` に残る） |
| `lib/utils/file_pick.dart` の `pickFile` | 関数を入れて、選んだ・キャンセル・中身なし・拡張子違い・エラーを作る |
| `lib/utils/asset_text.dart` の `loadAssetText` / `loadAssetBytes` | `setUp(useFileAssets)`（`test/test_assets.dart`）でファイルから直接読む。読めない・読み込み中も作れる |
| `test/test_assets.dart` の `loadAppFont` | 同梱の IPA P ゴシックで描く（既定のテスト用フォントは英字が広く、実際には収まる文字が「はみ出し」になるため） |
| `test/test_xlsx.dart` の `testXlsx` | テスト用の小さな .xlsx を作る |

### テストの一覧（frontend）

| 分野 | ファイル | 見ているところ |
|---|---|---|
| 画面全体 | `home_page_test` | テーマ × 幅 × データの 18 通りの描画、ナビ・グラフ・並び替え・ページ送り・フィルター・テーマ切替・スマホのメニュー、0 件・項目なし・プロフィールなし |
| 画面全体 | `all_files_loaded_test` / `min_width_scaler_test` / `widget_test` | 全ファイルの読み込み（自動生成）、320px より狭い画面、テーマ |
| Home / About | `hero_section_test` / `about_section_test` | まとめの中身と並び・押したとき、書いた項目だけを出す・開発経験の行・広い / 狭い画面・ダーク |
| Skills | `skills_aggregator_test` / `skills_charts_test` | 割合の集計（表記ゆれ・重複・利用なし・0 件）、円・棒グラフ（その他・押す・マウス・縦横の並び・ダーク） |
| 技術名 | `skill_name_test` / `tech_catalog_test` | 表記ゆれ、振り分け、グループ分け |
| Projects | `projects_model_test` | YAML の 1 件 → Project（値の形・期間の書き方 7 通り・進行中・月数） |
| Projects | `project_filter_logic_test` / `project_filter_state_test` | 16 分類・AND・部分一致・表記ゆれ・工程・期間の境目・進行中、条件の数・外す |
| Projects | `project_sort_test` / `projects_pagination_logic_test` | 並び替え 6 通り（同じ値・0 件・期間なし・進行中が複数）、ページ数とページの中身 |
| Projects | `project_detail_navigation_test` / `coverage_extra_test` | 詳細の前後移動・拡大・キー操作・公開ページ、ページ番号の出し方（スマホではみ出さない）、起動時の読み込み |
| Projects | `project_role_scale_test` | 役割・規模（Excel からの読み分け・人数の区分・フィルター） |
| データ | `data_format_test` / `profile_yaml_test` / `projects_yaml_validator_test` / `profile_bundle_test` | YAML / Markdown の見分けと変換、プロフィール・Work / Private の検証、まとめて書いたとき |
| データ | `browser_storage_test` / `yaml_loaders_test` | 読む順番の全通り、壊れたデータ |
| データ | `project_append_test` / `project_data_test` / `projects_diff_test` / `yaml_writer_test` | 追加（正常系・異常系）、［データ］の画面、上書きの違い、YAML の書き出し（誤読されうる 31 種類の文字列） |
| アップロード | `upload_dialogs_test` / `upload_paste_test` / `file_pick_dialogs_test` / `yaml_format_help_test` | 貼り付け・ファイル選択（YAML / Markdown / Excel、キャンセル・拡張子違い・エラー・文字コード・壊れた Excel）→ 確認 → 反映、書き方の説明 |
| スキルシート | `skill_sheet_test` / `xlsx_layout_test` / `skill_sheet_writer_test` / `skill_sheet_pdf_test` / `download_menu_test` | Excel → YAML、Excel の見た目、［ダウンロード］の Excel・PDF・保存・失敗 |
| 文言など | `app_texts_test` / `small_utils_test` | 期間の長さの表示・差し込む文言、区切り・工程の日本語化 |

backend（`backend/test/app_test.dart`）：各 API の正常系、404・500 のエラー、壊れた YAML、必須項目、ログの形、CORS。

---

## CI / デプロイ

| ワークフロー | いつ | 何をするか |
|---|---|---|
| `.github/workflows/test.yml` | `develop` / `main` への push、プルリクエスト、手動 | **frontend**：Flutter 3.41.6 → `flutter pub get` → `flutter analyze` → `flutter test --coverage --branch-coverage` → `coverage_check.dart --min-line 90 --min-branch 90`（結果を Actions のサマリーに表示）→ `coverage/` を成果物として保存。**backend**：Dart 3.11 → `dart pub get` → `dart analyze` → `dart test` |
| `.github/workflows/deploy.yml` | `develop` への push、手動 | Flutter Web をビルド（`--base-href "/dev-portfolio-site/"`）して GitHub Pages に公開 |

- `develop` への push は、そのまま公開ページに反映されます
- 今は deploy.yml が test.yml の結果を待ちません（テストが落ちていても公開されます。課題の 1 つ）
