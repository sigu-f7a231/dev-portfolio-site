// lib/sections/projects/projects_view_switch.dart
import 'package:flutter/material.dart';
import '../config/projects/projects_header_config.dart';

/// List / Collection 切り替えボタン（左右ボタンでハイライト）
class ProjectsViewSwitch extends StatelessWidget {
  final bool showCollection; // true: Collection, false: List
  final bool isDark;
  final Function(bool) onToggle;
  final bool reverseOrder; // ← ここを追加

  const ProjectsViewSwitch({
    super.key,
    required this.showCollection,
    required this.isDark,
    required this.onToggle,
    this.reverseOrder = false, // デフォルトは false
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _buildButton('List', !showCollection, () => onToggle(false)),
      SizedBox(width: ProjectsWidgetsHeaderConfig.switchSpacing),
      _buildButton('Collection', showCollection, () => onToggle(true)),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reverseOrder ? buttons.reversed.toList() : buttons,
    );
  }

  Widget _buildButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints:
            BoxConstraints(minWidth: ProjectsWidgetsHeaderConfig.switchMinWidth),
        padding: ProjectsWidgetsHeaderConfig.switchPadding,
        decoration: BoxDecoration(
          color: active
              ? ProjectsWidgetsHeaderConfig.switchActiveColor
              : ProjectsWidgetsHeaderConfig.switchInactiveColor(isDark),
          borderRadius: BorderRadius.circular(
              ProjectsWidgetsHeaderConfig.switchBorderRadius),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? ProjectsWidgetsHeaderConfig.switchTextActiveColor(isDark)
                : ProjectsWidgetsHeaderConfig.switchTextInactiveColor(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}