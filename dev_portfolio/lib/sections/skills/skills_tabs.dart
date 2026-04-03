// lib/sections/skills/skills_tabs.dart
import 'package:flutter/material.dart';
import 'charts/skills_bar_chart.dart';
import 'charts/skills_pie_chart.dart';
import 'data/skills_work.dart';
import 'data/skills_private.dart';

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

    return Column(
      children: [
        TabBar(
          controller: widget.tabController,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: widget.isDark ? Colors.white : Colors.white,
          indicatorColor: Colors.orangeAccent,
          tabs: const [
            Tab(text: 'Work'),
            Tab(text: 'Private'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: widget.tabController,
            children: [
              Center(
                child: SizedBox(
                  width: 1000,
                  height: 500,
                  child: widget.showPie
                      ? SkillsPieChart(data: workSkills!, isDark: widget.isDark)
                      : SkillsBarChart(data: workSkills!, isDark: widget.isDark),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 1000,
                  height: 500,
                  child: widget.showPie
                      ? SkillsPieChart(data: privateSkills!, isDark: widget.isDark)
                      : SkillsBarChart(data: privateSkills!, isDark: widget.isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}