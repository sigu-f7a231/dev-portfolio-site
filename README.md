# DevPortfolio

履歴書を補うための、開発者ポートフォリオサイトです。
業務（Work）と個人開発（Private）のプロジェクト、そこで使った技術の割合を 1 ページで見られます。
Flutter Web で作った SPA で、GitHub Pages で公開しています。

公開ページ: https://sigu-f7a231.github.io/dev-portfolio-site/

> **English summary**
> A single-page developer portfolio built with Flutter Web and hosted on GitHub Pages, designed to complement a résumé.
> It shows work and personal projects, and charts the technologies used across them.
> All content is driven by YAML / Markdown files or an Excel skill sheet: the profile (Home / About) is loaded at startup (`dart run tool/run.dart my_profile.yaml`) or in the first-run dialog, and projects can be added or replaced from the header's **Data** button (on-screen form, pasted text, or files).

---

## できること

### 画面

| セクション | 内容 |
|---|---|
| **Home** | 名前・職種・紹介文（プロフィール YAML から）。ボタンで Skills / Projects へ移動できます。右側にはプロフィールのカードを YAML 風に表示します |
| **About** | 自己紹介と、得意な領域・直近 / 過去の開発経験と主な技術・強み・開発スタイル・締めの一言（プロフィールから。書いていない項目は表示しません） |
| **Skills** | プロジェクトで使った技術の割合を、棒グラフ／円グラフで表示します。Work / Private の切り替えと、カテゴリの選択（ポップアップ）ができます。Skills・Tools はさらにグループ（プログラミング言語・ライブラリ・バージョン管理・開発ツール・環境など）に分けて表示します |
| **Projects** | プロジェクトの一覧です。**List**（年表）と **Collection**（カバー付きカード）を切り替えられ、全分類の技術・工程・期間で絞り込み（ポップアップ）、開始・終了・期間の長さ・名前で並べ替えができます。カードを押すと詳細が開き、‹ › や ← → キーで前後の案件に移れます |

- **ヘッダー**：Material 3 のトップアプリバー。ナビは表示中のセクションが強調され、スクロールに合わせて切り替わります
- **ダークモード**：ヘッダーのスイッチ（☀️ / 🌙）でライト／ダークを切り替えられます（スマホはアイコンボタン）
- **レスポンシブ**：スマホではメニューがドロワーになり、フィルターは下から出るシートで開きます。Collection は画面幅に合わせて 1〜4 列、ページネーションは幅に応じて「1 … 4 5 6 … 10」「‹ 3 / 10 ›」と省略表示になります
- **案件の詳細**：PC（幅 1024px 以上）はダイアログで開き、左右の ‹ › で前後の案件へ。タブレット・スマホは画面いっぱいで開き、文字を一回り大きく（1.15 倍）表示して、‹ › は下に置きます。前・次がないときはボタンを押せません。絞り込み・並び順のまま、ページをまたいで移れます
- **画面共有向けの表示**：詳細のヘッダーの［A−］［100%］［A＋］で文字を 100〜250% に、PC は［大きく表示］で画面いっぱいにできます（Google Meet・Teams・Slack ハドルなどで見やすく）。キーボードは − ＋ 0 F、⌘（Mac）/ Ctrl（Windows）＋ 0 で元の大きさ。開いている間はブラウザ自体の拡大・縮小は止めます
- **技術名の整理**（表示のときだけ。保存したデータは変えません）
  - 表記ゆれをまとめます：大文字・小文字・全角半角・末尾の `;` `:` `.` `/`・キャメルケース / スネークケースの違いは同じものとして扱い、正式な書き方（GitHub Actions、Node.js など）で表示します。数字の違い（Python と Python3）は別のものです。1 つのプロジェクトの中で重なっていても 1 回と数えます
  - AWS / Azure / GCP のサービスは、先頭の「AWS」などを外して同じものにまとめます（AWS Lambda と Lambda）
  - Skills や Tools に書かれたフロントエンド・バックエンドなどの技術は、本来の分類に移します（React → Frontend、Django → Backend、Docker → Container、k8s → Container Orchestration、Red Hat → Cloud など）
  - Skills・Tools は名前から推測してグループに分けます（言語・マークアップ・データ形式・アーキテクチャ・ライブラリ ／ バージョン管理・開発ツール・環境・CI/CD・プロジェクト管理・デザイン）。グラフ・フィルター・詳細・入力フォームで共通です
