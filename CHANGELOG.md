# 更新履歴

> このプロジェクトの変更の記録。新しいものが上。日付は日本時間、括弧の中はコミット（`git show <ハッシュ>` で中身を見られる）。
> タグ・版番号はまだ付けていない（本番に出すようになったら、出した時点でタグを付けて見出しにする）。
> 分類：**追加**（新しい機能・ファイル）／**変更**（今ある機能の変更）／**修正**（不具合）／**削除**／**ドキュメント**／**テスト・CI**。

## 書き方（変更したら）

- 変更したら、まず「未コミット」に 1 行ずつ足す。コミットしたら、その日の見出しを作ってコミットのハッシュを付けて移す。
- 画面・データの形・起動方法・テストなど、使う人・作る人に関係する変更を書く。中の作りだけの変更は「変更」にまとめて短く。
- 個人の情報（プロフィールの中身・スキルシートの中身）は書かない。

---

## 未コミット

### Phoenix の認証（段階 4。D-01 の B）
- **追加**：`services/auth-phoenix/`（Elixir・Phoenix・Bandit・Req）。登録（確認のメール）・ログイン・トークンの取り直し・自分の情報・すべての端末からのログアウト・パスワードの再設定と変更・退会（`/auth/*`）。パスワードは Firebase Auth が持ち、Phoenix は REST を呼ぶ窓口。発行されるのは Firebase の ID トークンなので、API（Hono）は変えていない
- **追加**：入力の確認（メールアドレスの形・パスワード 8〜128 文字）、登録できる人の制限（`SIGNUP_ALLOWLIST`）、総当たりの対策（同じメールアドレス・接続元で続けて失敗したら 429 と Retry-After）、ログインの失敗の理由を区別しない、再設定はいつも 204、JSON のログ（メールアドレス・パスワード・トークンは書かない）、demo- のプロジェクトは Emulator なしでは起動しない
- **テスト・CI**：ExUnit 33 件（ルート 22・つなぎ先と入力 9・Emulator の上 2）。CI に `auth-phoenix`（OTP 28・Elixir 1.18。警告もエラーにするコンパイル・テスト）。読めない JSON・大きすぎる・JSON でない送信は、例外にせず同じ形の JSON で 400・413・415 を返す（`plugs/json_body.ex`）
- **変更**：compose に `auth`（4100）、画面の nginx の `/auth/` を auth へ（`AUTH_ORIGIN`）、frontend は auth も healthy になってから起動
- **決定**：D-01 を B に。D-03 は仕組み（`SIGNUP_ALLOWLIST`）だけ作り、本番の方針は未決
- **ドキュメント**：設計・開発ガイド・ファイル構成・ライブラリ・ローカルのクラウド・テスト一覧・CI・計画（決めること・進め方）・CLAUDE.md・docs/claude/・README・services/

---

### ログイン・マイページ（段階 5-1）

- API（`services/api-hono`）に本人の情報（`GET /api/me`）・公開ページの名前（`PUT /api/me/slug`）・公開する／止める（`POST`・`DELETE /api/me/publish`）・データをすべて消す（`DELETE /api/me`）を追加。公開ページにはスキルシートだけの項目と表示設定で隠したものを入れない（`src/publish.ts`）
- Flutter：認証・API の呼び出し（`lib/api/`・`lib/auth/auth_api.dart`、パッケージ `http`）、ログインの状態（`lib/auth/auth_controller.dart`。ID トークンの取り直し、このタブで続けてログイン）
- ログイン中の Repository（`lib/data/api_portfolio_repository.dart`・`api_records.dart`）。ログインすると保存先がこのタブの中から API（Firestore）に替わる。ほかの場所で先に変わっていたら 3 回までやり直す
- ログインしたら公開ページ（`/`）に移り、一番上のバー（`lib/widgets/account_bar.dart`）から公開する・止める・［マイページ］（名前・ログアウト・退会のダイアログ）・ログアウトを操作する。マイページの中身は `MyPagePanel` にまとめ、`/me` とダイアログで共通。ログイン画面の［公開ページへ戻る］は外した（公開ページもログインが要るため）。ログインした直後の公開ページが、プロフィールを読み終わる前に入力画面を出さないようにした（`ProfileStore.loading`）
- ログインを使うビルドでは、ログインしていなければどの URL もログイン画面（`/login?from=開こうとした URL`）に移り、ログインしたら開こうとした URL へ戻る（`loginRedirect`・`lib/auth/auth_gate.dart`。ほかのサイトの URL には移らない）
- ログイン・登録・パスワードの再設定の画面（`/login`）、マイページ（`/me`：公開ページの名前・公開する／止める・ログアウト・退会）。`ENABLE_ACCOUNT` のときだけ。`compose.yaml` の frontend は `ENABLE_ACCOUNT=true` でビルド
- テスト：`api_client_test`・`api_records_test`・`account_test`（認証・API は偽物の `test/fake_backend.dart`）

