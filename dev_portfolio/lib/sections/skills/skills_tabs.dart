import 'package:flutter/material.dart';
import 'charts/skills_bar_chart.dart';
import 'charts/skills_pie_chart.dart';
import 'data/skills_work.dart';
import 'data/skills_private.dart';
import '../config/skills/skills_tabs_config.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';
import '../../widgets/app_loading_indicator.dart';

class SkillsTabs extends StatefulWidget {
  final TabController tabController;
  final bool showPie;

  const SkillsTabs({
    super.key,
    required this.tabController,
    required this.showPie,
  });

  @override
  State<SkillsTabs> createState() => _SkillsTabsState();
}

class _SkillsTabsState extends State<SkillsTabs> {
  Map<String, double>? workSkills;
  Map<String, double>? privateSkills;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final loadedWork = await loadWorkSkillsAll();
      final loadedPrivate = await loadPrivateSkillsAll();
      setState(() {
        workSkills = loadedWork['skills'];
        privateSkills = loadedPrivate['skills'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading skills: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    // Map -> List<MapEntry> に変換して変数に格納
    final workEntries = workSkills!.entries.toList();
    final privateEntries = privateSkills!.entries.toList();

    return Column(
      children: [
        TabBar(
          controller: widget.tabController,
          labelColor: context.colors.accent,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: context.colors.accent,
          tabs: SkillsTabsConfig.mainTabs.map((t) => Tab(text: t)).toList(),
        ),
        const SizedBox(height: SkillsTabsConfig.spacingBetweenTabBarAndContent),
        Expanded(
          child: TabBarView(
            controller: widget.tabController,
            children: [
              // Work Skills
              Center(
                child: SizedBox(
                  width: SkillsTabsConfig.cardWidth,
                  height: SkillsTabsConfig.cardHeight,
                  child: widget.showPie
                      ? SkillsPieChart(data: workSkills!)
                      : SkillsBarChart(entries: workEntries),
                ),
              ),
              // Private Skills
              Center(
                child: SizedBox(
                  width: SkillsTabsConfig.cardWidth,
                  height: SkillsTabsConfig.cardHeight,
                  child: Builder(
                    builder: (_) {
                      // privateEntriesを参照して警告を回避
                      final _ = privateEntries.length;
                      return Text(
                        AppTexts.privateHidden,
                        style: TextStyle(
                          color: context.colors.textStrong,
                          fontSize: AppSizes.skillsTabsMessageFontSize,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}