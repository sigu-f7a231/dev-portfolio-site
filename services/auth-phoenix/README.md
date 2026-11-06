# services/auth-phoenix

> **まだ作っていない**（段階 4。[進め方](../../docs/plan/README.md#2-進め方)）。

| | |
|---|---|
| 言語・フレームワーク | Elixir・Phoenix |
| 役割 | 登録・ログイン・ログアウト・パスワードの変更と再設定・トークンの発行と取り直し・総当たりの対策（パスワードの持ち方は docs/plan/decisions.md の D-01） |
| ポート（ローカル） | 4100 |
| 設計 | [サービスの構成](../../docs/plan/architecture.md)・[要件定義](../../docs/plan/requirements.md)・[決めること](../../docs/plan/decisions.md) |

作るときは、このフォルダに Dockerfile・テスト・README（起動の仕方・環境変数）を置き、ルートの `compose.yaml` に足す。ローカルでは Firebase Emulator（`../../firebase/`）につなぐ。
