# 起動・Docker・CI / デプロイ

> 開発のコマンド、Docker Compose、GitHub Actions。起動方法やビルド・CI を変えるときに読む。

## コマンド（`frontend/` で実行）

```bash
flutter pub get
dart run tool/run.dart my_profile.yaml   # プロフィール YAML を指定して起動（Home / About の内容）
dart run tool/run.dart                   # 指定なし → 起動後に「あなたのことを教えてください」を表示
flutter run -d chrome                    # ローカルで動作確認（Web 専用）
flutter analyze
flutter build web --release --base-href "/dev-portfolio-site/"
```

- web/ ディレクトリがない環境では、先に `flutter create . --platforms web` を実行する。
- フォルダーは 2026-11-06 に `dev_portfolio/` から `frontend/` に改名した。改名前に起動した `flutter run` の Chrome が古い場所に `.dart_tool/chrome-device` を作り直すことがある（ルートの `.gitignore` で `/dev_portfolio/` を除外）。生成物に古いパスが残っていたら `flutter clean && flutter pub get`。
- テストのコマンドは `testing.md`。

## Docker Compose（リポジトリの直下で）

```bash
docker compose up --build    # frontend http://localhost:8000（/api/ と /healthz は api へ）・api http://localhost:8787・Emulator の画面 http://localhost:4001
docker compose run --rm seed # Firebase Emulator にサンプル（架空のデータ）を入れる
docker compose up api        # API（と Emulator）だけ
docker compose down
```

| サービス | イメージ | 中身 |
|---|---|---|
| `frontend` | `ghcr.io/cirruslabs/flutter:3.41.6`（ローカルと同じ版。`FLUTTER_VERSION` で変更）でビルド → `nginx:1.27-alpine` | `flutter build web`（`BASE_HREF` で配信パス）→ nginx で配信。`nginx/default.conf.template` の `${BACKEND_ORIGIN}` は起動時に環境変数で置き換わる。index.html・Service Worker はキャッシュしない。SPA なのでファイルがなければ index.html |
| `api` | `node:22-bookworm-slim` | `services/api-hono`（Hono）。Node 22 が TypeScript の型を外してそのまま動かす（ビルドなし）。Firebase Emulator につなぐ。ヘルスチェックは `node src/server.ts healthcheck` |

- frontend は api のヘルスチェックが通ってから、api は firebase のヘルスチェックが通ってから起動する（`depends_on: condition: service_healthy`）。
- `frontend/.dockerignore` で `assets/profile/*`（個人のプロフィール）をイメージに入れない（`assets/profile/` はフォルダーごとアセットなので、入ると公開ページから取り出せる）。
- ローカルの Docker はオーナーの Mac の Rancher Desktop（dockerd / moby）。`docker context use rancher-desktop`。
- 本番の構成案（Cloudflare＋GCP の無料枠、Terraform、Cloud Build、SLO）は `docs/design.md` の「今後」にまとめた。まだ作っていない。

## api（`services/api-hono/` で）

```bash
npm install
FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 npm run dev   # http://localhost:8787
npm run typecheck && npm test
FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 npm run test:emulator
```

環境変数：`PORT`（既定 8787）、`FIREBASE_PROJECT`（既定 demo-dev-portfolio）、`FIRESTORE_EMULATOR_HOST`・`FIREBASE_AUTH_EMULATOR_HOST`（Emulator）、`ALLOWED_ORIGIN`。API の一覧は `services/api-hono/README.md`。

- Node 22.18 以上は `.ts` をそのまま動かす（型を外すだけ）。enum・引数のプロパティなど、型を外すだけでは消えない書き方は使わない（`tsconfig.json` の `erasableSyntaxOnly`）。import は `.ts` まで書く。
- Claude のクラウドの作業場所では npm のパッケージを取れないので、hono に依存しないファイル（`src/` の app・setup・server・worker 以外と、そのテスト）だけを `node --test` と `tsc` で確かめられる。ルートと Emulator のテストはオーナーの手元で動かす。

## CI / デプロイ（`.github/workflows/`）

- `test.yml`：`develop` / `main` への push、プルリクエスト、手動。
  - frontend：Flutter 3.41.6 → `pub get` → `analyze` → `flutter test --coverage --branch-coverage` → `dart run tool/coverage_check.dart --min-line 90 --min-branch 90`（結果を Actions のサマリーに出す。`shell: bash` で pipefail を付け、tee を挟んでも失敗が伝わる）→ `coverage/` を artifact に保存。
  - api-hono：Node 22 → `npm ci`（lock がなければ `npm install`）→ `npm run typecheck` → `npm test`。
  - firebase-seed：Node 22 → `node --test firebase/seed/seed.test.mjs`。
- `deploy.yml`：**`develop` への push**（または手動実行）→ Flutter stable 3.x → `pub get` → `flutter create . --platforms web` → `build web --base-href "/dev-portfolio-site/"` → `actions/deploy-pages@v4`。
  - develop への push はそのまま本番公開になるので注意する。今は test.yml の結果を待たずにデプロイする（`needs` でつないでいない）。
- `.github/` はファイルを書き戻す仕組み（device_commit_files）では書き込めない。Claude は手元のシェル（device_bash）で書く。
