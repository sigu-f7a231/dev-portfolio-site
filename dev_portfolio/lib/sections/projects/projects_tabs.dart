// lib/sections/projects/projects_tabs.dart
import 'package:flutter/material.dart';
import 'views/projects_tab_view.dart';
import 'models/projects_model.dart';

class ProjectsTabs extends StatefulWidget {
  final Future<List<Project>> workFuture;
  final Future<List<Project>> privateFuture;
  final bool showCollectionView;
  final bool isDark;

  const ProjectsTabs({
    super.key,
    required this.workFuture,
    required this.privateFuture,
    required this.showCollectionView,
    required this.isDark,
  });

  @override
  State<ProjectsTabs> createState() => _ProjectsTabsState();
}

class _ProjectsTabsState extends State<ProjectsTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProjectsTabView(
      tabController: _tabController,
      workFuture: widget.workFuture,
      privateFuture: widget.privateFuture,
      showCollectionView: widget.showCollectionView,
      isDark: widget.isDark,
    );
  }
}