import 'package:flutter/material.dart';
import 'data/skills_work.dart';
import 'data/skills_private.dart';
import '../config/skills_section_config.dart';
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

  final baseCategories = SkillsSectionConfig.categories;

  @override
  void initState() {
    super.initState();

    _mainTabController =
        TabController(length: SkillsSectionConfig.mainTabs.length, vsync: this);

    // workflow タブを含める
    _categoryTabController =
        TabController(length: baseCategories.length + 1, vsync: this);

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
      Map<String, Map<String, double>> data, String category) {
    return data[category] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = SkillsColors.background(isDark);
    final textColor = SkillsColors.text(isDark);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(SkillsLayout.sectionPadding),
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          // Header
          SkillsHeader(
            showPie: _showPie,
            isDark: isDark,
            onToggle: (val) => setState(() => _showPie = val),
          ),
          const SizedBox(height: SkillsLayout.spacing),

          // Main Tabs
          SkillsTabBar(
            controller: _mainTabController,
            tabs: SkillsSectionConfig.mainTabs,
            textColor: textColor,
          ),
          const SizedBox(height: SkillsLayout.spacing),

          // Category Tabs
          SkillsTabBar(
            controller: _categoryTabController,
            tabs: [...baseCategories.map((c) => c.toUpperCase()), 'WORKFLOW'],
            textColor: textColor,
          ),
          const SizedBox(height: SkillsLayout.spacing),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                // Work
                _buildFuture(
                  _workSkillsFuture,
                  isDark,
                  isPrivate: false,
                ),
                // Private
                _buildFuture(
                  _privateSkillsFuture,
                  isDark,
                  isPrivate: true,
                ),
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

        // カテゴリ + workflow
        final categories = [...baseCategories, 'workflow'];

        return TabBarView(
          controller: _categoryTabController,
          children: categories.map((category) {
            final categoryData = _getCategoryData(data, category);

            // Privateの場合はworkflowのみ非表示にしてメッセージ表示
            if (isPrivate && category.toLowerCase() == 'workflow') {
              return Center(
                child: Text(
                  "Private のため表示できません",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return SkillsCard(
              data: categoryData,
              isDark: isDark,
              showPie: !isPrivate ? _showPie : false,
            );
          }).toList(),
        );
      },
    );
  }
}