- **対応する最小の幅は 320px**（iPhone SE など）。それより狭い画面では、320px のレイアウトを画面幅に合わせて縮小して表示します

### 使い方（自分のデータで表示する）

このサイトは、**リポジトリをローカルに落として、自分の YAML を読み込んで使う**ことを想定しています。
公開ページを開くと、最初に「あなたのことを教えてください」（プロフィールの入力画面）が出ます。

#### 1. プロフィール（Home / About）

起動時に YAML を指定すると、その内容で Home と About を表示します（入力画面は出ません）。

```bash
cd dev_portfolio
dart run tool/run.dart my_profile.yaml   # Markdown なら my_profile.md、スキルシート（Excel）なら skill_sheet.xlsx
```

- `flutter run -d chrome my_profile.yaml` のように flutter run へ直接 YAML は渡せない（引数は起動する Dart ファイルとして扱われる）ため、このスクリプトを使います。中で `flutter run -d chrome` を実行するので、`r`（ホットリロード）などもそのまま使えます。2 つ目以降の引数は flutter run に渡します（例：`dart run tool/run.dart my_profile.yaml --release`）
- YAML を指定しない（`dart run tool/run.dart` や `flutter run -d chrome`）と、起動後に入力画面が出ます。**正しい YAML を読み込むまで閉じられません**
- 指定した YAML は `assets/profile/profile.yaml` にコピーされます。個人情報なので Git には含めません（`.gitignore` 済み）
- **プロフィールのファイルに Work / Private も書ける**：同じファイルに書いておくと、起動時の指定でも入力画面のアップロードでも、1 回で Home / About と Skills / Projects がまとめて切り替わります（あとで個別にアップロードしなくてよい。書き方は下の「データの書き方」）

#### 1'. スキルシート（Excel）から作る

入力画面の「入力方法」で **Excel（スキルシート）** を選ぶと、Excel のスキルシートから Home / About と Work / Private をまとめて作れます。

1. 「Excel テンプレートを保存」でひな形（`assets/data/format_skill_sheet.xlsx`）を名前を付けて保存（同じ形式のスキルシートがあれば不要）
2. Excel で書き換えて保存
3. 「Excel を選択」で読み込み → 確認画面 → OK で反映。中身から YAML を作り、YAML で読み込んだときと同じ確認をします。「作った YAML を保存」で保存しておくと、次回はその YAML（または Excel そのもの）を `tool/run.dart` に指定して起動できます

| 作るもの | Excel から読み取る項目 |
|---|---|
| Home / About | 氏名 → `name`、過去 / 直近の開発経験（「領域：説明」の行）→ `past` / `recent`、それぞれの「主な使用技術・開発環境」（「言語：A、B」の行）→ `past_tech` / `recent_tech`。紹介文（`tagline`）は直近の言語から、自己紹介（`intro`）と得意な領域（`domains`）は経験の領域から作ります。職種（`role`）は「エンジニア」固定（YAML を保存して書き換えられます） |
| Work / Private | プロジェクト名 → `title`、期間 → `period`、業務概要 → `description`（「概要：」の 1 行目）・`details`（全体）・`link`（URL）、サーバ OS → `server_os`、DB → `db`、FW・MW ツール等と使用言語 → 知っている名前は各分類（Django → `backend_frameworks`、Docker → `container`、「AI：」の行 → `ai_services` など）、それ以外は `tools` / `skills`、作業工程（● など）→ `workflow` |

- プロジェクト名に「**プライベート**」か「**個人開発**」が入っているものだけ Private になります（印はタイトルから外し、作業工程は使いません）
- セルの位置ではなく見出しの文字（「氏名」「プロジェクト名」「No.」など）で探すので、行や列が多少ずれても読めます。1 件は「No.」に番号がある行から次の番号の前の行まで
- `.xls`（古い形式）は読めません。Excel で `.xlsx` として保存し直してください

