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
  AppTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

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
  static const String helpRoleFormat = '文字の並び（例：[PL, SE]）';
  static const String helpRoleNote = '役割（PM・PL・SE・PG など）。詳細に表示し、フィルターで絞り込めます。なければ []';
  static const String helpScaleFormat = '文字（例：全体 20名（チーム 5名））';
  static const String helpScaleNote = '規模。最初に書いた人数（○名 / ○人）でフィルターの「規模（人数）」に分けます。なければ ""';
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
  static const String filterRole = '役割';
  static const String filterScale = '規模（人数）';
  static const String filterServerOS = 'Server OS';
  static const String filterDb = 'DB';
  static const String filterTools = 'Tools';
  static const String filterBackend = 'Backend';
  static const String filterFrontend = 'Frontend';
  // 案件の詳細：画面共有向けの表示の大きさ
  // [mod] は修飾キーの名前（Mac は ⌘、Windows などは Ctrl。lib/utils/platform_keys.dart）
  static String zoomOut(String mod) => '文字を小さく（− / $mod＋−）';
  static String zoomIn(String mod) => '文字を大きく（＋ / $mod＋＋）';
  static String zoomPercent(int percent) => '$percent%';
  static String zoomReset(String mod) => '元の大きさに戻す（$mod＋0。0 は文字の大きさだけ戻す）';
  static const String largeView = '大きく表示（画面共有向け・F）';
  static String normalView(String mod) => '元の大きさに戻す（F / $mod＋0）';
  // Projects の並び替え（lib/sections/projects/sort/project_sort.dart）
  static const String sort = '並び替え';
  static String sortCurrent(String name) => '並び：$name';
  static const String sortStartOldest = '開始が古い順';
  static const String sortStartNewest = '開始が新しい順';
  static const String sortEndNewest = '終了が新しい順';
  static const String sortDurationLongest = '期間が長い順';
  static const String sortDurationShortest = '期間が短い順';
  static const String sortTitle = '名前順';
  static const String filterUi = 'UI Frameworks';
  static const String filterTesting = 'Testing Frameworks';
  static const String filterCloud = 'Cloud Platforms';
  static const String filterAws = 'AWS';
  static const String filterAzure = 'Azure';
  static const String filterGcp = 'GCP';
  static const String filterContainer = 'Container';
  static const String filterOrchestration = 'Container Orchestration';
  static const String filterAi = 'AI Services';
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
  static const String fieldRole = '役割';
  static const String fieldScale = '規模';

  /// 規模（人数）のフィルターの区分（[上限, 名前]。上限は含む。最後は上限なし）
  static const List<(int?, String)> scaleBuckets = [
    (5, '〜5名'),
    (10, '6〜10名'),
    (30, '11〜30名'),
    (100, '31〜100名'),
    (null, '101名〜'),
  ];
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
  static const String categoryGroupTools = 'ツール';
  static const String categoryGroupSkills = 'スキル';
  static const String privateHidden = 'Private のため表示できません';

  /// カテゴリキー → 表示名
  static const Map<String, String> skillCategoryLabels = {
    'server_os': 'OS',
    'db': 'DB',
    'tools': 'Tools',
    'tools_vcs': 'Tools：バージョン管理',
    'tools_dev': 'Tools：エディタ・開発ツール',
    'tools_env': 'Tools：環境・ミドルウェア',
    'tools_cicd': 'Tools：CI/CD・構成管理',
    'tools_pm': 'Tools：プロジェクト管理・連絡',
    'tools_design': 'Tools：デザイン',
    'tools_other': 'Tools：その他',
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
    'skills_lang': 'Skills：プログラミング言語',
    'skills_markup': 'Skills：マークアップ・スタイルシート',
    'skills_data': 'Skills：データ形式・クエリ',
    'skills_arch': 'Skills：アーキテクチャ・設計',
    'skills_lib': 'Skills：ライブラリ',
    'skills_other': 'Skills：その他',
    'workflow': 'Workflow',
  };
}

/// Home に表示する内容（★ここを自分の情報に書き換える）
/// Home の固定の文言（名前・紹介文などは プロフィール YAML から読む）
class HeroContent {
  HeroContent._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  static const String skillsButtonLabel = 'スキルを見る';
  static const String projectsButtonLabel = 'プロジェクトを見る';

