// lib/sections/skills/widgets/skills_header.dart
import 'package:flutter/material.dart';
import '../../config/skills_widgets_header_config.dart';

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

          const Spacer(),

          // Pie切り替え
          Row(
            children: [
              Text(
                'Pie',
                style: TextStyle(
                  fontSize: SkillsHeaderConfig.labelFontSize,
                  color: SkillsHeaderConfig.labelColor(isDark),
                ),
              ),
              Switch(
                value: showPie,
                onChanged: onToggle,
                activeColor: SkillsHeaderConfig.switchActiveColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}