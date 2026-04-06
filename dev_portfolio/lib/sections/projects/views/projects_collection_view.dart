// lib/sections/projects/views/project_collection_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../config/projects_views_collection_config.dart';

class ProjectCollectionView extends StatelessWidget {
  final List<Project> projects;
  final bool isDark;

  const ProjectCollectionView({
    super.key,
    required this.projects,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: ProjectsCollectionConfig.padding,
      gridDelegate: ProjectsCollectionConfig.gridDelegate,
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];

        return Card(
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
              ],
            ),
          ),
        );
      },
    );
  }
}