  // ---------- ボタンの下のまとめ（lib/utils/hero_summary.dart） ----------
  static const String summaryExperience = '開発経験';
  static String experienceSince(DateTime d) => '${d.year}年${d.month}月から';
  static const String summaryProjects = 'プロジェクト';
  static String projectsCount(int n) => '$n件';
  static String projectsBreakdown(int work, int private) => '業務 $work件・個人開発 $private件';
  static const String summaryLatest = '直近のプロジェクト';
  static String latestPeriod(String from, String to) => '$from 〜 $to';
  static const String latestPrivate = '個人開発';
  static const String projectsTooltip = 'Projects を見る';
  static const String latestTooltip = 'このプロジェクトの詳細を見る';
}

/// About の固定の文言（中身は プロフィール YAML から読む）
class AboutContent {
  AboutContent._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  static const String heading = 'About';

  // 定義リストの見出し
  static const String domainsLabel = '得意な領域';
  static const String strengthsLabel = '強み';
  static const String styleLabel = '開発スタイル';
  static const String recentLabel = '直近の開発経験';
  static const String pastLabel = '過去の開発経験';
}

/// プロフィール（Home / About）の入力画面・説明・エラー
class ProfileTexts {
  ProfileTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  static const String setupTitle = 'あなたのことを教えてください';
  static const String setupLead =
      'Home と About に表示するあなたのプロフィールを読み込みます。'
      'スキルシート（Excel）か、YAML / Markdown のどちらで入力するかを選んでください。'
      'Excel のプロジェクトや、同じファイルに書いた Work / Private も、Skills と Projects にまとめて読み込めます。'
      '読み込むまでこの画面は閉じられません。';
  static const List<String> setupSteps = [
    '「テンプレートを保存」か「テンプレートをコピー」で、ひな形を用意する',
    '名前・職種・自己紹介などを自分の内容に書き換える（メモアプリなどでも OK）',
    '「ファイルを選択」か「テキストを貼り付け」で読み込み、「アップロード」で内容を確認して反映する',
  ];
  static const String setupNextTime = '次回からは、YAML を指定して起動するとこの画面は出ません：';
  static const String runCommand = 'dart run tool/run.dart あなたのファイル.yaml（.md・.xlsx も可）';

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
  static const String fieldRecentTech = '直近の主な技術';
  static const String fieldPastTech = '過去の主な技術';
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
    ('about.recent / about.past', false, '直近 / 過去の開発経験（複数行。「領域：説明」の行は領域を太字で表示）'),
    ('about.recent_tech / about.past_tech', false, '直近 / 過去の主な技術。「分類: のあとに - 箇条書き」で書きます（例：言語: - Python）'),
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
  MarkdownTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

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
  BundleTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

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
  OverwriteTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

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

/// 入力方法の切り替えと、スキルシート（Excel）からの読み込み
/// （lib/widgets/profile_setup_dialog.dart・lib/utils/skill_sheet.dart）
class ExcelTexts {
  ExcelTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  // ---------- 入力方法 ----------
  static const String methodLabel = '入力方法';
  static const String methodExcel = 'Excel（スキルシート）';
  static const String methodText = 'YAML / Markdown';

  // ---------- 入力画面（Excel） ----------
  static const List<String> steps = [
    '「Excel テンプレートを保存」で、名前を付けてひな形を保存する（同じ形式のスキルシートがあれば不要）',
    'Excel で氏名・過去 / 直近の開発経験・プロジェクトを書き換えて保存する',
    '「Excel を選択」で読み込み、「アップロード」で内容を確認して反映する',
  ];
  static const String saveTemplate = 'Excel テンプレートを保存';
  static const String chooseExcel = 'Excel を選択';
  static const String chooseAnotherExcel = '別の Excel を選択';
  static const String inputGroup = 'スキルシートを読み込む';
  static const String excelFileDescription = 'Excel ブック';
  static const String extensionOnly = '.xlsx / .xlsm のファイルだけ選べます（.xls は Excel で .xlsx として保存し直してください）';
  static const String saveYaml = '作った YAML を保存';
  static const String saveYamlNote =
      'Excel から作った YAML を保存しておくと、次回はその YAML を指定して起動できます（下のコマンド）。';
  static const String howItMaps = 'Excel から読み取る項目';
  static const List<String> mapping = [
    'Home / About：氏名、過去の開発経験・主な技術、直近の開発経験・主な技術',
    'Home / About のほか：ふりがな・性別・年齢・生年月日・国籍・配偶者・最寄駅・学歴（［ダウンロード］のスキルシートにそのまま書きます）',
    'Work / Private：プロジェクト名、期間、業務概要、役割・規模、サーバ OS、DB、FW・MW ツール等、使用言語、作業工程',
    'プロジェクト名に「プライベート」か「個人開発」が入っているものは Private（作業工程は使いません）',
  ];

