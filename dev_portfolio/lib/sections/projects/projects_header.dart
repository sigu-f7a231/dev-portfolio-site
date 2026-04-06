// lib/sections/projects/projects_header.dart
import 'package:flutter/material.dart';
import '../config/projects_header_config.dart';

class ProjectsHeader extends StatelessWidget {
  final bool showCollectionView;
  final ValueChanged<bool> onToggle;
  final bool isDark;

  const ProjectsHeader({
    super.key,
    required this.showCollectionView,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          ProjectsHeaderConfig.title,
          style: ProjectsHeaderConfig.titleStyle(isDark),
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              ProjectsHeaderConfig.toggleLabel,
              style: ProjectsHeaderConfig.labelStyle(isDark),
            ),
            Switch(
              value: showCollectionView,
              onChanged: onToggle,
            ),
          ],
        ),
      ],
    );
  }
}