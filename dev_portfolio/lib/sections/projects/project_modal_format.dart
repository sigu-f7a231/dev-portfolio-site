import 'models/projects_model.dart';
import '../../utils/language_utils.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';

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
    this.fontSize = AppSizes.modalFieldFontSize,
  });
}

class ProjectModalFormat {
  static List<ProjectModalField> fields({bool showWorkflow = false}) {
    final baseFields = [
      // =========================
      // BASIC
      // =========================
      ProjectModalField(
        label: AppTexts.fieldTitle,
        valueGetter: (p) => '\n${p.title}',
        isBold: true,
        fontSize: AppSizes.modalTitleFontSize,
      ),
      ProjectModalField(
        label: AppTexts.fieldDescription,
        valueGetter: (p) => '\n${p.description}',
      ),
      ProjectModalField(
        label: AppTexts.fieldDetails,
        valueGetter: (p) => '\n${p.details}',
      ),

      // =========================
      // CORE INFRA
      // =========================
      ProjectModalField(
        label: AppTexts.fieldServerOS,
        valueGetter: (p) => '\n${p.serverOS}',
      ),
      ProjectModalField(
        label: AppTexts.fieldDb,
        valueGetter: (p) => '\n${p.db}',
      ),

      // =========================
      // FRAMEWORKS / TOOLS
      // =========================
      ProjectModalField(
        label: AppTexts.fieldTools,
        valueGetter: (p) => '\n${p.tools}',
      ),
      ProjectModalField(
        label: AppTexts.fieldBackend,
        valueGetter: (p) => '\n${p.backendFrameworks}',
      ),
      ProjectModalField(
        label: AppTexts.fieldFrontend,
        valueGetter: (p) => '\n${p.frontendFrameworks}',
      ),
      ProjectModalField(
        label: AppTexts.fieldUi,
        valueGetter: (p) => '\n${p.uiFrameworks}',
      ),
      ProjectModalField(
        label: AppTexts.fieldTesting,
        valueGetter: (p) => '\n${p.testingFrameworks}',
      ),

      // =========================
      // CLOUD / PLATFORM
      // =========================
      ProjectModalField(
        label: AppTexts.fieldCloud,
        valueGetter: (p) => '\n${p.cloudPlatforms}',
      ),
      ProjectModalField(
        label: AppTexts.fieldAws,
        valueGetter: (p) => '\n${p.awsServices}',
      ),
      ProjectModalField(
        label: AppTexts.fieldAzure,
        valueGetter: (p) => '\n${p.azureServices}',
      ),
      ProjectModalField(
        label: AppTexts.fieldGcp,
        valueGetter: (p) => '\n${p.gcpServices}',
      ),

      // =========================
      // CONTAINER / AI
      // =========================
      ProjectModalField(
        label: AppTexts.fieldContainer,
        valueGetter: (p) => '\n${p.container}',
      ),
      ProjectModalField(
        label: AppTexts.fieldOrchestration,
        valueGetter: (p) => '\n${p.containerOrchestration}',
      ),
      ProjectModalField(
        label: AppTexts.fieldAi,
        valueGetter: (p) => '\n${p.aiServices}',
      ),

      // =========================
      // SKILLS
      // =========================
      ProjectModalField(
        label: AppTexts.fieldSkills,
        valueGetter: (p) => '\n${p.skills}',
      ),

      // =========================
      // PERIOD / LINK
      // =========================
      ProjectModalField(
        label: AppTexts.fieldPeriod,
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
          label: AppTexts.fieldWorkflow,
          valueGetter: (p) {
            final lines = p.workflow.entries.map((e) {
              final ja = LanguageUtils.workflowLabels['ja']?[e.key] ?? e.key;
              return '$ja: ${e.value ? AppTexts.workflowDone : AppTexts.workflowNotDone}';
            }).join('\n');

            return '\n$lines';
          },
        ),
      );
    }

    return baseFields;
  }
}