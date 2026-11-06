# 設計

> システムの構成、データの流れ、backend の API、使っている技術、現状の課題と今後の計画。
> プロジェクトの紹介は [README](../README.md)。

## 構成

```mermaid
flowchart LR
  user(["ブラウザ"])
  subgraph compose["docker compose（compose.yaml）"]
    direction LR
    fe["frontend<br/>nginx が Flutter Web を配信<br/>:8000"]
    be["backend<br/>shelf + shelf_router<br/>:8081"]
    data[("backend/data/*.yaml")]
    fe -- "/api/・/healthz を転送" --> be
    be -- "読む（更新日時が変われば読み直す）" --> data
    emu["firebase<br/>Firebase Emulator（Auth・Firestore）<br/>確認用の画面 :4001"]
    edata[("firebase/emulator-data<br/>止めたときに書き出し")]
    emu --- edata
  end
  user -- ":8000" --> fe
  pages["GitHub Pages（公開ページ）<br/>Flutter Web のビルドだけ・backend なし"]
  user -. "公開ページ" .-> pages
```

- **frontend**（`frontend/`）：画面のすべて。表示するデータは、リポジトリのサンプル（`assets/data/`）か、画面から読み込んだもの（ブラウザの sessionStorage）。Excel / PDF の作成もブラウザの中で行い、サーバーには何も送りません。
- **backend**（`backend/`）：プロフィールと Work / Private を JSON で返す小さな API。今は frontend からは呼んでいません（次の段階で、frontend の読み込み先に API を足す予定）。
- **データの流れ**（frontend）

```mermaid
flowchart LR
  subgraph src["読み込み元（上から優先）"]
    direction TB
    s1["sessionStorage<br/>work / private"]
    s2["起動時の指定<br/>tool/run.dart"]
    s4["サンプル<br/>assets/data/format_*.yaml"]
  end
  repo["PortfolioRepository<br/>（今は LocalPortfolioRepository）"]
  prov["projectRecordsProvider（Riverpod）<br/>構造のデータ（Map の並び）"]
  src --> repo --> prov
  prov --> model["projectsListProvider<br/>Project.fromMap・技術の振り分け"]
  prov --> agg["skillsDataProvider<br/>skills_aggregator（割合 %）"]
  model --> projects["Projects<br/>絞り込み・並び替え・ページ送り・詳細"]
  agg --> skills["Skills<br/>棒 / 円グラフ"]
  p1["sessionStorage profile /<br/>起動時の指定"] --> repo2["PortfolioRepository"] --> store["ProfileStore"] --> pp["profileProvider"] --> home["Home / About"]
  prov --> home
  rev["dataRevisionProvider<br/>（Riverpod）"] -. "変わったら作り直す" .-> skills & projects
```

---

## backend（API）

| メソッド・パス | 応答 |
|---|---|
| `GET /healthz` | `{"status":"ok"}`（キャッシュしない） |
| `GET /api/profile` | プロフィール（`data/profile.yaml` を JSON に） |
| `GET /api/projects/work` | 業務のプロジェクト（`data/work.yaml`） |
| `GET /api/projects/private` | 個人開発のプロジェクト（`data/private.yaml`） |

- エラーは `{"error": {"code": "...", "message": "..."}}`：`not_found`（知らないパス）・`unknown_type`（work / private 以外）・`data_not_found`（ファイルがない）は 404、`invalid_data`（YAML の誤り・必須項目がない・読めない）は 500
- 確かめる内容はアプリのアップロード時と同じ（プロフィールは `home.name` / `home.role` / `home.tagline` / `about.intro` が必須、Work は `workflow` が必須、Private は `workflow` を書かない）
- `/api/` の応答は `Cache-Control: public, max-age=60`（CDN で短くキャッシュできるように）

| 環境変数 | 既定 | 内容 |
|---|---|---|
| `PORT` | `8080` | 待ち受けるポート（Cloud Run が自動で渡す） |
| `DATA_DIR` | `data` | YAML を置いたフォルダー |
| `ALLOWED_ORIGIN` | なし | ブラウザから直接呼ぶときに許す Origin（`flutter run` の別ポートから呼ぶときなど。nginx 経由なら不要） |

詳しくは [backend/README.md](../backend/README.md)。

---

## 技術スタック

