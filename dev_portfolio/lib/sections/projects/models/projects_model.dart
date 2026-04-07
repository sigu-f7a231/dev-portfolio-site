// lib/sections/projects/models/projects_model.dart
class Project {
  final String title;
  final String description;
  final String details;
  final String serverOS;
  final String db;
  final String toolsFW;
  final String skills;
  final String period;
  final String link; // ← 追加

  Project({
    required this.title,
    required this.description,
    required this.details,
    required this.serverOS,
    required this.db,
    required this.toolsFW,
    required this.skills,
    required this.period,
    required this.link, // ← 追加
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        details: json['details'] ?? '',
        serverOS: json['server_os'] ?? '',
        db: json['db'] ?? '',
        toolsFW: json['tools_fw'] ?? '',
        skills: json['skills'] ?? '',
        period: json['period'] ?? '',
        link: json['link'] ?? '', // ← 追加
      );

     /// periodの開始日をDateTimeとして取得
  DateTime get periodStart {
    try {
      final startString = period.split('~').first.trim();
      final parts = startString.split('-');
      if (parts.length != 2) return DateTime(1970, 1);
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return DateTime(year, month);
    } catch (_) {
      return DateTime(1970, 1);
    }
  }

  /// periodの終了日をDateTimeとして取得（現在進行中ならDateTime.now()）
  DateTime get periodEnd {
    try {
      final endString = period.split('~').last.trim();
      if (endString.contains('現在') || endString.toLowerCase().contains('present')) {
        return DateTime.now();
      }
      final parts = endString.split('-');
      if (parts.length != 2) return DateTime.now();
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return DateTime(year, month);
    } catch (_) {
      return DateTime.now();
    }
  }


  factory Project.fromMap(Map<String, dynamic> map) => Project.fromJson(map);
}