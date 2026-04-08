class Project {
  final String title;
  final String description;
  final String details;
  final String serverOS;
  final String db;
  final String toolsFW;
  final String skills;
  final Map<String, bool> workflow; // 🔽 ここがポイント
  final String period;
  final String link;

  Project({
    required this.title,
    required this.description,
    required this.details,
    required this.serverOS,
    required this.db,
    required this.toolsFW,
    required this.skills,
    required this.workflow,
    required this.period,
    required this.link,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        details: json['details'] ?? '',
        serverOS: json['server_os'] ?? '',
        db: json['db'] ?? '',
        toolsFW: json['tools_fw'] ?? '',
        skills: json['skills'] ?? '',
        workflow: Map<String, bool>.from(json['workflow'] ?? {}), // 🔽 重要
        period: json['period'] ?? '',
        link: json['link'] ?? '',
      );

  // =========================
  // 🔽 フィルター用
  // =========================

  List<String> _split(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> get skillsList => _split(skills);
  List<String> get serverOSList => _split(serverOS);
  List<String> get dbList => _split(db);
  List<String> get toolsFWList => _split(toolsFW);

  /// 🔽 true の workflow だけ返す
  List<String> get workflowList {
    return workflow.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();
  }

  // =========================
  // period系（そのまま）
  // =========================

  DateTime get periodStart {
    try {
      final startString = period.split('~').first.trim();
      final parts = startString.split('-');
      if (parts.length != 2) return DateTime(1970, 1);
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return DateTime(1970, 1);
    }
  }

  DateTime get periodEnd {
    try {
      final endString = period.split('~').last.trim();
      if (endString.contains('現在') ||
          endString.toLowerCase().contains('present')) {
        return DateTime.now();
      }
      final parts = endString.split('-');
      if (parts.length != 2) return DateTime.now();
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return DateTime.now();
    }
  }

  factory Project.fromMap(Map<String, dynamic> map) =>
      Project.fromJson(map);
}