### Excel と FastAPI（段階 6。D-06）

- **決定**：D-06。Excel の読み込みと、本人がダウンロードする Excel・PDF は今の Flutter（ブラウザ）のまま。FastAPI には見る人向けのスキルシート（Excel・PDF）だけを任せる（比べた結果は `docs/plan/excel.md`）
- **追加**：`services/excel-fastapi/`（Python 3.12・FastAPI）。公開ページのデータを受け取り、本人がダウンロードするものと同じ形（Excel のテンプレート。PDF はその見た目のまま）のスキルシートにして返す。作るのはブラウザと同じ Dart の処理（`frontend/bin/skill_sheet.dart` を `dart compile exe`）。Firestore にはつながない。`INTERNAL_TOKEN` で api からだけ受け付ける。pytest 21 件（うち本物のコマンドの 2 件は CI で。網羅率 90%）
- **追加**：Flutter に依存しない共通の部品 `lib/utils/skill_sheet_data.dart`（本人の［ダウンロード］と見る人向けで、書く中身・並びを同じにする）・`skill_sheet_cli.dart`。テスト `skill_sheet_data_test`
- **追加**：API（Hono）に `GET /api/public/:slug/skill-sheet.pdf`・`.xlsx`。表示設定の `allowSheetDownload` が `true` のときだけ（ほかは 404）、excel に作らせて返す（`src/sheet.ts`。`EXCEL_ORIGIN`・`EXCEL_INTERNAL_TOKEN`）。テスト 6 件
- **変更**：compose に `excel`（8001）。api から `http://excel:8001` を呼ぶ。サンプルの利用者は `allowSheetDownload: true`（確かめやすいように）。CI に `excel-fastapi`
- **修正**：ログイン中に Excel を読み込むと保存で弾かれていた。API に送る前に文字数を API と同じ上限にし、生年月日を `YYYY-MM-DD` にする（`lib/data/api_records.dart`）
- **修正**：保存に失敗しても「読み込みました」と出ていた。理由を出す（`runReloading` が失敗の理由を返す。Work / Private・プロフィール・追加）
- **追加**：リポジトリの直下の `Makefile`。起動（`make up`・`seed`・`logs`・`dev`）・確認（`make smoke`）・テスト（`make test`・`test-frontend` など）を直下から。Node・Elixir・Python は手元になければ Docker の中で動かす。`make dev` のために api・auth に `ALLOWED_ORIGIN=http://localhost:5000`
- **追加**：ローカルの全体の疎通の確認 `scripts/smoke.sh`（起動・各サービス・ログイン・名前と公開・見る人向けのスキルシート・FastAPI のテスト。結果は Git 管理外の `smoke-result/`）
- **修正**：`make seed` を何度か動かすと、前に増えた版（versions/2 など）が残り、次の「公開する」が失敗していた。入れ直すときに、増えた版とほかの名前（slugs・publicPages）を消す（自分の uid のものだけ）。テスト 1 件
- **修正**：Docker の画面で、Excel のテンプレート・PDF のフォントが 403 になり、［ダウンロード］の Excel・PDF が作れなかった（手元のファイルの権限 600 がビルドしたアセットに残っていた）。ビルドのあとに誰でも読めるようにする（`frontend/Dockerfile`）
- **修正**：api を作り直すと、画面の nginx が古い住所に送って 502 になっていた。転送先の名前を 10 秒ごとに引き直す（`resolver`。`NGINX_RESOLVER`、既定は Docker の DNS）
- **追加**：計測のツール `tool/measure_skill_sheet.dart`（件数ごとの作成時間・大きさ）。テスト `excel_api_roundtrip_test`（Excel → API → Excel で同じ）、保存に失敗したときのテスト

## 2026-11-06 — 構成の分割・テスト・CI・ドキュメント

