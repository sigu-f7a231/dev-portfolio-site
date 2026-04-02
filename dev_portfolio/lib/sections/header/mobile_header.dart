// lib/sections/header/mobile_header.dart
import 'package:flutter/material.dart';

class MobileHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;
  final ThemeMode themeMode;
  final Function(bool) onThemeChanged;

  const MobileHeader({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('DevPortfolio'),
      actions: [
        Row(
          children: [
            const Text('Dark Mode'),
            Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: onThemeChanged,
            ),
          ],
        ),
      ],
    );
  }
}