#### 2. プロジェクト（Work / Private）：ヘッダーの［データ］

ヘッダーの［データ］ボタンから、プロジェクトを追加・更新できます。何も読み込まない場合は、リポジトリにある `assets/data/format_*.yaml`（サンプル）を表示します。
1 つの画面の中で順に選び（上に「追加 › Work › …」、［戻る］で前へ）、どの道を通っても反映の前に確認画面を出します。

| 選ぶもの | 動き |
|---|---|
| **更新** → Work / Private | これまでのアップロード画面で、ファイルや貼り付けた内容に丸ごと置き換えます |
| **追加** → Work / Private → ファイル・貼り付けで追加 | 同じアップロード画面で読み込み、今の一覧の後ろに足します |
| **追加** → … → 画面上で入力 → 1 件 → 入力フォーム | 項目ごとに入力します（下の表） |
| **追加** → … → 画面上で入力 → 1 件 / 複数件 → テキスト | YAML / Markdown を貼り付けるかファイルを選びます。テンプレートの保存・コピー、ⓘ の説明、［サンプルを入力欄に入れる］（複数件は 3 件入ったサンプル）もあります。複数件は「全部追加する」か「選んだものだけ追加する」を選べます |

- アップロード画面にも［戻る］があり、［データ］の 1 つ前の選択に戻れます
- 追加の確認画面では、今の件数・追加するもの・同じ名前があるときの注意を出します。サンプルを表示中なら「サンプルを外す」を選べます

**入力フォーム**

| 項目 | 入れ方 |
|---|---|
| プロジェクト名 | 必須 |
| 期間（開始・終了） | 欄を押すと、Material 3 の日付選択と同じ見た目で年と月を選ぶ画面が開きます（‹ › で年、年の部分で 12 年ずつの一覧）。終了は開始より前を選べません。進行中ならチェック |
| 技術 | Skills・Tools はグループごと、ほかは項目ごとの小さなボタン（入れた数をバッジで表示）。押すと入力欄と「すでにある項目」の一覧が開き、一覧を押すと追加・もう一度で外します。入力欄は打つと候補が出て、カンマか Enter で区切り、空の欄で Backspace 1 回目で直前を強調・2 回目で消します |
| 担当した工程 | Work のみ。チップで選びます |

#### アップロード画面の流れ（プロフィール / Work / Private 共通）

1. **テンプレートを用意**：形式（YAML / Markdown）を選び、「テンプレートを保存」でひな形を「名前を付けて保存」（Chrome / Edge は保存ダイアログ、そのほかのブラウザは通常のダウンロード）、または「テンプレートをコピー」でクリップボードにコピー。ⓘ で書き方の説明を開けます
2. **データを読み込む**：「ファイルを選択」（`.yaml` / `.yml` / `.md` / `.markdown`）か、「テキストを貼り付け」で内容を貼り付けます（YAML か Markdown かは自動で見分けます。貼り付け画面にはクリアボタンがあります）。ファイルを保存・選択できない端末でも、コピー → メモアプリなどで書き換え → 貼り付け で使えます。読み込んだ時点で形式を確かめ、間違っていれば理由を表示します（このときは「アップロード」を押せません）
3. **アップロード**：確認画面で中身（プロフィールの各項目 / プロジェクトの一覧）を確認し、**OK のときだけ**反映します
4. **今の内容が上書きされるときは確かめる**：Work / Private（最初の入力画面で一緒に書いたものも）が今表示している内容と違うときは、なくなる・内容が変わる・追加されるプロジェクトを並べて「上書きされます」と知らせ、［上書きしてアップロード］を選んだときだけ反映します（［やめる］なら何も変えずに戻ります）。同じ内容なら確認は出しません
5. 反映中は全画面のローディングを数秒（5〜8 秒）表示し、描き直しが終わってから画面に戻ります

読み込んだデータはブラウザの **sessionStorage** にだけ保存されます。サーバーには送信されず、タブを閉じると消えます。

---

## データの書き方

データは **YAML** と **Markdown** のどちらでも書けます（中身は同じ。Markdown は読み込むときに YAML と同じ形に変換します）。
ひな形は `dev_portfolio/assets/data/` の `format_*.yaml` と `format_*.md` です。

