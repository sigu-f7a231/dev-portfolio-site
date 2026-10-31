// lib/sections/projects/views/project_list/project_list_view.dart
import 'package:flutter/material.dart';
import '../../models/projects_model.dart';
import '../../../config/projects/projects_views_list_config.dart';
import 'project_list_ui.dart';
import 'project_list_sort.dart';
import '../../pagination/projects_pagination_logic.dart';
import '../../pagination/projects_pagination_ui.dart';
import 'project_list_modal_function.dart';

class ProjectList extends StatefulWidget {
  final Future<List<Project>> future;

  const ProjectList({super.key, required this.future});

  @override
  State<ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  int currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ProjectsListConfig.loading;
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ProjectsListConfig.empty;
        }

        final projects = snapshot.data!;
        projects.sort(sortProjects);

        final totalPages = ProjectsPaginationLogic.getTotalPages(projects);
        final paginatedProjects =
            ProjectsPaginationLogic.getPaginatedProjects(projects, currentPage);

        return Column(
          children: [
            Expanded(
              child: ProjectListUI(
                projects: paginatedProjects,
                onProjectTap: (project) {
                  showProjectDetailModal(
                    context,
                    project,
                  );
                },
              ),
            ),
            ProjectsPaginationUI(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageChanged: (page) {
                setState(() {
                  currentPage = page;
                });
              },
            ),
          ],
        );
      },
    );
  }
}