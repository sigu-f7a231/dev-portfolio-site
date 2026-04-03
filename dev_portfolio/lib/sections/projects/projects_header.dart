// lib/sections/projects/projects_header.dart
import 'package:flutter/material.dart';

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
    final textColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        Text('Projects', style: TextStyle(fontSize: 28, color: textColor)),
        const Spacer(),
        Row(
          children: [
            Text('Collection View', style: TextStyle(color: textColor)),
            Switch(value: showCollectionView, onChanged: onToggle),
          ],
        ),
      ],
    );
  }
}