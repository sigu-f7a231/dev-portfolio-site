// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../sections/header/header.dart';
import '../sections/hero_section.dart';
import '../sections/about_section.dart';
import '../sections/skills/skills_section.dart';
import '../sections/projects/projects_section.dart';
import '../controllers/scroll_controller.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SectionScrollController scroll = SectionScrollController();

  /// Drawer の並び順に対応するセクション
  static const List<String> _sections = ['home', 'about', 'skills', 'projects'];
  int _refreshKey = 0;        // Projects用の再描画キー
  int _skillsRefreshKey = 0;  // ★ Skills専用の再描画キーを追加

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // M3 の NavigationDrawer（スマホ幅のときにメニューから開く）
      drawer: NavigationDrawer(
        selectedIndex: null, // 1 ページ内のスクロールなので選択状態は持たない
        onDestinationSelected: (index) {
          scroll.scrollTo(_sections[index]);
          Navigator.pop(context);
        },
        children: [
          Padding(
            padding: AppSizes.drawerHeaderPadding,
            child: Text(
              AppTexts.appTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            label: Text(AppTexts.navHome),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.person_outline),
            label: Text(AppTexts.navAbout),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.bar_chart),
            label: Text(AppTexts.navSkills),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.work_outline),
            label: Text(AppTexts.navProjects),
          ),
        ],
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
