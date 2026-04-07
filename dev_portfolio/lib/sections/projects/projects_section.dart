// lib/sections/projects/projects_section.dart
import 'package:flutter/material.dart';
import 'data/projects_work.dart';
import 'data/projects_private.dart';
import 'models/projects_model.dart';
import 'views/projects_tab_view.dart';
import 'projects_header.dart';
import '../config/projects/projects_section_config.dart';

class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🔽 変更：ValueNotifier
  final ValueNotifier<bool> showCollectionNotifier =
      ValueNotifier(false);

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
    showCollectionNotifier.dispose(); // 忘れずに
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: ProjectsSectionConfig.backgroundColor(isDark),
      padding: ProjectsSectionConfig.padding,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          // 🔽 Header（Notifier渡す）
          ProjectsHeader(
            showCollectionNotifier: showCollectionNotifier,
            isDark: isDark,
          ),
          ProjectsSectionConfig.headerSpacing,

          // 🔽 TabView（Notifier渡す）
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