// lib/utils/tech_catalog.dart
//
// よく知られた技術名が、どの分類（YAML のキー）に入るか
// - Excel から作るとき（skill_sheet.dart）：セルの見出しがない項目を振り分ける
// - 読み込んだ Work / Private（redistributeProject）：Skills や Tools に書かれた
//   フロントエンド・バックエンドなどの技術を、本来の分類に移す（Skills の集計・Projects の一覧の両方）
// 名前は表記ゆれを無視して比べる（skillKey。Node.js / NodeJS / nodejs は同じ）
//
// Flutter に依存しない。
import 'skill_name.dart';

/// 名前（小文字）→（分類, あわせて cloud_platforms に足すクラウド）
const Map<String, (String, String?)> _known = {
  // バックエンド
  'django': ('backend_frameworks', null), 'flask': ('backend_frameworks', null),
  'fastapi': ('backend_frameworks', null), 'laravel': ('backend_frameworks', null),
  'codeigniter': ('backend_frameworks', null), 'phalcon': ('backend_frameworks', null),
  'cakephp': ('backend_frameworks', null), 'symfony': ('backend_frameworks', null),
  'ruby on rails': ('backend_frameworks', null), 'rails': ('backend_frameworks', null),
  'spring': ('backend_frameworks', null), 'spring boot': ('backend_frameworks', null),
  'struts': ('backend_frameworks', null), 'express': ('backend_frameworks', null),
  'express.js': ('backend_frameworks', null), 'nestjs': ('backend_frameworks', null),
  'node.js': ('backend_frameworks', null), 'asp.net': ('backend_frameworks', null),
  '.net': ('backend_frameworks', null), 'gin': ('backend_frameworks', null),
  'streamlit': ('backend_frameworks', null),
  // フロントエンド
  'react': ('frontend_frameworks', null), 'next.js': ('frontend_frameworks', null),
  'vue': ('frontend_frameworks', null), 'vue.js': ('frontend_frameworks', null),
  'nuxt': ('frontend_frameworks', null), 'nuxt.js': ('frontend_frameworks', null),
  'angular': ('frontend_frameworks', null), 'svelte': ('frontend_frameworks', null),
  'jquery': ('frontend_frameworks', null), 'flutter': ('frontend_frameworks', null),
  'react native': ('frontend_frameworks', null),
  // UI
  'bootstrap': ('ui_frameworks', null), 'tailwind': ('ui_frameworks', null),
  'tailwind css': ('ui_frameworks', null), 'tailwindcss': ('ui_frameworks', null),
  'material ui': ('ui_frameworks', null), 'mui': ('ui_frameworks', null),
  'vuetify': ('ui_frameworks', null), 'element ui': ('ui_frameworks', null),
  'chakra ui': ('ui_frameworks', null),
  // テスト
  'pytest': ('testing_frameworks', null), 'jest': ('testing_frameworks', null),
  'vitest': ('testing_frameworks', null), 'junit': ('testing_frameworks', null),
  'phpunit': ('testing_frameworks', null), 'rspec': ('testing_frameworks', null),
  'mocha': ('testing_frameworks', null), 'chai': ('testing_frameworks', null),
  'jasmine': ('testing_frameworks', null), 'karma': ('testing_frameworks', null),
  'testng': ('testing_frameworks', null), 'unittest': ('testing_frameworks', null),
  'xunit': ('testing_frameworks', null), 'nunit': ('testing_frameworks', null),
  'cucumber': ('testing_frameworks', null), 'puppeteer': ('testing_frameworks', null),
  'testing library': ('testing_frameworks', null),
  'react testing library': ('testing_frameworks', null), 'selenium': ('testing_frameworks', null),
  'cypress': ('testing_frameworks', null), 'playwright': ('testing_frameworks', null),
  // クラウド
  'aws': ('cloud_platforms', null), 'amazon web services': ('cloud_platforms', null),
  'azure': ('cloud_platforms', null), 'microsoft azure': ('cloud_platforms', null),
  'gcp': ('cloud_platforms', null), 'google cloud': ('cloud_platforms', null),
  'google cloud platform': ('cloud_platforms', null), 'firebase': ('cloud_platforms', null),
  'heroku': ('cloud_platforms', null),
  'red hat': ('cloud_platforms', null), 'redhat': ('cloud_platforms', null),
  'lambda': ('aws_services', 'AWS'), 's3': ('aws_services', 'AWS'),
  'ec2': ('aws_services', 'AWS'), 'rds': ('aws_services', 'AWS'),
  'dynamodb': ('aws_services', 'AWS'), 'step functions': ('aws_services', 'AWS'),
  'bedrock': ('aws_services', 'AWS'), 'cloudwatch': ('aws_services', 'AWS'),
  'api gateway': ('aws_services', 'AWS'), 'ecs': ('aws_services', 'AWS'),
  'eks': ('aws_services', 'AWS'), 'cloudfront': ('aws_services', 'AWS'),
  'cloud functions': ('gcp_services', 'Google Cloud'),
  'cloud run': ('gcp_services', 'Google Cloud'), 'bigquery': ('gcp_services', 'Google Cloud'),
  // バージョン管理（Skills などに書かれていたら Tools に移す）
  'git': ('tools', null), 'github': ('tools', null), 'gitlab': ('tools', null),
  'bitbucket': ('tools', null), 'svn': ('tools', null), 'subversion': ('tools', null),
  // コンテナ
  'docker': ('container', null), 'podman': ('container', null),
  'docker compose': ('container', null), 'docker-compose': ('container', null),
  'kubernetes': ('container_orchestration', null), 'k8s': ('container_orchestration', null),
  'openshift': ('container_orchestration', null),
  'red hat openshift': ('container_orchestration', null),
  'amazon eks': ('aws_services', 'AWS'), 'gke': ('gcp_services', 'Google Cloud'),
  'aks': ('azure_services', 'Microsoft Azure'),
  // AI
  'chatgpt': ('ai_services', null), 'openai': ('ai_services', null),
  'github copilot': ('ai_services', null), 'copilot': ('ai_services', null),
  'cursor': ('ai_services', null), 'claude': ('ai_services', null),
  'claude code': ('ai_services', null), 'gemini': ('ai_services', null),
};

