# services/

次の構成（[docs/plan/](../docs/plan/README.md)）のサーバーのサービスを置く場所。今はまだ中身がなく、それぞれの段階で作る。

| フォルダ | 言語・フレームワーク | 役割 | ポート（ローカル） | 作る段階 |
|---|---|---|---|---|
| [auth-phoenix/](auth-phoenix/README.md) | Elixir・Phoenix | 登録・ログイン・ログアウト・パスワード・トークン | 4100 | 4 |
| [api-hono/](api-hono/README.md) | TypeScript・Hono | マイページの API（プロフィール・スキル・職務経歴・表示設定・編集中・版・公開） | 8787 | 3 |
| [excel-fastapi/](excel-fastapi/README.md) | Python・FastAPI | Excel の処理のうち、ブラウザでやらないと決めたものだけ | 8001 | 6 |

- どのサービスも、ローカルでは Firebase Emulator（[firebase/](../firebase/README.md)）につなぐ。つなぎ先は環境変数 `FIREBASE_AUTH_EMULATOR_HOST`（`firebase:9099`）・`FIRESTORE_EMULATOR_HOST`（`firebase:8080`）で、なければ本物。
- 作ったら、サービスごとに Dockerfile・テスト・README を置き、ルートの `compose.yaml` に足す。
- 今ある `backend/`（shelf）は、`api-hono/` ができたら消す（段階 3）。