### Hono の API（段階 3。shelf の backend を置き換え）（`eed4845`）
- **追加**：`services/api-hono/`（TypeScript・Hono・Node 22。型を外してそのまま動かすのでビルドなし）。プロフィール・スキル・表示設定（`/api/me/{profile,skills,display}`）、職務経歴（`/api/me/projects`。追加・置き換え・削除）、編集中のデータ全体（`/api/me/draft`。読んだときの `updatedAt` と違えば 409）、公開ページ（`/api/public/:slug`）、`/healthz`
- **追加**：Firebase の ID トークンの確認（本物は Google の公開鍵で RS256、Emulator は中身だけ）。読み書きする文書は確かめた uid から作るので、本人のデータだけ。Firestore は REST（Emulator は `Bearer owner`）で、Admin SDK なし（Cloudflare Workers でも動く。`npm run dev:workers` は Emulator だけ）
- **追加**：受け取ったデータの形の確認（データ設計の 2.）、まとまりごとの保存は読み直して 3 回までやり直す、1 行 1 件の JSON ログ（uid・中身は書かない）、SIGTERM で止まる、`healthcheck`
- **テスト・CI**：51 件（値・設定・ID トークン・Firestore・形・読み書き・ルート、Emulator の上で本人だけとセキュリティルール）。CI の backend のジョブを `api-hono`（型の確認・テスト）に置き換え
- **変更**：`compose.yaml` の backend を `api`（8787。Emulator につなぐ）に、frontend の転送先（`BACKEND_ORIGIN`）を `http://api:8787` に。ルートの `.gitignore` に `node_modules/`
- **修正**：api のコンテナが起動しない（手元のファイルの権限 600 のまま写され、`node` ユーザーが読めない）→ `COPY --chown=node:node`。テストのヘッダーの型の誤り（`tsc`）
- **削除**：`backend/`（Dart の shelf）。このパソコン側のポート 8081 も使わなくなった
- **ドキュメント**：設計（API の節）・開発ガイド・ファイル構成・ライブラリ・ローカルのクラウド・テスト計画書と一覧・CI の設計と状況・計画・今後の動き・CLAUDE.md・docs/claude/・README

### ローカルのクラウド（段階 2）（`7eb1b1d`）
- **追加**：Firebase Emulator（`firebase/`）。Node 22 ＋ Java 21 ＋ `firebase-tools@15.34.0` のイメージ、Auth（9099）・Firestore（8080）・確認用の画面（4001）。プロジェクトは `demo-dev-portfolio`（本物の Firebase にはつながらない）。止めたとき（SIGINT）にデータを `firebase/emulator-data/`（Git 管理外）に書き出し、次の起動で読み込む
- **追加**：Firestore のセキュリティルール（画面からの読み書きは全部断る。D-05 の案）
- **追加**：サンプルを入れる `docker compose run --rm seed`（`firebase/seed/`。架空の利用者と、データ設計の 5 つの文書。公開ページには `sheet` を入れない。何度実行してもよい）とそのテスト（6 件）、CI の `firebase-seed` ジョブ
- **追加**：`services/{auth-phoenix,api-hono,excel-fastapi}/`（置き場所と README だけ。中身は段階 3・4・6）
- **変更**：`compose.yaml` に `firebase`・`seed` を足した。Firestore Emulator（8080）と重なるので、backend のこのパソコン側のポートを 8080 → **8081** に
- **ドキュメント**：[ローカルのクラウド](docs/local-cloud.md) を追加（目的と決まり・全体の図・ポートと決めた理由・ファイルとイメージの中身・起動から止めるまでの流れ・データが残る操作と残らない操作・サンプル・つなぎ先の環境変数・セキュリティルール・よく使う操作・よくある失敗と対処・確かめたこと・これから）。開発ガイド・設計・ファイル構成・CI の設計と状況・テスト一覧・計画（サービスの構成・進め方）・CLAUDE.md・backend と firebase の README も更新

### 次の構成の計画・Flutter の中の整理（`3979ae0`）

#### 次の構成の計画
- [次の構成の計画](docs/plan/README.md) を追加：ログイン・マイページ・Firestore への保存・公開ページの[要件定義](docs/plan/requirements.md)、[画面設計](docs/plan/screens.md)（画面の一覧・URL・遷移・表示設定）、[データ設計](docs/plan/data-model.md)（Excel の構成・項目と型・Firestore のコレクション・編集中 / 版 / 公開・無料枠の見積もり）、[サービスの構成](docs/plan/architecture.md)（Phoenix・Hono・FastAPI・Firebase の役割・ローカルと本番・無料枠と守り方）、[決めること](docs/plan/decisions.md)（D-01〜D-10、すべて未決）
- README・ファイル構成・CLAUDE.md から案内、更新履歴の前のコミットにハッシュを付けた