/// 言語（Tools などに書かれていたら skills に移す）
const List<String> _languages = [
  'Python', 'Java', 'JavaScript', 'TypeScript', 'PHP', 'Ruby', 'Go', 'Golang', 'Rust', 'Kotlin',
  'Swift', 'Objective-C', 'Dart', 'C', 'C++', 'C#', 'Scala', 'Perl', 'R', 'SQL', 'PL/SQL',
  'HTML', 'CSS', 'Sass', 'SCSS', 'Shell', 'Bash', 'PowerShell', 'VBA', 'VB.NET', 'COBOL',
];

/// skillKey → 分類（_known と _languages をまとめたもの）
final Map<String, (String, String?)> _byKey = {
  for (final e in _known.entries) skillKey(e.key): e.value,
  for (final l in _languages) skillKey(l): ('skills', null),
};

/// この名前で始まれば、その分類とみなす（「Mocha Test」「JUnit5」「k8s クラスタ」など、一覧の名前に言葉が付いたもの）
const List<(String, String)> _prefixes = [
  ('kubernetes', 'container_orchestration'), ('k8s', 'container_orchestration'),
  ('openshift', 'container_orchestration'),
  ('mocha', 'testing_frameworks'), ('jest', 'testing_frameworks'), ('pytest', 'testing_frameworks'),
  ('junit', 'testing_frameworks'), ('rspec', 'testing_frameworks'), ('phpunit', 'testing_frameworks'),
  ('vitest', 'testing_frameworks'), ('cypress', 'testing_frameworks'),
  ('playwright', 'testing_frameworks'), ('selenium', 'testing_frameworks'),
  ('jasmine', 'testing_frameworks'), ('karma', 'testing_frameworks'),
  ('bitbucket', 'tools'),
];

