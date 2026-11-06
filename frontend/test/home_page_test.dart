// Home 画面全体（Header・Hero・About・Skills・Projects）のテスト
// 対象：lib/pages/home_page.dart と、そこから使う各セクション
// - 描画の組み合わせ：テーマ（ライト / ダーク）× 幅（スマホ 360 / タブレット 800 / PC 1280）× データ（サンプル / たくさん / 1 件）
//   はみ出し（overflow）や例外があれば、そのテストが失敗する
// - 操作：ナビ・グラフの切替・Work / Private・表示の切替・並び替え・ページ送り・フィルター・テーマ切替・スマホのメニュー
// - 異常系：データが 0 件・プロフィールがない
//
// 実行：flutter test test/home_page_test.dart（frontend/ で）
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/pages/home_page.dart';
import 'package:dev_portfolio/sections/about_section.dart';
import 'package:dev_portfolio/sections/header/header_parts.dart';
import 'package:dev_portfolio/sections/projects/projects_section.dart';
import 'package:dev_portfolio/sections/projects/sort/project_sort.dart';
import 'package:dev_portfolio/sections/skills/skills_section.dart';
import 'package:dev_portfolio/sections/skills/widgets/skills_category_filter.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/private_yaml_loader.dart';
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/utils/work_yaml_loader.dart';

import 'test_assets.dart';

const _profile = Profile(name: '鈴木 一郎', role: 'Web エンジニア', tagline: '紹介文です', intro: '自己紹介です');

/// Work の案件を [n] 件（期間・役割・規模・技術・工程がそろったもの。最後の 1 件は進行中）
String _workYaml(int n) {
  final b = StringBuffer('projects:\n');
  for (var i = 1; i <= n; i++) {
    final y = 2010 + i;
    b
      ..writeln('  - title: 業務 $i')
      ..writeln('    description: 業務 $i の説明')
      ..writeln('    details: |\n      1 行目\n      2 行目')
      ..writeln('    period: [$y-04, ${i == n ? '現在' : '$y-12'}]')
      ..writeln('    role: [${i.isEven ? 'PM, PL' : 'PG'}]')
      ..writeln("    scale: '全体 ${i * 7}名（チーム ${i + 2}名）'")
      ..writeln('    server_os: [Linux]')
      ..writeln('    db: [${i.isEven ? 'MySQL' : 'PostgreSQL'}]')
      ..writeln('    tools: [Git, VS Code, Docker]')
      ..writeln('    backend_frameworks: [${i.isEven ? 'Django' : 'Laravel'}]')
      ..writeln('    frontend_frameworks: [React]')
      ..writeln('    ui_frameworks: [Bootstrap]')
      ..writeln('    testing_frameworks: [pytest]')
      ..writeln('    cloud_platforms: [AWS]')
      ..writeln('    aws_services: [Lambda, S3]')
      ..writeln('    azure_services: [利用なし]')
      ..writeln('    gcp_services: [利用なし]')
      ..writeln('    container: [Docker]')
      ..writeln('    container_orchestration: [Kubernetes]')
      ..writeln('    ai_services: [Claude]')
      ..writeln('    skills: [Python, ${i.isEven ? 'TypeScript' : 'PHP'}, SQL]')
      ..writeln('    workflow:')
      ..writeln('      requirements: ${i.isEven}')
      ..writeln('      basic_design: true')
      ..writeln('      detailed_design: true')
      ..writeln('      implementation_unit_test: true')
      ..writeln('      integration_test: ${i % 3 == 0}')
      ..writeln('      system_test: false')
      ..writeln('      maintenance_operation: ${i == n}');
  }
  return b.toString();
}

/// Private の案件を [n] 件
String _privateYaml(int n) {
  final b = StringBuffer('projects:\n');
  for (var i = 1; i <= n; i++) {
    b
      ..writeln('  - title: 個人 $i')
      ..writeln('    description: 個人 $i の説明')
      ..writeln('    period: [${2018 + i}-01, ${2018 + i}-06]')
      ..writeln('    link: https://example.com/$i')
      ..writeln('    skills: [Dart, Flutter]')
      ..writeln('    tools: [Git]')
      ..writeln('    cloud_platforms: [Firebase]');
  }
  return b.toString();
}

