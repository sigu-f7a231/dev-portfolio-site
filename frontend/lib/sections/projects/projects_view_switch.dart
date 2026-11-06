// lib/sections/projects/projects_view_switch.dart
import 'package:flutter/material.dart';
import '../../widgets/app_segment.dart';
import '../../constants/app_texts.dart';

/// List / Collection 切り替え（アイコン）
class ProjectsViewSwitch extends StatelessWidget {
  final bool showCollection; // true: Collection, false: List
  final ValueChanged<bool> onToggle;

  const ProjectsViewSwitch({
    super.key,
    required this.showCollection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppSegment<bool>(
      value: showCollection,
      onChanged: onToggle,
      items: const [
        AppSegmentItem(
          value: false,
          icon: Icons.view_agenda_outlined,
          tooltip: AppTexts.viewListTooltip,
        ),
        AppSegmentItem(
          value: true,
          icon: Icons.grid_view,
          tooltip: AppTexts.viewCollectionTooltip,
        ),
      ],
    );
  }
}