/// 技術名の分類（知らない名前は null）
(String, String?)? classifyTech(String name) {
  final key = skillKey(name);
  final hit = _byKey[key];
  if (hit != null) return hit;
  for (final (prefix, category) in _prefixes) {
    if (key.startsWith(prefix)) return (category, null);
  }
  final lower = cleanSkillName(name).toLowerCase();
  if (lower.startsWith('aws ') || lower.startsWith('amazon ')) return ('aws_services', 'AWS');
  if (lower.startsWith('azure ')) return ('azure_services', 'Microsoft Azure');
  if (lower.startsWith('google cloud ') || lower.startsWith('gcp ')) {
    return ('gcp_services', 'Google Cloud');
  }
  return null;
}

/// 振り分け直す元の分類（ここに書かれた知っている名前だけを、本来の分類へ移す）
const List<String> _redistributeFrom = ['skills', 'tools'];

const String _notUsed = '利用なし';

/// 値（リスト・カンマ区切りの文字）を文字のリストにする
List<String> _items(Object? v) {
  if (v is List) return [for (final e in v) '$e'.trim()].where((e) => e.isNotEmpty).toList();
  if (v is String) return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  return [];
}

/// 1 件のプロジェクトの Skills・Tools に書かれた、フロントエンド・バックエンドなどの技術を本来の分類に移す
/// （例：skills の React → frontend_frameworks、tools の Django → backend_frameworks、tools の Python → skills、
///   skills の Lambda → aws_services と cloud_platforms に AWS）
/// - 知らない名前・すでに本来の分類にあるものはそのまま（同じものは 2 つ入れない）
/// - 移した先の「利用なし」は外し、移して空になった分類は「利用なし」にする
/// - 元の Map は変えず、新しい Map を返す
Map<String, dynamic> redistributeProject(Map<String, dynamic> project) {
  final result = Map<String, dynamic>.from(project);
  final moves = <String, List<String>>{}; // 移す先 → 名前

  for (final from in _redistributeFrom) {
    if (!project.containsKey(from)) continue;
    final keep = <String>[];
    for (final item in _items(project[from])) {
      final hit = classifyTech(item);
      if (hit == null || hit.$1 == from) {
        keep.add(item);
        continue;
      }
      (moves[hit.$1] ??= []).add(item);
      if (hit.$2 case final cloud?) (moves['cloud_platforms'] ??= []).add(cloud);
    }
    if (keep.length != _items(project[from]).length) {
      result[from] = keep.isEmpty ? [_notUsed] : keep;
    }
  }

  for (final e in moves.entries) {
    final target = [
      for (final v in _items(result[e.key]))
        if (cleanSkillName(v) != _notUsed) v,
    ];
    for (final v in e.value) {
      final k = skillKey(v, category: e.key);
      if (!target.any((t) => skillKey(t, category: e.key) == k)) target.add(v);
    }
    result[e.key] = target;
  }
  return result;
}

/// プロジェクトの並び全部に redistributeProject をかける
List<Map<String, dynamic>> redistributeProjects(Iterable<Object?> projects) => [
      for (final p in projects)
        if (p is Map) redistributeProject(Map<String, dynamic>.from(p)),
    ];

// ============================================================
// Tools のグループ分け（バージョン管理・開発ツール・環境…）
// 名前から推測する：まずよく知られた名前の一覧、なければ名前に含まれる言葉で見分け、どれでもなければ「その他」
// Skills のグラフ（Tools をグループごとのカテゴリに分ける）と、Projects のフィルター（Tools をグループごとに並べる）で使う
// ============================================================
enum ToolGroup {
  vcs('tools_vcs'),
  devTool('tools_dev'),
  environment('tools_env'),
  ciCd('tools_cicd'),
  projectManagement('tools_pm'),
  design('tools_design'),
  other('tools_other');

  /// Skills のカテゴリのキー（AppTexts.skillCategoryLabels の見出し）
  final String key;
  const ToolGroup(this.key);
}

