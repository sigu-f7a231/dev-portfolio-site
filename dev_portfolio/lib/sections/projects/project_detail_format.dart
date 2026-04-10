import 'models/projects_model.dart';

class ProjectDetailFormat {
  static List<ProjectField> fields({bool showWorkflow = false}) {
    final baseFields = [
      ProjectField(label: 'Title', valueGetter: (p) => p.title, isBold: true, fontSize: 20),
      ProjectField(label: 'Details', valueGetter: (p) => p.details),
      ProjectField(label: 'Server OS', valueGetter: (p) => p.serverOS),
      ProjectField(label: 'DB', valueGetter: (p) => p.db),
      ProjectField(label: 'Tools', valueGetter: (p) => p.tools),

      // ★ 拡張フィールド
      ProjectField(label: 'Backend', valueGetter: (p) => p.backendFrameworks),
      ProjectField(label: 'Frontend', valueGetter: (p) => p.frontendFrameworks),
      ProjectField(label: 'UI', valueGetter: (p) => p.uiFrameworks),
      ProjectField(label: 'Testing', valueGetter: (p) => p.testingFrameworks),

      ProjectField(label: 'Cloud', valueGetter: (p) => p.cloudPlatforms),
      ProjectField(label: 'AWS', valueGetter: (p) => p.awsServices),
      ProjectField(label: 'Azure', valueGetter: (p) => p.azureServices),
      ProjectField(label: 'GCP', valueGetter: (p) => p.gcpServices),

      ProjectField(label: 'Container', valueGetter: (p) => p.container),
      ProjectField(label: 'Orchestration', valueGetter: (p) => p.containerOrchestration),
      ProjectField(label: 'AI', valueGetter: (p) => p.aiServices),

      ProjectField(label: 'Skills', valueGetter: (p) => p.skills),
      ProjectField(label: 'Period', valueGetter: (p) => p.period),
    ];

    if (showWorkflow) {
      baseFields.add(
        ProjectField(
          label: 'Workflow',
          valueGetter: (p) =>
              p.workflow.entries.map((e) => '${e.key}:${e.value}').join(', '),
        ),
      );
    }

    return baseFields;
  }
}

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