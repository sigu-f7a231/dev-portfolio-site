import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/header_config.dart';
import 'desktop_header.dart';
import 'mobile_header.dart';

class Header extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;
  final VoidCallback? onYamlStateChanged; // ★ 追加

  /// いま表示中のセクション（ナビの選択表示に使う）
  final ValueListenable<String> activeSection;

  const Header({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
    this.onYamlStateChanged, // ★ 追加
    required this.activeSection,
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
            onYamlStateChanged: onYamlStateChanged, // ★ モバイル側でも必要なら渡す
          );
        } else {
          return DesktopHeader(
            onHomePressed: onHomePressed,
            onAboutPressed: onAboutPressed,
            onSkillsPressed: onSkillsPressed,
            onProjectsPressed: onProjectsPressed,
            onYamlStateChanged: onYamlStateChanged, // ★ DesktopHeaderに渡す
            activeSection: activeSection,
          );
        }
      },
    );
  }
}