/// 名前 → グループ（表記ゆれは無視して比べる）
const Map<ToolGroup, List<String>> _toolNames = {
  ToolGroup.ciCd: [
    'GitHub Actions', 'GitLab CI', 'Jenkins', 'CircleCI', 'Travis CI', 'Argo CD', 'CodeBuild',
    'CodePipeline', 'CodeDeploy', 'Bamboo', 'TeamCity', 'Azure Pipelines', 'Cloud Build',
    'Terraform', 'Ansible', 'Chef', 'Puppet', 'CloudFormation', 'SonarQube',
  ],
  ToolGroup.vcs: [
    'Git', 'GitHub', 'GitLab', 'Bitbucket', 'SVN', 'Subversion', 'Mercurial', 'CVS', 'Perforce',
    'SourceTree', 'TortoiseSVN', 'TortoiseGit', 'GitKraken', 'Fork', 'CodeCommit',
  ],
  ToolGroup.devTool: [
    'VS Code', 'Visual Studio Code', 'Visual Studio', 'IntelliJ IDEA', 'IntelliJ', 'Eclipse',
    'Xcode', 'Android Studio', 'PyCharm', 'WebStorm', 'PhpStorm', 'RubyMine', 'GoLand', 'Rider',
    'NetBeans', 'Vim', 'Neovim', 'Emacs', 'Sublime Text', 'Atom', 'Cloud9', 'Jupyter',
    'Jupyter Notebook', 'Postman', 'Swagger', 'Insomnia', 'Tera Term', 'WinSCP', 'PuTTY', 'iTerm2',
    'DBeaver', 'A5:SQL Mk-2', 'A5M2', 'pgAdmin', 'MySQL Workbench', 'SQL Server Management Studio',
    'SSMS', 'Navicat', 'phpMyAdmin', 'サクラエディタ', '秀丸', 'Notepad++', 'npm', 'Yarn', 'pnpm',
    'pip', 'Poetry', 'Maven', 'Gradle', 'Webpack', 'Vite', 'Babel', 'ESLint', 'Prettier',
    'Composer', 'Chrome DevTools', 'Storybook',
  ],
  ToolGroup.environment: [
    'WSL', 'WSL2', 'Vagrant', 'VirtualBox', 'VMware', 'Hyper-V', 'Parallels', 'Homebrew',
    'Anaconda', 'Conda', 'Miniconda', 'venv', 'pyenv', 'nvm', 'nodenv', 'rbenv', 'asdf',
    'Apache', 'Nginx', 'Tomcat', 'IIS', 'JBoss', 'WildFly', 'WebLogic', 'WebSphere', 'GitHub Pages',
    'Netlify', 'XAMPP', 'MAMP', 'LocalStack', 'ngrok',
  ],
  ToolGroup.projectManagement: [
    'Redmine', 'Jira', 'Backlog', 'Confluence', 'Trello', 'Asana', 'Notion', 'Slack', 'Teams',
    'Microsoft Teams', 'Zoom', 'Google Meet', 'Chatwork', 'Discord', 'Google Workspace',
    'Microsoft 365', 'Office', 'Excel', 'Word', 'PowerPoint', 'SharePoint', 'Box', 'Google Drive',
    'Miro', 'Wrike', 'ClickUp', 'Linear', 'esa', 'Kibela', 'Azure DevOps', 'GitHub Projects',
  ],
  ToolGroup.design: [
    'Figma', 'Adobe XD', 'XD', 'Sketch', 'Photoshop', 'Illustrator', 'Canva', 'Zeplin', 'InVision',
    'draw.io', 'Cacoo', 'diagrams.net', 'Adobe Illustrator', 'Adobe Photoshop', 'Balsamiq',
  ],
};

final Map<String, ToolGroup> _toolByKey = {
  for (final e in _toolNames.entries)
    for (final n in e.value) skillKey(n): e.key,
};

/// 名前に含まれる言葉で見分ける（一覧にないとき。上から順に見る）
const List<(ToolGroup, List<String>)> _toolHints = [
  (ToolGroup.ciCd, ['actions', 'cicd', 'pipeline', 'jenkins', 'deploy', 'terraform', 'ansible']),
  (ToolGroup.vcs, ['git', 'svn', 'subversion', 'bitbucket', 'mercurial']),
  (ToolGroup.design, ['figma', 'adobe', 'photoshop', 'illustrator', 'design', 'デザイン', 'draw']),
  (ToolGroup.projectManagement, ['jira', 'slack', 'teams', 'office', 'drive', 'wiki', 'chat', 'チャット', '管理', 'チケット']),
  (ToolGroup.environment, ['wsl', 'vm', 'virtual', 'env', 'server', 'サーバ', 'apache', 'nginx', 'tomcat', 'docker', '環境', 'hosting', 'pages']),
  (ToolGroup.devTool, ['code', 'studio', 'ide', 'idea', 'editor', 'エディタ', 'storm', 'term', 'sql', 'workbench', 'admin', 'shell', 'cli']),
];

