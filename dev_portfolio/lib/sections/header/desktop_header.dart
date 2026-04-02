// lib/sections/header/desktop_header.dart
import 'package:flutter/material.dart';

class DesktopHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;
  final ThemeMode themeMode;
  final Function(bool) onThemeChanged;

  const DesktopHeader({
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TextButton(onPressed: onHomePressed, child: const Text('Home')),
              TextButton(onPressed: onAboutPressed, child: const Text('About')),
              TextButton(onPressed: onSkillsPressed, child: const Text('Skills')),
              TextButton(onPressed: onProjectsPressed, child: const Text('Projects')),
            ],
          ),
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
      ),
    );
  }
}