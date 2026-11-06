# services/api-hono

> **まだ作っていない**（段階 3。[進め方](../../docs/plan/README.md#2-進め方)）。

| | |
|---|---|
| 言語・フレームワーク | TypeScript・Hono |
| 役割 | マイページの API と、公開ページのデータを返す。Firestore への読み書きはここだけ（D-05 の案） |
| ポート（ローカル） | 8787 |
| 設計 | [サービスの構成](../../docs/plan/architecture.md)・[要件定義](../../docs/plan/requirements.md)・[決めること](../../docs/plan/decisions.md) |

作るときは、このフォルダに Dockerfile・テスト・README（起動の仕方・環境変数）を置き、ルートの `compose.yaml` に足す。ローカルでは Firebase Emulator（`../../firebase/`）につなぐ。
