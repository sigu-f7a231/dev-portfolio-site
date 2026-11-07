# 開発ガイド

> 起動（Docker / Flutter / API）、テストと網羅率の基準、CI / デプロイ。
> プロジェクトの紹介は [README](../README.md)。

## 起動

### Docker（frontend + API + Firebase Emulator）

リポジトリの直下（`frontend/`・`services/`・`firebase/` がある場所）で：

```bash
docker compose up --build        # http://localhost:8000（API は http://localhost:8787、Emulator の確認用の画面は http://localhost:4001）
docker compose run --rm seed     # Emulator にサンプル（架空のデータ）を入れる。何度実行してもよい
docker compose up api            # API（と Emulator）だけ
docker compose up auth           # 認証（と Emulator）だけ
docker compose up firebase       # Firebase Emulator だけ
docker compose stop              # 止める（Emulator はデータを firebase/emulator-data/ に書き出し、次の起動で読み込む）
docker compose down              # 止めてコンテナを消す（書き出したデータは残る）
```

| サービス | ビルド | 中身 | ポート |
|---|---|---|---|
| `frontend` | `ghcr.io/cirruslabs/flutter:3.41.6` で `flutter build web` → `nginx:1.27-alpine` | Flutter Web を nginx で配信。`/api/` と `/healthz` は api へ、`/auth/` は auth へ転送（転送先は環境変数 `BACKEND_ORIGIN`・`AUTH_ORIGIN`）。index.html と Service Worker はキャッシュしない | 8000 |
| `api` | `node:22-bookworm-slim`（本番の依存だけ・`node` ユーザー） | マイページの API（`services/api-hono/`。Hono）。Firebase Emulator につなぐ。ヘルスチェック（`node src/server.ts healthcheck`）が通ってから frontend を起動 | 8787 |
| `auth` | `elixir:1.18-alpine` で `mix release` → 同じイメージ（`nobody` ユーザー） | 認証（`services/auth-phoenix/`。Phoenix）。Auth Emulator につなぐ。ヘルスチェック（`wget /healthz`）が通ってから frontend を起動。nginx の `/auth/` はここへ | 4100 |
| `firebase` | `node:22-bookworm-slim` ＋ Java 21（`eclipse-temurin:21-jre` から）＋ `firebase-tools@15.34.0` | Firebase Emulator（Auth・Firestore・確認用の画面）。プロジェクトは `demo-dev-portfolio`（本物にはつながらない）。止めるときに SIGINT を送ってデータを `firebase/emulator-data/`（Git 管理外）に書き出し、次の起動で読み込む。詳しくは [firebase/README.md](../firebase/README.md) | 4001（確認用の画面）・9099（Auth）・8080（Firestore）・9150・4400 |
| `seed` | `node:22-bookworm-slim` | `docker compose run --rm seed` のときだけ。Emulator にサンプル（`firebase/seed/sample.json` の架空のデータ）を入れる | ― |

