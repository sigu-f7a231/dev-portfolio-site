// 状態（Riverpod）と画面の URL（go_router）のテスト
// 対象：lib/state/providers.dart、lib/router/app_router.dart、lib/pages/placeholder_page.dart、
//       HomePage・Home・About・Skills・Projects が Provider からデータを読むこと
//
// 実行：flutter test test/app_state_test.dart（frontend/ で）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/data/local_portfolio_repository.dart';
import 'package:dev_portfolio/data/portfolio_repository.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/pages/home_page.dart';
import 'package:dev_portfolio/pages/placeholder_page.dart';
import 'package:dev_portfolio/router/app_router.dart';
import 'package:dev_portfolio/sections/projects/projects_section.dart';
import 'package:dev_portfolio/sections/skills/skills_section.dart';
import 'package:dev_portfolio/state/providers.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/profile_store.dart';

import 'test_assets.dart';

const _profile = Profile(name: '状態 太郎', role: 'エンジニア', tagline: '紹介文', intro: '自己紹介');

const _work = '''
projects:
  - title: 状態の業務
    skills: [Dart]
    period: [2024-01, 2024-06]
    workflow: {implementation_unit_test: true}
''';

/// 仮の時間を少しずつ進める（読み込み中の表示など、終わらないアニメーションがあっても止まらないように）
Future<void> _settle(WidgetTester tester, [int frames = 15]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// main.dart と同じ組み立て（ProviderScope ＋ MaterialApp.router）。中の ProviderContainer を返す
Future<ProviderContainer> _pumpApp(WidgetTester tester, GoRouter router) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ref.watch(themeModeProvider),
        routerConfig: router,
      ),
    ),
  ));
  await _settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

