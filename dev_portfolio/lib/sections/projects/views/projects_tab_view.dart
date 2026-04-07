import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_tab_config.dart';
import '../views/project_list/project_list_view.dart';
import 'projects_collection_view.dart';

class ProjectsTabView extends StatelessWidget {
  final TabController tabController;
  final Future<List<Project>> workFuture;
  final Future<List<Project>> privateFuture;
  final ValueNotifier<bool> showCollectionNotifier; // 🔽変更
  final bool isDark;

  const ProjectsTabView({
    super.key,
    required this.tabController,
    required this.workFuture,
    required this.privateFuture,
    required this.showCollectionNotifier,
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

        // 🔽 ここが重要（チラつき防止）
        return ValueListenableBuilder<bool>(
          valueListenable: showCollectionNotifier,
          builder: (_, showCollection, __) {
            return showCollection
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
      },
    );
  }
}