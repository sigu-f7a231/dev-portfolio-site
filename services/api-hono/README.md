# services/api-hono

マイページの API（TypeScript・[Hono](https://hono.dev/)）。プロフィール・スキル・職務経歴・表示設定・編集中のデータを、Firestore（ローカルでは Firebase Emulator）に読み書きする。前の `backend/`（Dart の shelf）を置き換えた（2026-11-06）。

- 設計：[サービスの構成](../../docs/plan/architecture.md)・[データ設計](../../docs/plan/data-model.md)・[要件定義](../../docs/plan/requirements.md) の API-01〜08
- ローカルの Firebase：[ローカルのクラウド](../../docs/local-cloud.md)

## 起動

```bash
# リポジトリの直下で（Firebase Emulator と一緒に）
docker compose up --build api            # http://localhost:8787/healthz
docker compose run --rm seed             # サンプルを入れる

# このフォルダで（Node 22.18 以上。TypeScript をそのまま動かす。ビルドはない）
npm install
docker compose up -d firebase            # Emulator（リポジトリの直下で）
FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 npm run dev

# Cloudflare Workers の環境で確かめる（wrangler dev。設定は wrangler.toml）
npm run dev:workers
```

| 環境変数 | 既定 | 中身 |
|---|---|---|
| `PORT` | `8787` | 待ち受けるポート（Node だけ。Cloud Run は自動で渡す） |
| `FIREBASE_PROJECT` | `demo-dev-portfolio` | Firebase のプロジェクト。`demo-` で始まる名前は Emulator だけ（本物には向かない） |
| `FIRESTORE_EMULATOR_HOST` | なし | あれば Firestore Emulator につなぐ（`firebase:8080` / `localhost:8080`）。管理者（`Bearer owner`）として読み書きする |
| `FIREBASE_AUTH_EMULATOR_HOST` | なし | あれば Auth Emulator のトークン（署名なし）を受け付ける。`FIRESTORE_EMULATOR_HOST` もないと起動しない（本物のデータを署名なしのトークンで読ませないため） |
| `ALLOWED_ORIGIN` | なし | ブラウザから別のオリジンで呼ぶときに許すオリジン（`flutter run --web-port 5000` なら `http://localhost:5000`） |

## API

すべて JSON。エラーは `{"error": {"code", "message", "details"?}}`（`details` は入力の誤りの一覧）。

| メソッド | パス | ログイン | 中身 |
|---|---|---|---|
| GET | `/healthz` | いらない | 動作確認。`{"status":"ok"}` |
| GET | `/api/public/:slug` | いらない | 公開ページのデータ（`publicPages/{slug}`）。なければ 404。CDN で 60 秒キャッシュ |
| GET / PUT | `/api/me/draft` | 要る | 編集中のデータ全体。PUT は `{ "data": ..., "updatedAt": 読んだときの値（はじめては null） }`。違えば 409（別のタブ・端末で先に変わった） |
| GET / PUT | `/api/me/profile` | 要る | プロフィール（`home`・`about`・`sheet`）を置き換え |
| GET / PUT | `/api/me/skills` | 要る | スキル（`recentTech`・`pastTech`）を置き換え |
| GET / PUT | `/api/me/display` | 要る | Home の表示設定を置き換え |
| GET | `/api/me/projects` | 要る | 職務経歴の一覧 |
| POST | `/api/me/projects` | 要る | 1 件足す（201）。`id` がなければ作り、`order` は同じ種類の最後 |
| PUT | `/api/me/projects/:id` | 要る | 1 件を置き換え（`id` は変えられない） |
| DELETE | `/api/me/projects/:id` | 要る | 1 件消す（204） |

- **ログイン**：`Authorization: Bearer <Firebase の ID トークン>`。本物は Google の公開鍵で RS256 の署名を、Emulator は中身だけを確かめる（宛先・発行元・期限・発行時刻・利用者）。
- **本人のデータだけ**：読み書きする文書のパスは、確かめたトークンの uid から作る（`users/{uid}/...`）。ほかの人の uid は受け取らない。
- **形の確認**：書く前に必ず確かめる（`src/validate.ts`。形は [データ設計](../../docs/plan/data-model.md#2-項目と型) の 2.）。編集中のデータなので必須の項目が空でもよい。
- **同時に変えたとき**：全体の保存は `updatedAt` が違えば 409。まとまりごと（プロフィールなど）・職務経歴の保存は、ほかのまとまりを消さないよう読み直して 3 回までやり直す。
- **まだないもの**：版（保存・戻す）と公開（API-06・07）、slug の設定。段階 5 で画面と一緒に作る。

## ファイル

| ファイル | 中身 |
|---|---|
| `src/app.ts` | ルート（Hono）・ログ・CORS・エラーの JSON |
| `src/portfolio.ts` | 本人のデータの読み書き（編集中のデータ・まとまりごと・職務経歴・公開ページ） |
| `src/validate.ts` | 受け取ったデータの形の確認 |
| `src/auth.ts` | ID トークンの確認（Web Crypto。Node・Workers のどちらでも動く） |
| `src/firestore.ts` | Firestore の REST（`DocStore`。Emulator は `Bearer owner`、本物はメタデータサーバーのアクセストークン） |
| `src/values.ts` | JavaScript の値 ⇔ Firestore の値 |
| `src/config.ts` | 環境変数から設定（demo- のプロジェクトは Emulator だけ、などの安全の確認） |
| `src/log.ts` | 1 行 1 件の JSON ログ（Cloud Logging の構造化ログ）。個人の情報は書かない |
| `src/setup.ts` | 設定からアプリを組み立てる |
| `src/server.ts` | Node の入口（SIGTERM で止まる・`healthcheck`） |
| `src/worker.ts` | Workers の入口（今は Emulator だけ。本物の Firestore には、サービスアカウントの JWT が要る） |
| `Dockerfile` | `node:22-bookworm-slim`、本番の依存だけ、`node` ユーザーで動かす |

## テスト

```bash
npm test                 # 単体・ルートのテスト（Emulator のテストは環境変数がなければ飛ばす）
npm run typecheck        # 型の確認（tsc）
# Emulator の上で（docker compose up -d firebase のあと）
FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 npm run test:emulator
```

| ファイル | 確かめていること |
|---|---|
| `test/values.test.ts` | Firestore の値への変換と戻し |
| `test/config.test.ts` | 環境変数・安全の確認（demo- なのに Emulator なし、Auth だけ Emulator） |
| `test/auth.test.ts` | RS256 の署名（正しい・違う鍵・鍵がない・署名なし）、Emulator のトークン、宛先・発行元・期限などの異常系 |
| `test/firestore.test.ts` | REST に送る中身（読む・書く・項目だけ・消す・前提）、前提が崩れたとき、本物のアクセストークン |
| `test/validate.test.ts` | プロフィール・スキル・職務経歴・表示設定・全体の形の正常系と異常系 |
| `test/portfolio.test.ts` | 本人の文書だけに書く、409（読んだあと・書くまでの間に変わった）、まとまりごとのやり直し、職務経歴の追加・変更・削除、公開ページ |
| `test/app.test.ts` | ルート：401・本人だけ・400 と誤りの一覧・409・201 / 204・404・500・ログ（uid や中身を書かない）・CORS |
| `test/emulator.test.ts` | Emulator の上で：Auth Emulator のトークンで本人だけ、セキュリティルールが直接の読み書きを断る |
