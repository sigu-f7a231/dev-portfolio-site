// lib/sections/projects/views/project_list/project_list_ui.dart
import 'package:flutter/material.dart';
import '../../models/projects_model.dart';
import '../../../config/projects/projects_views_list_config.dart';
import '../project_card_parts.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';

/// List 表示：1 行 1 プロジェクト。カード全体がタップできる
class ProjectListUI extends StatelessWidget {
  final List<Project> projects;
  final void Function(Project) onProjectTap;

  const ProjectListUI({
    super.key,
    required this.projects,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: projects.length,
      separatorBuilder: (_, __) => ProjectsListConfig.separator,
      itemBuilder: (context, index) {
        final p = projects[index];

        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppStyles.radiusLg),
            onTap: () => onProjectTap(p),
            child: Ink(
              padding: ProjectsListConfig.cardPadding,
              decoration: AppStyles.projectCard(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // タイトル＋進行中
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(p.title, style: AppStyles.cardTitle(context)),
                            ),
                            if (p.isOngoing) ...[
                              const SizedBox(width: AppSizes.space8),
                              const OngoingTag(),
                            ],
                          ],
                        ),
                        if (p.description.isNotEmpty) ...[
                          ProjectsListConfig.smallSpacing,
                          Text(
                            p.description,
                            maxLines: ProjectsListConfig.descriptionMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.cardDescription(context),
                          ),
                        ],
                        ProjectsListConfig.mediumSpacing,
                        ProjectPeriod(project: p),
                        if (p.skillsList.isNotEmpty) ...[
                          ProjectsListConfig.mediumSpacing,
                          // ✅ skillsList = カンマ区切りで分割（空白を含むスキル名も 1 つのタグ）
                          ProjectSkillTags(project: p),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  Icon(
                    Icons.chevron_right,
                    size: ProjectsListConfig.chevronSize,
                    color: context.colors.textTertiary,
                    semanticLabel: AppTexts.viewDetails,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