#### Flutter の中の整理（見た目・操作は変えない）
- **追加**：Repository（`lib/data/`）。プロフィール・Work / Private の読み書きはすべてここを通し、どこに置くかを画面から隠した。受け渡しは構造のデータ（`DataRecord`。YAML の項目と同じキーの Map＝Firestore の文書と同じ形）。新しい実装（API・Firestore）が書くのは読み書きの 5 つだけで、YAML の文字・サンプルはそこから作る。今の実装（`LocalPortfolioRepository`。sessionStorage・起動時の指定）は元の文字（コメント・書き方）を保つ
- **追加**：Riverpod（`flutter_riverpod`）。`main.dart` に `ProviderScope`、`lib/state/providers.dart` にテーマ・Repository・データが変わった回数・プロフィール・Work / Private・Skills の集計・Projects の一覧の Provider。Home・About・Skills・Projects・テーマの切り替えは Provider から読む。読めないときは繰り返さない
- **追加**：go_router（`lib/router/app_router.dart`）。`MaterialApp.router` にし、`/`（公開ページ）と、`--dart-define=ENABLE_ACCOUNT=true` のときだけ `/login`・`/me`・`/me/edit`（準備中の空の画面、`lib/pages/placeholder_page.dart`）。`#` 付きの URL のまま（GitHub Pages のため）。ない URL は `/` へ
- **変更**：`ThemeController` を `themeModeProvider` に置き換えた。`WorkYamlLoader`・`PrivateYamlLoader`・`ProfileStore` は Repository を呼ぶだけにした。アップロード・追加・入力画面の保存（`SessionStore.write` を直接呼んでいた 3 か所）を Repository 経由に。HomePage の作り直しの数（`_refreshKey`・`_skillsRefreshKey`）は `dataRevisionProvider` に、Home の `refreshKey` はなくした（Provider が読み直す）
- **削除**：ローダーのメモリ上の控え（`setCustomYaml` の 3 番目の読み先。アプリからは使われていなかった）、Skills / Projects のデータの読み込みの関数（`loadWorkSkillsAll` など。Provider に移した）
- **テスト・CI**：`portfolio_repository_test`（33 件）・`app_state_test`（15 件）を追加、Home に 2 件を追加。`yaml_loaders_test` をメモリの控えがない形に、`home_page_test`・`hero_section_test`・`about_section_test` を `ProviderScope` の中で pump する形に、`widget_test` のテーマを Provider に、`all_files_loaded_test` を作り直し（116 ファイル）

### ライブラリとスタイリング・更新履歴（`e076f79`）
- **ドキュメント**：[ライブラリとスタイリング](docs/libraries-and-styling.md) を追加：CSS・CSS フレームワークを使っていない理由（Flutter Web は canvas に描く）、CSS を書いている唯一の場所（`web/index.html` の起動時のローディング）、ライブラリの一覧（版・用途・使っているファイル）、画面ごとにどの部品・ライブラリをどう使っているか
- **ドキュメント**：画面仕様書・デザインシステム・UI / UX の誤りを直した：フィルターの件数とフォームの技術のボタンで `Badge.count` を使っている、「進行中のみ」はスイッチではなくチップ、案件が 0 件のときは「ヒットしませんでした」
- **ドキュメント**：この更新履歴（CHANGELOG.md）を追加し、README・ファイル構成・CLAUDE.md から案内

### デザインシステム・UI / UX・パフォーマンス・画面仕様書（`a7e8d87`）
- **ドキュメント**：[デザインシステム](docs/design-system.md)（トークン・部品・ダークモード）、[UI / UX](docs/ui-ux.md)（ブレークポイント・UX の決まり・アクセシビリティ）、[パフォーマンス](docs/performance.md)（起動の流れ・待ち時間・配信）、[画面仕様書](docs/screens/README.md)（画面 ID・遷移図・各画面の項目）を追加
- 課題を記録：0 件のときの案内の文言、使われていない文言、体感の速さ・アクセシビリティが未計測

### 図を Mermaid に（`213b63f`）
- **ドキュメント**：文字で描いていた図（Docker の構成・データの流れ・CI の流れ）を Mermaid に置き換え、［データ］の選び方・アップロードの流れ・コンポーネントの層・テストの進め方・段階の順番などの図を追加
- CLAUDE.md に「ドキュメントの図は Mermaid で描く」を追加

