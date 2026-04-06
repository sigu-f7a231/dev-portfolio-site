import 'package:flutter/material.dart';
import '../../config/skills/skills_widgets_header_config.dart';

/// Bar / Pie 切り替えボタン（左右ボタンでハイライト）
class SkillsChartSwitch extends StatelessWidget {
  final bool showPie; // true: Pie 選択, false: Bar 選択
  final bool isDark;
  final Function(bool) onToggle;

  const SkillsChartSwitch({
    super.key,
    required this.showPie,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = SkillsHeaderConfig.switchActiveColor;
    final inactiveColor = isDark ? Colors.white10 : Colors.black12;
    final textActiveColor = isDark ? Colors.black : Colors.black87;
    final textInactiveColor = isDark ? Colors.white60 : Colors.black45;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ■ Bar ボタン
        GestureDetector(
          onTap: () => onToggle(false),
          child: Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: !showPie ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Bar',
              style: TextStyle(
                color: !showPie ? textActiveColor : textInactiveColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ■ Pie ボタン
        GestureDetector(
          onTap: () => onToggle(true),
          child: Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: showPie ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Pie',
              style: TextStyle(
                color: showPie ? textActiveColor : textInactiveColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}