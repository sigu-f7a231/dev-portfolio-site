// lib/sections/projects/views/projects_tab_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_tab_config.dart';
import 'projects_list_views.dart';
import 'projects_collection_view.dart';

class ProjectsTabView extends StatelessWidget {
  final TabController tabController;
  final Future<List<Project>> workFuture;
  final Future<List<Project>> privateFuture;
  final bool showCollectionView;
  final bool isDark;

  const ProjectsTabView({
    super.key,
    required this.tabController,
    required this.workFuture,
    required this.privateFuture,
    required this.showCollectionView,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          labelColor: ProjectsTabConfig.activeColor,
          unselectedLabelColor:
              ProjectsTabConfig.unselectedColor(isDark),
          indicatorColor: ProjectsTabConfig.activeColor,
          tabs: ProjectsTabConfig.tabs,
        ),
        ProjectsTabConfig.spacing,
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _buildTab(workFuture),
              _buildTab(privateFuture),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(Future<List<Project>> future) {
    return FutureBuilder<List<Project>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ProjectsTabConfig.loading;
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ProjectsTabConfig.empty;
        }

        final projects = snapshot.data!;

        return showCollectionView
            ? ProjectCollectionView(
                projects: projects,
                isDark: isDark,
              )
            : ProjectList(
                future: Future.value(projects),
                isDark: isDark,
              );
      },
    );
  }
}