### プロフィール（Home / About）

ひな形：`dev_portfolio/assets/data/format_profile.yaml`。★ は必須、それ以外は書かなければ表示しません。

```yaml
home:
  name: 山田 太郎                # ★ 名前
  role: Web / モバイルエンジニア   # ★ 職種
  tagline: |                    # ★ 紹介文
    Flutter と Dart を中心に開発しています。
  card:                         # 右側のカード（「キー: 値」か「キー: - 箇条書き」で自由に）
    stack:
      - Flutter
      - Dart
about:
  intro: |                      # ★ 自己紹介
    受託開発の会社で Web アプリの設計から実装までを担当しています。
  domains: [Web, モバイル]       # 得意な領域（タグで表示）
  strengths: チーム開発、テスト設計  # 強み
  style: コード品質を重視しています  # 開発スタイル
  closing: ユーザー視点を大切に     # 締めの一言
```

知らない項目・必須の空欄・型の違い（文章の場所に箇条書きなど）はエラーになり、読み込みません。

Markdown で書く場合（`format_profile.md`）：

```markdown
# home
- name: 山田 太郎
- role: Web / モバイルエンジニア

## tagline
Flutter と Dart を中心に開発しています。

## card
- stack: Flutter, Dart

# about
- domains: Web, モバイル
- strengths: チーム開発、テスト設計

## intro
受託開発の会社で Web アプリの設計から実装までを担当しています。
```

- `# home` と `# about` に分け、1 行の項目は `- キー: 値`、複数行の文章は `## キー` の下に書きます（`- キー: 値` は `##` より前に書く）
- `card` は `## card` の下に `- キー: 値`（カンマ区切りは箇条書き）。`domains` はカンマ区切り
- `<!-- -->` の中はメモとして読み飛ばします

#### Work / Private も一緒に書く（任意）

プロフィールのファイルに足すと、1 回のアップロードで Skills と Projects もまとめて読み込みます。

YAML：トップに `work:` / `private:` を足し、その下に Work / Private のファイルの `projects:` の中身を書きます。

```yaml
home: ...
about: ...
work:
  - title: 業務のプロジェクト名
    workflow: { basic_design: true, implementation_unit_test: true }
private:
  - title: 個人開発のプロジェクト名
```

Markdown：`# work` / `# private` の見出しの下に、Work / Private のファイルより**見出しを 1 段深く**して書きます（プロジェクト名は `##`、詳細は `###`）。

```markdown
# home
...
# about
...
# work

## 業務のプロジェクト名
- workflow: 基本設計, 実装・単体テスト

### details
詳細

# private

## 個人開発のプロジェクト名
- skills: Dart
```

Work / Private のアップロードと同じ確認をします（Work は `workflow` が必要、Private は書かない）。

プロフィールのテンプレート（`format_profile.yaml` / `.md`）には、Work / Private のテンプレートと同じ全項目のサンプルが最初から入っています。書き換えて使い、要らないときは `work:` / `private:`（Markdown は `# work` / `# private`）ごと消してください。

### プロジェクト（Work / Private）

Work 用と Private 用でファイルが分かれています。

| ファイル | 用途 |
|---|---|
| `dev_portfolio/assets/data/format_work.yaml` | 業務のプロジェクト（`workflow` が必須） |
| `dev_portfolio/assets/data/format_private.yaml` | 個人開発のプロジェクト（`workflow` は書かない） |