  // ---------- Excel の見出し・値 ----------
  static const String labelName = '氏名';

  /// スキルシートだけにある個人の項目（YAML の sheet のキー → Excel の見出し）
  /// 読み込んだ Excel のものをそのまま持っておき、［ダウンロード］でそのまま書く
  static const Map<String, String> sheetLabels = {
    'furigana': 'ふりがな',
    'gender': '性別',
    'age': '年齢',
    'birthday': '生年月日',
    'nationality': '国籍',
    'spouse': '配偶者',
    'station': '最寄駅',
    'education': '学歴',
  };

  /// プロジェクトの「役割・規模」の列の中の見出し（「役割：PG」「規模：10名」など）
  static const List<String> roleLabels = ['役割', 'ポジション', '担当'];
  static const List<String> scaleLabels = ['規模', '体制', '人数', 'チーム'];
  static const List<String> privateMarkers = ['プライベート', '個人開発'];
  static const String notUsed = '利用なし';
  static const String periodOngoing = '現在';

  // ---------- 作る文言（Excel にない Home の項目） ----------
  static const String defaultRole = 'エンジニア';
  static String taglineLanguages(List<String> languages) =>
      '${languages.join('・')} などを使って開発しています。';
  static String taglineAreas(List<String> areas) => '${areas.join('、')} などに携わっています。';
  static const String taglineFallback = 'これまでの開発経験と、関わったプロジェクトをまとめています。';
  static String introPast(List<String> areas) => 'これまでに、${areas.join('、')} などを経験してきました。';
  static String introRecent(List<String> areas) => '直近では、${areas.join('、')} などに取り組んでいます。';
  static const String introFallback = 'これまでの開発経験をまとめています。';
  static String yamlHeader(String? fileName) => [
        if (fileName != null) '$fileName から作ったプロフィール',
        'role（職種）などは自由に書き換えてください。書き方は format_profile.yaml を参照',
      ].join('\n');

  // ---------- エラー ----------
  static const String notXlsx = 'Excel（.xlsx）として読み込めません。ファイルが壊れていないか確かめてください';
  static const String nameMissing = '「氏名」の欄が見つからないか、空です';
  static const String experienceMissing =
      '「過去の開発経験」「直近の開発経験」が見つかりません（見出しの行のあとに、1 行ずつ「領域：説明」で書いてください）';
}

/// ヘッダーの［データ］：Work / Private のプロジェクトの追加・更新（lib/sections/header/project_data_dialog.dart）
class DataTexts {
  DataTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  // ---------- ヘッダーのボタン ----------
  static const String button = 'データ';
  static const String buttonTooltip = 'Work / Private のプロジェクトを追加・更新';

  // ---------- 画面 ----------
  static const String title = 'プロジェクトの追加・更新';
  static const String next = '次へ';
  static const String back = '戻る';

  // 各ステップの見出し
  static const String stepAction = '何をしますか？';
  static const String stepTarget = 'どちらのプロジェクトですか？';
  static const String stepMethod = 'どの方法で追加しますか？';
  static const String stepCount = '何件追加しますか？';
  static const String stepSingleInput = 'どうやって入力しますか？';
  static const String stepForm = '入力フォーム';
  static const String stepText = 'テキストから追加';
  static const String stepPick = '追加するプロジェクトを選ぶ';

  // 選択肢（見出し・説明）
  static const String add = '追加';
  static const String addNote = '今の一覧はそのままで、新しいプロジェクトを後ろに足します';
  static const String update = '更新';
  static const String updateNote = 'ファイルや貼り付けた内容で、丸ごと置き換えます（これまでのアップロード画面）';
  static const String workNote = '業務のプロジェクト';
  static const String privateNote = '個人開発のプロジェクト';
  static const String onScreen = '画面上で入力';
  static const String onScreenNote = 'この画面の入力フォームや、テキストから追加します';
  static const String existing = 'ファイル・貼り付けで追加';
  static const String existingNote = 'これまでのアップロード画面で、ファイルやテキストを読み込んで追加します';
  static const String single = '1 件';
  static const String singleNote = '1 件だけ追加します';
  static const String multiple = '複数件';
  static const String multipleNote = 'YAML / Markdown のテキストやファイルから、まとめて追加します';
  static const String form = '入力フォーム';
  static const String formNote = '項目ごとに入力します';
  static const String text = 'テキスト（YAML / Markdown）';
  static const String textNote = 'YAML や Markdown で書いたものを貼り付けるか、ファイルを選びます';

