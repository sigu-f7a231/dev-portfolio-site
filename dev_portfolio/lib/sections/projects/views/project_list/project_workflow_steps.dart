// lib/sections/projects/views/project_list/project_workflow_steps.dart
//
// 詳細ダイアログの Workflow：工程を左から順に横へ並べる（狭い画面では折り返す）
// - 担当した工程：塗り（secondaryContainer）＋ ✓ アイコン
// - 担当外の工程：枠線だけの控えめな表示
// 工程の順番は LanguageUtils.workflowLabels の並び（要件定義 → … → 保守・運用）。
import 'package:flutter/material.dart';
import 'project_detail_sections.dart';
import '../../models/projects_model.dart';
import '../../../config/projects/projects_views_list_config.dart';
import '../../../../utils/language_utils.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_texts.dart';

class ProjectWorkflowSteps extends StatelessWidget {
  final Project project;

  const ProjectWorkflowSteps({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final labels = LanguageUtils.workflowLabels['ja'] ?? const <String, String>{};
    // 決まった工程順に並べ、YAML に無い工程は出さない（未知のキーは後ろに付ける）
    final keys = [
      ...labels.keys.where(project.workflow.containsKey),
      ...project.workflow.keys.where((k) => !labels.containsKey(k)),
    ];

    return ProjectDetailSection(
      label: AppTexts.fieldWorkflow,
      child: Wrap(
          spacing: ProjectsListConfig.workflowStepSpacing,
          runSpacing: ProjectsListConfig.workflowStepRunSpacing,
          children: keys.map((key) {
            final done = project.workflow[key] ?? false;
            final label = labels[key] ?? key;
            return Semantics(
              label: AppTexts.workflowStepSemantics(label, done),
              excludeSemantics: true,
              child: Container(
                padding: ProjectsListConfig.workflowStepPadding,
                decoration: AppStyles.workflowStep(context, done: done),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: ProjectsListConfig.workflowStepIconSize,
                      color: AppStyles.workflowStepIcon(context, done: done),
                    ),
                    const SizedBox(width: ProjectsListConfig.workflowStepIconGap),
                    Text(label, style: AppStyles.workflowStepText(context, done: done)),
                  ],
                ),
              ),
            );
          }).toList(),
      ),
    );
  }
}