```yaml
projects:
  - title: プロジェクト名            # 必須
    description: 一覧に出る一言説明
    details: |
      詳細モーダルに出る説明（複数行）
    period:
      - 2024-04                      # 開始（YYYY-MM）
      - 現在                         # 終了（YYYY-MM）。進行中なら「現在」
    link: https://example.com        # なければ ""
    server_os: [Linux]
    db: [PostgreSQL]
    tools: [Git, VSCode]
    backend_frameworks: [Django]
    frontend_frameworks: [React]
    ui_frameworks: [利用なし]        # 該当しない項目は「利用なし」（集計から除外）
    testing_frameworks: [利用なし]
    cloud_platforms: [AWS]
    aws_services: [EC2, S3]
    azure_services: [利用なし]
    gcp_services: [利用なし]
    container: [Docker]
    container_orchestration: [利用なし]
    ai_services: [利用なし]
    skills: [Python, TypeScript]
    workflow:                        # Work 用のみ。担当した工程を true に
      requirements: false            # 要件定義
      basic_design: true             # 基本設計
      detailed_design: true          # 詳細設計
      implementation_unit_test: true # 実装・単体テスト
      integration_test: true         # 結合テスト
      system_test: false             # 総合テスト
      maintenance_operation: false   # 保守・運用
```

Markdown で書く場合（`format_work.md` / `format_private.md`）：

```markdown
# プロジェクト名
- description: 一覧に出る一言説明
- period: 2024-04 ~ 現在
- link: https://example.com
- skills: Python, TypeScript
- workflow: 基本設計, 詳細設計, 実装・単体テスト

## details
詳細モーダルに出る説明（複数行）
```

- 1 件ごとに `# プロジェクト名` から書き始め、項目は `- キー: 値`（キーは YAML と同じ。複数あるときはカンマ区切り）
- 期間は `2024-04 ~ 2024-09`（`〜` `→` も可）。詳細は `## details` の下
- `workflow`（Work のみ）は担当した工程をカンマ区切りで（日本語の工程名でも英語のキーでも可）
- 書き方の誤りは行番号付きで表示します

YAML の注意：

- インデントは半角スペース 2 つです（タブは使えません）
- リストは `[a, b]` の形でも、1 行に 1 つ `- a` と書く形でもかまいません
- Skills のグラフは、全プロジェクトでの各技術の出現割合です。`workflow` は true の割合を表示します

---

## 技術スタック

