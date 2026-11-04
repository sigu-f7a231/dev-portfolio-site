<!--
  プロフィール（Home と About）Markdown テンプレート
  - 「# home」「# about」の 2 つに分けて書く
  - 「- キー: 値」で 1 行の項目を書く。「## キー」の下には複数行の文章を書く
  - 「- キー: 値」は、その見出しの「## 」より前に書く
  - ★ は必須：home の name / role / tagline、about の intro
  - card（右側のカード）は「## card」の下に「- キー: 値」で自由に書く（カンマ区切りは箇条書きになる）
  - domains（得意な領域）はカンマ区切り
  - この囲み（コメント）の中はメモ。読み込まれない
-->

# home
- name: 山田 太郎
- role: Web / モバイルエンジニア

## tagline
Flutter と Dart を中心に、Web とモバイルのフロントエンドを開発しています。
このサイトでは、業務と個人開発で使ってきた技術と、関わったプロジェクトをまとめています。

## card
- name: Taro Yamada
- role: Web / Mobile Engineer
- stack: Flutter, Dart, TypeScript
- focus: ユーザー視点の UI

# about
- domains: Web, モバイル, Flutter, Dart
- strengths: チーム開発、テストの設計と実施、UI の改善
- style: コード品質を重視し、スクラムでの開発経験があります。レスポンシブ対応を前提に設計します。
- closing: ユーザー視点での開発を常に心がけています。

## intro
受託開発の会社で Web アプリの設計から実装・テストまでを担当し、
現在は Flutter を使ったモバイル / Web アプリの開発に取り組んでいます。

<!--
  ---------- Work / Private（任意） ----------
  ここにも書くと、プロフィールと一緒に Skills と Projects も読み込みます（あとで個別にアップロードしなくてよい）。
  書き方は Work / Private のテンプレート（format_work.md / format_private.md）と同じで、見出しを 1 段深くします：
    プロジェクト名 … 「## プロジェクト名」（複数件は続けて書く）、詳細 … 「### details」
  - 該当しない項目は「利用なし」
  - Work は workflow（担当した工程）を必ず書く。Private には書かない
  - 使わないときは「# work」「# private」の見出しごと消してください（消すと、今表示している Work / Private はそのまま）
-->

# work

## サンプル・ワークプロジェクト
- description: チーム開発における設計から実装、テストまでのアジャイル開発を担当
- period: 2023-04 ~ 2023-09
- link:
- server_os: Linux, Windows
- db: PostgreSQL
- tools: Git, GitLab, VSCode
- backend_frameworks: Django
- frontend_frameworks: 利用なし
- ui_frameworks: Bootstrap
- testing_frameworks: 利用なし
- cloud_platforms: 利用なし
- aws_services: 利用なし
- azure_services: 利用なし
- gcp_services: 利用なし
- container: 利用なし
- container_orchestration: 利用なし
- ai_services: 利用なし
- skills: Python
- workflow: 基本設計, 詳細設計, 実装・単体テスト, 結合テスト

### details
要件定義を元にした詳細設計、バックエンドのAPI実装、フロントエンドのUI調整を実施。
単体テストの作成やコードレビューを通じて品質担保に貢献。

# private

## サンプル・プライベートプロジェクト
- description: 個人開発によるWebアプリケーション制作
- period: 2024-01 ~ 2024-06
- link: https://sigu-f7a231.github.io/my-portfolio/
- server_os: Windows
- db: 利用なし
- tools: GitHub, VSCode
- backend_frameworks: Node.js
- frontend_frameworks: React, Next.js
- ui_frameworks: 利用なし
- testing_frameworks: 利用なし
- cloud_platforms: 利用なし
- aws_services: 利用なし
- azure_services: 利用なし
- gcp_services: 利用なし
- container: Docker
- container_orchestration: 利用なし
- ai_services: 利用なし
- skills: JavaScript, TypeScript, HTML, CSS, YAML

### details
モダンな技術スタックを用いたフルスタック開発の検証。
UI/UXの設計からレスポンシブ対応、コンテナ化までを一人で担当。
