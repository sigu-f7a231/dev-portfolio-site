# firebase/

ローカルで使う Firebase Emulator（Auth・Firestore・確認用の画面）。本物の Firebase にはつながらない（プロジェクトは `demo-dev-portfolio`。`demo-` で始まる名前は Emulator だけで使える）。

> 全体の構成・ポート・起動から止めるまでの流れ・データの残り方・つなぎ先・よくある失敗は [ローカルのクラウド](../docs/local-cloud.md)。ここはこのフォルダのファイルと使い方の要約。

| ファイル | 中身 |
|---|---|
| `Dockerfile` | Node 22 ＋ Java 21（firebase-tools 15 に必要）＋ firebase-tools（版を固定）。Firestore と確認用の画面の本体はビルドのときに取っておく |
| `firebase.json` | エミュレーターのポート（下の表）。コンテナの外から見られるよう `0.0.0.0` で待つ |
| `firestore.rules` | Firestore のセキュリティルール。今は画面からの読み書きを全部断る（[データ設計](../docs/plan/data-model.md#5-セキュリティルール案)） |
| `entrypoint.sh` | 起動。前に書き出したデータがあれば読み込み、止めたときに書き出す |
| `seed/seed.mjs`・`seed/sample.json` | サンプル（架空の人・案件）を入れるスクリプトとデータ |
| `seed/seed.test.mjs` | スクリプトのテスト（偽物の Emulator に送った中身を確かめる） |
| `emulator-data/` | 書き出したデータ（**Git 管理外**。止めるたびに作り直される） |

## 使い方（リポジトリのルートで）

```bash
docker compose up --build firebase   # Emulator だけ起動（全部なら docker compose up --build）
docker compose run --rm seed         # サンプルを入れる（何度実行してもよい）
open http://localhost:4001           # 確認用の画面（Auth の利用者・Firestore の文書を見る）
docker compose stop firebase         # 止める（データを emulator-data/ に書き出す）
rm -rf firebase/emulator-data        # データを消して、空から始める
node --test firebase/seed/seed.test.mjs   # スクリプトのテスト（Node 22。パッケージはいらない）
```

| ポート | 中身 |
|---|---|
| 4001 | 確認用の画面（Emulator UI。既定の 4000 は Phoenix と重なるので変えた） |
| 9099 | Auth |
| 8080 | Firestore（既定のまま） |
| 9150 | 確認用の画面が Firestore を見るための WebSocket |
| 4400 | ハブ（起動しているエミュレーターの一覧。compose の healthcheck が使う） |

## サンプル

- 利用者：`sample@example.com` / `sample-password`（Emulator の中だけのアカウント）、公開ページの名前（slug）は `sample`。
- 文書：`users/{uid}`・`users/{uid}/drafts/current`・`users/{uid}/versions/1`・`slugs/sample`・`publicPages/sample`（形は [データ設計](../docs/plan/data-model.md#3-firestore-のコレクション)）。公開ページには、スキルシートだけの項目（`sheet`）を入れない。
- **個人の情報は入れない**：確認には `sample.json` の架空のデータだけを使う。自分のデータで試したときは、終わったら `emulator-data/` を消す。

## 注意

- `docker compose kill` や Docker の強制終了では書き出さない（そのときの変更は消える）。
- 書き出しは「止めたとき」だけ。動いている間の変更は、止めるまでファイルに残らない。
