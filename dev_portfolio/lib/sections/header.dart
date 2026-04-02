import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;

  const Header({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 600px以下ならモバイル用のDrawer、以上なら通常の横並び
        if (constraints.maxWidth < 600) {
          return MobileHeader(
            onHomePressed: onHomePressed,
            onAboutPressed: onAboutPressed,
            onSkillsPressed: onSkillsPressed,
            onProjectsPressed: onProjectsPressed,
          );
        } else {
          return DesktopHeader(
            onHomePressed: onHomePressed,
            onAboutPressed: onAboutPressed,
            onSkillsPressed: onSkillsPressed,
            onProjectsPressed: onProjectsPressed,
          );
        }
      },
    );
  }
}

// デスクトップ用
class DesktopHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;

  const DesktopHeader({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'DevPortfolio',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          Row(
            children: [
              TextButton(onPressed: onHomePressed, child: const Text('Home', style: TextStyle(color: Colors.white))),
              TextButton(onPressed: onAboutPressed, child: const Text('About', style: TextStyle(color: Colors.white))),
              TextButton(onPressed: onSkillsPressed, child: const Text('Skills', style: TextStyle(color: Colors.white))),
              TextButton(onPressed: onProjectsPressed, child: const Text('Projects', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }
}

// モバイル用
class MobileHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;

  const MobileHeader({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('DevPortfolio'),
      backgroundColor: Colors.black87,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [],
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
    );
  }
}