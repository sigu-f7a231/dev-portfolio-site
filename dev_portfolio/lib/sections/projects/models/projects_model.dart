import '../../../utils/skill_name.dart';
import '../../../utils/tech_catalog.dart';

class Project {
  /// YAML で「該当なし」を表す値（集計・フィルター候補・詳細表示から除く）
  static const String notUsed = '利用なし';

  // =========================
  // BASIC
  // =========================
  final String title;
  final String description;
  final String details;
  final String period;
  final String link;

  // =========================
  // INFRA
  // =========================
  final String serverOS;
  final String db;

  // =========================
  // TOOLING (統合ビュー用)
  // =========================
  final String tools;

  // =========================
  // FRAMEWORKS
  // =========================
  final String backendFrameworks;
  final String frontendFrameworks;
  final String uiFrameworks;
  final String testingFrameworks;

  // =========================
  // CLOUD
  // =========================
  final String cloudPlatforms;
  final String awsServices;
  final String azureServices;
  final String gcpServices;

  // =========================
  // ADVANCED
  // =========================
  final String container;
  final String containerOrchestration;
  final String aiServices;

  // =========================
  // SKILLS (統合)
  // =========================
  final String skills;

  // =========================
  // WORKFLOW
  // =========================
  final Map<String, bool> workflow;

  Project({
    required this.title,
    required this.description,
    required this.details,
    required this.period,
    required this.link,

    required this.serverOS,
    required this.db,
    required this.tools,

    required this.backendFrameworks,
    required this.frontendFrameworks,
    required this.uiFrameworks,
    required this.testingFrameworks,

    required this.cloudPlatforms,
    required this.awsServices,
    required this.azureServices,
    required this.gcpServices,

    required this.container,
    required this.containerOrchestration,
    required this.aiServices,

    required this.skills,
    required this.workflow,
  });

  // =========================
  // SAFE CONVERTER
  // =========================
  static String _toCsv(dynamic v) {
    if (v == null) return '';
    if (v is List) return v.map((e) => e.toString()).join(', ');
    if (v is String) return v;
    return v.toString();
  }

  static String _toPeriod(dynamic v) {
    if (v is List && v.length == 2) {
      return '${v[0]} ~ ${v[1]}';
    }
    if (v is String) return v;
    return '';
  }

  /// Skills・Tools に書かれたフロントエンド・バックエンドなどの技術は、本来の分類に移してから読む
  /// （lib/utils/tech_catalog.dart の redistributeProject）
  factory Project.fromMap(Map<String, dynamic> raw) {
    final json = redistributeProject(raw);
    return Project(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      details: json['details'] ?? '',
      period: _toPeriod(json['period']),
      link: json['link'] ?? '',

      serverOS: _toCsv(json['server_os']),
      db: _toCsv(json['db']),

      // ★ YAML揺れ完全吸収（tools or tools_fw）
      tools: _toCsv(json['tools'] ?? json['tools_fw']),

      backendFrameworks: _toCsv(json['backend_frameworks']),
      frontendFrameworks: _toCsv(json['frontend_frameworks']),
      uiFrameworks: _toCsv(json['ui_frameworks']),
      testingFrameworks: _toCsv(json['testing_frameworks']),

      cloudPlatforms: _toCsv(json['cloud_platforms']),
      awsServices: _toCsv(json['aws_services']),
      azureServices: _toCsv(json['azure_services']),
      gcpServices: _toCsv(json['gcp_services']),

      container: _toCsv(json['container']),
      containerOrchestration: _toCsv(json['container_orchestration']),
      aiServices: _toCsv(json['ai_services']),

      skills: _toCsv(json['skills']),

      workflow: Map<String, bool>.from(json['workflow'] ?? {}),
    );
  }

  // =========================
  // SPLIT
  // =========================
  List<String> _split(String v) =>
      v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  /// 分けたうえで、同じもの（表記ゆれ・AWS などの先頭の違いを含む）を 1 つにする（lib/utils/skill_name.dart）
  List<String> _unique(String v, [String? category]) =>
      uniqueSkillNames(_split(v), category: category);

  // =========================
  // FILTER GETTERS（UI/Filter用）
  // =========================
  List<String> get skillsList => _unique(skills);
  List<String> get serverOSList => _unique(serverOS);
  List<String> get dbList => _unique(db);

  List<String> get toolsList => _unique(tools);

  List<String> get backendList => _unique(backendFrameworks);
  List<String> get frontendList => _unique(frontendFrameworks);
  List<String> get uiList => _unique(uiFrameworks);
  List<String> get testingList => _unique(testingFrameworks);

  List<String> get cloudList => _unique(cloudPlatforms);
  List<String> get awsList => _unique(awsServices, 'aws_services');
  List<String> get azureList => _unique(azureServices, 'azure_services');
  List<String> get gcpList => _unique(gcpServices, 'gcp_services');

  List<String> get containerList => _unique(container);
  List<String> get orchestrationList => _unique(containerOrchestration);
  List<String> get aiList => _unique(aiServices);

  List<String> get workflowList =>
      workflow.entries.where((e) => e.value).map((e) => e.key).toList();

  // =========================
  // PERIOD SORT FIX
  // =========================
  /// 期間の文字から年月を順に読む（「2020-03 ~ 2020-10」「2020/03 から 2020/１０」「2020年3月〜」など）
  static List<DateTime> _yearMonths(String s) => [
        for (final m in RegExp(r'(\d{4})\s*[-/.年]\s*(\d{1,2})(?!\d)').allMatches(toHalfWidth(s)))
          if (int.parse(m.group(2)!) case final month when month >= 1 && month <= 12)
            DateTime(int.parse(m.group(1)!), month),
      ];

  DateTime get periodStart {
    final ym = _yearMonths(period);
    return ym.isEmpty ? DateTime(1970, 1) : ym.first;
  }

  DateTime get periodEnd {
    if (isOngoing) return DateTime.now();
    final ym = _yearMonths(period);
    // 終わりが書かれていないときは、進行中ではなく開始と同じ月とみなす
    if (ym.length >= 2) return ym[1];
    return ym.isEmpty ? DateTime.now() : ym.first;
  }

  /// 期間が「開始 ~ 終了」（終わりは「現在」/ present も可）の形で、年月として読み取れるか
  bool get hasValidPeriod {
    final ym = _yearMonths(period);
    return ym.isNotEmpty && (isOngoing || ym.length >= 2);
  }

  /// 期間の長さ（月数）。開始月と終了月の両方を含めて数える（例：2023-04〜2023-09 は 6 か月）
  int get durationMonths {
    final s = periodStart, e = periodEnd;
    final months = (e.year * 12 + e.month) - (s.year * 12 + s.month) + 1;
    return months < 1 ? 1 : months;
  }

  bool get isOngoing =>
      period.contains('現在') || period.toLowerCase().contains('present');
}