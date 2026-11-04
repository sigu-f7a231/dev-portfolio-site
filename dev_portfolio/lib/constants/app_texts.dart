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
  static const String toLightMode = 'ライトモードにする';
  static const String toDarkMode = 'ダークモードにする';

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
  static const String save = '保存';

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
  static const String uploadYaml = 'YAML をアップロード';
  static const String chooseFile = 'ファイルを選択';

  // テキストの貼り付け（ファイルを保存・選択できない人向け）
  static const String templateGroup = 'テンプレート（ひな形）';
  static const String inputGroup = 'データを読み込む';
  static const String copyTemplate = 'テンプレートをコピー';
  static String templateCopied(String fileName) => '$fileName の内容をコピーしました';
  static const String copyFailed = 'コピーできませんでした。「テンプレートを保存」を使ってください';
  static const String pasteText = 'テキストを貼り付け';
  static const String pastedTextName = '貼り付けたテキスト';
  static const String pasteTitle = 'YAML / Markdown を貼り付け'; // 開くボタン（pasteText）と同じ文言にしない
  static const String pasteLead =
      '書き換えた YAML または Markdown の内容をそのまま貼り付けてください（形式は自動で見分けます）。'
      'YAML はインデント（半角スペース）も含めて貼り付けます。';
  static const String pasteHint = '例）YAML\nprojects:\n  - title: プロジェクト名\n\n例）Markdown\n# プロジェクト名\n- skills: Dart, Flutter';
  static const String pasteFromClipboard = 'クリップボードから貼り付け';
  static const String clipboardEmpty = 'クリップボードにテキストがありません';
  static const String clipboardDenied =
      'クリップボードを読めませんでした。入力欄を長押し（PC は Ctrl+V / ⌘V）して貼り付けてください';
  static const String pasteApply = '読み込む';
  static const String pasteEmpty = 'テキストが空です';
  static const String chooseAnotherFile = '別のファイルを選択';
  static const String noFileChosen =
      'まだ読み込んでいません（.yaml / .yml / .md のファイル、またはテキストの貼り付け）';
  static const String formatYaml = 'YAML';
  static const String formatMarkdown = 'Markdown';
  static String sourceWithFormat(String source, String format) => '$source（$format）';
  static const String markdownFileDescription = 'Markdown ファイル';
  static const String pasteClear = 'クリア';
  static String fileReady(String name) => '$name（読み込めます）';
  static String fileRejected(String name) => '$name（読み込めません）';
  static const String uploadNeedsFile = '「ファイルを選択」か「テキストを貼り付け」で正しい YAML を読み込むと、アップロードできます';

  // アップロード前の確認画面
  static const String confirmTitle = 'この内容でアップロードしますか？';
  static String confirmFile(String name) => '読み込み元：$name';
  static String confirmReplace(String what) => '今表示している $what の内容は、この内容に置き換わります。';
  static String confirmProjectCount(int n) => 'プロジェクト $n 件';
  static const String confirmBack = '戻る';
  static const String confirmOk = 'OK（アップロード）';
  static const String reloading = '読み込み中…';
  static const String uploadFailedTitle = 'このファイルは読み込めません';
  static const List<String> workUploadSteps = [
    '「テンプレートを保存」か「テンプレートをコピー」で、ひな形を用意する',
    '業務で関わったプロジェクトを書き換える（書き方は ⓘ）',
    '「ファイルを選択」か「テキストを貼り付け」で読み込み、「アップロード」で内容を確認すると Skills と Projects に反映される',
  ];
  static const List<String> privateUploadSteps = [
    '「テンプレートを保存」か「テンプレートをコピー」で、ひな形を用意する',
    '個人開発のプロジェクトを書き換える（書き方は ⓘ）',
    '「ファイルを選択」か「テキストを貼り付け」で読み込み、「アップロード」で内容を確認すると Skills と Projects に反映される',
  ];
  static String uploadSessionNote(String dataType) =>
      '読み込んだ内容はこのタブの中だけで使います（セッションの「$dataType」に保存。サーバーには送りません）。';
  static const String upload = 'アップロード';
  static const String loading = '読み込み中';
  static String selectedFile(String name) => '選択中: $name';
  static String fileReadFailed(Object e) => 'ファイルの読み込みに失敗しました: $e';
  static String uploadSaved(String dataType) => '$dataType用YAMLをセッションに保存しました！';
  static String formatMismatch(String dataType, String templateName) =>
      'フォーマットが一致しません。\n'
      'このファイルは $dataType 用ではありません（$templateName の構造を満たしていません）。';

  // ----------------------------------------------------------
  // フォーマットのダウンロード / 書き方の説明（ⓘ）
  // ----------------------------------------------------------
  static const String downloadFormat = 'テンプレートを保存';
  static const String helpTemplateWhere =
      'テンプレートは、アップロード画面の「テンプレートを保存」「テンプレートをコピー」から用意できます'
      '（形式を「Markdown」にすると Markdown のひな形になります）。';
  static String downloadFormatTooltip(String fileName) => '$fileName を名前を付けて保存します';
  static String downloadFailed(Object e) => '保存に失敗しました: $e';
  static String formatSaved(String fileName) => '$fileName を保存しました';
  static const String yamlFileDescription = 'YAML ファイル';
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

  // Markdown で書く場合（ⓘ）
  static const String helpMarkdownTitle = 'Markdown で書く場合';
  static const List<String> helpMarkdownProjects = [
    '1 件ごとに「# プロジェクト名」から書き始めます',
    '項目は「- キー: 値」（キーは YAML と同じ。複数あるときはカンマ区切り）',
    '期間は「- period: 2024-04 ~ 2024-09」（続いているときは「~ 現在」）',
    '詳細は「## details」の下に複数行で書きます（項目はそれより前に書く）',
    '「<!-- -->」の中はメモとして読み飛ばします',
  ];
  static const String helpMarkdownWorkflow =
      'workflow は担当した工程をカンマ区切りで書きます（例：- workflow: 基本設計, 詳細設計）';
  static const String helpMarkdownPrivate = 'Private には workflow を書きません';
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

  // ページネーション
  static const String paginationEllipsis = '…';
  static String paginationCompact(int current, int total) => '$current / $total';
  static const String paginationPrev = '前のページ';
  static const String paginationNext = '次のページ';
  static String moreTags(int count) => '+$count';
  static const String filterServerOS = 'Server OS';
  static const String filterDb = 'DB';
  static const String filterTools = 'Tools';
  static const String filterBackend = 'Backend';
  static const String filterFrontend = 'Frontend';
  static const String filterSkills = 'Skills';
  static const String filterWorkflow = 'Workflow';
  static const String filterPeriod = '期間';
  static const String filterOngoingOnly = '進行中のみ';
  static const String periodAll = '指定なし（すべての期間）';
  static String periodRange(int from, int to) => from == to ? '$from年' : '$from年〜$to年';
  static String periodSingleYear(int year) => 'すべて $year 年のプロジェクトです';

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
  static const String periodNow = '現在';
  static String periodSpan(String from, String to) => '$from → $to';
  static String yearMonth(DateTime d) => '${d.year}年${d.month}月';

  /// List（年表）の左側：開始の年と月
  static String listYear(DateTime d) => '${d.year}';
  static String listMonth(DateTime d) => '${d.month}月';
  static const String listNoDate = '—';
  static const String listStartLabel = '開始';

  /// 詳細ダイアログの前 / 次の案件
  static const String prevProject = '前の案件';
  static const String nextProject = '次の案件';
  static const String prevShort = '前へ';
  static const String nextShort = '次へ';
  static const String noPrevProject = '最初の案件です';
  static const String noNextProject = '最後の案件です';
  static String projectPosition(int current, int total) => '$current / $total';

  /// 期間の長さ（例：6か月 / 1年 / 1年3か月）
  static String durationLabel(int months) {
    final y = months ~/ 12, m = months % 12;
    if (y == 0) return '$mか月';
    if (m == 0) return '$y年';
    return '$y年$mか月';
  }

  static String periodSemantics(String from, String to, String duration) =>
      '期間 $from から $to まで、$duration';
  static const String fieldWorkflow = 'Workflow';
  static const String workflowDone = '担当';
  static const String workflowNotDone = '担当外';
  static String workflowStepSemantics(String step, bool done) =>
      '$step：${done ? workflowDone : workflowNotDone}';

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
/// Home の固定の文言（名前・紹介文などは プロフィール YAML から読む）
class HeroContent {
  HeroContent._();

