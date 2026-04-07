import 'models/projects_model.dart';

typedef ValueGetterFunc = String Function(Project project);

/// モーダル表示用のフィールド定義
class ProjectModalField {
  final String label; // ラベル
  final ValueGetterFunc valueGetter; // Project から値を取り出す関数
  final bool isBold; // 値を太字で表示するか
  final double fontSize; // フォントサイズ

  ProjectModalField({
    required this.label,
    required this.valueGetter,
    this.isBold = false,
    this.fontSize = 14,
  });
}

/// モーダル内で表示するフィールド一覧
class ProjectModalFormat {
  static final List<ProjectModalField> fields = [
    ProjectModalField(label: 'タイトル', valueGetter: (p) => p.title, isBold: true),
    ProjectModalField(label: '説明', valueGetter: (p) => p.description),
    ProjectModalField(label: '詳細', valueGetter: (p) => p.details),
    ProjectModalField(label: 'サーバーOS', valueGetter: (p) => p.serverOS),
    ProjectModalField(label: 'DB', valueGetter: (p) => p.db),
    ProjectModalField(label: 'ツール/フレームワーク', valueGetter: (p) => p.toolsFW),
    ProjectModalField(label: 'スキル', valueGetter: (p) => p.skills),
    ProjectModalField(label: '期間', valueGetter: (p) => p.period),
  ];
}