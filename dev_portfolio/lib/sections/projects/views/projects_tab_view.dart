// lib/sections/projects/views/projects_tab_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_tab_config.dart';
import '../views/project_list/project_list_ui.dart';
import '../views/projects_collection_view.dart';
import '../pagination/projects_pagination_logic.dart';
import '../pagination/projects_pagination_ui.dart';
import '../views/project_list/project_list_modal_function.dart';

class ProjectsTabView extends StatefulWidget {
  final TabController tabController;
  final Future<List<Project>> workFuture;
  final Future<List<Project>> privateFuture;
  final ValueNotifier<bool> showCollectionNotifier;
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
  State<ProjectsTabView> createState() => _ProjectsTabViewState();
}

class _ProjectsTabViewState extends State<ProjectsTabView> {
  // タブごとの現在ページ番号を保持
  Map<int, int> currentPages = {};

  // 🔹 Future をキャッシュして、再ビルド時に変化させない
  late Future<List<Project>> _workFuture;
  late Future<List<Project>> _privateFuture;

  @override
  void initState() {
    super.initState();
    currentPages = {0: 1, 1: 1};
    _workFuture = widget.workFuture;
    _privateFuture = widget.privateFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: widget.tabController,
          labelColor: ProjectsTabConfig.activeColor,
          unselectedLabelColor:
              ProjectsTabConfig.unselectedColor(widget.isDark),
          indicatorColor: ProjectsTabConfig.activeColor,
          tabs: ProjectsTabConfig.tabs,
        ),
        ProjectsTabConfig.spacing,
        Expanded(
          child: TabBarView(
            controller: widget.tabController,
            children: [
              _buildTab(_workFuture, 0),
              _buildTab(_privateFuture, 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(Future<List<Project>> future, int tabIndex) {
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

        // 🔹 開始日が古い順にソート
        projects.sort((a, b) => a.periodStart.compareTo(b.periodStart));

        final totalPages = ProjectsPaginationLogic.getTotalPages(projects);

        // 🔹 タブごとの現在ページを使用
        final currentPage = currentPages[tabIndex] ?? 1;

        final paginatedProjects =
            ProjectsPaginationLogic.getPaginatedProjects(projects, currentPage);

        return ValueListenableBuilder<bool>(
          valueListenable: widget.showCollectionNotifier,
          builder: (_, showCollection, __) {
            return LayoutBuilder(
              builder: (context, constraints) {
                const paginationHeight = 60.0;
                return Column(
                  children: [
                    SizedBox(
                      height: constraints.maxHeight - paginationHeight,
                      child: showCollection
                          ? ProjectCollectionView(
                              projects: paginatedProjects,
                              isDark: widget.isDark,
                              onProjectTap: (project) {
                                showProjectDetailModal(
                                  context,
                                  project,
                                  isDark: widget.isDark,
                                );
                              },
                            )
                          : ProjectListUI(
                              projects: paginatedProjects,
                              isDark: widget.isDark,
                              onProjectTap: (project) {
                                showProjectDetailModal(
                                  context,
                                  project,
                                  isDark: widget.isDark,
                                );
                              },
                            ),
                    ),
                    SizedBox(
                      height: paginationHeight,
                      child: ProjectsPaginationUI(
                        currentPage: currentPage,
                        totalPages: totalPages,
                        onPageChanged: (page) {
                          setState(() {
                            currentPages[tabIndex] = page;
                          });
                        },
                        // 🔹 ダークモード対応（既存色は ProjectsPaginationConfig を参照）
                        isDark: widget.isDark,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}