/// ツールのグループ（推測。わからなければ「その他」）
ToolGroup toolGroupOf(String name) {
  final key = skillKey(name);
  final hit = _toolByKey[key];
  if (hit != null) return hit;
  for (final (group, words) in _toolHints) {
    if (words.any((w) => key.contains(w))) return group;
  }
  return ToolGroup.other;
}

/// プロジェクトの並びから、Tools をグループごとに分けた「仮のプロジェクト」を作る（Skills の集計用）
/// 例：{'tools_vcs': [Git, GitHub], 'tools_dev': [VS Code], …}
List<Map<String, dynamic>> splitToolGroups(Iterable<Map<String, dynamic>> projects) => [
      for (final p in projects)
        {
          for (final g in ToolGroup.values)
            g.key: [
              for (final t in _items(p['tools']))
                if (cleanSkillName(t) != _notUsed && toolGroupOf(t) == g) t,
            ],
        },
    ];

// ============================================================
// Skills のグループ分け（プログラミング言語・マークアップ / スタイルシート・データ形式 / クエリ・
// アーキテクチャ / 設計・ライブラリ…）。Tools と同じく名前から推測する
// ============================================================
enum SkillGroup {
  language('skills_lang'),
  markup('skills_markup'),
  data('skills_data'),
  architecture('skills_arch'),
  library('skills_lib'),
  other('skills_other');

  /// Skills のカテゴリのキー（AppTexts.skillCategoryLabels の見出し）
  final String key;
  const SkillGroup(this.key);
}

const Map<SkillGroup, List<String>> _skillNames = {
  SkillGroup.language: [
    'Python', 'Java', 'JavaScript', 'TypeScript', 'PHP', 'Ruby', 'Go', 'Golang', 'Rust', 'Kotlin',
    'Swift', 'Objective-C', 'Dart', 'C', 'C++', 'C#', 'Scala', 'Perl', 'R', 'Shell', 'Shell Script',
    'Bash', 'PowerShell', 'VBA', 'VB.NET', 'Visual Basic', 'COBOL', 'RPG', 'Lua', 'Elixir', 'Erlang',
    'Haskell', 'Clojure', 'F#', 'Groovy', 'Assembly', 'MATLAB', 'Fortran', 'Julia', 'Solidity', 'Zig',
    'ECMAScript', 'Apex', 'ABAP', 'Delphi', 'Pascal',
  ],
  SkillGroup.markup: [
    'HTML', 'HTML5', 'CSS', 'CSS3', 'Sass', 'SCSS', 'Less', 'Stylus', 'PostCSS', 'Pug', 'EJS',
    'Handlebars', 'JSX', 'TSX', 'XAML', 'XHTML', 'Thymeleaf', 'Jinja2', 'Blade', 'Smarty',
  ],
  SkillGroup.data: [
    'SQL', 'PL/SQL', 'T-SQL', 'PL/pgSQL', 'GraphQL', 'YAML', 'JSON', 'XML', 'Markdown', 'CSV',
    'TOML', 'Protocol Buffers', 'protobuf', 'JSON Schema', 'OpenAPI', '正規表現', 'Regex',
  ],
  SkillGroup.architecture: [
    'REST', 'REST API', 'RESTful API', 'gRPC', 'MVC', 'MVVM', 'MVP', 'Clean Architecture',
    'クリーンアーキテクチャ', 'DDD', 'ドメイン駆動設計', 'マイクロサービス', 'Microservices',
    'サーバーレス', 'Serverless', 'SPA', 'SSR', 'SSG', 'PWA', 'イベント駆動', 'オブジェクト指向',
    'OOP', '関数型プログラミング', 'TDD', 'BDD', 'CQRS', 'WebSocket', 'OAuth', 'OAuth 2.0',
    'JWT', 'レスポンシブデザイン', 'Responsive Design', 'モノレポ', 'Monorepo', 'API 設計',
    'オニオンアーキテクチャ', 'Onion Architecture', 'オニオンモデル', 'Onion Model',
    'ヘキサゴナルアーキテクチャ', 'Hexagonal Architecture', 'レイヤードアーキテクチャ', 'Layered Architecture',
  ],
  SkillGroup.library: [
    'pandas', 'NumPy', 'SciPy', 'scikit-learn', 'TensorFlow', 'PyTorch', 'Keras', 'Matplotlib',
    'seaborn', 'OpenCV', 'Requests', 'BeautifulSoup', 'Beautiful Soup', 'Redux', 'Zustand', 'Axios',
    'Lodash', 'Moment.js', 'Day.js', 'Three.js', 'D3.js', 'Chart.js', 'fl_chart', 'Riverpod',
    'Provider', 'Bloc', 'GetX', 'Dio', 'RxJS', 'Prisma', 'TypeORM', 'Sequelize', 'SQLAlchemy',
    'Hibernate', 'MyBatis', 'Pydantic', 'LangChain', 'LlamaIndex', 'Boto3', 'Celery', 'Socket.IO',
    'Hugging Face Transformers', 'Transformers', 'jQuery UI', 'Swiper', 'React Query',
    'TanStack Query', 'SWR', 'Zod', 'Yup', 'Formik', 'React Hook Form',
  ],
};