  static const String skillsButtonLabel = 'スキルを見る';
  static const String projectsButtonLabel = 'プロジェクトを見る';
}

/// About の固定の文言（中身は プロフィール YAML から読む）
class AboutContent {
  AboutContent._();

  static const String heading = 'About';

  // 定義リストの見出し
  static const String domainsLabel = '得意な領域';
  static const String strengthsLabel = '強み';
  static const String styleLabel = '開発スタイル';
}

/// プロフィール（Home / About）の入力画面・説明・エラー
class ProfileTexts {
  ProfileTexts._();

  static const String setupTitle = 'あなたのことを教えてください';
  static const String setupLead =
      'Home と About に表示するあなたのプロフィールを、YAML か Markdown で読み込みます。'
      '同じファイルに Work / Private も書けば、Skills と Projects もまとめて読み込めます。'
      '読み込むまでこの画面は閉じられません。';
  static const List<String> setupSteps = [
    '「テンプレートを保存」か「テンプレートをコピー」で、ひな形を用意する',
    '名前・職種・自己紹介などを自分の内容に書き換える（メモアプリなどでも OK）',
    '「ファイルを選択」か「テキストを貼り付け」で読み込み、「アップロード」で内容を確認して反映する',
  ];
  static const String setupNextTime = '次回からは、YAML を指定して起動するとこの画面は出ません：';
  static const String runCommand = 'dart run tool/run.dart あなたのファイル.yaml（.md も可）';

