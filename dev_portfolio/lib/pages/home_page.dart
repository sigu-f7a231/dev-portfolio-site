// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../sections/header/header.dart';
import '../sections/header/header_parts.dart';
import '../utils/profile_store.dart';
import '../widgets/profile_setup_dialog.dart';
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
  void initState() {
    super.initState();
    // YAML を指定せずに起動した（かつ未アップロード）ときは、最初に入力画面を出す
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ProfileStore.instance.value == null) {
        // プロフィールに Work / Private も書かれていれば、Skills / Projects も作り直す
        showProfileSetupDialog(
          context,
          onProjectsChanged: () => setState(() {
            _refreshKey++;
            _skillsRefreshKey++;
          }),
        );
      }
    });
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // M3 の NavigationDrawer（スマホ幅のときにメニューから開く）
      // スクロールで表示中のセクションが変わったら、選択表示も変わる
      drawer: ValueListenableBuilder<String>(
        valueListenable: scroll.active,
        builder: (context, active, _) => NavigationDrawer(
            // 表示中のセクションを選択状態にする
            selectedIndex: _sections.indexOf(active),
            onDestinationSelected: (index) {
              Navigator.pop(context);
              scroll.scrollTo(_sections[index]);
            },
            children: [
              Padding(
                padding: AppSizes.drawerHeaderPadding,
                child: Text(
                  AppTexts.appTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final d in NavDestination.all)
                NavigationDrawerDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
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
            activeSection: scroll.active,
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
                    refreshKey: _refreshKey, // 案件を変えたら、まとめ（件数・直近）も作り直す
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
