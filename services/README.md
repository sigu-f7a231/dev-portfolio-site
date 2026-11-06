# services/

次の構成（[docs/plan/](../docs/plan/README.md)）のサーバーのサービスを置く場所。api-hono はできた（段階 3）。ほかはそれぞれの段階で作る。

| フォルダ | 言語・フレームワーク | 役割 | ポート（ローカル） | 作る段階 |
|---|---|---|---|---|
| [auth-phoenix/](auth-phoenix/README.md) | Elixir・Phoenix | 登録・ログイン・ログアウト・パスワード・トークン | 4100 | 4 |
| [api-hono/](api-hono/README.md) | TypeScript・Hono | マイページの API（プロフィール・スキル・職務経歴・表示設定・編集中のデータ。版・公開は段階 5） | 8787 | 3（**済み**） |
| [excel-fastapi/](excel-fastapi/README.md) | Python・FastAPI | Excel の処理のうち、ブラウザでやらないと決めたものだけ | 8001 | 6 |

- どのサービスも、ローカルでは Firebase Emulator（[firebase/](../firebase/README.md)）につなぐ。つなぎ先は環境変数 `FIREBASE_AUTH_EMULATOR_HOST`（`firebase:9099`）・`FIRESTORE_EMULATOR_HOST`（`firebase:8080`）で、なければ本物。
- 作ったら、サービスごとに Dockerfile・テスト・README を置き、ルートの `compose.yaml` に足す。
- 前の `backend/`（shelf）は、`api-hono/` ができたので消した（2026-11-06）。
