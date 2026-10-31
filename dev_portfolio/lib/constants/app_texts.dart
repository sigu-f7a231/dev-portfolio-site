// lib/constants/app_texts.dart
//
// ============================================================
// 画面に表示する文言（ウィジェットに直接文字列を書かず、ここから参照する）
// ============================================================
// - 文言を変えたいときはこのファイルだけを書き換える。
// - 変数を埋め込む文言は関数にしている（例: AppTexts.uploadSaved('work')）。
// - YAML のキー名（title / workflow など）はデータの一部なのでここには置かない。

/// 共通の文言
class AppTexts {
  AppTexts._();

  // ----------------------------------------------------------
  // アプリ全体・ナビゲーション
  // ----------------------------------------------------------
  static const String appTitle = 'DevPortfolio';
  static const String navHome = 'Home';
  static const String navAbout = 'About';
  static const String navSkills = 'Skills';
  static const String navProjects = 'Projects';
  static const String darkMode = 'Dark Mode';

  // ----------------------------------------------------------
  // 共通ラベル
  // ----------------------------------------------------------
  static const String work = 'Work';
  static const String private = 'Private';
  static const String viewList = 'List';
  static const String viewCollection = 'Collection';
  static const String chartBar = 'Bar';
  static const String chartPie = 'Pie';
  static const String cancel = 'キャンセル';
  static const String close = '閉じる';
  static const String download = 'ダウンロード';

  // ----------------------------------------------------------
  // YAML アップロード（ヘッダー）
  // ----------------------------------------------------------
  static const String workUploadTooltip = 'Work用のYAMLをアップロード';
  static const String privateUploadTooltip = 'Private用のYAMLをアップロード';
  static const String workUploadTitle = 'Work用 YAMLのアップロード';
  static const String privateUploadTitle = 'Private用 YAMLのアップロード';

  static const String workUploadDescription =
      'Work用のプロジェクト情報を定義したYAMLファイルをアップロードしてください。';
  static const String privateUploadDescription =
      'Private用の非公開プロジェクト情報を定義したYAMLファイルをアップロードしてください。';

  /// デスクトップ版のみ説明の後ろに付ける注意事項
  static const String workUploadNote = '\n\n【注意事項】\n'
      '・アップロード時に `assets/data/format_work.yaml` の構造と照合され、セッションの `work` キーに保持されます。';
  static const String privateUploadNote = '\n\n【注意事項】\n'
      '・アップロード時に `assets/data/format_private.yaml` の構造と照合され、セッションの `private` キーに保持されます。';

  static const String selectYamlFile = 'YAMLファイルを選択 (.yaml, .yml)';
  static const String upload = 'アップロード';
  static String selectedFile(String name) => '選択中: $name';
  static String fileReadFailed(Object e) => 'ファイルの読み込みに失敗しました: $e';
  static String uploadSaved(String dataType) => '$dataType用YAMLをセッションに保存しました！';
  static String formatMismatch(String dataType, String templateName) =>
      'フォーマットが一致しません。\n'
      'このファイルは $dataType 用ではありません（$templateName の構造を満たしていません）。';

  // ----------------------------------------------------------
  // フォーマットのダウンロード / 書き方の説明（ⓘ）
  // ----------------------------------------------------------
  static const String downloadFormat = 'フォーマットをダウンロード';
  static String downloadFormatTooltip(String fileName) => '$fileName をダウンロードします';
  static String downloadFailed(Object e) => 'ダウンロードに失敗しました: $e';
  static const String formatHelpTooltip = '書き方の説明';
  static String formatHelpTitle(bool isWork) => '${isWork ? work : private} 用 YAML の書き方';

  static const String helpBasicRules = '基本ルール';
  static const String helpRuleStructure =
      'ファイルの先頭に `projects:` を書き、その下に `- title:` から始まるブロックを並べます（1 ブロック = 1 プロジェクト）。';
  static const String helpRuleIndent = 'インデントは半角スペース 2 つです（タブは使えません）。';
  static const String helpRuleTitle = '`title` は必須です。';
  static const String helpRuleWorkflowWork = 'Work 用は、すべてのプロジェクトに `workflow` が必須です。';
  static const String helpRuleWorkflowPrivate =
      'Private 用には `workflow` を書かないでください（書くとエラーになります）。';
  static const String helpRuleNotUsed = '該当しない項目は `- 利用なし` と書きます（グラフの集計からは除外されます）。';

  static const String helpFields = '各項目';
  static const String helpTitleFormat = '文字列（必須）';
  static const String helpTitleNote = 'プロジェクト名';
  static const String helpDescriptionFormat = '文字列';
  static const String helpDescriptionNote = '一覧に表示する一言説明';
  static const String helpDetailsFormat = '複数行（`|` のあとに改行して書く）';
  static const String helpDetailsNote = '詳細モーダルに表示する説明';
  static const String helpPeriodFormat = 'リスト 2 行：`- 開始(YYYY-MM)` `- 終了(YYYY-MM)`';
  static const String helpPeriodNote = '進行中なら終了を `現在` にします（例: `- 2024-04` / `- 現在`）';
  static const String helpLinkFormat = 'URL';
  static const String helpLinkNote = '公開ページ。ない場合は `""`';
  static const String helpListFormat = 'リスト（1 行に 1 つ `- 値`）';
  static const String helpListNote = 'Skills のグラフ集計とフィルターに使われます';
  static const String helpWorkflowFormat = '各工程を true / false で指定（必須）';
  static const String helpWorkflowNote = '担当した工程を true にします';
  static String helpSampleTitle(String fileName) => 'サンプル（$fileName の中身）';
  static const String helpSampleLoadFailed = 'サンプルを読み込めませんでした';
  static const String bullet = '・';

