// lib/sections/projects/project_model.dart
class Project {
  final String title;
  final String description; // 簡易説明
  final String details;     // 展開用詳細説明
  final String serverOS;
  final String db;
  final String toolsFW;
  final String skills;
  final String period;

  Project({
    required this.title,
    required this.description,
    required this.details,
    required this.serverOS,
    required this.db,
    required this.toolsFW,
    required this.skills,
    required this.period,
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
      );

  factory Project.fromMap(Map<String, dynamic> map) => Project.fromJson(map);
}