- **Flutter Web / Dart**（Dart SDK ^3.9.2）
- [fl_chart](https://pub.dev/packages/fl_chart)：円グラフ
- [yaml](https://pub.dev/packages/yaml)：データの読み込み
- [file_picker](https://pub.dev/packages/file_picker)：ファイルの選択
- [archive](https://pub.dev/packages/archive) / [xml](https://pub.dev/packages/xml)：Excel（.xlsx）の読み込み
- [web](https://pub.dev/packages/web)：ブラウザの機能（sessionStorage・ファイルの保存）
- [url_launcher](https://pub.dev/packages/url_launcher)：公開ページへのリンク
- **GitHub Actions + GitHub Pages**：自動デプロイ

> ブラウザの機能（`package:web`：sessionStorage・ファイルの保存）を使っているため、**Web 専用**です。

---

## ローカルでの起動

```bash
cd dev_portfolio
flutter pub get
dart run tool/run.dart my_profile.yaml   # プロフィールを指定して起動（おすすめ）
# または
flutter run -d chrome                    # 起動後にプロフィールの入力画面が出る
```

> `web/index.html`（起動時のローディング表示など）は Git で管理しています。CI の `flutter create . --platforms web` は既存のファイルを上書きしません。

テストの実行：

```bash
flutter analyze
flutter test
```

| テスト | 内容 |
|---|---|
| `widget_test.dart` | テーマの切り替え・色・非推奨 API の置き換え結果 |
| `profile_yaml_test.dart` | プロフィール YAML の検証（テンプレートが通るか・各エラー） |
| `projects_yaml_validator_test.dart` | Work / Private YAML の検証 |
| `browser_storage_test.dart` | sessionStorage（テストではメモリで代用）・データの読み込み順・プロフィールの保持・アセットの読み込みの差し替え |
| `projects_diff_test.dart` | 今の内容とこれからの内容の違い（追加・削除・変更、書き方だけの違いは無視）・テンプレートがそろっているか |
| `profile_bundle_test.dart` | プロフィールに Work / Private も書いたとき（YAML / Markdown）：分け方・確認・行番号付きのエラー |
| `data_format_test.dart` | YAML / Markdown の見分け・Markdown の変換（テンプレートが YAML 版と同じ中身になるか・行番号付きのエラー。コメントがあっても元の行番号）・テンプレートが `pubspec.yaml` に登録されているか |
| `upload_paste_test.dart` | テキストの貼り付け画面（クリアボタン）・テンプレートのコピー・形式の切り替え・読み込みボタン |
| `upload_dialogs_test.dart` | Work / Private / 最初の入力画面：貼り付け（YAML / Markdown）→ 確認画面 → OK で反映、間違ったデータを弾く、入力画面が閉じられない、プロフィールと一緒に Work / Private も反映、上書きの確認（やめる / 上書き / 同じ内容なら出さない） |
| `project_detail_navigation_test.dart` | 案件の詳細：‹ › / ← → で前後に移る・端では押せない・PC はダイアログ／タブレット・スマホは全画面・画面共有向けの拡大（ボタン・キーボード・Mac / Windows の ⌘ / Ctrl ＋ 0） |
| `min_width_scaler_test.dart` | 320px より狭い画面での縮小表示 |
| `skill_sheet_test.dart` | スキルシート（Excel）から YAML を作る：テンプレートが Work / Private のサンプルと同じ中身になるか・Private の見分け・期間（全角の数字も）・作業工程・セル内の見出し（「AWS Service;」など）・技術の振り分け・読めないときのエラー・YAML の書き出し・Projects の期間の解釈 |
| `skill_name_test.dart` | 技術名の表記ゆれ（末尾の記号・大文字小文字・全角・キャメル / スネーク・AWS などの先頭）・Skills の集計・Projects のフィルター |
| `tech_catalog_test.dart` | Skills・Tools に書かれた技術の振り分け（React → Frontend など）・Tools / Skills のグループ分け |
| `project_data_test.dart` | ［データ］：テキストの読み取り・追加・複数件のサンプル・入力フォーム・タグ入力（候補・カンマ・Backspace）・年月の選択・画面の流れ（追加・更新・戻る） |
| `project_sort_test.dart` | Projects の並び替え |

> ブラウザの機能（sessionStorage・ファイル保存）は、テストでは代わりの実装に自動で切り替わります（`lib/utils/browser/`・`lib/utils/file_saver.dart`）。ファイル選択の OS ダイアログはテストから操作できないので、同じ確認処理を通るテキストの貼り付けで確かめています。
>
> アセット（テンプレート・サンプル）は `lib/utils/asset_text.dart` の `loadAssetText` で読みます。画面を動かすテスト（testWidgets）の中では本物の読み込み（rootBundle）が終わらないことがあるため、`setUp(useFileAssets)`（`test/test_assets.dart`）でファイルを直接読む方法に差し替えています。

本番と同じ設定でビルドする場合：

```bash
flutter build web --release --base-href "/dev-portfolio-site/"
```

## デプロイ

`develop` ブランチに push すると、GitHub Actions（`.github/workflows/deploy.yml`）がビルドして GitHub Pages に公開します。
Actions の画面から手動で実行することもできます。

---

## カスタマイズ

見た目や文言は、場所を決めて 1 か所で管理しています。ウィジェットのファイルには、色・数値・文言を直接書かないルールです。

| 変えたいもの | ファイル |
|---|---|
| 名前・紹介文・About の内容 | プロフィール YAML（ひな形 `assets/data/format_profile.yaml`） |
| 画面の文言（ボタン名・メッセージなど） | `lib/constants/app_texts.dart`（`AppTexts`） |
| 色（ライト / ダーク） | `lib/theme/app_colors.dart` |
| 文字スタイル・角丸・カードなどの共通の見た目 | `lib/theme/app_styles.dart` |
| 余白・アニメーション時間などの数値 | `lib/constants/app_sizes.dart` |
| セクションごとのレイアウト（グラフの大きさ、Collection の列数など） | `lib/sections/config/` |
| 表示するプロジェクト（サンプル） | `assets/data/format_work.yaml` / `format_private.yaml` |
| 画面の固定の見出し（About の見出し名など） | `lib/constants/app_texts.dart`（`HeroContent` / `AboutContent` / `ProfileTexts`） |

## ディレクトリ構成

```
dev-portfolio-site/
├── .github/workflows/deploy.yml   # GitHub Pages への自動デプロイ
├── CLAUDE.md                      # 開発メモ（構成・データの流れ・規約・既知の課題）
└── dev_portfolio/                 # Flutter アプリ
    ├── assets/
    │   ├── data/                  # ひな形・サンプル（format_profile / format_work / format_private / format_skill_sheet.xlsx / sample_*_multi）
    │   └── profile/               # 起動時に指定したプロフィール（Git 管理外）
    ├── tool/run.dart              # プロフィール YAML（.md・.xlsx も可）を指定して起動するスクリプト
    ├── web/index.html             # 起動時のローディング表示
    └── lib/
        ├── main.dart
        ├── pages/                 # HomePage（全セクションを縦に並べる・入力画面を出す）
        ├── models/                # プロフィール（読み込みと検証）
        ├── sections/              # header / hero / about / skills / projects と config
        ├── theme/                 # 色・テーマ切替・共通スタイル
        ├── constants/             # 文言・数値
        ├── controllers/           # セクションへのスクロール・表示中セクション
        ├── widgets/               # 共通部品（セグメント・ポップアップ・入力画面・アップロード部品・ローディング）
        └── utils/                 # YAML ローダー・Excel の読み取り・技術名の整理と振り分け・追加の処理・ファイル保存など
```

---

## 現状と技術的な課題

**現状**（2026-11-05）：スキルシート（Excel）からの入力、［データ］からの追加・更新（入力フォーム・タグ入力・年月の選択）、技術名の整理とグループ分け、並び替え、詳細の画面共有向け拡大を追加しました。追加した機能のテストは作者の手元で実行しながら直しています。ブラウザ・スマホでの見た目と操作（特にキーボード操作・日本語入力・ブラウザの拡大との兼ね合い）は、引き続き実機での確認が必要です。

課題と今後の改善候補です（詳細は [CLAUDE.md](CLAUDE.md) の「現状と課題」）。

**優先度 高**
- **画面での動作確認**：レスポンシブ対応・ヘッダー・アップロード画面・詳細の全画面表示などの最近の変更は、実機（PC・タブレット・スマホ）での見た目と操作の確認がまだです
- **ローカルでビルドするとプロフィールが入る**：`assets/profile/profile.yaml` が残っていると `flutter build web` の成果物に含まれます（表示はしません）。公開用にビルドする前に消してください
- **Work / Private の検証が浅い**：`projects` と `title`・`workflow` の有無しか確かめていないため、項目の型が違うと表示が崩れる可能性があります

**優先度 中**
- **自動テストがまだ足りない**：ページネーションのテストはまだありません。ファイル選択（OS のダイアログ）はテストできないため、貼り付けで代わりに確かめています
- **Android で Google Drive のファイルを選べないことがある**：ファイル選択画面がファイルの種類（MIME タイプ）で絞り込むため、Drive 側の種類の情報によっては選べません。テキストの貼り付けで回避できます
- **文字列の分割処理が複数ある**：カンマ区切りの扱いがファイルによって違います
- **Projects のページを切り替えても一覧の先頭に戻らない**
- **スマホでのグラフ操作**：棒グラフの強調表示はマウスを乗せたときだけで、タップには反応しません
- **プロフィール YAML を書き換えたら起動し直しが必要**（`tool/run.dart` は起動時に 1 回読むだけ）

**優先度 低（仕様・整理）**
- **公開ページでは入力画面が出る**：プロフィールは各自がローカルで読み込む前提です
- **データはタブを閉じると消える**：アップロードした内容は sessionStorage にだけ保存しています
- **Web 専用**：ブラウザの機能（`package:web` / `dart:js_interop`）を使うため、Web 以外ではビルドできません
- **使っていないコード・定数が残っている**：古いタブ UI、旧形式のソート処理、作り直しで不要になった文言など
- **技術名の振り分け・グループ分けは名前からの推測**：一覧にない名前は、名前に含まれる言葉で推測し、わからなければ「その他」になります。合わないものは `lib/utils/tech_catalog.dart` の一覧に足してください

---

## ライセンス

[CC BY-ND 4.0](LICENSE)（Creative Commons Attribution-NoDerivatives 4.0 International）
