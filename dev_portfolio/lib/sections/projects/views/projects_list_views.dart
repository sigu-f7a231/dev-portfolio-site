// lib/sections/projects/views/project_list.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../config/projects_views_list_config.dart';

class ProjectList extends StatelessWidget {
  final Future<List<Project>> future;
  final bool isDark;

  const ProjectList({
    super.key,
    required this.future,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ProjectsListConfig.loading;
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ProjectsListConfig.empty;
        }

        final projects = snapshot.data!;

        return ListView.separated(
          itemCount: projects.length,
          separatorBuilder: (_, __) => ProjectsListConfig.separator,
          itemBuilder: (context, index) {
            final p = projects[index];

            return Card(
              color: ProjectsListConfig.cardColor(isDark),
              child: ListTile(
                title: Text(
                  p.title,
                  style: ProjectsListConfig.titleStyle(isDark),
                ),
                subtitle: Text(
                  p.description,
                  style: ProjectsListConfig.subtitleStyle(isDark),
                ),
              ),
            );
          },
        );
      },
    );
  }
}