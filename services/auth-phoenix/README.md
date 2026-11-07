# services/auth-phoenix

認証サービス（Elixir・[Phoenix](https://www.phoenixframework.org/)）。登録・ログイン・トークンの取り直し・ログアウト・パスワードの再設定と変更・退会を受け付け、**Firebase Auth の REST** を呼ぶ。パスワードは Firebase が持ち、ここには残さない（[決めること](../../docs/plan/decisions.md#d-01-認証の形) の D-01 の **B**）。

- 発行されるのは Firebase の ID トークンなので、API（[services/api-hono](../api-hono/README.md)）は今のまま「Firebase の ID トークンを確かめる」だけでよい。
- ここで足しているもの：入力の確認（メールアドレスの形・パスワード 8〜128 文字）、登録できる人の制限（`SIGNUP_ALLOWLIST`）、**総当たりの対策**（同じメールアドレス・接続元で続けて失敗したら 429）、**すべての端末からのログアウト**（更新用のトークンを使えなくする）、JSON のログ（メールアドレス・パスワード・トークンは書かない）。
- 設計：[サービスの構成](../../docs/plan/architecture.md)・[要件定義](../../docs/plan/requirements.md) の AUTH-01〜06。

## 起動

```bash
# リポジトリの直下で（Firebase Emulator と一緒に）
docker compose up --build auth        # http://localhost:4100/healthz
# 画面の nginx を通すなら http://localhost:8000/auth/...

# はじめて：mix.lock を作る（手元に Elixir がなくてよい。作ったらコミットする）
docker run --rm -v "$PWD/services/auth-phoenix":/app -w /app elixir:1.18-alpine \
  sh -c "mix local.hex --force && mix local.rebar --force && mix deps.get"
```

| 環境変数 | 既定 | 中身 |
|---|---|---|
| `PORT` | `4100` | 待ち受けるポート（Emulator の確認用の画面の既定 4000 を避けた） |
| `FIREBASE_PROJECT` | `demo-dev-portfolio` | Firebase のプロジェクト（`demo-` は Emulator だけ。Emulator なしでは起動しない） |
| `FIREBASE_API_KEY` | `demo` | 本物の Firebase の Web API キー（Emulator は何でもよい） |
| `FIREBASE_AUTH_EMULATOR_HOST` | なし | あれば Auth Emulator につなぐ（`firebase:9099` / `localhost:9099`） |
| `SIGNUP_ALLOWLIST` | なし（誰でも） | 登録できるメールアドレス（カンマ区切り。[D-03](../../docs/plan/decisions.md#d-03-新規登録を誰に開くか) の招待の形） |
| `ALLOWED_ORIGIN` | なし | ブラウザから別のオリジンで呼ぶときに許すオリジン（nginx を通すなら要らない） |
| `SECRET_KEY_BASE` | 起動ごとに作る | Phoenix の秘密（セッションは使わない） |

## API

すべて JSON。エラーは `{"error": {"code", "message"}}`（API（Hono）と同じ形）。

| メソッド | パス | 送るもの | 返すもの |
|---|---|---|---|
| GET | `/healthz` | | `{"status":"ok"}` |
| POST | `/auth/signup` | `{ email, password }` | 201 `{ uid, idToken, refreshToken, expiresIn }`。確認のメールを送る |
| POST | `/auth/login` | `{ email, password }` | `{ uid, idToken, refreshToken, expiresIn }` |
| POST | `/auth/refresh` | `{ refreshToken }` | 新しい `{ uid, idToken, refreshToken, expiresIn }` |
| GET | `/auth/me` | Bearer | `{ uid, email, emailVerified }` |
| POST | `/auth/logout` | Bearer | 204。**すべての端末**の更新用のトークンを使えなくする（ID トークンは期限の 1 時間まで残る） |
| POST | `/auth/password/reset` | `{ email }` | 204（登録があるかどうかは返さない） |
| POST | `/auth/password/change` | Bearer、`{ newPassword }` | 新しいトークン |
| DELETE | `/auth/account` | Bearer | 204（アカウントを消す。データの削除は段階 5 で API に） |

- Bearer は `Authorization: Bearer <ID トークン>`。ID トークンが正しいかは Firebase（`accounts:lookup`）が確かめる。
- ログインの失敗は、メールアドレスがない・パスワードが違うを区別しない（`invalid_credentials`）。
- 続けて失敗したら 429 と `Retry-After`（テストでない設定は 15 分に 5 回。台ごとに数える）。

| コード | 状態 | いつ |
|---|---|---|
| `invalid_request` | 400 | 必要なものを送っていない・JSON が読めない |
| `invalid_email` / `weak_password` | 400 | メールアドレスの形・パスワードの長さ |
| `unauthorized` / `invalid_credentials` | 401 | トークンがない・使えない／メールアドレスかパスワードが違う |
| `signup_not_allowed` | 403 | `SIGNUP_ALLOWLIST` にない |
| `email_exists` | 409 | もう登録されている |
| `too_many_attempts` | 429 | 続けて失敗した |
| `upstream_error` / `unavailable` | 502 / 503 | Firebase がエラー・つながらない |

## ファイル

| ファイル | 中身 |
|---|---|
| `lib/auth_service/accounts.ex` | 決まり（入力の確認・登録できる人・総当たりの対策）と Firebase の呼び出しをまとめる |
| `lib/auth_service/firebase.ex` | Firebase Auth の REST（Identity Toolkit・Secure Token）。Emulator / 本物の切り替え |
| `lib/auth_service/access_token.ex` | 管理者として呼ぶときのトークン（Emulator は `owner`、本物はメタデータサーバー） |
| `lib/auth_service/login_throttle.ex` | 失敗の数（ETS。メールアドレスはハッシュにする） |
| `lib/auth_service/error.ex` | エラーと、Firebase のエラーの名前の日本語 |
| `lib/auth_service_web/` | Endpoint・Router・コントローラー・JSON のログ・CORS |
| `config/runtime.exs` | 起動のときに環境変数から読む設定 |

## テスト

```bash
# 手元に Elixir があれば
mix deps.get && mix test
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 mix test --only emulator   # Emulator の上（docker compose up -d firebase のあと）

# Docker だけで（リポジトリの直下で）
docker run --rm -v "$PWD/services/auth-phoenix":/app -w /app -e MIX_ENV=test elixir:1.18-alpine \
  sh -c "mix local.hex --force && mix local.rebar --force && mix deps.get && mix test"
docker run --rm --network dev-portfolio_default -v "$PWD/services/auth-phoenix":/app -w /app -e MIX_ENV=test \
  -e FIREBASE_AUTH_EMULATOR_HOST=firebase:9099 elixir:1.18-alpine \
  sh -c "mix local.hex --force && mix local.rebar --force && mix deps.get && mix test --only emulator"
```

| ファイル | 確かめていること |
|---|---|
| `test/auth_controller_test.exs` | 各ルートの正常系・異常系（Firebase は Req.Test の偽物）、送った中身、同じ 401、総当たりの 429、すべての端末からのログアウト、再設定はいつも 204、ログに秘密を書かない、CORS |
| `test/firebase_test.exs` | つなぎ先（Emulator / 本物）、管理者のトークン、demo- の安全の確認、エラーの日本語、入力の確認、失敗の数え方 |
| `test/emulator_test.exs` | Auth Emulator の上で、登録 → ログイン → 自分の情報 → 取り直し → パスワードの変更 → ログアウト → 再設定 → 退会、二重の登録 |