String _path(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

void main() {
  setUpAll(loadAppFont);

  setUp(() {
    useFileAssets();
    stub.SessionStore.clear();
    PortfolioRepository.reset();
    ProfileStore.instance.value = _profile; // 入力画面を出さない
  });
  tearDown(() {
    ProfileStore.instance.value = null;
  });

  group('Provider', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('portfolioRepositoryProvider は今の Repository を返し、差し替えられる', () {
      expect(container.read(portfolioRepositoryProvider), same(PortfolioRepository.instance));
      final other = LocalPortfolioRepository();
      final overridden = ProviderContainer(overrides: [portfolioRepositoryProvider.overrideWithValue(other)]);
      addTearDown(overridden.dispose);
      expect(overridden.read(portfolioRepositoryProvider), same(other));
    });

    test('dataRevisionProvider は 0 から始まり、bump で 1 ずつ増える', () {
      expect(container.read(dataRevisionProvider), 0);
      container.read(dataRevisionProvider.notifier).bump();
      expect(container.read(dataRevisionProvider), 1);
    });

    test('themeModeProvider：はじめはライト。toggle で切り替える。最初のテーマを決められる', () {
      expect(container.read(themeModeProvider), ThemeMode.light);
      container.read(themeModeProvider.notifier).toggle(true);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      final dark = ProviderContainer(
        overrides: [themeModeProvider.overrideWith(() => ThemeModeNotifier(ThemeMode.dark))],
      );
      addTearDown(dark.dispose);
      expect(dark.read(themeModeProvider), ThemeMode.dark);
    });

    test('profileProvider：ProfileStore の今の値。変わったら新しい値', () {
      expect(container.read(profileProvider)?.name, '状態 太郎');
      ProfileStore.instance.value = null;
      expect(container.read(profileProvider), isNull);
      ProfileStore.instance.value = _profile;
      expect(container.read(profileProvider), same(_profile));
    });

    test('projectRecordsProvider：Repository から Work / Private を読む（なければサンプル）', () async {
      stub.SessionStore.write('work', _work);
      final records = await container.read(projectRecordsProvider.future);
      expect(records.work.single['title'], '状態の業務');
      expect(records.private, isNotEmpty); // サンプル
    });

    test('データが変わったと知らせると読み直す。Skills の集計・Projects の一覧も', () async {
      expect((await container.read(projectsListProvider.future))[0].first.title, isNot('状態の業務'));
      stub.SessionStore.write('work', _work);
      expect((await container.read(projectsListProvider.future))[0].first.title, isNot('状態の業務'),
          reason: '知らせるまでは前のまま');

      container.read(dataRevisionProvider.notifier).bump();
      final projects = await container.read(projectsListProvider.future);
      expect(projects[0].single.title, '状態の業務');
      final skills = await container.read(skillsDataProvider.future);
      expect(skills[0]['skills'], {'Dart': 100.0});
      expect(skills[0].containsKey('workflow'), isTrue, reason: 'Work は担当の工程も数える');
      expect(skills[1].containsKey('workflow'), isFalse);
    });

    test('異常系：読めなければエラーになり、繰り返さない', () async {
      stub.SessionStore.write('work', 'projects: [\n');
      await expectLater(container.read(projectRecordsProvider.future), throwsA(anything));
      await expectLater(container.read(skillsDataProvider.future), throwsA(anything));
      await expectLater(container.read(projectsListProvider.future), throwsA(anything));
    });
  });

  group('画面の URL', () {
    testWidgets('/ は公開ページ（HomePage）', (tester) async {
      await _pumpApp(tester, createAppRouter());
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('状態 太郎'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ない URL を開くと / に移る', (tester) async {
      final router = createAppRouter(initialLocation: '/no-such-page');
      await _pumpApp(tester, router);
      expect(find.byType(HomePage), findsOneWidget);
      expect(_path(router), AppRoutes.home);
    });

    testWidgets('ふだんのビルド（ENABLE_ACCOUNT なし）では、ログイン・マイページを開くと / に移る', (tester) async {
      expect(accountRoutesEnabled, isFalse);
      for (final location in [AppRoutes.login, AppRoutes.myPage, AppRoutes.edit]) {
        final router = createAppRouter(initialLocation: location);
        await _pumpApp(tester, router);
        expect(find.byType(PlaceholderPage), findsNothing, reason: location);
        expect(_path(router), AppRoutes.home, reason: location);
      }
    });

    testWidgets('ENABLE_ACCOUNT のときは、ログイン・マイページ・編集の空の画面を開ける', (tester) async {
      for (final (location, title, id) in [
        (AppRoutes.login, RouteTexts.login, 'A-01'),
        (AppRoutes.myPage, RouteTexts.myPage, 'M-01'),
        (AppRoutes.edit, RouteTexts.edit, 'M-02〜M-06'),
      ]) {
        final router = createAppRouter(initialLocation: location, enableAccount: true);
        await _pumpApp(tester, router);
        expect(find.byType(PlaceholderPage), findsOneWidget, reason: location);
        expect(find.text(title), findsOneWidget);
        expect(find.text(RouteTexts.preparing), findsOneWidget);
        expect(find.text(RouteTexts.planned(id)), findsOneWidget);
        expect(_path(router), location);
      }
    });

    testWidgets('空の画面の［公開ページへ戻る］で / に戻る', (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.myPage, enableAccount: true);
      await _pumpApp(tester, router);
      await tester.tap(find.text(RouteTexts.backToPublic));
      await _settle(tester);
      expect(find.byType(HomePage), findsOneWidget);
      expect(_path(router), AppRoutes.home);
    });

    test('main.dart が使う appRouter は / から始まる', () {
      expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.home);
    });
  });

  group('画面は Provider からデータを読む', () {
    testWidgets('dataRevisionProvider が増えると、Skills / Projects を作り直し、新しいデータを出す', (tester) async {
      final container = await _pumpApp(tester, createAppRouter());
      final skillsBefore = tester.state(find.byType(SkillsSection));
      final projectsBefore = tester.state(find.byType(ProjectsSection));
      expect(find.text('状態の業務'), findsNothing);

      stub.SessionStore.write('work', _work);
      container.read(dataRevisionProvider.notifier).bump();
      await _settle(tester);

      expect(tester.state(find.byType(SkillsSection)), isNot(same(skillsBefore)));
      expect(tester.state(find.byType(ProjectsSection)), isNot(same(projectsBefore)));
      expect(find.text('状態の業務'), findsWidgets); // Home のまとめ（直近）・Projects の一覧
      expect(tester.takeException(), isNull);
    });

    testWidgets('テーマを Provider で変えると、画面がダークになる', (tester) async {
      final container = await _pumpApp(tester, createAppRouter());
      expect(Theme.of(tester.element(find.byType(HomePage))).brightness, Brightness.light);
      container.read(themeModeProvider.notifier).toggle(true);
      await _settle(tester); // テーマの切り替えのアニメーションが終わるまで
      expect(Theme.of(tester.element(find.byType(HomePage))).brightness, Brightness.dark);
    });
  });
}
