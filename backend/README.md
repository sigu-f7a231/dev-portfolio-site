# backend — ポートフォリオの API（shelf + shelf_router）

`data/` の YAML（`profile.yaml` / `work.yaml` / `private.yaml`）を JSON で返す、小さな API サーバーです。
書き方は frontend のひな形（`frontend/assets/data/format_*.yaml`）と同じです。最初はそのサンプルを置いています。

| メソッド・パス | 内容 |
|---|---|
| `GET /healthz` | 動作確認（`{"status":"ok"}`） |
| `GET /api/profile` | プロフィール（Home / About） |
| `GET /api/projects/work` | 業務のプロジェクト |
| `GET /api/projects/private` | 個人開発のプロジェクト |

エラーは `{"error": {"code": "...", "message": "..."}}` です（`not_found` / `unknown_type` / `data_not_found` は 404、`invalid_data` は 500）。
確認する内容はアプリのアップロード時と同じです（プロフィールは `home.name` / `home.role` / `home.tagline` / `about.intro` が必須、Work は `workflow` が必須、Private は `workflow` を書かない）。

## 起動

```bash
# Docker（リポジトリの直下で。frontend も一緒に起動）
docker compose up --build

# Dart で直接（backend/ で）
dart pub get
dart run bin/server.dart          # http://localhost:8080（Firebase Emulator の Firestore も 8080 なので、一緒に動かすときは PORT=8081 を付ける。compose ではこのパソコン側を 8081 にしている）
dart test                         # テスト
```

| 環境変数 | 既定 | 内容 |
|---|---|---|
| `PORT` | `8080` | 待ち受けるポート（Cloud Run が自動で渡す） |
| `DATA_DIR` | `data` | YAML を置いたフォルダー |
| `ALLOWED_ORIGIN` | なし | ブラウザから直接呼ぶときに許す Origin（`flutter run` の別ポートから呼ぶときなど） |

- ログは 1 リクエスト 1 行の JSON（`severity`・`httpRequest`）。Cloud Run ではそのまま Cloud Logging の構造化ログになります
- `SIGTERM` を受けると処理中のリクエストを終えてから止まります
- イメージは `dart compile exe` → `scratch` で 10MB 前後。`/app/bin/server healthcheck` でヘルスチェックします（コンテナに curl がないため）
- `data/` の YAML は更新日時が変わったときだけ読み直すので、書き換えれば再起動せずに反映されます
- **自分のデータを置くときは、個人情報が Git に入らないよう注意**してください（公開リポジトリならサンプルのままにして、本番はバケットなどから渡す）
