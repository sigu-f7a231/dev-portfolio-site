// lib/sections/skills/skills_header.dart
import 'package:flutter/material.dart';

class SkillsHeader extends StatelessWidget {
  final bool showPie;
  final ValueChanged<bool> onToggle;
  final Color textColor;

  const SkillsHeader({
    super.key,
    required this.showPie,
    required this.onToggle,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Skills', style: TextStyle(fontSize: 28, color: textColor)),
        const Spacer(),
        Row(
          children: [
            Text('Pie', style: TextStyle(color: textColor)),
            Switch(
              value: showPie,
              onChanged: onToggle,
            ),
          ],
        ),
      ],
    );
  }
}