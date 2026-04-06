// lib/sections/skills/widgets/skills_header.dart
import 'package:flutter/material.dart';
import '../../config/skills/skills_widgets_header_config.dart';
import 'skills_chart_switch.dart';

class SkillsHeader extends StatelessWidget {
  final bool showPie;
  final bool isDark;
  final Function(bool) onToggle;

  const SkillsHeader({
    super.key,
    required this.showPie,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SkillsHeaderConfig.rowPadding,
      child: Row(
        children: [
          // タイトル
          Text(
            'Skills',
            style: TextStyle(
              fontSize: SkillsHeaderConfig.titleFontSize,
              fontWeight: SkillsHeaderConfig.titleFontWeight,
              color: SkillsHeaderConfig.titleColor(isDark),
            ),
          ),
          const SizedBox(width: SkillsHeaderConfig.spacingBetweenTitleAndSwitch),

          // Pie/Bar 切り替えボタン
          SkillsChartSwitch(
            showPie: showPie,
            isDark: isDark,
            onToggle: onToggle,
          ),
        ],
      ),
    );
  }
}