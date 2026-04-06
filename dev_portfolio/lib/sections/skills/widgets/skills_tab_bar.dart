// lib/sections/skills/widgets/skills_tab_bar.dart
import 'package:flutter/material.dart';
import '../../config/skills_widgets_tab_bar_config.dart';

class SkillsTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final bool isDark;

  const SkillsTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: SkillsTabBarConfig.selectedLabelColor,
      unselectedLabelColor: SkillsTabBarConfig.labelColor(isDark),
      indicatorColor: SkillsTabBarConfig.indicatorColor,
      tabs: tabs
          .map(
            (t) => Tab(
              child: Text(
                t,
                style: TextStyle(
                  fontSize: SkillsTabBarConfig.labelFontSize,
                  color: SkillsTabBarConfig.labelColor(isDark),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}