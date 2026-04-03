// lib/sections/projects/projects_section.dart
import 'package:flutter/material.dart';
import 'data/projects_work.dart';
import 'data/projects_private.dart';
import 'models/projects_model.dart';
import 'views/projects_tab_view.dart';

class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool showCollectionView = false;

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
    super.dispose();
  }

  void toggleView(bool value) {
    setState(() {
      showCollectionView = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.indigo;
    final textColor = Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          // ヘッダー＋表示切替スイッチ
          Row(
            children: [
              Text('Projects', style: TextStyle(fontSize: 28, color: textColor)),
              const Spacer(),
              Row(
                children: [
                  Text('Collection View', style: TextStyle(color: textColor)),
                  Switch(
                    value: showCollectionView,
                    onChanged: toggleView,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // タブバー＋タブビューは別コンポーネントへ
          Expanded(
            child: ProjectsTabView(
              tabController: _tabController,
              workFuture: workFuture,
              privateFuture: privateFuture,
              showCollectionView: showCollectionView,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}