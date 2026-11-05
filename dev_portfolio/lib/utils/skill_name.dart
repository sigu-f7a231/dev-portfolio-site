// lib/utils/skill_name.dart
//
// 技術名の表記ゆれをそろえる（Skills の集計・Projects のフィルターで使う）
// - 全角の英数字・記号は半角に（Ｐｙｔｈｏｎ３ → Python3）
// - 前後の余分な記号を外す（「mac.」「mac/」「Git;」「Docker：」→ mac / Git / Docker）
// - 同じものとみなすかは、大文字・小文字と区切り（空白・_・-・.）を無視して比べる
//   （MAC / mac / Mac、PYTHON3 / Python３、github_actions / GitHubActions / GitHub Actions は同じ）
//   数字は区別する（Python と Python3 は別）
// - クラウドのサービス（aws_services など）は、先頭の「AWS」「Amazon」「Azure」「GCP」なども無視する
//   （AWS Lambda / Lambda、Amazon S3 / S3 は同じ。表示は先頭を外した名前）
// - 表示する名前：よく知られた名前は正式な書き方（_officialNames）。
//   それ以外は、大文字と小文字が混ざった書き方を優先し、次に多く使われている書き方（同数なら先に出てきたもの）。
//   小文字だけなら単語の頭を大文字に、「_」は空白にする（my_tool → My Tool）
//
// Flutter に依存しない。

/// 前後から外す記号（「.」は .NET のように先頭に来るものがあるので、末尾だけ外す）
const String _edgeMarks = ' \t\n;:；：,，、。/／\\|・-－_';
const String _trailingOnlyMarks = '.．';

/// 先頭の会社名・クラウド名を外して比べる分類 → 外す接頭辞（長いものから）
const Map<String, List<String>> _vendorPrefixes = {
  'aws_services': ['Amazon Web Services', 'AWS', 'Amazon'],
  'azure_services': ['Microsoft Azure', 'Azure', 'Microsoft'],
  'gcp_services': ['Google Cloud Platform', 'Google Cloud', 'GCP', 'Google'],
};

/// 全角の英数字・記号（！〜～）を半角に、全角の空白を半角の空白にする
String toHalfWidth(String s) {
  final buffer = StringBuffer();
  for (final code in s.runes) {
    if (code >= 0xFF01 && code <= 0xFF5E) {
      buffer.writeCharCode(code - 0xFEE0);
    } else if (code == 0x3000) {
      buffer.write(' ');
    } else {
      buffer.writeCharCode(code);
    }
  }
  return buffer.toString();
}

/// 表示用にきれいにした名前（半角にし、前後の余分な記号と連続する空白を除く）
String cleanSkillName(String raw) {
  final s = toHalfWidth(raw).replaceAll(RegExp(r'\s+'), ' ');
  var start = 0;
  var end = s.length;
  while (start < end && _edgeMarks.contains(s[start])) {
    start++;
  }
  while (end > start &&
      (_edgeMarks.contains(s[end - 1]) || _trailingOnlyMarks.contains(s[end - 1]))) {
    end--;
  }
  return s.substring(start, end);
}

/// [category] がクラウドのサービスなら、先頭の「AWS」「Amazon」などを外す（外すと空になるときはそのまま）
String withoutVendorPrefix(String name, String? category) {
  final prefixes = _vendorPrefixes[category];
  if (prefixes == null) return name;
  var s = name;
  var changed = true;
  while (changed) {
    changed = false;
    for (final p in prefixes) {
      final m = RegExp('^${RegExp.escape(p)}[\\s_\\-:：]+', caseSensitive: false).firstMatch(s);
      if (m != null && m.end < s.length) {
        s = s.substring(m.end);
        changed = true;
        break;
      }
    }
  }
  return s;
}

/// 同じものかを比べるためのキー（きれいにしたうえで小文字にし、空白・_・-・. を除く）
/// [category] がクラウドのサービスなら、先頭の「AWS」なども除く
String skillKey(String raw, {String? category}) =>
    withoutVendorPrefix(cleanSkillName(raw), category)
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-.]'), '');