  static const String saveTemplate = 'テンプレートを保存';
  static const String replaceTarget = 'プロフィール（Home / About）';
  static const String confirmHome = 'Home';
  static const String confirmAbout = 'About';
  static const String fieldName = '名前';
  static const String fieldRole = '職種';
  static const String fieldTagline = '紹介文';
  static const String fieldCard = '右側のカード';
  static const String fieldIntro = '自己紹介';
  static const String fieldClosing = '締めの一言';
  static const String upload = 'YAML をアップロード';
  static const String helpTooltip = '書き方の説明';
  static const String uploaded = 'プロフィールを読み込みました';
  static const String uploadFailedTitle = 'このファイルは読み込めません';
  static const String startupFailedTitle = '起動時に指定した YAML を読み込めませんでした';
  static const String extensionOnly = '.yaml / .yml / .md / .markdown のファイルだけ選べます';

  // 説明（ⓘ）
  static const String helpTitle = 'プロフィール YAML の書き方';
  static const String helpRules = '基本ルール';
  static const List<String> helpRuleList = [
    'home:（最初の画面）と about:（自己紹介）の 2 つに分けて書きます',
    'インデントは半角スペース 2 つ',
    '★ の項目は必須です。それ以外は書かなければ表示しません',
    '複数行の文章は「|」のあとに改行して書きます',
  ];
  static const String helpFields = '各項目';
  static const String required = '★ 必須';
  static const String optional = '任意';
  static const List<(String, bool, String)> helpFieldList = [
    ('home.name', true, '名前（大きく表示）'),
    ('home.role', true, '職種（名前の上に小さく表示）'),
    ('home.tagline', true, '紹介文（名前の下に表示）'),
    ('home.card', false, '右側のカード。「キー: 値」や「キー: のあとに - 箇条書き」で自由に書けます'),
    ('about.intro', true, '自己紹介（名前・職種・経歴を 2〜3 文で）'),
    ('about.domains', false, '得意な領域（- 箇条書き。タグで表示）'),
    ('about.strengths', false, '強み'),
    ('about.style', false, '開発スタイル・価値観'),
    ('about.closing', false, '締めの一言'),
  ];
  static const String helpTemplate = 'ひな形（テンプレート）';
  static const String helpMarkdownTitle = 'Markdown で書く場合';
  static const List<String> helpMarkdownRules = [
    '「# home」と「# about」の 2 つの見出しに分けて書きます',
    '1 行の項目は「- キー: 値」（例：- name: 山田 太郎）',
    '複数行の文章（tagline・intro）は「## キー」の下に書きます（「- キー: 値」はそれより前に書く）',
    'card は「## card」の下に「- キー: 値」で書きます（カンマ区切りは箇条書きになる）',
    'domains はカンマ区切りで書きます（例：- domains: Web, モバイル）',
    '「<!-- -->」の中はメモとして読み飛ばします',
  ];
  static const String helpMarkdownTemplate = 'テンプレートの形式を「Markdown」にすると、Markdown のひな形を保存・コピーできます。';
  static const String helpBundleTitle = 'Work / Private も一緒に読み込む（任意）';
  static const List<String> helpBundleRules = [
    '同じファイルに Work / Private も書くと、1 回のアップロードで Skills と Projects も切り替わります（あとで個別にアップロードしなくてよい）',
    'YAML：トップに「work:」「private:」を足し、その下に Work / Private のテンプレートの「projects:」の中身（- title: …）を書きます',
    'Markdown：「# work」「# private」の見出しの下に、1 件ごとに「## プロジェクト名」、詳細は「### details」（単独のファイルより見出しを 1 段深く）',
    '書いたものは Work / Private のアップロードと同じように確かめます（Work は workflow が必要、Private は workflow を書かない）',
  ];
  static const String helpTemplateNote =
      '書き方の見本になるファイルです。前の画面の「テンプレートを保存」から保存して、書き換えてください。';

