// Home（Hero）のテスト：中央寄せ・ボタンの下のまとめ（開発経験・プロジェクトの件数・直近のプロジェクト）
// 対象：lib/sections/hero_section.dart・lib/utils/hero_summary.dart
//
// 実行：flutter test test/hero_section_test.dart（dev_portfolio/ で）
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/sections/hero_section.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/hero_summary.dart';
import 'package:dev_portfolio/utils/profile_store.dart';

import 'test_assets.dart';

Project _p(String title, List<String>? period) =>
    Project.fromMap({'title': title, if (period != null) 'period': period});

const _work = '''
projects:
  - title: 最初の業務
    period: [2019-07, 2019-12]
    workflow: {requirements: true}
  - title: 今の業務
    period: [2026-03, 現在]
    workflow: {requirements: true}
''';

const _private = '''
projects:
  - title: 個人アプリ
    period: [2024-01, 2024-06]
''';

const _profile = Profile(name: '鈴木 一郎', role: 'Web エンジニア', tagline: '紹介文です', intro: '自己紹介');

void main() {
  group('まとめの中身（HeroSummary）', () {
    final now = DateTime(2026, 11, 5);

    test('開発経験：業務のいちばん古い開始から今日まで', () {
      final s = HeroSummary.of(
        [_p('a', ['2019-07', '2019-12']), _p('b', ['2021-01', '現在'])],
        [_p('c', ['2015-01', '2015-03'])], // 個人開発は、業務があれば数えない
        now: now,
      );
      expect(s.since, DateTime(2019, 7));
      expect(s.experienceMonths, 7 * 12 + 5); // 2019/7〜2026/11
      expect(AppTexts.durationLabel(s.experienceMonths), '7年5か月');
    });

    test('業務がなければ、個人開発のいちばん古い開始から', () {
      final s = HeroSummary.of(const [], [_p('c', ['2025-11', '2026-01'])], now: now);
      expect(s.since, DateTime(2025, 11));
      expect(s.experienceMonths, 13);
    });

    test('件数は期間がなくても数える。直近は開始がいちばん新しいもの（Private も）', () {
      final s = HeroSummary.of(
        [_p('古い', ['2020-01', '2020-06']), _p('期間なし', null)],
        [_p('新しい個人', ['2025-04', '現在'])],
        now: now,
      );
      expect(s.workCount, 2);
      expect(s.privateCount, 1);
      expect(s.totalCount, 3);
      expect(s.latest!.title, '新しい個人');
      expect(s.latestIsPrivate, isTrue);
    });

    test('開始が同じなら Work を直近にする', () {
      final s = HeroSummary.of(
          [_p('業務', ['2025-04', '2025-09'])], [_p('個人', ['2025-04', '2025-05'])], now: now);
      expect(s.latest!.title, '業務');
      expect(s.latestIsPrivate, isFalse);
    });

    test('案件がなければ空。期間の読めるものがなければ開発経験・直近なし', () {
      expect(HeroSummary.of(const [], const [], now: now).isEmpty, isTrue);
      final s = HeroSummary.of([_p('期間なし', null)], const [], now: now);
      expect(s.isEmpty, isFalse);
      expect(s.since, isNull);
      expect(s.experienceMonths, 0);
      expect(s.latest, isNull);
    });
  });

  group('Home の画面', () {
    setUp(useFileAssets);
    setUp(() {
      stub.SessionStore.clear();
      ProfileStore.instance.value = _profile;
    });
    tearDown(() => ProfileStore.instance.value = null);

    Future<void> pump(WidgetTester tester, {double width = 1280, VoidCallback? onProjects}) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HeroSection(onSkillsPressed: () {}, onProjectsPressed: onProjects),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('名前・紹介文・ボタンは中央寄せ。右側の YAML 風のカードは出さない', (tester) async {
      stub.SessionStore.write('work', _work);
      await pump(tester);
      final center = tester.getSize(find.byType(HeroSection)).width / 2;
      for (final text in ['鈴木 一郎', '紹介文です', HeroContent.skillsButtonLabel]) {
        final rect = tester.getRect(find.text(text));
        if (text == HeroContent.skillsButtonLabel) {
          // ボタンは 2 つ並びの中央
          final both = tester.getRect(find.text(HeroContent.skillsButtonLabel))
              .expandToInclude(tester.getRect(find.text(HeroContent.projectsButtonLabel)));
          expect(both.center.dx, closeTo(center, 40));
        } else {
          expect(rect.center.dx, closeTo(center, 2), reason: text);
        }
      }
      expect(find.textContaining('stack:'), findsNothing);
    });

    testWidgets('ボタンの下に、開発経験・プロジェクトの件数・直近のプロジェクト', (tester) async {
      stub.SessionStore.write('work', _work);
      stub.SessionStore.write('private', _private);
      await pump(tester);
      expect(find.text(HeroContent.summaryExperience), findsOneWidget);
      expect(find.text(HeroContent.experienceSince(DateTime(2019, 7))), findsOneWidget);
      expect(find.text(HeroContent.summaryProjects), findsOneWidget);
      expect(find.text(HeroContent.projectsCount(3)), findsOneWidget);
      expect(find.text(HeroContent.projectsBreakdown(2, 1)), findsOneWidget);
      expect(find.text(HeroContent.summaryLatest), findsOneWidget);
      expect(find.text('今の業務'), findsOneWidget);
      expect(find.textContaining(AppTexts.periodNow), findsOneWidget);

      // ボタンより下にある
      final buttons = tester.getRect(find.text(HeroContent.skillsButtonLabel));
      expect(tester.getRect(find.text(HeroContent.summaryProjects)).top, greaterThan(buttons.bottom));
    });

    testWidgets('幅があれば 3 つを横に、狭ければ縦に並べる', (tester) async {
      stub.SessionStore.write('work', _work);
      await pump(tester, width: 1280);
      final a = tester.getRect(find.text(HeroContent.summaryExperience));
      final b = tester.getRect(find.text(HeroContent.summaryProjects));
      expect(a.top, closeTo(b.top, 1));
      expect(b.left, greaterThan(a.right));

      await pump(tester, width: 400);
      final c = tester.getRect(find.text(HeroContent.summaryExperience));
      final d = tester.getRect(find.text(HeroContent.summaryProjects));
      expect(d.top, greaterThan(c.bottom));
    });

    testWidgets('プロジェクトの件数を押すと Projects へ。直近のプロジェクトを押すと、その詳細', (tester) async {
      stub.SessionStore.write('work', _work);
      var toProjects = 0;
      await pump(tester, onProjects: () => toProjects++);
      await tester.tap(find.text(HeroContent.summaryProjects));
      await tester.pump();
      expect(toProjects, 1);

      await tester.tap(find.text('今の業務'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('今の業務'), findsAtLeastNWidgets(2)); // まとめ＋詳細の見出し
    });

    testWidgets('［データ］で案件が変わったら（refreshKey）、まとめを作り直す', (tester) async {
      stub.SessionStore.write('work', _work);
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget app(int key) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: SingleChildScrollView(child: HeroSection(refreshKey: key))),
          );
      await tester.pumpWidget(app(0));
      await tester.pumpAndSettle();
      expect(find.text(HeroContent.projectsCount(2 + 1)), findsOneWidget); // Private はサンプル 1 件

      stub.SessionStore.write('work', 'projects:\n  - title: 1 件だけ\n    workflow: {}\n');
      await tester.pumpWidget(app(1));
      await tester.pumpAndSettle();
      expect(find.text(HeroContent.projectsCount(1 + 1)), findsOneWidget);
    });
  });
}
