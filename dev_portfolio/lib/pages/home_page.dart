// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../sections/header/header.dart';
import '../sections/hero_section.dart';
import '../sections/about_section.dart';
import '../sections/skills/skills_section.dart';
import '../sections/projects/projects_section.dart';
import '../controllers/scroll_controller.dart';
import '../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SectionScrollController scroll = SectionScrollController();
  int _refreshKey = 0;        // Projects用の再描画キー
  int _skillsRefreshKey = 0;  // ★ Skills専用の再描画キーを追加

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colors.drawerHeaderBackground),
              child: Text(
                AppTexts.appTitle,
                style: TextStyle(color: colors.drawerHeaderForeground, fontSize: AppSizes.drawerTitleFontSize),
              ),
            ),
            ListTile(
              title: const Text(AppTexts.navHome),
              onTap: () {
                scroll.scrollTo('home');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(AppTexts.navAbout),
              onTap: () {
                scroll.scrollTo('about');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(AppTexts.navSkills),
              onTap: () {
                scroll.scrollTo('skills');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(AppTexts.navProjects),
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
                  HeroSection(
                    key: scroll.keys['home'],
                    onSkillsPressed: () => scroll.scrollTo('skills'),
                    onProjectsPressed: () => scroll.scrollTo('projects'),
                  ),
                  AboutSection(key: scroll.keys['about']),
                  // ★ スクロール用キーは外側のContainerに持たせ、
                  // 内部の SkillsSection に ValueKey を持たせることで確実に再構築・再集計させる
                  Container(
                    key: scroll.keys['skills'],
                    child: SkillsSection(
                      key: ValueKey('skills_$_skillsRefreshKey'),
                    ),
                  ),
                  // Skills と同じく、スクロール用キーは外側の Container に持たせる
                  Container(
                    key: scroll.keys['projects'],
                    child: ProjectsSection(key: ValueKey(_refreshKey)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
