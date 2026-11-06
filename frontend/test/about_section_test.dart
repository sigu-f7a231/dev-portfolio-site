// About（自己紹介）のテスト
// 対象：lib/sections/about_section.dart
// - 書いた項目だけを出す（全部・一部・最小）。直近 / 過去の開発経験は文章だけ・技術だけ・両方
// - 「領域：説明」の行は領域を太字に
// - 広い画面は「見出し｜説明」を横に、狭い画面は縦に積む。ライト / ダーク
//
// 実行：flutter test test/about_section_test.dart（frontend/ で）
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/sections/about_section.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/profile_store.dart';

import 'test_assets.dart';

const _full = Profile(
  name: '鈴木 一郎',
  role: 'エンジニア',
  tagline: '紹介文',
  intro: '自己紹介です',
  domains: ['Web', 'モバイル'],
  recent: '領域：Web アプリの開発\nただの行\n\n  \n',
  recentTech: {
    '言語': ['Dart', 'Go'],
    'DB': ['MySQL'],
  },
  past: '過去：業務システム',
  pastTech: {
    '言語': ['Java'],
  },
  strengths: '強みです',
  style: '開発スタイルです',
  closing: '締めの一言です',
);

const _minimal = Profile(name: '鈴木 一郎', role: 'エンジニア', tagline: '紹介文', intro: '自己紹介だけ');

const _rowLabels = [
  AboutContent.domainsLabel,
  AboutContent.recentLabel,
  AboutContent.pastLabel,
  AboutContent.strengthsLabel,
  AboutContent.styleLabel,
];

Future<void> _pump(WidgetTester tester, Profile? profile, {double width = 1280, bool dark = false}) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ProfileStore.instance.value = profile;
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: const Scaffold(body: SingleChildScrollView(child: AboutSection())),
  ));
  await tester.pump();
}

void main() {
  setUpAll(loadAppFont);
  tearDown(() => ProfileStore.instance.value = null);

  group('書いた項目だけを出す', () {
    testWidgets('全部書いたとき：5 つの行と締めの一言', (tester) async {
      await _pump(tester, _full);
      for (final label in _rowLabels) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('自己紹介です'), findsOneWidget);
      for (final t in ['Web', 'モバイル', 'Dart', 'Go', 'MySQL', 'Java', '強みです', '開発スタイルです', '締めの一言です']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      // 行は書かれた順（得意な領域 → 直近 → 過去 → 強み → 開発スタイル）
      final tops = [for (final l in _rowLabels) tester.getTopLeft(find.text(l)).dy];
      expect(tops, orderedEquals([...tops]..sort()));
    });

    testWidgets('自己紹介だけのとき：行も締めの一言も出さない', (tester) async {
      await _pump(tester, _minimal);
      expect(find.text('自己紹介だけ'), findsOneWidget);
      for (final label in _rowLabels) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    testWidgets('1 つだけ（得意な領域）', (tester) async {
      await _pump(tester, const Profile(name: 'a', role: 'b', tagline: 'c', intro: 'd', domains: ['Web']));
      expect(find.text(AboutContent.domainsLabel), findsOneWidget);
      expect(find.text(AboutContent.strengthsLabel), findsNothing);
    });

    testWidgets('開発経験：技術だけ（文章なし）・文章だけ（技術なし）', (tester) async {
      await _pump(
        tester,
        const Profile(
          name: 'a',
          role: 'b',
          tagline: 'c',
          intro: 'd',
          recentTech: {
            '言語': ['Rust'],
          },
          past: '文章だけの経験',
        ),
      );
      expect(find.text(AboutContent.recentLabel), findsOneWidget);
      expect(find.text('Rust'), findsOneWidget);
      expect(find.text(AboutContent.pastLabel), findsOneWidget);
      expect(find.text('文章だけの経験'), findsOneWidget);
    });

    testWidgets('プロフィールがまだない（null）でも落ちない', (tester) async {
      await _pump(tester, null);
      expect(find.byType(AboutSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('開発経験の行の書き方', () {
    testWidgets('「領域：説明」は領域までを太字、それ以外の行はそのまま。空の行は出さない', (tester) async {
      await _pump(tester, _full);
      final labeled = tester.widget<Text>(find.text('領域：Web アプリの開発'));
      final span = labeled.textSpan! as TextSpan;
      final head = span.children!.first as TextSpan;
      expect(head.text, '領域：');
      expect(head.style!.fontWeight, FontWeight.w600);

      final plain = tester.widget<Text>(find.text('ただの行'));
      expect((plain.textSpan! as TextSpan).children, isNull);
    });

    testWidgets('半角の「:」でも領域として扱う', (tester) async {
      await _pump(tester, const Profile(name: 'a', role: 'b', tagline: 'c', intro: 'd', recent: 'Web: 開発'));
      final t = tester.widget<Text>(find.text('Web: 開発'));
      expect(((t.textSpan! as TextSpan).children!.first as TextSpan).text, 'Web:');
    });
  });

  group('画面の幅とテーマ', () {
    testWidgets('広い画面：見出しと説明を横に並べる', (tester) async {
      await _pump(tester, _full, width: 1280);
      final term = tester.getRect(find.text(AboutContent.strengthsLabel));
      final body = tester.getRect(find.text('強みです'));
      expect(body.left, greaterThanOrEqualTo(term.right)); // 見出しは固定幅の枠なので、説明はその右端から始まる
      expect(body.top, closeTo(term.top, 8));
    });

    testWidgets('狭い画面：見出しの下に説明', (tester) async {
      await _pump(tester, _full, width: 360);
      final term = tester.getRect(find.text(AboutContent.strengthsLabel));
      final body = tester.getRect(find.text('強みです'));
      expect(body.top, greaterThanOrEqualTo(term.bottom));
      expect(tester.takeException(), isNull);
    });

    for (final width in [360.0, 1280.0]) {
      testWidgets('ダーク（幅 $width）でも全部の項目を描ける', (tester) async {
        await _pump(tester, _full, width: width, dark: true);
        expect(find.text('締めの一言です'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
