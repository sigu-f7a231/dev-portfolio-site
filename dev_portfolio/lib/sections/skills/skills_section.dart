import 'package:flutter/material.dart';
import 'data/skills_work.dart';
import 'data/skills_private.dart';
import '../config/skills/skills_section_config.dart';
import 'widgets/skills_header.dart';
import 'widgets/skills_tab_bar.dart';
import 'widgets/skills_card.dart';

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _categoryTabController;

  bool _showPie = false;

  late Future<Map<String, Map<String, double>>> _workSkillsFuture;
  late Future<Map<String, Map<String, double>>> _privateSkillsFuture;

  final List<String> _categories = const [
    'server_os',
    'db',
    'tools',
    'backend_frameworks',
    'frontend_frameworks',
    'ui_frameworks',
    'testing_frameworks',
    'cloud_platforms',
    'aws_services',
    'azure_services',
    'gcp_services',
    'container',
    'container_orchestration',
    'ai_services',
    'skills',
  ];

  @override
  void initState() {
    super.initState();

    _mainTabController = TabController(
      length: SkillsSectionConfig.mainTabs.length,
      vsync: this,
    );

    _categoryTabController = TabController(
      length: _categories.length,
      vsync: this,
    );

    _workSkillsFuture = loadWorkSkillsAll();
    _privateSkillsFuture = loadPrivateSkillsAll();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _categoryTabController.dispose();
    super.dispose();
  }

  Map<String, double> _getCategoryData(
    Map<String, Map<String, double>> data,
    String category,
  ) {
    return data[category] ?? {};
  }

  String _label(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((e) => e.isEmpty
            ? ''
            : '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Text(
        'データがありません',
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = SkillsColors.background(isDark);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(SkillsLayout.sectionPadding),
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          /// HEADER
          SkillsHeader(
            showPie: _showPie,
            isDark: isDark,
            onToggle: (val) => setState(() => _showPie = val),
          ),

          const SizedBox(height: SkillsLayout.spacing),

          /// MAIN TAB
          SkillsTabBar(
            controller: _mainTabController,
            tabs: SkillsSectionConfig.mainTabs,
            isDark: isDark,
          ),

          const SizedBox(height: SkillsLayout.spacing),

          /// CATEGORY TAB
          SkillsTabBar(
            controller: _categoryTabController,
            tabs: _categories.map(_label).toList(),
            isDark: isDark,
          ),

          const SizedBox(height: SkillsLayout.spacing),

          /// CONTENT
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildFuture(_workSkillsFuture, isDark, isPrivate: false),
                _buildFuture(_privateSkillsFuture, isDark, isPrivate: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuture(
    Future<Map<String, Map<String, double>>> future,
    bool isDark, {
    required bool isPrivate,
  }) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        return TabBarView(
          controller: _categoryTabController,
          children: _categories.map((category) {
            final categoryData = _getCategoryData(data, category);

            /// PRIVATE制御
            if (isPrivate && category == 'workflow') {
              return _emptyState(isDark);
            }

            /// ★ 追加：データなし判定
            if (categoryData.isEmpty) {
              return _emptyState(isDark);
            }

            return SkillsCard(
              data: categoryData,
              isDark: isDark,
              showPie: _showPie,
            );
          }).toList(),
        );
      },
    );
  }
}