import 'package:flutter/material.dart';
import '../config/header_config.dart';
import 'desktop_header.dart';
import 'mobile_header.dart';

class Header extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;
  final ThemeMode themeMode;
  final Function(bool) onThemeChanged;
  final VoidCallback? onYamlStateChanged; // ★ 追加

  const Header({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
    required this.themeMode,
    required this.onThemeChanged,
    this.onYamlStateChanged, // ★ 追加
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < HeaderConfig.mobileBreakpoint) {
          return MobileHeader(
            onHomePressed: onHomePressed,
            onAboutPressed: onAboutPressed,
            onSkillsPressed: onSkillsPressed,
            onProjectsPressed: onProjectsPressed,
            themeMode: themeMode,
            onThemeChanged: onThemeChanged,
            onYamlStateChanged: onYamlStateChanged, // ★ モバイル側でも必要なら渡す
          );
        } else {
          return DesktopHeader(
            onHomePressed: onHomePressed,
            onAboutPressed: onAboutPressed,
            onSkillsPressed: onSkillsPressed,
            onProjectsPressed: onProjectsPressed,
            themeMode: themeMode,
            onThemeChanged: onThemeChanged,
            onYamlStateChanged: onYamlStateChanged, // ★ DesktopHeaderに渡す
          );
        }
      },
    );
  }
}