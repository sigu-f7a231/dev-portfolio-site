// lib/sections/projects/projects_section.dart
import 'package:flutter/material.dart';
import 'data/projects_work.dart';
import 'data/projects_private.dart';
import 'models/projects_model.dart';
import 'views/projects_tab_view.dart';
import 'projects_header.dart';
import 'filters/ui/project_filter_panel.dart';
import 'filters/state/project_filter_state.dart';
import '../config/projects/projects_section_config.dart';
import '../../utils/theme_colors.dart';

class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ValueNotifier<bool> showCollectionNotifier = ValueNotifier(false);

  late Future<List<Project>> workFuture;
  late Future<List<Project>> privateFuture;

  int currentTabIndex = 0; // 0: work, 1: private

  // ★ フィルター状態
  ProjectFilterState filterState = ProjectFilterState.initial();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        currentTabIndex = _tabController.index;
      });
    });

    workFuture = loadWorkProjects();
    privateFuture = loadPrivateProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    showCollectionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: AppColors.background(isDark),
      padding: ProjectsSectionConfig.padding,
      height: screenHeight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProjectsHeader(
              showCollectionNotifier: showCollectionNotifier,
              isDark: isDark,
            ),
            ProjectsSectionConfig.headerSpacing,

            // ★ Filter UI
            FutureBuilder<List<Project>>(
              future: currentTabIndex == 0 ? workFuture : privateFuture,
              builder: (context, snapshot) {
                final projects = snapshot.data ?? [];
                return ProjectsFilter(
                  projects: projects,
                  tabIndex: currentTabIndex,
                  isDark: isDark,
                  onApply: (filtersMap) {
                    setState(() {
                      filterState =
                          ProjectFilterState(selectedFilters: filtersMap);
                    });
                  },
                );
              },
            ),

            // ★ TabView（高さを画面の70%に固定）
            SizedBox(
              height: screenHeight * 0.7,
              child: ProjectsTabView(
                tabController: _tabController,
                workFuture: workFuture,
                privateFuture: privateFuture,
                showCollectionNotifier: showCollectionNotifier,
                isDark: isDark,
                filterState: filterState,
              ),
            ),
          ],
        ),
      ),
    );
  }
}