/// よく知られた技術の正式な書き方（キーが同じなら、この書き方で表示する）
const List<String> _officialNames = [
  // 言語
  'Python', 'PHP', 'Java', 'JavaScript', 'TypeScript', 'Ruby', 'Go', 'Rust', 'Kotlin', 'Swift',
  'Objective-C', 'C', 'C++', 'C#', 'Dart', 'SQL', 'PL/SQL', 'HTML', 'CSS', 'Sass', 'SCSS',
  'Shell', 'Bash', 'PowerShell', 'Perl', 'Scala', 'R', 'VBA', 'VB.NET', 'COBOL', 'RPG',
  'YAML', 'JSON', 'XML', 'Markdown',
  // OS
  'Windows', 'Windows Server', 'Linux', 'macOS', 'Mac', 'Ubuntu', 'CentOS', 'Debian',
  'Red Hat', 'RHEL', 'Amazon Linux', 'Unix', 'iOS', 'Android',
  // DB
  'MySQL', 'PostgreSQL', 'Oracle', 'SQL Server', 'SQLite', 'MariaDB', 'MongoDB', 'Redis',
  'DynamoDB', 'DB2', 'Firestore', 'Elasticsearch',
  // ツール
  'Git', 'GitHub', 'GitLab', 'Bitbucket', 'SVN', 'Redmine', 'Jira', 'Backlog', 'Confluence',
  'Slack', 'Teams', 'Notion', 'Jenkins', 'GitHub Actions', 'CircleCI', 'Terraform', 'Ansible',
  'VS Code', 'Visual Studio', 'IntelliJ IDEA', 'Eclipse', 'Xcode', 'Android Studio', 'Cloud9',
  'Tera Term', 'WinSCP', 'Postman', 'Swagger', 'Figma', 'Adobe XD', 'Excel', 'Apache', 'Nginx',
  'Tomcat', 'Vagrant', 'Webpack', 'Vite', 'npm', 'Yarn',
  // フレームワーク
  'Django', 'Flask', 'FastAPI', 'Streamlit', 'Laravel', 'CodeIgniter', 'CakePHP', 'Symfony',
  'Phalcon', 'Ruby on Rails', 'Spring', 'Spring Boot', 'Struts', 'Express', 'NestJS', 'Node.js',
  '.NET', 'ASP.NET', 'React', 'Next.js', 'Vue.js', 'Nuxt.js', 'Angular', 'Svelte', 'jQuery',
  'Flutter', 'React Native', 'Bootstrap', 'Tailwind CSS', 'Material UI', 'Vuetify',
  'pytest', 'Jest', 'Vitest', 'JUnit', 'PHPUnit', 'RSpec', 'Mocha', 'Selenium', 'Cypress',
  'Playwright',
  // クラウド・コンテナ
  'AWS', 'Microsoft Azure', 'Google Cloud', 'Firebase', 'Heroku', 'Vercel', 'GitHub Pages',
  'Lambda', 'S3', 'EC2', 'RDS', 'ECS', 'EKS', 'ECR', 'CloudFront', 'CloudWatch', 'API Gateway',
  'Step Functions', 'Bedrock', 'SQS', 'SNS', 'IAM', 'Cognito', 'Cloud Run', 'Cloud Functions',
  'BigQuery', 'Functions', 'App Service',
  'Docker', 'Docker Compose', 'Podman', 'Kubernetes', 'OpenShift',
  // AI
  'ChatGPT', 'OpenAI', 'GitHub Copilot', 'Copilot', 'Cursor', 'Claude', 'Claude Code', 'Gemini',
];

final Map<String, String> _officialByKey = {for (final n in _officialNames) skillKey(n): n};

/// 名前の並びから、キー → 表示する名前
/// [category] がクラウドのサービスなら、先頭の「AWS」などを外してまとめ、外した名前で表示する
Map<String, String> canonicalSkillNames(Iterable<String> names, {String? category}) {
  final counts = <String, Map<String, int>>{}; // キー → 書き方 → 回数（挿入順を保つ）
  for (final raw in names) {
    final name = withoutVendorPrefix(cleanSkillName(raw), category);
    if (name.isEmpty) continue;
    final forms = counts.putIfAbsent(skillKey(name), () => {});
    forms[name] = (forms[name] ?? 0) + 1;
  }
  return {
    for (final e in counts.entries) e.key: _officialByKey[e.key] ?? _bestForm(e.value),
  };
}

/// 書き方の良さ：大文字と小文字が混ざっていて「_」がない ＞「_」がない ＞ そのほか
int _formScore(String s) {
  if (s.contains('_')) return 0;
  final hasUpper = s != s.toLowerCase();
  final hasLower = s != s.toUpperCase();
  return hasUpper && hasLower ? 2 : 1;
}

String _bestForm(Map<String, int> forms) {
  var best = forms.entries.first;
  for (final e in forms.entries.skip(1)) {
    final byScore = _formScore(e.key).compareTo(_formScore(best.key));
    if (byScore > 0 || (byScore == 0 && e.value > best.value)) best = e;
  }
  return _prettify(best.key);
}

/// 「_」は空白に。小文字だけなら単語の頭を大文字にする（my_tool → My Tool、python3 → Python3）
String _prettify(String s) {
  final spaced = s.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (spaced != spaced.toLowerCase()) return spaced;
  return spaced
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// 表記ゆれをまとめた一覧（出てきた順。「利用なし」などの除外は呼び出し側で）
List<String> uniqueSkillNames(Iterable<String> names, {String? category}) =>
    canonicalSkillNames(names, category: category).values.toList();
