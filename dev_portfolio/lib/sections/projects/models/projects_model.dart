class Project {
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

  factory Project.fromMap(Map<String, dynamic> json) {
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

  // =========================
  // FILTER GETTERS（UI/Filter用）
  // =========================
  List<String> get skillsList => _split(skills);
  List<String> get serverOSList => _split(serverOS);
  List<String> get dbList => _split(db);

  List<String> get toolsList => _split(tools);

  List<String> get backendList => _split(backendFrameworks);
  List<String> get frontendList => _split(frontendFrameworks);
  List<String> get uiList => _split(uiFrameworks);
  List<String> get testingList => _split(testingFrameworks);

  List<String> get cloudList => _split(cloudPlatforms);
  List<String> get awsList => _split(awsServices);
  List<String> get azureList => _split(azureServices);
  List<String> get gcpList => _split(gcpServices);

  List<String> get containerList => _split(container);
  List<String> get orchestrationList => _split(containerOrchestration);
  List<String> get aiList => _split(aiServices);

  List<String> get workflowList =>
      workflow.entries.where((e) => e.value).map((e) => e.key).toList();

  // =========================
  // PERIOD SORT FIX
  // =========================
  DateTime get periodStart {
    try {
      final start = period.split('~').first.trim();
      final parts = start.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return DateTime(1970, 1);
    }
  }

  DateTime get periodEnd {
    try {
      final end = period.split('~').last.trim();

      if (end.contains('現在') || end.toLowerCase().contains('present')) {
        return DateTime.now();
      }

      final parts = end.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get isOngoing =>
      period.contains('現在') || period.toLowerCase().contains('present');
}