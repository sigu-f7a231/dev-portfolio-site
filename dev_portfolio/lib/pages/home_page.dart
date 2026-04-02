// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../sections/header/header.dart';
import '../sections/hero_section.dart';
import '../sections/about_section.dart';
import '../sections/skills_section.dart';
import '../sections/projects_section.dart';
import '../controllers/scroll_controller.dart';

class HomePage extends StatelessWidget {
  final ThemeMode themeMode;
  final Function(bool) onThemeChanged;
  final SectionScrollController scroll = SectionScrollController();

  HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black87),
              child: const Text(
                'DevPortfolio',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                scroll.scrollTo('home');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('About'),
              onTap: () {
                scroll.scrollTo('about');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Skills'),
              onTap: () {
                scroll.scrollTo('skills');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Projects'),
              onTap: () {
                scroll.scrollTo('projects');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header にダークモード切替スイッチを渡す
          Header(
            onHomePressed: () => scroll.scrollTo('home'),
            onAboutPressed: () => scroll.scrollTo('about'),
            onSkillsPressed: () => scroll.scrollTo('skills'),
            onProjectsPressed: () => scroll.scrollTo('projects'),
            themeMode: themeMode,
            onThemeChanged: onThemeChanged,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scroll.controller,
              child: Column(
                children: [
                  HeroSection(key: scroll.keys['home']),
                  AboutSection(key: scroll.keys['about']),
                  SkillsSection(key: scroll.keys['skills']),
                  ProjectsSection(key: scroll.keys['projects']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}