  // テキストから追加
  static String textLead(bool single) => single
      ? '1 件分の YAML か Markdown を貼り付けるか、ファイルを選んでください（書き方は Work / Private のテンプレートと同じ）。'
      : '追加するプロジェクトを YAML か Markdown で貼り付けるか、ファイルを選んでください（書き方は Work / Private のテンプレートと同じ）。';
  static const String textHint = '- title: プロジェクト名\n  description: 説明\n  period: [2024-04, 2024-09]\n  …';
  static const String insertSample = 'サンプルを入力欄に入れる（上で選んだ形式）';
  static String notSingle(int n) => '$n 件あります。1 件だけ書くか、前の画面で「複数件」を選んでください';

  // 複数件：全部か、選んだものだけか
  static String found(int n) => '$n 件のプロジェクトが見つかりました';
  static const String addAll = '全部追加する';
  static const String addSelected = '選んだものだけ追加する';
  static String selectedCount(int n, int total) => '$total 件中 $n 件を選んでいます';
  static const String selectAll = 'すべて選ぶ';
  static const String selectNone = 'すべて外す';
  static const String selectAtLeastOne = '1 件以上選んでください';

  // 入力フォーム
  static const String formTitle = 'プロジェクト名 ★';
  static const String formDescription = '説明（1 行）';
  static const String formDetails = '詳細（複数行）';
  static const String formPeriodStart = '開始';
  static const String formPeriodEnd = '終了';
  static const String formOngoing = '進行中（終わりは「現在」）';
  static const String formLink = 'リンク（URL）';
  static const String formListHint = '打つと候補が出ます。カンマか Enter で区切り、空の欄で Backspace 2 回で直前を消す';
  static const String formMainTech = '使った技術';
  static const String formMoreTech = 'そのほかの技術（UI・テスト・クラウド・コンテナ・AI）';
  static const String formOtherTech = 'フレームワーク・DB・OS・クラウド・コンテナ・AI';
  static const String formTechNote = '項目を押すと、入力欄と、すでにある項目の一覧が開きます';
  static const String tagPickerInput = '入力（打つと候補が出ます）';
  static const String tagPickerExisting = 'すでにある項目（押すと追加、もう一度押すと外す）';
  static const String tagPickerNoExisting = 'まだありません。上の欄に入力してください';
  static const String tagPickerDone = '完了';
  static String tagPickerTooltip(String label) => '$label を入力・選択';
  static const String formWorkflow = '担当した工程';
  static const String formRole = '役割';
  static const String formRoleNote = '押すと入力欄と候補（PM・PL・SE・PG など）が開きます';
  static const String formScale = '規模';
  static const String formScaleHint = '例：全体 20名（チーム 5名）';

  /// 役割の候補（今の Work / Private にあるものに足す）
  static const List<String> roleSuggestions = [
    'PM', 'PMO', 'PL', 'TL', 'SE', 'PG', 'テスター', 'インフラ', '運用・保守', 'デザイナー', 'フルスタック',
  ];
  static const String formTitleRequired = 'プロジェクト名を入れてください';
  static const String formPeriodInvalid = '「2024-04」の形で入れてください';
  static const String formPeriodEndMissing = '終了を入れるか、「進行中」にチェックしてください';
  static const String formPeriodOrder = '終了は開始と同じか、より後にしてください';
  static const String formPeriodStartMissing = '開始を入れてください';

  // 年と月を選ぶ画面
  static const String pickStart = '開始の年月を選ぶ';
  static const String pickEnd = '終了の年月を選ぶ';
  static String pickerYear(int y) => '$y年';
  static String pickerMonth(int m) => '$m月';
  static const String pickerPrevYear = '前の年';
  static const String pickerNextYear = '次の年';
  static const String pickerPrevYears = '前の 12 年';
  static const String pickerNextYears = '次の 12 年';
  static const String pickerOk = 'OK';
  static const String pickerOpen = '押すと年月を選べます';
  static const String pickerClear = '消す';