  // ----------------------------------------------------------
  // Projects
  // ----------------------------------------------------------
  static const String filter = 'フィルター';
  static const String filterApply = '反映';
  static const String filterClear = 'クリア';
  static const String filterActive = '適用中';
  static const String filterClearAll = 'すべて解除';
  static String filterRemoveTooltip(String value) => '「$value」を外す';
  static const String viewListTooltip = 'リスト表示';
  static const String viewCollectionTooltip = 'コレクション表示';
  static const String noResultsHint = 'フィルターの条件を減らすと表示されます';
  static String moreTags(int count) => '+$count';
  static const String filterServerOS = 'Server OS';
  static const String filterDb = 'DB';
  static const String filterTools = 'Tools';
  static const String filterBackend = 'Backend';
  static const String filterFrontend = 'Frontend';
  static const String filterSkills = 'Skills';
  static const String filterWorkflow = 'Workflow';

  static const String viewDetails = '詳細を見る';
  static const String ongoing = '進行中';
  static const String noResults = 'ヒットしませんでした';
  static const String noProjects = 'No projects';
  static const String openPublicPage = '公開ページを見る';

  // 詳細モーダルの項目名
  static const String fieldTitle = 'タイトル';
  static const String fieldDescription = '説明';
  static const String fieldDetails = '詳細';
  static const String fieldServerOS = 'サーバーOS';
  static const String fieldDb = 'DB';
  static const String fieldTools = 'Tools';
  static const String fieldBackend = 'Backend Frameworks';
  static const String fieldFrontend = 'Frontend Frameworks';
  static const String fieldUi = 'UI Frameworks';
  static const String fieldTesting = 'Testing Frameworks';
  static const String fieldCloud = 'Cloud Platforms';
  static const String fieldAws = 'AWS Services';
  static const String fieldAzure = 'Azure Services';
  static const String fieldGcp = 'GCP Services';
  static const String fieldContainer = 'Container';
  static const String fieldOrchestration = 'Container Orchestration';
  static const String fieldAi = 'AI Services';
  static const String fieldSkills = 'Skills';
  static const String fieldPeriod = '期間';
  static const String fieldWorkflow = 'Workflow';
  static const String workflowDone = '✅';
  static const String workflowNotDone = '❌';

  // ----------------------------------------------------------
  // Skills
  // ----------------------------------------------------------
  static const String noData = 'データがありません';
  static const String chartOthers = 'その他';
  static const String chartBarTooltip = '棒グラフ';
  static const String chartPieTooltip = '円グラフ';
  // カテゴリ（ツールバーのボタン・パネル）
  static const String category = 'カテゴリ';
  static const String categoryGroupInfra = 'インフラ';
  static const String categoryGroupDev = '開発';
  static const String categoryGroupCloud = 'クラウド・AI';
  static const String categoryGroupProcess = '工程';
  static const String privateHidden = 'Private のため表示できません';

  /// カテゴリキー → 表示名
  static const Map<String, String> skillCategoryLabels = {
    'server_os': 'OS',
    'db': 'DB',
    'tools': 'Tools',
    'backend_frameworks': 'Backend',
    'frontend_frameworks': 'Frontend',
    'ui_frameworks': 'UI Frameworks',
    'testing_frameworks': 'Testing Frameworks',
    'cloud_platforms': 'Cloud Platforms',
    'aws_services': 'AWS',
    'gcp_services': 'GCP',
    'azure_services': 'Azure',
    'container': 'Container',
    'container_orchestration': 'Container Orchestration',
    'ai_services': 'AI Services',
    'skills': 'Skills',
    'workflow': 'Workflow',
  };
}

/// Home に表示する内容（★ここを自分の情報に書き換える）
class HeroContent {
  HeroContent._();

  static const String name = 'あなたの名前';
  static const String role = 'Web / モバイルエンジニア';
  static const String tagline =
      'Flutter と Dart を中心に、Web とモバイルのフロントエンドを開発しています。'
      'このサイトでは、業務と個人開発で使ってきた技術と、関わったプロジェクトをまとめています。';

  /// 右側の「プロフィール YAML」に表示する項目（キー: 値。値が List なら箇条書きになる）
  static const Map<String, Object> profile = {
    'name': name,
    'role': 'Web / Mobile Engineer',
    'stack': ['Flutter', 'Dart', 'TypeScript'],
    'focus': 'ユーザー視点の UI',
  };

  static const String skillsButtonLabel = 'スキルを見る';
  static const String projectsButtonLabel = 'プロジェクトを見る';
}

/// About に表示する内容（★ここを自分の情報に書き換える）
class AboutContent {
  AboutContent._();

  static const String heading = 'About';

  /// 自己紹介（名前・職種・簡単な経歴）
  static const String intro =
      'ここに自己紹介を書きます。名前、職種、これまでの経歴を 2〜3 文で。'
      '例: 受託開発の会社で Web アプリの設計から実装・テストまでを担当し、'
      '現在は Flutter を使ったモバイル / Web アプリの開発に取り組んでいます。';

  /// 得意な開発領域（タグで表示）
  static const List<String> domains = ['Web', 'モバイル', 'Flutter', 'Dart'];

  /// 強み・スキル
  static const String strengths = 'チーム開発、テストの設計と実施、UI の改善';

  /// 開発スタイル・価値観
  static const String style = 'コード品質を重視し、スクラムでの開発経験があります。レスポンシブ対応を前提に設計します。';

  /// 締めの一言
  static const String closing = 'ユーザー視点での開発を常に心がけています。';

  // 定義リストの見出し
  static const String domainsLabel = '得意な領域';
  static const String strengthsLabel = '強み';
  static const String styleLabel = '開発スタイル';
}
