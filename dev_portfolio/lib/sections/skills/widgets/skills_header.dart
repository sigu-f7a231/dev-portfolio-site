import 'package:flutter/material.dart';
import '../config/skills_section_config.dart';

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
    return Row(
      children: [
        // タイトル
        Text(
          'Skills',
          style: SkillsTextStyle.title(isDark),
        ),

        const Spacer(),

        // Pie切り替え
        Row(
          children: [
            Text(
              'Pie',
              style: SkillsTextStyle.label(isDark),
            ),
            Switch(
              value: showPie,
              onChanged: onToggle,
              activeColor: SkillsColors.accent,
            ),
          ],
        ),
      ],
    );
  }
}