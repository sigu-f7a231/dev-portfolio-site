// lib/sections/header/header.dart
import 'package:flutter/material.dart';
import 'desktop_header.dart';
import 'mobile_header.dart';

class Header extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;
  final ThemeMode themeMode;
  final Function(bool) onThemeChanged;

  const Header({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return MobileHeader(
            onHomePressed: onHomePressed,
            onAboutPressed: onAboutPressed,
            onSkillsPressed: onSkillsPressed,
            onProjectsPressed: onProjectsPressed,
            themeMode: themeMode,
            onThemeChanged: onThemeChanged,
          );
        } else {
          return DesktopHeader(
            onHomePressed: onHomePressed,
            onAboutPressed: onAboutPressed,
            onSkillsPressed: onSkillsPressed,
            onProjectsPressed: onProjectsPressed,
            themeMode: themeMode,
            onThemeChanged: onThemeChanged,
          );
        }
      },
    );
  }
}