### テスト計画書・CI・今後の動き（`2ea737f`）
- **ドキュメント**：[テスト計画書](docs/testing/test-plan.md)、[テスト一覧](docs/testing/test-catalog.md)、[CI の設計](docs/ci/ci-design.md)、[CI の状況](docs/ci/ci-status.md)、[今後の動き](docs/roadmap.md) を追加

### frontend / backend への分割・Docker・テスト・CI（`bb305d0`）
- **変更**：`dev_portfolio/` を `frontend/` に改名（Dart のパッケージ名は `dev_portfolio` のまま）
- **追加**：`backend/`（shelf + shelf_router の API：`/healthz`・`/api/profile`・`/api/projects/<work|private>`、JSON のログ、終了の合図での停止、Dockerfile は `dart compile exe` → scratch）
- **追加**：`compose.yaml`（frontend は `flutter build web` → nginx で `/api/` を backend へ転送、backend とまとめて起動）、ルートの `.gitignore`
- **テスト・CI**：正常系・異常系のテストを 19 ファイル追加し、網羅率は行 96.2%・分岐 90.4%。`tool/coverage_check.dart`（基準 90% の確認・読み込まれていないファイルの検出）、`.github/workflows/test.yml`（analyze・テスト・網羅率・backend のテスト）
- **変更**：ファイル選択を `lib/utils/file_pick.dart` の `pickFile` 経由にし、テストで差し替えられるように
- **修正**：円グラフの扇を押しても選べない／期間のない案件・進行中の案件があると並び替えが毎回揺れる／スマホの幅でカードの期間・切替のラベルがはみ出す／スマホでページ送りの › が画面の外に出る
- **削除**：使っていないファイル・文言の関数・`.DS_Store`
- **ドキュメント**：README を紹介・[操作説明書](docs/manual.md)・[設計](docs/design.md)・[ファイル構成](docs/structure.md)・[開発ガイド](docs/development.md) に分割、CLAUDE.md を入口だけにして詳細を `docs/claude/` に分割

---

## 2026-11-05 — Excel・［データ］・スキルシートの書き出し

### スキルシートのダウンロード・役割と規模・Home のまとめ（`21aa1f0`）
- **追加**：ヘッダーの［ダウンロード］：プロフィールと Work / Private をテンプレートの書式のままスキルシート（Excel）に書き込み、同じ見た目の PDF も作る（IPA P ゴシックを埋め込み、列幅・結合・罫線・折り返し・改ページ・ページ番号を Excel のとおりに）
- **追加**：スキルシートだけの項目（ふりがな・性別・年齢など）を Excel から読み、書き出す
- **追加**：プロジェクトの役割（`role`）・規模（`scale`）：読み書き・フィルター・詳細・入力フォーム・テンプレート
- **変更**：Home を中央寄せにし、ボタンの下にまとめ（開発経験・件数・直近のプロジェクト）
- **修正**：業務概要の URL・概要が二重になる／PDF のタイトルの全角スペースが「、」になる
- **変更**：archive / pdf / image の版の組み合わせを固定（image < 4.11）

### Excel 入力・［データ］・技術名の整理・並び替え・詳細の拡大（`2d1d974`）
- **追加**：最初の入力画面で Excel（スキルシート）からプロフィール・Work / Private を作る（`tool/run.dart` も `.xlsx` に対応）
- **追加**：About に直近 / 過去の開発経験と主な技術
- **変更**：ヘッダーのボタンを［データ］にまとめ、追加（入力フォーム・テキスト・ファイル、1 件 / 複数件）と更新を選べるように
- **追加**：入力フォーム（技術はグループごとのボタン＋タグ入力、期間は年月の選択）
- **変更**：技術名の表記ゆれをまとめ、本来の分類へ移し、Skills / Tools をグループに分ける
- **追加**：Projects の全分類のフィルター・並び替え、期間の書き方（「/」・全角の数字）に対応
- **追加**：案件の詳細の文字の拡大・大きく表示（画面共有向け）

---

## 2026-11-04 — 案件の詳細・最小の幅・Markdown

### Markdown・まとめての読み込み・上書きの確認（`5e827cc`）
- **追加**：Work / Private / プロフィールを Markdown でも書ける（誤りは元のファイルの行番号付きで表示）、Markdown のテンプレート
- **追加**：プロフィールのファイルに work / private も書けば 1 回でまとめて切り替わる
- **追加**：今の内容と違うとき、なくなる・変わる・追加されるプロジェクトを並べて上書きを確認
- **追加**：貼り付け画面のクリア
- **テスト・CI**：アセットの読み込みを `loadAssetText` にまとめ、テストではファイルを直接読む（テストが止まる問題の対策）

