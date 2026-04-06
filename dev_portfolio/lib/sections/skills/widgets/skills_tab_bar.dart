import 'package:flutter/material.dart';
import '../../config/skills_section_config.dart';

class SkillsTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final Color textColor;

  const SkillsTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: SkillsColors.accent,
      unselectedLabelColor: textColor,
      indicatorColor: SkillsColors.accent,
      tabs: tabs.map((t) => Tab(text: t)).toList(),
    );
  }
}