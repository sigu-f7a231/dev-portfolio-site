// lib/sections/projects/views/project_list/project_list_view.dart
import 'package:flutter/material.dart';
import '../../models/projects_model.dart';
import '../../../config/projects/projects_views_list_config.dart';
import 'project_list_ui.dart';
import 'project_list_sort.dart';

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
        // ローディング中
        if (snapshot.connectionState != ConnectionState.done) {
          return ProjectsListConfig.loading;
        }

        // データなし
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ProjectsListConfig.empty;
        }

        final projects = snapshot.data!;

        // ソート
        projects.sort(sortProjects);

        // UI表示（ProjectListUI 内で直接モーダルを呼ぶ）
        return ProjectListUI(
          projects: projects,
          isDark: isDark,
        );
      },
    );
  }
}