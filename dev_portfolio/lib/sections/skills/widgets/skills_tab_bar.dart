// ※現在どこからも参照されていない
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class SkillsTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;

  const SkillsTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      labelColor: context.colors.textStrong,
      unselectedLabelColor: context.colors.textSecondary,
      tabs: tabs.map((t) => Tab(text: t)).toList(),
    );
  }
}