### 案件の前後移動・全画面表示・320px 未満の縮小・貼り付け（`f4b43b8`）
- **追加**：詳細で ‹ › と ← → キーで前後の案件へ、「3 / 12」の表示
- **変更**：PC（幅 1024 以上）はダイアログ、タブレット・スマホは全画面
- **追加**：320px より狭い画面は 320px のレイアウトを縮小して表示（スマホのヘッダーがはみ出す問題の対策）
- **追加**：アップロード画面に［テンプレートをコピー］［テキストを貼り付け］

---

## 2026-11-03 — スマホ対応・プロフィール YAML

### 非推奨 API の置き換え・テスト（`8a29c13`）
- **変更**：`dart:html` → `package:web`、`Color.withOpacity` → `withValues(alpha:)`
- **テスト・CI**：プロフィール・Work / Private の検証、sessionStorage、ローダーの読み込み順などのテストを追加

### スマホ対応・M3 ヘッダー・プロフィール YAML・アップロード画面（`b2bd0ed`）
- **変更**：スクロールをページ全体の 1 つにまとめた（スマホで操作できなくなる問題）、Collection の件数を画面の幅で決める、ページ送りを幅に合わせて省略
- **変更**：List を年表、Collection をカバー付きのカードに。フィルター・カテゴリをポップアップ（PC はダイアログ、スマホは下からのシート）に
- **変更**：ヘッダーを M3 の Small top app bar に、表示中のセクションのインジケーター、テーマの切替
- **追加**：Home / About の内容をプロフィール YAML から読む（`dart run tool/run.dart xxx.yaml`）、なければ最初の入力画面
- **変更**：アップロード画面の流れを統一（選択 → 検証 → 確認画面 → OK で反映）

---

## 2026-11-02 — Material 3・期間フィルター

### 期間フィルター・詳細と一覧の表示（`1701564`）
- **追加**：フィルターに「期間」（年の範囲のスライダー・「進行中のみ」）
- **変更**：詳細ダイアログの見出しとフッターを固定、項目を「見出し → 中身」に、Workflow を工程のステップ表示に、期間を［開始 → 終了］＋長さで表示
- **変更**：一覧のカードの期間の表示、Collection のカードの高さ

### Material 3・ローディング・フォーマットの保存（`742365c`）
- **変更**：Material 3 へ移行（`ColorScheme.fromSeed`、タイプスケール・シェイプスケール、SegmentedButton・FilledButton・FilterChip・Badge・NavigationDrawer など）
- **追加**：起動時のローディング（`web/index.html`）とアプリの準備完了の合図、重い描画の後のフェード表示（`SettledReveal`）
- **変更**：「フォーマットをダウンロード」を「名前を付けて保存」に

---

## 2026-10-31 — 定数・設定の整理（`0308d8f`）

- **変更**：寸法・文言を `AppSizes`・`AppTexts` にまとめ、各セクションの設定（`sections/config/`）を整理
- **追加**：YAML の書き方の説明、適用中のフィルターの表示
- **ドキュメント**：README と CLAUDE.md を追加・更新

## 2026-10-11〜12 — GitHub Pages への公開

- **テスト・CI**：GitHub Actions で Web をビルドして公開するワークフローを追加し、公式の Pages のデプロイに切り替え（`d40c709`〜`886089f`）
- **変更**：サンプルの YAML の更新（`da2f4f4`・`b227ab8`・`20e5371`）

## 2026-04-01〜13 — 最初の実装

- **追加**：リポジトリの作成、ライセンス（CC BY-ND 4.0）（`4b3e3a4`・`2b44191`）
- **追加**：Flutter のプロジェクト、スキルのサンプル（`9acd3db`〜`935a975`）
- **追加**：Skills の棒グラフ・円グラフと、グラフ・セクションの設定（`fe08d47`〜`29c76be`）
- **追加**：案件の詳細（モーダル）、ページ送り（`c4b500b`・`2f8e8aa`）
- **追加**：Skills の集計、Projects のフィルター、YAML からの読み込み（`eaae6b5`〜`e128523`）
- **修正**：Collection の大きさ、グラフ・YAML・Skills・フィルターの修正（`47e0e0c`〜`7ba1dc1`）
