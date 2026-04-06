import 'package:flutter/material.dart';
import '../config/header_config.dart';

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
    final bgColor = HeaderConfig.backgroundColor(context);
    final txtColor = HeaderConfig.textColor(context);

    return Container(
      padding: HeaderConfig.desktopPadding,
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: onHomePressed,
                child: Text('Home', style: TextStyle(color: txtColor)),
              ),
              TextButton(
                onPressed: onAboutPressed,
                child: Text('About', style: TextStyle(color: txtColor)),
              ),
              TextButton(
                onPressed: onSkillsPressed,
                child: Text('Skills', style: TextStyle(color: txtColor)),
              ),
              TextButton(
                onPressed: onProjectsPressed,
                child: Text('Projects', style: TextStyle(color: txtColor)),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Dark Mode', style: TextStyle(color: Colors.white70)),
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