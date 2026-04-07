// lib/sections/projects/projects_section.dart
import 'package:flutter/material.dart';
import 'data/projects_work.dart';
import 'data/projects_private.dart';
import 'models/projects_model.dart';
import 'views/projects_tab_view.dart';
import 'projects_header.dart';
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

  // コレクションモード切替
  final ValueNotifier<bool> showCollectionNotifier = ValueNotifier(false);

  // Future は initState で保持 → build 内で再生成しない
  late Future<List<Project>> workFuture;
  late Future<List<Project>> privateFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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

    return Container(
      color: AppColors.background(isDark),
      padding: ProjectsSectionConfig.padding,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          ProjectsHeader(
            showCollectionNotifier: showCollectionNotifier,
            isDark: isDark,
          ),
          ProjectsSectionConfig.headerSpacing,
          Expanded(
            child: ProjectsTabView(
              tabController: _tabController,
              workFuture: workFuture,
              privateFuture: privateFuture,
              showCollectionNotifier: showCollectionNotifier,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}