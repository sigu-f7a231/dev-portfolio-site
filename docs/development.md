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

ログイン・マイページの URL（`#/login`・`#/me`・`#/me/edit`。今は準備中の空の画面）を開けるようにするには、`--dart-define=ENABLE_ACCOUNT=true` を付けて起動します（ふだんのビルド・公開ページでは開けず、`/` に移ります）。

```bash
flutter run -d chrome --dart-define=ENABLE_ACCOUNT=true
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

```bash
cd frontend
flutter analyze
flutter test                                   # すべて（約 20 秒）
flutter test test/home_page_test.dart          # 1 ファイルだけ
flutter test --coverage --branch-coverage      # 網羅率も記録（coverage/lcov.info）
dart run tool/coverage_check.dart              # 網羅率の集計と基準（行・分岐とも 90% 以上）の確認
dart run tool/coverage_check.dart --update-imports   # lib/ にファイルを足したら

cd ../backend && dart test                     # backend
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
