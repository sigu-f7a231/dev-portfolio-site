// lib/sections/projects/views/project_collection_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_collection_config.dart';

class ProjectCollectionView extends StatelessWidget {
  final List<Project> projects;
  final bool isDark;

  // 🔽 追加
  final void Function(Project) onProjectTap;

  const ProjectCollectionView({
    super.key,
    required this.projects,
    required this.isDark,
    required this.onProjectTap, // 🔽 追加
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
          onTap: () => onProjectTap(p), // 🔽 統一
          child: Card(
            color: ProjectsCollectionConfig.cardColor(isDark),
            child: Padding(
              padding: ProjectsCollectionConfig.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: ProjectsCollectionConfig.titleStyle(isDark),
                  ),
                  ProjectsCollectionConfig.verticalSpacingSmall,
                  Text(
                    p.description,
                    style: ProjectsCollectionConfig.descriptionStyle(isDark),
                  ),
                  ProjectsCollectionConfig.verticalSpacingSmall,
                  Text(
                    'Period: ${p.period}',
                    style: ProjectsCollectionConfig.periodStyle(isDark),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => onProjectTap(p), // 🔽 統一
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