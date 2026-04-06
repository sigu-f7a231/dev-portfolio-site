import 'package:flutter/material.dart';

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
      isScrollable: true,
      labelColor: isDark ? Colors.white : Colors.black,
      unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
      tabs: tabs.map((t) => Tab(text: t)).toList(),
    );
  }
}