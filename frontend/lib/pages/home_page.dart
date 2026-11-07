// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../state/providers.dart';
import '../auth/auth_controller.dart';
import '../widgets/account_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final SectionScrollController scroll = SectionScrollController();

  /// Drawer の並び順に対応するセクション
  static const List<String> _sections = ['home', 'about', 'skills', 'projects'];

  /// Work / Private が変わったことを知らせる（Provider が読み直し、Home のまとめ・Skills・Projects が作り直される）
  void _dataChanged() => ref.read(dataRevisionProvider.notifier).bump();

  @override
  void initState() {
    super.initState();
    // YAML を指定せずに起動した（かつ未アップロード）ときは、最初に入力画面を出す
    // ログインした直後など、プロフィールを読んでいる途中なら、読み終わるまで待ってから決める
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ProfileStore.instance.loading.catchError((_) {});
      if (mounted && ProfileStore.instance.value == null) {
        // プロフィールに Work / Private も書かれていれば、Skills / Projects も作り直す
        showProfileSetupDialog(context, onProjectsChanged: _dataChanged);
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
    // データが変わった回数。変わったら下の ValueKey が変わり、Skills / Projects を作り直す
    // （中のデータは Provider が読み直す。作り直すのは、選んでいたタブ・フィルター・ページを初めに戻すため。前と同じ動き）
    final revision = ref.watch(dataRevisionProvider);
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
          // ログイン中は、一番上にマイページの操作（公開する・マイページ・ログアウト）
          if (ref.watch(authControllerProvider) != null) const AccountBar(),
          Header(
            onHomePressed: () => scroll.scrollTo('home'),
            onAboutPressed: () => scroll.scrollTo('about'),
            onSkillsPressed: () => scroll.scrollTo('skills'),
            onProjectsPressed: () => scroll.scrollTo('projects'),
            activeSection: scroll.active,
            onYamlStateChanged: _dataChanged, // Skills / Projects を作り直して集計し直す
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
                  // スクロール用キーは外側の Container に持たせ、
                  // 中の SkillsSection に ValueKey を持たせることで、データが変わったら作り直して集計し直す
                  Container(
                    key: scroll.keys['skills'],
                    child: SkillsSection(
                      key: ValueKey('skills_$revision'),
                    ),
                  ),
                  // Skills と同じく、スクロール用キーは外側の Container に持たせる
                  Container(
                    key: scroll.keys['projects'],
                    child: ProjectsSection(key: ValueKey('projects_$revision')),
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