final Map<String, SkillGroup> _skillByKey = {
  for (final e in _skillNames.entries)
    for (final n in e.value) skillKey(n): e.key,
};

/// 言語の名前＋版（python3 / java8 / php7.4 / es2015 など）
final _languageWithVersion = RegExp(
  r'^(python|java|javascript|typescript|php|ruby|perl|swift|kotlin|scala|dart|go|rust|c\+\+|c#|c|es|ecmascript|vb|lua)\d+$',
);

/// 名前に含まれる言葉で見分ける（一覧にないとき。上から順に見る）
const List<(SkillGroup, List<String>)> _skillHints = [
  (SkillGroup.markup, ['html', 'css', 'scss', 'sass']),
  (SkillGroup.data, ['sql', 'json', 'yaml', 'xml', 'graphql']),
  (SkillGroup.architecture, ['api', 'architecture', 'アーキテクチャ', '設計', '駆動', '指向', 'pattern', 'パターン', 'micro', 'serverless', 'サーバーレス', 'onion', 'オニオン', 'hexagonal', 'ヘキサゴナル', 'layered', 'レイヤード']),
  (SkillGroup.library, ['lib', 'ライブラリ', 'sdk', 'package', 'パッケージ', 'plugin', 'プラグイン']),
];

/// スキルのグループ（推測。わからなければ「その他」）
/// 小文字の「_」「-」区切りの名前（fl_chart / url_launcher / file_picker など）や「○○.js」はライブラリとみなす
SkillGroup skillGroupOf(String name) {
  final key = skillKey(name);
  final hit = _skillByKey[key];
  if (hit != null) return hit;
  if (_languageWithVersion.hasMatch(key)) return SkillGroup.language;
  for (final (group, words) in _skillHints) {
    if (words.any((w) => key.contains(w))) return group;
  }
  final clean = cleanSkillName(name);
  final packageLike = clean == clean.toLowerCase() && RegExp(r'^[a-z0-9]+([_-][a-z0-9]+)+$').hasMatch(clean);
  if (packageLike || key.endsWith('js')) return SkillGroup.library;
  return SkillGroup.other;
}

/// プロジェクトの並びから、Skills をグループごとに分けた「仮のプロジェクト」を作る（Skills の集計用）
List<Map<String, dynamic>> splitSkillGroups(Iterable<Map<String, dynamic>> projects) => [
      for (final p in projects)
        {
          for (final g in SkillGroup.values)
            g.key: [
              for (final s in _items(p['skills']))
                if (cleanSkillName(s) != _notUsed && skillGroupOf(s) == g) s,
            ],
        },
    ];