| 分野 | 使っているもの |
|---|---|
| 画面 | **Flutter Web / Dart**（Dart SDK ^3.9.2、Material 3） |
| グラフ | [fl_chart](https://pub.dev/packages/fl_chart) |
| データ | [yaml](https://pub.dev/packages/yaml)（読み込み）、[archive](https://pub.dev/packages/archive) / [xml](https://pub.dev/packages/xml)（Excel .xlsx の読み書き）、[pdf](https://pub.dev/packages/pdf)（PDF の出力） |
| ブラウザ | [web](https://pub.dev/packages/web)（sessionStorage・ファイルの保存）、[file_picker](https://pub.dev/packages/file_picker)（ファイルの選択）、[url_launcher](https://pub.dev/packages/url_launcher)（公開ページへのリンク） |
| API | **Dart 3.11**、[shelf](https://pub.dev/packages/shelf) / [shelf_router](https://pub.dev/packages/shelf_router) |
| 実行環境 | **Docker / Docker Compose**（frontend は nginx、backend は scratch のネイティブ実行ファイル） |
| テスト | flutter_test、[test](https://pub.dev/packages/test)（backend）、網羅率は `flutter test --coverage --branch-coverage` と `tool/coverage_check.dart` |
| CI / 公開 | **GitHub Actions**、**GitHub Pages** |

> ブラウザの機能（`package:web`：sessionStorage・ファイルの保存）を使っているため、frontend は **Web 専用**です（テストは VM で動きます）。

---

## 現状と課題

**現状**（2026-11-06）：リポジトリを `frontend/`（Flutter）と `backend/`（API）に分け、Docker Compose で両方を起動できるようにしました。テストは正常系・異常系の両方を書き、網羅率は行 96.2%・分岐 90.4%（基準 90%）です。テストを足す中で見つけた不具合（円グラフの扇を押しても選べない、並び替えが毎回揺れる、スマホ幅のはみ出し、ページ送りの › が画面の外に出る）は直しました。ブラウザ・スマホでの見た目と操作は、引き続き実機での確認が必要です。

課題と今後の改善候補です（詳細は [docs/claude/status.md](claude/status.md)）。

**優先度 高**
- **画面での動作確認**：最近の変更は、実機（PC・タブレット・スマホ）での見た目と操作の確認がまだです
- **ローカルでビルドするとプロフィールが入る**：`assets/profile/profile.yaml` が残っていると `flutter build web` の成果物に含まれます（表示はしません）。Docker のビルドでは除いていますが、`flutter build web` を直接使うときは消してください
- **Work / Private の検証が浅い**：`projects` と `title`・`workflow` の有無しか確かめていないため、項目の型が違うと表示が崩れる可能性があります

**優先度 中**
- **期間で絞り込むと、期間を書いていない案件が必ず残る**
- **文字列の分割処理が複数ある**：値を文字で書くと、Skills のグラフでは空白でも区切られます（Projects のフィルターはカンマだけ）
- **Projects のページを切り替えても一覧の先頭に戻らない**
- **スマホでのグラフ操作**：棒グラフの強調表示はマウスを乗せたときだけで、タップには反応しません
- **Android で Google Drive のファイルを選べないことがある**：テキストの貼り付けで回避できます
- **frontend がまだ API を呼ばない**、**デプロイがテストの結果を待たない**
- **プロフィール YAML を書き換えたら起動し直しが必要**（`tool/run.dart` は起動時に 1 回読むだけ）

**優先度 低（仕様・整理）**
- **公開ページでは入力画面が出る**：プロフィールは各自がローカルで読み込む前提です
- **データはタブを閉じると消える**：アップロードした内容は sessionStorage にだけ保存しています
- **Web 専用**：ブラウザの機能（`package:web` / `dart:js_interop`）を使うため、Web 以外ではビルドできません
- **使っていない定数・依存パッケージが残っている**（`shared_preferences` など）
- **技術名の振り分け・グループ分けは名前からの推測**：一覧にない名前は、名前に含まれる言葉で推測し、わからなければ「その他」になります。合わないものは `lib/utils/tech_catalog.dart` の一覧に足してください

---

## 今後

目標の本番構成（費用ゼロ。まだ作っていない）：

```mermaid
flowchart LR
  user(["ブラウザ"]) --> cf
  subgraph cf["Cloudflare（無料）"]
    worker["Workers<br/>静的アセット（Flutter Web）<br/>/api/ をエッジでキャッシュ"]
  end
  subgraph gcp["GCP（無料枠・us-central1）"]
    run["Cloud Run<br/>backend（最小 0・最大 1〜2）"]
    gcs[("Cloud Storage<br/>公開用の YAML")]
    ar[("Artifact Registry<br/>イメージ")]
    mon["Cloud Monitoring / Logging<br/>アップタイム・SLO・ログ"]
  end
  worker -- "/api/*" --> run --> gcs
  ar -.-> run
  mon -.-> run
  gh["GitHub Actions<br/>frontend・Terraform"] -. "WIF（キーなし）" .-> gcp
  gh -.-> cf
  cb["Cloud Build<br/>backend のイメージ"] -.-> ar
```

- **frontend から API を読む**：Repository 層（`lib/data/`。構造のデータで受け渡す）・Riverpod（`lib/state/`。画面はすべて Provider から読む）・go_router（`lib/router/`）は入れた（2026-11-06）。次は API の Repository（構造のデータの 5 つ）を足し、読み先（サンプル・sessionStorage・API）を切り替える（画面は変えない）
- **費用をかけない本番構成**：配信は Cloudflare（Workers の静的アセット。`/api/` を Cloud Run へ転送してエッジでキャッシュ）、API は GCP の無料枠（Cloud Run・Artifact Registry・Cloud Storage、us-central1）
- **IaC と CI/CD**：Terraform（google / cloudflare プロバイダ、state は GCS、GitHub Actions からは Workload Identity Federation）、frontend と IaC は GitHub Actions、API のイメージは Cloud Build
- **監視**：Cloud Monitoring のアップタイムチェックと SLO（可用性・レイテンシ）のバーンレートアラート、構造化ログ（backend は対応済み）、予算のアラート

テスト・CI を含めた進める順番は [今後の動き](roadmap.md)。
