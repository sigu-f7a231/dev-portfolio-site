import 'package:flutter/material.dart';
import 'charts/skills_bar_chart.dart';
import 'charts/skills_pie_chart.dart';
import 'data/skills_work.dart';
import 'data/skills_private.dart';
import '../config/skills/skills_tabs_config.dart';

class SkillsTabs extends StatefulWidget {
  final TabController tabController;
  final bool showPie;
  final bool isDark;

  const SkillsTabs({
    super.key,
    required this.tabController,
    required this.showPie,
    required this.isDark,
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
      return const Center(child: CircularProgressIndicator());
    }

    // Map -> List<MapEntry> に変換して変数に格納
    final workEntries = workSkills!.entries.toList();
    final privateEntries = privateSkills!.entries.toList();

    return Column(
      children: [
        TabBar(
          controller: widget.tabController,
          labelColor: SkillsTabsConfig.labelColor(widget.isDark),
          unselectedLabelColor: SkillsTabsConfig.unselectedLabelColor(widget.isDark),
          indicatorColor: SkillsTabsConfig.indicatorColor(widget.isDark),
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
                      ? SkillsPieChart(data: workSkills!, isDark: widget.isDark)
                      : SkillsBarChart(entries: workEntries, isDark: widget.isDark),
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
                        "Private のため表示できません",
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.black,
                          fontSize: 16,
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