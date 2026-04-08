import 'models/projects_model.dart';
import '../../utils/language_utils.dart';

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
  /// workflow を表示するかどうかでフィールドを返す
  static List<ProjectModalField> fields({bool showWorkflow = false}) {
    final baseFields = [
      ProjectModalField(label: 'タイトル', valueGetter: (p) => '\n${p.title.split(',').map((s) => s.trim()).join(', ')}', isBold: true),
      ProjectModalField(label: '説明', valueGetter: (p) => '\n${p.description.split(',').map((s) => s.trim()).join(', ')}',),
      ProjectModalField(label: '詳細', valueGetter: (p) => '\n${p.details}'),
      ProjectModalField(label: 'サーバーOS',valueGetter: (p) => '\n${p.serverOS.split(',').map((s) => s.trim()).join(', ')}',),
      ProjectModalField(label: 'DB',valueGetter: (p) => '\n${p.db.split(',').map((s) => s.trim()).join(', ')}',),
      ProjectModalField(label: 'ツール/フレームワーク',valueGetter: (p) => '\n${p.toolsFW.split(',').map((s) => s.trim()).join(', ')}',),
      ProjectModalField(label: 'スキル',valueGetter: (p) => '\n${p.skills.split(',').map((s) => s.trim()).join(', ')}',),
      ProjectModalField(label: '期間', valueGetter: (p) => '\n${p.period.split(',').map((s) => s.trim()).join(', ')}',),
    ];

    if (showWorkflow) {
      baseFields.add(
        ProjectModalField(
          label: 'Workflow',
          valueGetter: (p) {
            final workflowLines = p.workflow.entries.map((e) {
            final jaLabel = LanguageUtils.workflowLabels['ja']?[e.key] ?? e.key;
            return '$jaLabel: ${e.value ? '✅' : '❌'}';
        }).join('\n');
      return '\n$workflowLines'; // interpolation を使って先頭改行
    } 
),
      );
    }

    return baseFields;
  }
}