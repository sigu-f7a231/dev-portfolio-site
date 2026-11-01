// lib/sections/projects/views/project_list/project_detail_sections.dart
//
// 詳細ダイアログの 1 項目分の部品（見出し＋中身の 2 段）
// - ProjectDetailSection：見出しと中身を縦に並べる
// - ProjectDetailChips：カンマ区切りの値を 1 つずつ枠に入れて横に並べる（狭いときは折り返す）
// - ProjectDetailText：説明・詳細などの文章
// - ProjectDetailPeriod：期間（開始 → 終了・長さ）
// 間隔は Workflow（project_workflow_steps.dart）と同じ値を使い、見た目をそろえる。
import 'package:flutter/material.dart';
import '../../../config/projects/projects_views_list_config.dart';
import '../../../../theme/app_styles.dart';
import '../../models/projects_model.dart';
import '../project_card_parts.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';

class ProjectDetailSection extends StatelessWidget {
  final String label;
  final Widget child;

  const ProjectDetailSection({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ProjectsListConfig.detailSectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.modalLabel(context, AppSizes.modalFieldFontSize)),
          ProjectsListConfig.workflowLabelSpacing,
          child,
        ],
      ),
    );
  }
}

class ProjectDetailChips extends StatelessWidget {
  final List<String> values;

  const ProjectDetailChips({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ProjectsListConfig.workflowStepSpacing,
      runSpacing: ProjectsListConfig.workflowStepRunSpacing,
      children: values
          .map((v) => Container(
                padding: ProjectsListConfig.workflowStepPadding,
                decoration: AppStyles.detailChip(context),
                child: Text(v, style: AppStyles.detailChipText(context)),
              ))
          .toList(),
    );
  }
}

class ProjectDetailText extends StatelessWidget {
  final String text;

  const ProjectDetailText({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Text(text, style: AppStyles.detailText(context));
}

/// 期間：［📅 開始］→［終了 / 現在］・長さ（・進行中）
/// 読み取れない書き方の期間は、文章のまま表示する
class ProjectDetailPeriod extends StatelessWidget {
  final Project project;

  const ProjectDetailPeriod({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (!project.hasValidPeriod) return ProjectDetailText(text: project.period);

    final from = AppTexts.yearMonth(project.periodStart);
    final to = project.isOngoing ? AppTexts.periodNow : AppTexts.yearMonth(project.periodEnd);
    final duration = AppTexts.durationLabel(project.durationMonths);

    Widget box(String text, {IconData? icon}) => Container(
          padding: ProjectsListConfig.workflowStepPadding,
          decoration: AppStyles.detailChip(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: ProjectsListConfig.periodIconSize,
                    color: AppStyles.periodIcon(context)),
                const SizedBox(width: ProjectsListConfig.workflowStepIconGap),
              ],
              Text(text, style: AppStyles.detailChipText(context)),
            ],
          ),
        );

    return Semantics(
      label: AppTexts.periodSemantics(from, to, duration),
      excludeSemantics: true,
      child: Wrap(
        spacing: ProjectsListConfig.workflowStepSpacing,
        runSpacing: ProjectsListConfig.workflowStepRunSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          box(from, icon: Icons.calendar_today_outlined),
          Icon(Icons.arrow_forward,
              size: ProjectsListConfig.periodIconSize, color: AppStyles.periodIcon(context)),
          box(to),
          Text(duration, style: AppStyles.periodDuration(context)),
          if (project.isOngoing) const OngoingTag(),
        ],
      ),
    );
  }
}
