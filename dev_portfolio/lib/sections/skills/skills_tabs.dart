// lib/sections/skills/skills_tabs.dart
import 'package:flutter/material.dart';
import 'skills_bar_chart.dart';
import 'skills_pie_chart.dart';
import 'skills_work.dart';
import 'skills_private.dart';

class SkillsTabs extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: isDark ? Colors.white : Colors.white,
          indicatorColor: Colors.orangeAccent,
          tabs: const [
            Tab(text: 'Work'),
            Tab(text: 'Private'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              Center(
                child: SizedBox(
                  width: 1000,
                  height: 500,
                  child: showPie
                      ? SkillsPieChart(data: workSkills, isDark: isDark)
                      : SkillsBarChart(data: workSkills, isDark: isDark),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 1000,
                  height: 500,
                  child: showPie
                      ? SkillsPieChart(data: privateSkills, isDark: isDark)
                      : SkillsBarChart(data: privateSkills, isDark: isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}