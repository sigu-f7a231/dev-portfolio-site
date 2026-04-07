// lib/sections/projects/views/projects_tab_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../pagination/projects_pagination_logic.dart';
import '../pagination/projects_pagination_ui.dart';
import '../views/project_list/project_list_ui.dart';
import '../views/projects_collection_view.dart';
import '../views/project_list/project_list_modal_function.dart';
import '../../../utils/theme_colors.dart';

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
  Map<int, int> currentPages = {}; // タブごとのページ番号
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
          labelColor: AppColors.tabLabel(widget.isDark),
          unselectedLabelColor: AppColors.tabUnselected(widget.isDark),
          indicatorColor: AppColors.tabLabel(widget.isDark),
          tabs: const [
            Tab(text: 'Work'),
            Tab(text: 'Private'),
          ],
        ),
        const SizedBox(height: 8),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No projects'));
        }

        final projects = snapshot.data!;
        projects.sort((a, b) => a.periodStart.compareTo(b.periodStart));

        final totalPages = ProjectsPaginationLogic.getTotalPages(projects);
        final currentPage = currentPages[tabIndex] ?? 1;
        final paginatedProjects =
            ProjectsPaginationLogic.getPaginatedProjects(projects, currentPage);

        return ValueListenableBuilder<bool>(
          valueListenable: widget.showCollectionNotifier,
          builder: (_, showCollection, __) {
            return Column(
              children: [
                Expanded(
                  child: showCollection
                      ? ProjectCollectionView(
                          projects: paginatedProjects,
                          isDark: widget.isDark,
                          onProjectTap: (p) => showProjectDetailModal(
                            context,
                            p,
                            isDark: widget.isDark,
                          ),
                        )
                      : ProjectListUI(
                          projects: paginatedProjects,
                          isDark: widget.isDark,
                          onProjectTap: (p) => showProjectDetailModal(
                            context,
                            p,
                            isDark: widget.isDark,
                          ),
                        ),
                ),
                SizedBox(
                  height: 60,
                  child: ProjectsPaginationUI(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    onPageChanged: (page) {
                      setState(() => currentPages[tabIndex] = page);
                    },
                    isDark: widget.isDark,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}