  // エラー
  static String errorSyntax(String m) => 'YAML の書き方に誤りがあります（$m）';
  static const String errorNotMap = 'プロフィールの形式ではありません（home: と about: が必要です）';
  static String errorUnknownKey(String k) => '使えない項目があります：$k';
  static String errorMissingSection(String k) => '$k: がありません';
  static String errorRequired(String k) => '必須の項目が空です：$k';
  static String errorNotText(String k) => '$k は文章で書いてください';
  static String errorNotList(String k) => '$k は「- 」の箇条書きで書いてください';
  static String errorNotMapField(String k) => '$k は「キー: 値」の形で書いてください';
  static String errorCardValue(String k) => '$k の値は文章か「- 」の箇条書きにしてください';
}

/// Markdown で書いたデータの読み取りのエラー（lib/utils/data_format.dart）
class MarkdownTexts {
  MarkdownTexts._();

  static String beforeFirstHeading(int line, String text) =>
      '$line 行目：最初の「# 見出し」より前に書かれています（$text）';
  static String strayLine(int line, String text) =>
      '$line 行目：「- キー: 値」の形になっていません（$text）';
  static String unknownKey(int line, String key) => '$line 行目：使えない項目があります：$key';
  static String unknownSection(int line, String name) =>
      '$line 行目：使えない見出しです：## $name（使えるのは ## details）';
  static String unknownWorkflow(int line, String step) =>
      '$line 行目：workflow の工程名が違います：$step（要件定義 / 基本設計 / 詳細設計 / 実装・単体テスト / 結合テスト / 総合テスト / 保守・運用）';
  static String cardNeedsFields(int line, String name) =>
      '$line 行目：## $name の下は「- キー: 値」の形で書いてください';
  static const String noProjects = 'プロジェクトがありません（1 件ごとに「# プロジェクト名」から書き始めてください）';
  static const String noProfileSections = '「# home」と「# about」の見出しがありません';
}

/// プロフィールのファイルに Work / Private も一緒に書いたとき（lib/utils/data_format.dart / profile_bundle.dart）
class BundleTexts {
  BundleTexts._();

  static String notProjects(String key) =>
      '$key: はプロジェクトの並び（- title: …）で書いてください';
  static String noProjectsIn(String key) =>
      '# $key の下にプロジェクトがありません（1 件ごとに「## プロジェクト名」から書き始めてください）';
  static const String workInvalid =
      'work の形式が違います（各プロジェクトに title と workflow が必要です）';
  static const String privateInvalid =
      'private の形式が違います（各プロジェクトに title が必要で、workflow は書きません）';
  static String includes(int? work, int? private) => [
        if (work != null) 'Work $work 件',
        if (private != null) 'Private $private 件',
      ].join('・');
  static String alsoLoads(String what) => '$what も一緒に読み込みます（Skills と Projects も切り替わります）';
  static String confirmSection(String label, int count) => '$label：プロジェクト $count 件';
}

/// アップロードで今の内容が上書きされるときの確認（lib/widgets/upload_parts.dart の confirmOverwrite）
class OverwriteTexts {
  OverwriteTexts._();

  static const String title = '今の内容が上書きされます';
  static String lead(String targets) =>
      '今表示している $targets と、これからアップロードする内容に違いがあります。'
      'アップロードすると今の内容は上書きされ、元には戻せません。';
  static String added(int n) => '追加されるプロジェクト（$n 件）';
  static String removed(int n) => 'なくなるプロジェクト（$n 件）';
  static String changed(int n) => '内容が変わるプロジェクト（$n 件）';
  static String more(int n) => '…ほか $n 件';
  static const String question = 'それでもアップロードしますか？';
  static const String cancel = 'やめる';
  static const String overwrite = '上書きしてアップロード';
}

