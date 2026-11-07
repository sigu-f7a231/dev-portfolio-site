# CI の状況

> 今の CI とテストの状態。確かめたこと・まだのこと・注意点。状況が変わったら更新する。設計は [CI の設計](ci-design.md)。
> 更新：2026-11-06

---

## 1. まとめ

| 項目 | 状態 |
|---|---|
| Test（test.yml） | **追加済み・GitHub 上ではまだ動いていない**（追加したコミット `bb305d0` を push していないため） |
| Deploy（deploy.yml） | フォルダーの改名（`dev_portfolio/` → `frontend/`）に合わせてパスを直した。**改名後はまだ動いていない**（同じく未 push） |
| ローカルのテスト | 1 件を除いて成功（オーナーの手元）。その 1 件は原因を直したが、直したあとの実行はまだ（2 章） |
| ローカルの網羅率 | 行 **96.3%**・分岐 **90.7%**（基準 90% を満たす） |
| Docker | `docker compose up --build` で起動を確認（オーナーの手元） |

GitHub 上の実行の履歴（Actions のタブ）は、Claude の作業環境からは見られない。push したあとの結果はオーナーが確かめる。

## 2. ローカルでの最新の結果

| 確認 | 結果 | 日時 |
|---|---|---|
| `flutter test --coverage --branch-coverage`（全体） | 成功（Repository・Riverpod・go_router を入れたあと。ページ送りの修正のテストも含む） | 2026-11-06 |
| `flutter test` / `flutter analyze`（URL・構造のデータの Repository・画面が Provider から読む形にしたあと） | **未確認**（このあとオーナーの手元で実行） | ― |
| `dart run tool/coverage_check.dart` | 行 96.3%（5900 / 6125）・分岐 90.7%（2173 / 2397）、99 ファイル、基準を満たす。新しいファイル（`lib/data/`・`lib/state/`・`lib/router/`）は行・分岐とも 100% | 2026-11-06 |
| `node --test firebase/seed/seed.test.mjs` | 6 件すべて成功（Node 22、Claude のクラウドの作業場所で実行） | 2026-11-06 |
| `docker compose up --build`（Firebase Emulator を足したあと） | オーナーの手元で起動。「おそらく問題ない」との報告。seed・止めたときの書き出し・次の起動での読み込みを通しての記録はまだ（確かめ方は [ローカルのクラウド](../local-cloud.md#11-確かめたこと確かめ方)） | 2026-11-06 |
| `node --test`（api-hono のうち hono に依存しないもの：値・設定・ID トークン・Firestore・形の確認・読み書き） | 35 件すべて成功、`tsc` の型の確認も通る（Claude のクラウドの作業場所。npm のパッケージを取れないため、ルートと Emulator の上のテストは動かせない） | 2026-11-06 |
| `npm run test:emulator`（api-hono。Emulator の上で本人だけ・セキュリティルール） | 4 件すべて成功（オーナーの手元） | 2026-11-06 |
| `npm run typecheck`・`npm test`（api-hono 全体） | 型の誤りが 1 件（テストのヘッダーの型）→ 直して、`tsc` は通り、テストは 47 件すべて成功（Emulator の上の 4 件は環境変数がないので飛ばす） | 2026-11-06 |
| `docker compose up --build`（backend を api に置き換えたあと） | firebase・api・frontend がすべて起動し、api は healthy、`curl http://localhost:8787/healthz` → `{"status":"ok"}`（オーナーの手元。最初はファイルの権限で api が起動せず、`COPY --chown` で直した） | 2026-11-06 |
| `mix compile --warnings-as-errors`・`mix test`（auth-phoenix。elixir:1.18-alpine＝OTP 28） | コンパイルは警告なしで通った。テストは 31 件のうち 1 件が失敗（Phoenix 1.8 は 404・400 の例外を投げ直さないのに、投げ直す前提で書いていた）→ テストを直した。直したあとは**未確認** | 2026-11-06 |
| GitHub Actions の Test（作業用ブランチ `wip/stage5-6` で手動実行。段階 4〜6 のあと） | 5 つのジョブがすべて成功（[実行 42399896477](https://github.com/sigu-f7a231/dev-portfolio-site/actions/runs/42399896477)）。frontend：`flutter analyze` 指摘なし、テスト 895 件成功、行 96.7%（6490 / 6714）・分岐 91.6%（2449 / 2675）、126 ファイル。excel-fastapi：21 件成功（本物のコマンドの 2 件を含む）、網羅率 100%。api-hono・auth-phoenix・firebase-seed も成功。途中で excel-fastapi のテストの誤り 2 つ（手伝いの関数の名前・PDF の文字の空白）を直した | 2026-11-08 |
| `docker compose`（`make smoke`。段階 4〜6 のあと） | 37 項目すべて PASS（起動・ログイン・API・名前と公開・見る人向けの PDF と Excel・FastAPI のテスト）。途中で Excel のテンプレートの 403・seed の残り・nginx の住所を直した | 2026-11-08 |
| `flutter analyze` | 成功（上の GitHub Actions で。指摘なし） | 2026-11-08 |

## 3. 初めて動かすときの注意点

まだ GitHub 上で一度も動いていないので、次のところで止まる可能性がある。止まったら [CI の設計](ci-design.md#5-失敗したときの見方) の見方で原因を確かめる。

| 注意点 | 起こりうること | 対応 |
|---|---|---|
| `flutter analyze` を CI で初めて動かす | 新しく足したテスト・コードの指摘（使っていない import など）で止まる | 指摘を直してコミット |
| Flutter 3.41.6 の取得 | `subosito/flutter-action` が版を見つけられない | 版の書き方を直すか、`channel: stable` だけにする |
| `--branch-coverage` | 分岐の情報が出ない（版による） | `coverage_check.dart` が「分岐の情報なし」で知らせる |
| api-hono の `npm ci` | `package-lock.json` がまだないと、毎回 `npm install` で版がそろわない | オーナーの手元で `npm install` し、lock をコミットする |
| Deploy のパス | `frontend/` への改名後、初めてのビルド | ビルドのログでパスの誤りを確かめる |
| Deploy がテストを待たない | テストが失敗していても、develop に push すれば公開される | 今は push の前にローカルで確かめる。今後つなぐ（[今後の動き](../roadmap.md)） |

## 4. 次に確かめること

1. `flutter test test/coverage_extra_test.dart`（ページ送りの修正）
2. `flutter analyze`（ローカル）
3. push して、Actions のタブで Test・Deploy の両方が成功するか
4. 公開ページ（https://sigu-f7a231.github.io/dev-portfolio-site/ ）が開けるか
5. 結果をこのファイルの 1・2 章に書き込む

## 5. 既知の課題（CI）

| 課題 | 影響 | 予定 |
|---|---|---|
| Deploy が Test を待たない | テストが落ちたままでも公開される | Deploy を Test の成功のあとに動かす |
| ブランチの保護がない | develop に直接 push できる・失敗しても入る | プルリクエストと、Test の成功を必須にする |
| Docker イメージのビルドを CI で確かめていない | Dockerfile が壊れても気づかない | `docker compose build` のジョブを足す |
| api の網羅率を測っていない | api のテストの抜けに気づけない | `node --test --experimental-test-coverage` で測り、frontend と同じ基準にする |
| Emulator の上のテストを CI で動かしていない | 本人だけ・セキュリティルールの崩れに気づけない | 段階 7 で、CI で Emulator を起動して `npm run test:emulator` |
| 画面の見た目の変化（ゴールデン）・実ブラウザでの動き（E2E）を確かめていない | 色や配置の変化・ブラウザだけで起きる不具合に気づけない | ゴールデンテスト、Playwright での E2E |

いつ・どの順で進めるかは [今後の動き](../roadmap.md)。
