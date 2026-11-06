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
docker compose up --build    # frontend http://localhost:8000（/api/ と /healthz は backend へ）・backend http://localhost:8081・Emulator の画面 http://localhost:4001
docker compose run --rm seed # Firebase Emulator にサンプル（架空のデータ）を入れる
docker compose up backend    # API だけ
docker compose down
```

| サービス | イメージ | 中身 |
|---|---|---|
| `frontend` | `ghcr.io/cirruslabs/flutter:3.41.6`（ローカルと同じ版。`FLUTTER_VERSION` で変更）でビルド → `nginx:1.27-alpine` | `flutter build web`（`BASE_HREF` で配信パス）→ nginx で配信。`nginx/default.conf.template` の `${BACKEND_ORIGIN}` は起動時に環境変数で置き換わる。index.html・Service Worker はキャッシュしない。SPA なのでファイルがなければ index.html |
| `backend` | `dart:3.11` でビルド → `scratch` | `dart compile exe` の実行ファイルだけ（10MB 前後）。`backend/data` を読み取り専用でマウント。ヘルスチェックは `/app/bin/server healthcheck`（コンテナに curl がない） |

- frontend は backend のヘルスチェックが通ってから起動する（`depends_on: condition: service_healthy`）。
- `frontend/.dockerignore` で `assets/profile/*`（個人のプロフィール）をイメージに入れない（`assets/profile/` はフォルダーごとアセットなので、入ると公開ページから取り出せる）。
- ローカルの Docker はオーナーの Mac の Rancher Desktop（dockerd / moby）。`docker context use rancher-desktop`。
- 本番の構成案（Cloudflare＋GCP の無料枠、Terraform、Cloud Build、SLO）は `docs/design.md` の「今後」にまとめた。まだ作っていない。

## backend（`backend/` で）

```bash
dart pub get
dart run bin/server.dart     # http://localhost:8080（DATA_DIR 既定 data）
dart test
```

環境変数：`PORT`（既定 8080。Cloud Run が渡す）、`DATA_DIR`（既定 data）、`ALLOWED_ORIGIN`（ブラウザから直接呼ぶときに許す Origin）。API の一覧は README と `backend/README.md`。

## CI / デプロイ（`.github/workflows/`）

- `test.yml`：`develop` / `main` への push、プルリクエスト、手動。
  - frontend：Flutter 3.41.6 → `pub get` → `analyze` → `flutter test --coverage --branch-coverage` → `dart run tool/coverage_check.dart --min-line 90 --min-branch 90`（結果を Actions のサマリーに出す。`shell: bash` で pipefail を付け、tee を挟んでも失敗が伝わる）→ `coverage/` を artifact に保存。
  - backend：Dart 3.11 → `pub get` → `analyze` → `test`。
- `deploy.yml`：**`develop` への push**（または手動実行）→ Flutter stable 3.x → `pub get` → `flutter create . --platforms web` → `build web --base-href "/dev-portfolio-site/"` → `actions/deploy-pages@v4`。
  - develop への push はそのまま本番公開になるので注意する。今は test.yml の結果を待たずにデプロイする（`needs` でつないでいない）。
- `.github/` はファイルを書き戻す仕組み（device_commit_files）では書き込めない。Claude は手元のシェル（device_bash）で書く。
