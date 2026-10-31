// lib/sections/projects/views/project_card_parts.dart
//
// List / Collection のカードで共通に使う部品
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_list_config.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_styles.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_texts.dart';

/// スキルタグ。maxTags を超えた分は「+N」にまとめる（null なら全部出す）
class ProjectSkillTags extends StatelessWidget {
  final Project project;
  final int? maxTags;

  const ProjectSkillTags({super.key, required this.project, this.maxTags});

  @override
  Widget build(BuildContext context) {
    final skills = project.skillsList;
    if (skills.isEmpty) return const SizedBox.shrink();

    final shown = maxTags == null ? skills : skills.take(maxTags!).toList();
    final rest = skills.length - shown.length;

    Widget tag(String text) => Container(
          padding: AppStyles.skillTagPadding,
          decoration: AppStyles.skillTag(context),
          child: Text(text, style: AppStyles.skillTagText(context)),
        );

    return Wrap(
      spacing: AppStyles.skillTagSpacing,
      runSpacing: AppStyles.skillTagRunSpacing,
      children: [
        ...shown.map(tag),
        if (rest > 0) tag(AppTexts.moreTags(rest)),
      ],
    );
  }
}

/// 「進行中」ラベル
class OngoingTag extends StatelessWidget {
  const OngoingTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppStyles.ongoingTagPadding,
      decoration: AppStyles.ongoingTag(context),
      child: Text(AppTexts.ongoing, style: AppStyles.ongoingTagText(context)),
    );
  }
}

/// 期間（時計アイコン＋期間）
class ProjectPeriod extends StatelessWidget {
  final Project project;

  const ProjectPeriod({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: ProjectsListConfig.scheduleIconSize,
          color: context.colors.textTertiary,
        ),
        const SizedBox(width: AppSizes.space4),
        Text(project.period, style: AppStyles.cardMeta(context)),
      ],
    );
  }
}
