// lib/sections/projects/project_detail_format.dart
import '../projects/models/projects_model.dart';

/// Project モーダル表示用のフィールド定義
class ProjectDetailFormat {
  /// 表示順のリスト
  static List<ProjectField> fields = [
    ProjectField(
      label: 'Title',
      valueGetter: (p) => p.title,
      isBold: true,
      fontSize: 20,
    ),
    ProjectField(
      label: 'Details',
      valueGetter: (p) => p.details,
      isBold: false,
      fontSize: 14,
    ),
    ProjectField(
      label: 'Server OS',
      valueGetter: (p) => p.serverOS,
      isBold: false,
      fontSize: 14,
    ),
    ProjectField(
      label: 'DB',
      valueGetter: (p) => p.db,
      isBold: false,
      fontSize: 14,
    ),
    ProjectField(
      label: 'Tools/Framework',
      valueGetter: (p) => p.toolsFW,
      isBold: false,
      fontSize: 14,
    ),
    ProjectField(
      label: 'Skills',
      valueGetter: (p) => p.skills,
      isBold: false,
      fontSize: 14,
    ),
    ProjectField(
      label: 'Period',
      valueGetter: (p) => p.period,
      isBold: false,
      fontSize: 12,
    ),
  ];
}

/// 1項目の定義
class ProjectField {
  final String label;
  final String Function(Project) valueGetter;
  final bool isBold;
  final double fontSize;

  ProjectField({
    required this.label,
    required this.valueGetter,
    this.isBold = false,
    this.fontSize = 14,
  });
}