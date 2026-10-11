// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../sections/header/header.dart';
import '../sections/hero_section.dart';
import '../sections/about_section.dart';
import '../sections/skills/skills_section.dart';
import '../sections/projects/projects_section.dart';
import '../controllers/scroll_controller.dart';

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final Function(bool) onThemeChanged;

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SectionScrollController scroll = SectionScrollController();
  int _refreshKey = 0;        // Projects用の再描画キー
  int _skillsRefreshKey = 0;  // ★ Skills専用の再描画キーを追加

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
          Header(
            onHomePressed: () => scroll.scrollTo('home'),
            onAboutPressed: () => scroll.scrollTo('about'),
            onSkillsPressed: () => scroll.scrollTo('skills'),
            onProjectsPressed: () => scroll.scrollTo('projects'),
            themeMode: widget.themeMode,
            onThemeChanged: widget.onThemeChanged,
            onYamlStateChanged: () {
              setState(() {
                _refreshKey++;       // Projectsを再描画
                _skillsRefreshKey++; // ★ Skillsも同時に独立して再描画・再集計させる
              });
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scroll.controller,
              child: Column(
                children: [
                  HeroSection(key: scroll.keys['home']),
                  AboutSection(key: scroll.keys['about']),
                  
                  // ★ スクロール用キーは外側のContainerに持たせ、
                  // 内部の SkillsSection に ValueKey を持たせることで確実に再構築・再集計させる
                  Container(
                    key: scroll.keys['skills'], 
                    child: SkillsSection(
                      key: ValueKey('skills_$_skillsRefreshKey'),
                    ),
                  ),

                  ProjectsSection(key: ValueKey(_refreshKey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}