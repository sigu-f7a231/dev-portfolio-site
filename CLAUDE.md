# CLAUDE.md — dev-portfolio-site

> Claude は作業開始時にまずこのファイルを読み、下の「どこを読むか」で作業に関わるファイルを読んでから始めること。
> 構成や方針が変わったら、該当するファイル（`docs/claude/`）も一緒に直す。このファイルは入口として短く保つ。

## プロジェクト概要

- **目的**: 履歴書を補完する開発者ポートフォリオ（SPA）。Work（業務）/ Private（個人）プロジェクトとスキル構成を可視化する。
- **構成**:
  - `frontend/` … Flutter Web / Dart（SDK `^3.9.2`）、Material 3。Dart のパッケージ名は `dev_portfolio`（2026-11-06 に `dev_portfolio/` から改名したため。import は `package:dev_portfolio/...`）
  - `backend/` … API サーバー（shelf + shelf_router。Dart 3.11）。まだ frontend からは呼んでいない
  - `compose.yaml` … Docker Compose で両方を起動（frontend :8000 / backend :8080）
- **公開先**: GitHub Pages（`/dev-portfolio-site/` 配下）
- **リポジトリ**: `git@github.com:sigu-f7a231/dev-portfolio-site.git`
- **ブランチ**: `develop`（作業・デプロイ対象）、`main`
- **言語**: UI 文言・コメント・ドキュメントは日本語が基本。

## どこを読むか（`docs/claude/`）

| 作業 | 読むファイル |
|---|---|
| ファイルの場所・画面の構成を知りたい、画面を足す・変える | [architecture.md](docs/claude/architecture.md) |
| データの読み込み・検証・保存・集計、Excel / PDF、YAML のスキーマを変える | [data-flow.md](docs/claude/data-flow.md) |
| UI を書く（色・テーマ・文言と数値の置き場所・部品・レスポンシブ） | [conventions.md](docs/claude/conventions.md) |
| テストを書く・直す、網羅率、テストの補助 | [testing.md](docs/claude/testing.md) |
| 起動・Docker・backend・CI / デプロイ | [operations.md](docs/claude/operations.md) |
| 大きな変更の前、不具合・課題の確認 | [status.md](docs/claude/status.md) |

人向けの説明は README とそこから案内する `docs/`：[README.md](README.md)（プロジェクトの紹介）・[docs/manual.md](docs/manual.md)（操作説明書・データの書き方）・[docs/design.md](docs/design.md)（設計・API）・[docs/structure.md](docs/structure.md)（ファイル構成・コンポーネント）・[docs/development.md](docs/development.md)（起動・テスト・CI）、backend の詳細は [backend/README.md](backend/README.md)。画面・データの形・起動方法・テストを変えたら、該当する人向けの説明も直す。

## 必ず守ること（詳細は各ファイル）

- 色は `lib/theme/app_colors.dart`、文言は `lib/constants/app_texts.dart`、数値は `app_sizes.dart` / `sections/config/`。ウィジェットに直接書かない（conventions.md）。
- スクロールはページ全体の 1 つだけ。対応する最小の幅は 320px（conventions.md）。
- `dart:html` / `package:web` / `FilePicker` / `rootBundle` を直接使わない。`utils/browser/browser.dart`・`utils/file_saver.dart`・`utils/file_pick.dart`・`utils/asset_text.dart` を通す（テストで差し替えるため）。
- テストは正常系と異常系の両方。網羅率は行・分岐とも 90% 以上（testing.md）。lib/ にファイルを足したら `dart run tool/coverage_check.dart --update-imports`。
- `// coverage:ignore-line` などの印は行の最後に置き、後ろに説明を書かない（testing.md）。
- 個人情報（`frontend/assets/profile/*.yaml`、`skill_sheet_yaml/` の中身）は Git にもイメージにも入れない。

## Claude の作業メモ

- 開発者本人（オーナー）とのやり取りが前提。回答は日本語で行う。
- Claude の作業環境には Flutter がない。テスト・解析・画面の確認はオーナーの手元で行い、結果を貼ってもらう（`coverage/` は手元のフォルダーから直接読める）。
- Git の操作（コミット・push）はオーナーが行う。
- 大きな変更の前には data-flow.md と status.md を確認する。
- 変更が構成・スキーマ・既知の問題に関わるときは、該当するファイルも一緒に更新する。
