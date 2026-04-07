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

  factory Project.fromMap(Map<String, dynamic> map) => Project.fromJson(map);
}