class Project {
  final String title;
  final String description;
  final String details;
  final String serverOS;
  final String db;
  final String toolsFW;
  final String skills;
  final Map<String, bool> workflow;
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

  // =========================
  // 🔽 追加（ここだけ）
  // =========================

  static String _toCsvString(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    } else if (value is String) {
      return value;
    }
    return '';
  }

  static String _toPeriodString(dynamic value) {
    if (value is List && value.length == 2) {
      return '${value[0]} ~ ${value[1]}';
    } else if (value is String) {
      return value;
    }
    return '';
  }

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        details: json['details'] ?? '',
        serverOS: _toCsvString(json['server_os']),
        db: _toCsvString(json['db']),
        toolsFW: _toCsvString(json['tools_fw']),
        skills: _toCsvString(json['skills']),
        workflow: Map<String, bool>.from(json['workflow'] ?? {}),
        period: _toPeriodString(json['period']),
        link: json['link'] ?? '',
      );

  // =========================
  // 🔽 既存そのまま
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

  List<String> get workflowList {
    return workflow.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();
  }

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