  // 読み取りのエラー
  static const String noProjectsFound =
      'プロジェクトが見つかりません（「projects:」の下か、「- title:」から書いてください）';
  static String itemNotMap(int i) => '$i 件目：「title: …」などの項目の形で書いてください';
  static String itemNoTitle(int i) => '$i 件目：title（プロジェクト名）がありません';
  static String itemNoWorkflow(int i) => '$i 件目：Work は workflow（担当した工程）が必要です';
  static String itemHasWorkflow(int i) => '$i 件目：Private には workflow を書きません';

  // 確認画面
  static const String confirmTitle = 'この内容で追加しますか？';
  static String confirmLead(String target, int current, int adding) =>
      '$target の今の $current 件の後ろに、$adding 件を追加します。';
  static const String dropSample = '今表示しているサンプルは外す（追加したものだけにする）';
  static String duplicates(String titles) =>
      '同じ名前のプロジェクトがすでにあります：$titles（両方とも残ります）';
  static const String confirmOk = 'OK（追加）';
  static String added(String target, int n) => '$target に $n 件追加しました';

  // これまでのアップロード画面を「追加」で使うとき
  static String appendTitle(String target) => '$target に追加（ファイル・貼り付け）';
  static const String appendDescription =
      '読み込んだプロジェクトを、今の一覧の後ろに足します（今の一覧は消えません）。';
}

/// スキルシート（Excel / PDF）の書き出し（lib/utils/skill_sheet_writer.dart・skill_sheet_pdf.dart・
/// lib/sections/header/download_menu.dart）
/// セルに書く見出しは、読み込み（skill_sheet.dart）で同じ分類として読み直せる書き方にしてある
class SkillSheetTexts {
  SkillSheetTexts._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  // ---------- テンプレートの見出し（探すとき） ----------
  static const String labelName = '氏名';
  static const String headerProjectName = 'プロジェクト名';

  // ---------- セルに書く文字 ----------
  static const String pastHeading = '過去の開発経験';
  static const String recentHeading = '直近の開発経験';
  static const String techHeading = '主な使用技術・開発環境：';
  static String months(int n) => '（$nヶ月）';
  static const String privateMark = '【個人開発】';
  static const String summaryHeading = '概要：';
  static const String detailsHeading = '内容：';
  static const String urlHeading = 'URL：';
  static const String osHeading = 'サーバOS：';
  static const String dbHeading = 'DB：';
  static const String none = 'なし';
  static const String toolsHeading = 'その他ツール・技術：';
  static const String cloudHeading = 'クラウド：';
  static const String awsHeading = 'AWS Service：';
  static const String azureHeading = 'Azure Service：';
  static const String gcpHeading = 'GCP Service：';
  static const String containerHeading = 'コンテナ：';
  static const String orchestrationHeading = 'コンテナオーケストレーション：';
  static const String aiHeading = 'AI：';
  static const String languageHeading = '使用言語/ライブラリー：';
  static const String frameworkHeading = 'FW・MW・ツール等：';
  static const String check = '●';
  static const String scaleHeading = '規模：';

  // ---------- ヘッダーの［ダウンロード］ ----------
  static const String button = 'ダウンロード';
  static const String buttonTooltip = 'スキルシート（Work / Private を含む）を Excel か PDF で保存';
  static const String excel = 'Excel（.xlsx）で名前を付けて保存…';
  static const String pdf = 'PDF で名前を付けて保存…';
  static const String making = 'スキルシートを作っています…';
  static String fileName(DateTime d, String ext) =>
      'skill_sheet_${d.year}${'${d.month}'.padLeft(2, '0')}${'${d.day}'.padLeft(2, '0')}.$ext';
  static const String excelDescription = 'Excel ブック';
  static const String pdfDescription = 'PDF ファイル';
  static const String pdfMimeType = 'application/pdf';
  static String saved(String what, String name) => '$what を保存しました（$name）';
  static String downloaded(String what, String name) => '$what をダウンロードしました（$name）';
  static String cancelled(String what) => '$what の保存をやめました';
  static String failed(String what, Object e) => '$what を出力できませんでした：$e';
  static const String excelShort = 'スキルシート（Excel）';
  static const String pdfShort = 'スキルシート（PDF）';
}