/// テストのデータ（null はサンプルのまま）
class _Data {
  const _Data(this.name, this.work, this.private);
  final String name;
  final String? work;
  final String? private;
}

final _datasets = [
  const _Data('サンプル', null, null),
  _Data('たくさん（Work 12 件・Private 7 件）', _workYaml(12), _privateYaml(7)),
  _Data('1 件ずつ', _workYaml(1), _privateYaml(1)),
];

const _widths = <String, double>{'スマホ 360': 360, 'タブレット 800': 800, 'PC 1280': 1280};

/// 仮の時間を少しずつ進める（読み込み中の表示など、終わらないアニメーションがあっても止まらないように）
Future<void> _settle(WidgetTester tester, [int frames = 15]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// アプリ本体（main.dart の DevPortfolioApp）と同じく、ThemeController の値でライト / ダークを切り替える
Future<void> _pumpHome(
  WidgetTester tester, {
  double width = 1280,
  bool dark = false,
  String? work,
  String? private,
}) async {
  ThemeController.instance.toggle(dark);
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (work != null) stub.SessionStore.write('work', work);
  if (private != null) stub.SessionStore.write('private', private);
  await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeController.instance,
    builder: (context, mode, _) => MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const HomePage(),
    ),
  ));
  await _settle(tester);
}

/// 画面に出るまでスクロールしてから押す
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first, warnIfMissed: false);
  await _settle(tester);
}

/// 見つかったときだけ押す（画面の幅・データによって出ないボタン用）
Future<bool> _tapIfPresent(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) return false;
  await _tap(tester, finder);
  return true;
}

