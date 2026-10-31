// lib/sections/projects/views/projects_collection_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_collection_config.dart';
import 'project_card_parts.dart';
import '../../../theme/app_styles.dart';
import '../../../constants/app_sizes.dart';

/// Collection 表示：画面幅に応じて 1〜4 列のグリッド（カードの高さは一定）
class ProjectCollectionView extends StatelessWidget {
  final List<Project> projects;
  final void Function(Project) onProjectTap;

  const ProjectCollectionView({
    super.key,
    required this.projects,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ProjectsCollectionConfig.columnsFor(constraints.maxWidth);

        return GridView.builder(
          padding: ProjectsCollectionConfig.padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: ProjectsCollectionConfig.cardHeight,
            crossAxisSpacing: ProjectsCollectionConfig.gridSpacing,
            mainAxisSpacing: ProjectsCollectionConfig.gridSpacing,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final p = projects[index];

            return Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppStyles.radiusLg),
                onTap: () => onProjectTap(p),
                child: Ink(
                  padding: ProjectsCollectionConfig.cardPadding,
                  decoration: AppStyles.projectCard(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトル＋進行中
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.title,
                              maxLines: ProjectsCollectionConfig.titleMaxLines,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.cardTitle(context),
                            ),
                          ),
                          if (p.isOngoing) ...[
                            const SizedBox(width: AppSizes.space8),
                            const OngoingTag(),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSizes.space8),
                      Expanded(
                        child: Text(
                          p.description,
                          maxLines: ProjectsCollectionConfig.descriptionMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.cardDescription(context),
                        ),
                      ),
                      ProjectPeriod(project: p),
                      if (p.skillsList.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.space10),
                        ProjectSkillTags(
                          project: p,
                          maxTags: ProjectsCollectionConfig.maxTags,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
