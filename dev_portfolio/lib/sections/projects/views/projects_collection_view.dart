// lib/sections/projects/views/projects_collection_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_collection_config.dart';
import 'project_card_parts.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_styles.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_texts.dart';

/// Collection 表示：カバー付きのカードを 1〜4 列のグリッドに並べる（ギャラリー）
/// - 上：プロジェクトごとの色のカバー（頭文字・期間の長さ・進行中）
/// - 下：タイトル・説明・期間・タグ
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
          // スクロールはページ全体で行う（入れ子スクロールにしない）
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: ProjectsCollectionConfig.padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: ProjectsCollectionConfig.cardHeight,
            crossAxisSpacing: ProjectsCollectionConfig.gridSpacing,
            mainAxisSpacing: ProjectsCollectionConfig.gridSpacing,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) => _CollectionCard(
            project: projects[index],
            onTap: () => onProjectTap(projects[index]),
          ),
        );
      },
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _CollectionCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = project;
    final seed = projectColorSeed(p);
    final initial = p.title.trim().isEmpty ? '' : p.title.trim().characters.first.toUpperCase();

    return Material(
      color: context.colors.collectionCardBackground,
      shape: AppStyles.collectionCardShape(context),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // カバー（Ink にして、押したときの波紋がカバーの上にも出るようにする）
            Ink(
              height: ProjectsCollectionConfig.coverHeight,
              padding: ProjectsCollectionConfig.coverPadding,
              decoration: AppStyles.collectionCover(context, seed),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(initial, style: AppStyles.collectionInitial(context, seed)),
                  const Spacer(),
                  if (p.isOngoing) const OngoingTag(),
                  if (p.isOngoing && p.hasValidPeriod)
                    const SizedBox(width: AppSizes.space6),
                  if (p.hasValidPeriod)
                    Container(
                      padding: ProjectsCollectionConfig.coverBadgePadding,
                      decoration: AppStyles.collectionCoverBadge(context),
                      child: Text(
                        AppTexts.durationLabel(p.durationMonths),
                        style: AppStyles.collectionCoverBadgeText(context),
                      ),
                    ),
                ],
              ),
            ),

            // 本文
            Expanded(
              child: Padding(
                padding: ProjectsCollectionConfig.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: ProjectsCollectionConfig.titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.cardTitle(context),
                    ),
                    const SizedBox(height: AppSizes.space6),
                    Expanded(
                      child: Text(
                        p.description,
                        maxLines: ProjectsCollectionConfig.descriptionMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.cardDescription(context),
                      ),
                    ),
                    ProjectPeriod(project: p, showDuration: false),
                    if (p.skillsList.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.space8),
                      ProjectSkillTags(
                        project: p,
                        maxTags: ProjectsCollectionConfig.maxTags,
                        singleLine: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