void main() {
  setUpAll(loadAppFont);

  setUp(() {
    useFileAssets();
    stub.SessionStore.clear();
    WorkYamlLoader.clearCustomYaml();
    PrivateYamlLoader.clearCustomYaml();
    ProfileStore.instance.value = _profile;
  });
  tearDown(() {
    ProfileStore.instance.value = null;
    ThemeController.instance.toggle(false);
  });

  group('描画の組み合わせ（テーマ × 幅 × データ）', () {
    for (final (themeName, dark) in [('ライト', false), ('ダーク', true)]) {
      for (final MapEntry(key: widthName, value: width) in _widths.entries) {
        for (final data in _datasets) {
          testWidgets('$themeName・$widthName・${data.name}', (tester) async {
            await _pumpHome(tester, width: width, dark: dark, work: data.work, private: data.private);
            expect(Theme.of(tester.element(find.byType(HomePage))).brightness, dark ? Brightness.dark : Brightness.light);

            // すべてのセクションがある
            expect(find.text('鈴木 一郎'), findsWidgets);
            expect(find.byType(AboutSection), findsOneWidget);
            expect(find.byType(SkillsSection), findsOneWidget);
            expect(find.byType(ProjectsSection), findsOneWidget);

            // 幅でヘッダーが変わる（600 未満はメニュー、以上はナビのボタン）
            if (width < 600) {
              expect(find.byIcon(Icons.menu), findsOneWidget);
            } else {
              expect(find.byType(HeaderNavButton), findsNWidgets(NavDestination.all.length));
            }

            // 上から下までスクロールして、表示中のセクションの切り替わりも通す
            for (final section in [AboutSection, SkillsSection, ProjectsSection]) {
              await tester.ensureVisible(find.byType(section));
              await _settle(tester, 5);
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('操作（PC 1280・たくさんのデータ）', () {
    Future<void> pump(WidgetTester tester) =>
        _pumpHome(tester, work: _workYaml(12), private: _privateYaml(7));

    testWidgets('ヘッダーのナビで各セクションへ移る', (tester) async {
      await pump(tester);
      for (final d in NavDestination.all) {
        await _tap(tester, find.byWidgetPredicate((w) => w is HeaderNavButton && w.destination == d));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Skills：円グラフ・棒グラフの切替、Work / Private の切替、カテゴリーの選択', (tester) async {
      await pump(tester);
      await _tap(tester, find.byTooltip(AppTexts.chartPieTooltip));
      await _tap(tester, find.byTooltip(AppTexts.chartBarTooltip));
      await _tap(tester, find.text(AppTexts.private)); // 先に出てくるのは Skills の切替
      await _tap(tester, find.text(AppTexts.work));

      await _tap(tester, find.byType(SkillsCategoryButton));
      // 開いたパネル：［キャンセル］で閉じる → もう一度開いて［適用］
      await _tapIfPresent(tester, find.text(AppTexts.cancel));
      await _tap(tester, find.byType(SkillsCategoryButton));
      await _tapIfPresent(tester, find.text(AppTexts.filterApply));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Projects：コレクション / リスト表示、Private、並び替え、ページ送り', (tester) async {
      await pump(tester);
      await _tap(tester, find.byTooltip(AppTexts.viewCollectionTooltip));
      await _tap(tester, find.byTooltip(AppTexts.viewListTooltip));

      // ページ送り（Work 12 件 → 複数ページ）
      expect(await _tapIfPresent(tester, find.byTooltip(AppTexts.paginationNext)), isTrue);
      await _tapIfPresent(tester, find.byTooltip(AppTexts.paginationPrev));

      // 並び替え：すべての並びを選ぶ
      for (final sort in ProjectSort.values) {
        await _tap(tester, find.textContaining(AppTexts.sortCurrent('').trim()));
        await _tap(tester, find.text(sort.label).last);
      }

      await _tap(tester, find.text(AppTexts.private).last); // 後に出てくるのは Projects の切替
      await _tap(tester, find.byTooltip(AppTexts.viewCollectionTooltip));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Projects：フィルターを開いて閉じる・適用する', (tester) async {
      await pump(tester);
      await _tap(tester, find.text(AppTexts.filter));
      await _tapIfPresent(tester, find.text(AppTexts.cancel));
      await _tap(tester, find.text(AppTexts.filter));
      await _tapIfPresent(tester, find.text(AppTexts.filterApply).last);
      expect(tester.takeException(), isNull);
    });

    testWidgets('テーマの切替', (tester) async {
      await pump(tester);
      await _tap(tester, find.byType(Switch));
      expect(ThemeController.instance.value, ThemeMode.dark);
      await _tap(tester, find.byType(Switch));
      expect(ThemeController.instance.value, ThemeMode.light);
    });
  });

  testWidgets('スマホ：メニューから各セクションへ移る（Drawer）', (tester) async {
    await _pumpHome(tester, width: 360, work: _workYaml(3), private: _privateYaml(2));
    for (final d in NavDestination.all) {
      await tester.tap(find.byIcon(Icons.menu));
      await _settle(tester);
      expect(find.byType(NavigationDrawer), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(NavigationDrawer), matching: find.text(d.label)));
      await _settle(tester);
    }
    expect(find.byType(NavigationDrawer), findsNothing); // 選ぶと閉じる
    expect(tester.takeException(), isNull);
  });

  group('異常系', () {
    for (final MapEntry(key: widthName, value: width) in _widths.entries) {
      testWidgets('Work / Private が 0 件でも落ちない（$widthName）', (tester) async {
        await _pumpHome(tester, width: width, work: 'projects: []\n', private: 'projects: []\n');
        for (final section in [SkillsSection, ProjectsSection]) {
          await tester.ensureVisible(find.byType(section));
          await _settle(tester, 5);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('案件の項目がほとんどない（title と workflow だけ）でも落ちない', (tester) async {
      await _pumpHome(
        tester,
        work: 'projects:\n  - title: 項目なし\n    workflow: {}\n',
        private: 'projects:\n  - title: 項目なし\n',
      );
      await tester.ensureVisible(find.byType(ProjectsSection));
      await _settle(tester);
      expect(find.text('項目なし'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('プロフィールがなければ、最初に入力画面を出す', (tester) async {
      ProfileStore.instance.value = null;
      await _pumpHome(tester);
      expect(find.textContaining('あなたのことを教えてください'), findsWidgets);
    });
  });
}
