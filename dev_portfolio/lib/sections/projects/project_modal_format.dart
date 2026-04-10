import 'models/projects_model.dart';
import '../../utils/language_utils.dart';

typedef ValueGetterFunc = String Function(Project project);

class ProjectModalField {
  final String label;
  final ValueGetterFunc valueGetter;
  final bool isBold;
  final double fontSize;

  ProjectModalField({
    required this.label,
    required this.valueGetter,
    this.isBold = false,
    this.fontSize = 14,
  });
}

class ProjectModalFormat {
  static List<ProjectModalField> fields({bool showWorkflow = false}) {
    final baseFields = [
      // =========================
      // BASIC
      // =========================
      ProjectModalField(
        label: 'タイトル',
        valueGetter: (p) => '\n${p.title}',
        isBold: true,
        fontSize: 18,
      ),
      ProjectModalField(
        label: '説明',
        valueGetter: (p) => '\n${p.description}',
      ),
      ProjectModalField(
        label: '詳細',
        valueGetter: (p) => '\n${p.details}',
      ),

      // =========================
      // CORE INFRA
      // =========================
      ProjectModalField(
        label: 'サーバーOS',
        valueGetter: (p) => '\n${p.serverOS}',
      ),
      ProjectModalField(
        label: 'DB',
        valueGetter: (p) => '\n${p.db}',
      ),

      // =========================
      // FRAMEWORKS / TOOLS
      // =========================
      ProjectModalField(
        label: 'Tools',
        valueGetter: (p) => '\n${p.tools}',
      ),
      ProjectModalField(
        label: 'Backend Frameworks',
        valueGetter: (p) => '\n${p.backendFrameworks}',
      ),
      ProjectModalField(
        label: 'Frontend Frameworks',
        valueGetter: (p) => '\n${p.frontendFrameworks}',
      ),
      ProjectModalField(
        label: 'UI Frameworks',
        valueGetter: (p) => '\n${p.uiFrameworks}',
      ),
      ProjectModalField(
        label: 'Testing Frameworks',
        valueGetter: (p) => '\n${p.testingFrameworks}',
      ),

      // =========================
      // CLOUD / PLATFORM
      // =========================
      ProjectModalField(
        label: 'Cloud Platforms',
        valueGetter: (p) => '\n${p.cloudPlatforms}',
      ),
      ProjectModalField(
        label: 'AWS Services',
        valueGetter: (p) => '\n${p.awsServices}',
      ),
      ProjectModalField(
        label: 'Azure Services',
        valueGetter: (p) => '\n${p.azureServices}',
      ),
      ProjectModalField(
        label: 'GCP Services',
        valueGetter: (p) => '\n${p.gcpServices}',
      ),

      // =========================
      // CONTAINER / AI
      // =========================
      ProjectModalField(
        label: 'Container',
        valueGetter: (p) => '\n${p.container}',
      ),
      ProjectModalField(
        label: 'Container Orchestration',
        valueGetter: (p) => '\n${p.containerOrchestration}',
      ),
      ProjectModalField(
        label: 'AI Services',
        valueGetter: (p) => '\n${p.aiServices}',
      ),

      // =========================
      // SKILLS
      // =========================
      ProjectModalField(
        label: 'Skills',
        valueGetter: (p) => '\n${p.skills}',
      ),

      // =========================
      // PERIOD / LINK
      // =========================
      ProjectModalField(
        label: '期間',
        valueGetter: (p) => '\n${p.period}',
      ),
      // ProjectModalField(
      //   label: 'Link',
      //   valueGetter: (p) => '\n${p.link}',
      // ),
    ];

    // =========================
    // WORKFLOW（optional）
    // =========================
    if (showWorkflow) {
      baseFields.add(
        ProjectModalField(
          label: 'Workflow',
          valueGetter: (p) {
            final lines = p.workflow.entries.map((e) {
              final ja = LanguageUtils.workflowLabels['ja']?[e.key] ?? e.key;
              return '$ja: ${e.value ? "✅" : "❌"}';
            }).join('\n');

            return '\n$lines';
          },
        ),
      );
    }

    return baseFields;
  }
}