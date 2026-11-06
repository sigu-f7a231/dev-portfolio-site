# services/excel-fastapi

> **まだ作っていない**（段階 6。[進め方](../../docs/plan/README.md#2-進め方)）。

| | |
|---|---|
| 言語・フレームワーク | Python・FastAPI |
| 役割 | Excel の処理のうち、ブラウザでやらないと決めたものだけ（D-06。書き出しが有力） |
| ポート（ローカル） | 8001 |
| 設計 | [サービスの構成](../../docs/plan/architecture.md)・[要件定義](../../docs/plan/requirements.md)・[決めること](../../docs/plan/decisions.md) |

作るときは、このフォルダに Dockerfile・テスト・README（起動の仕方・環境変数）を置き、ルートの `compose.yaml` に足す。ローカルでは Firebase Emulator（`../../firebase/`）につなぐ。