- 詳しい構成・データの残り方・サンプル・つなぎ先・よくある失敗は [ローカルのクラウド](local-cloud.md)
- ポートの重なり：Firestore Emulator の既定は 8080（前の backend と同じだったが、backend は消した）。Emulator の確認用の画面の既定の 4000 は Phoenix と重なるので 4001、Phoenix は 4100 にした。これから足すサービスのポートは [サービスの構成](plan/architecture.md#2-ローカルの構成)（excel-fastapi 8001）
- Emulator で確かめるデータは **サンプルだけ** にする（個人の情報は入れない）。自分のデータで試したら、終わったら `firebase/emulator-data/` を消す

- 初回は Flutter のイメージの取得とビルドに数分かかります。Flutter のビルドはメモリを使うので、Docker に 6〜8GB 程度割り当ててください
- `frontend/assets/profile/` の個人のプロフィールは、イメージに入らないようにしています（`frontend/.dockerignore`）
- ビルドの引数：`FLUTTER_VERSION`（frontend の Flutter の版）、`BASE_HREF`（配信するパス。既定 `/`）
- `Cannot connect to the Docker daemon` と出たら、Docker Desktop / Rancher Desktop が起動しているか、`docker context ls` で接続先を確かめてください

### ローカル（Flutter）

```bash
cd frontend
flutter pub get
dart run tool/run.dart my_profile.yaml   # プロフィールを指定して起動（おすすめ）
# または
flutter run -d chrome                    # 起動後にプロフィールの入力画面が出る
```

ログイン・マイページ（`#/login`・`#/me`。`#/me/edit` はまだ準備中の空の画面）を開けるようにするには、`--dart-define=ENABLE_ACCOUNT=true` を付けて起動します（ふだんのビルド・公開ページでは開けず、`/` に移ります）。ログインには認証（`services/auth-phoenix`）と API（`services/api-hono`）が動いている必要があります。

いちばん簡単なのは Docker でまとめて動かす方法です（`compose.yaml` は `ENABLE_ACCOUNT=true` でビルドし、nginx が `/auth/`・`/api/` を転送します）。

```bash
docker compose up -d --build
docker compose run --rm seed          # サンプルの利用者 sample@example.com / sample-password
# http://localhost:8000/#/login
```

`flutter run` で直接つなぐときは、つなぎ先を指定し、各サービスに `ALLOWED_ORIGIN` を設定します。

```bash
flutter run -d chrome --web-port 5000 --dart-define=ENABLE_ACCOUNT=true \
  --dart-define=API_BASE=http://localhost:8787 --dart-define=AUTH_BASE=http://localhost:4100
```

ログインを使うビルドでは、ログインしていなければどの URL を開いてもログイン画面に移り、ログインすると開こうとした URL に戻ります。

ログインしている間は、プロフィール・Work / Private の保存先がこのタブの中（sessionStorage）から API（Firestore）に替わります（`lib/data/api_portfolio_repository.dart`）。

> `web/index.html`（起動時のローディング表示など）は Git で管理しています。CI の `flutter create . --platforms web` は既存のファイルを上書きしません。

本番と同じ設定でビルドする場合：

```bash
flutter build web --release --base-href "/dev-portfolio-site/"
```

### 認証だけ（Elixir・Phoenix）

手元に Elixir がなくても、Docker で動かせる（[services/auth-phoenix/README.md](../services/auth-phoenix/README.md)）。

```bash
docker compose up --build auth   # http://localhost:4100/healthz（画面の nginx を通すなら http://localhost:8000/auth/...）
```

### API だけ（Node）

```bash
cd services/api-hono
npm install                  # はじめて（package-lock.json ができたらコミットする）
docker compose up -d firebase   # リポジトリの直下で、Emulator を起動
FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 npm run dev   # http://localhost:8787
```

詳しくは [services/api-hono/README.md](../services/api-hono/README.md)。

---

## テスト

リポジトリの直下から `make` で動かせます（Node・Elixir・Python が手元になければ Docker の中で動かす）。

| コマンド | 中身 |
|---|---|
| `make test` | すべて（下の 5 つ。CI と同じ） |
| `make test-frontend` | Flutter：静的解析・テスト・網羅率の基準。`F=test/account_test.dart` で 1 ファイルだけ |
| `make test-api` | API（Hono）：型の確認・テスト。`make test-api-emulator` で Emulator の上のテスト（`make up` のあと） |
| `make test-auth` | 認証（Phoenix）：警告もエラーにするコンパイル・テスト。`make test-auth-emulator` で Emulator の上 |
| `make test-excel` | 見る人向けのスキルシート（FastAPI）：テスト・網羅率 |
| `make test-seed` | Emulator にサンプルを入れるスクリプト |
| `make smoke` | 全体の疎通（起動し直し → ログイン → API → 見る人向けのスキルシート） |
| `make imports` | `lib/` にファイルを足したら（網羅率の集計に入れる） |
| `make measure` | スキルシートを作る時間を測る |

個別に動かすとき：

```bash
cd frontend
flutter analyze
flutter test                                   # すべて（約 20 秒）
flutter test test/home_page_test.dart          # 1 ファイルだけ
flutter test --coverage --branch-coverage      # 網羅率も記録（coverage/lcov.info）
dart run tool/coverage_check.dart              # 網羅率の集計と基準（行・分岐とも 90% 以上）の確認
dart run tool/coverage_check.dart --update-imports   # lib/ にファイルを足したら

cd ../services/api-hono && npm run typecheck && npm test   # API（Emulator の上のテストは npm run test:emulator）
cd ../auth-phoenix && mix test                  # 認証（Elixir がなければ README の docker run で）
```

| ドキュメント | 中身 |
|---|---|
| [テスト計画書](testing/test-plan.md) | 目的・範囲・テストのレベル・観点（正常系 / 異常系 / 境界 / 組み合わせ）・環境・手動の確認・合格の基準・進め方・リスク・実績 |
| [テスト一覧](testing/test-catalog.md) | 各テストファイルが確かめていること（件数・観点）、補助ファイルと差し替えの入口、テストを足す場所 |

---

## CI / デプロイ

| ドキュメント | 中身 |
|---|---|
| [CI の設計](ci/ci-design.md) | ワークフロー（Test・Deploy）の流れ、ジョブとステップ、失敗する条件、ローカルでの同じ確認、失敗したときの見方 |
| [CI の状況](ci/ci-status.md) | 今の状態、ローカルでの最新の結果、初めて動かすときの注意点、既知の課題 |
| [今後の動き](roadmap.md) | テスト・CI・アプリ・インフラをこれからどの順で進めるか |

- `develop` への push は、そのまま公開ページに反映されます（今は Deploy が Test の結果を待ちません）
