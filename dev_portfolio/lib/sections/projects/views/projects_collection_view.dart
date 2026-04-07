// lib/sections/projects/views/project_collection_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_collection_config.dart';

// 🔽 追加（Listと同じ）
import '../../../utils/string_utils.dart';
import '../../config/projects/projects_views_list_config.dart';

class ProjectCollectionView extends StatelessWidget {
  final List<Project> projects;
  final bool isDark;

  final void Function(Project) onProjectTap;

  const ProjectCollectionView({
    super.key,
    required this.projects,
    required this.isDark,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: ProjectsCollectionConfig.padding,
      gridDelegate: ProjectsCollectionConfig.gridDelegate,
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];

        return GestureDetector(
          onTap: () => onProjectTap(p),
          child: Card(
            color: ProjectsCollectionConfig.cardColor(isDark),
            child: Padding(
              padding: ProjectsCollectionConfig.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    p.title,
                    style: ProjectsCollectionConfig.titleStyle(isDark),
                  ),

                  ProjectsCollectionConfig.verticalSpacingSmall,

                  // 説明
                  Text(
                    p.description,
                    style: ProjectsCollectionConfig.descriptionStyle(isDark),
                  ),

                  ProjectsCollectionConfig.verticalSpacingSmall,

                  // 期間
                  Text(
                    'Period: ${p.period}',
                    style: ProjectsCollectionConfig.periodStyle(isDark),
                  ),

                  ProjectsCollectionConfig.verticalSpacingSmall,

                  // =========================
                  // 🔽 ここ追加：スキル表示
                  // =========================
                  if (p.skills.isNotEmpty)
                    Wrap(
                      spacing: ProjectsListConfig.skillButtonSpacing,
                      runSpacing: ProjectsListConfig.skillButtonRunSpacing,
                      children: splitSkills(p.skills).map((skill) {
                        return Container(
                          padding: ProjectsListConfig.skillButtonPadding,
                          decoration: BoxDecoration(
                            color: ProjectsListConfig.skillButtonColor(isDark),
                            borderRadius: BorderRadius.circular(
                              ProjectsListConfig.skillButtonBorderRadius,
                            ),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              color: ProjectsListConfig.skillButtonTextColor(isDark),
                              fontSize: ProjectsListConfig.skillButtonFontSize,
                              fontWeight: ProjectsListConfig.skillButtonFontWeight,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const Spacer(),

                  // 詳細ボタン
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => onProjectTap(p),
                      child: const Text('詳細を見る'),
                    ),
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