// 案件の詳細ダイアログ：‹ › で前後の案件に移るテスト
// 対象：lib/sections/projects/views/project_list/project_list_modal_function.dart
//
// 実行：flutter test test/project_detail_navigation_test.dart（dev_portfolio/ で）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/config/projects/projects_views_list_config.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/sections/projects/views/project_list/project_list_modal_function.dart';
import 'package:dev_portfolio/theme/app_theme.dart';

final _projects = [
  for (final t in ['案件A', '案件B', '案件C'])
    Project.fromMap({
      'title': t,
      'description': '$t の説明',
      'period': ['2024-01', '2024-03'],
    }),
];

/// 画面の大きさを決める（幅 1024 以上は PC のダイアログ＋左右の ‹ ›、未満は全画面＋下の ‹ ›）
void _setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 詳細を開くボタンだけの画面。閉じたときの位置を [onClosed] で受け取る
Future<void> _open(
  WidgetTester tester, {
  required int index,
  required ValueChanged<int> onClosed,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onClosed(await showProjectDetailModal(
            context,
            _projects[index],
            projects: _projects,
          )),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await _settle(tester);
}

/// 描画が落ち着くまで（SettledReveal の最低表示時間を含めて）時間を進める
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

IconButton _iconButton(WidgetTester tester, IconData icon) => tester.widget<IconButton>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
    );

// TextButton.icon は TextButton のサブクラスなので、byType ではなく型で判定する
TextButton _textButton(WidgetTester tester, String label) => tester.widget<TextButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is TextButton),
      ),
    );

void main() {
  group('PC 幅（ダイアログ、‹ › は左右）', () {
    testWidgets('ダイアログの幅は最大幅まで（画面いっぱいにはしない）、文字の倍率はそのまま', (tester) async {
      _setScreen(tester, const Size(1400, 900));
      await _open(tester, index: 0, onClosed: (_) {});

      final surface = find.ancestor(
        of: find.text('案件A'),
        matching: find.byWidgetPredicate((w) => w is Material && w.color != null),
      ).first;
      expect(tester.getSize(surface).width, ProjectsListConfig.modalMaxWidth);
      expect(MediaQuery.textScalerOf(tester.element(find.text('案件A'))).scale(10), 10);
      expect(find.byTooltip(AppTexts.nextProject), findsOneWidget);
    });

    testWidgets('次へ・前へで案件が切り替わり、位置（n / 全件）も変わる', (tester) async {
      _setScreen(tester, const Size(1200, 900));
      await _open(tester, index: 0, onClosed: (_) {});

      expect(find.text('案件A'), findsOneWidget);
      expect(find.text(AppTexts.projectPosition(1, 3)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await _settle(tester);
      expect(find.text('案件B'), findsOneWidget);
      expect(find.text('案件A'), findsNothing);
      expect(find.text(AppTexts.projectPosition(2, 3)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await _settle(tester);
      expect(find.text('案件A'), findsOneWidget);
    });

    testWidgets('最初の案件では「前」、最後の案件では「次」を押せない', (tester) async {
      _setScreen(tester, const Size(1200, 900));
      await _open(tester, index: 0, onClosed: (_) {});

      expect(_iconButton(tester, Icons.chevron_left).onPressed, isNull);
      expect(_iconButton(tester, Icons.chevron_right).onPressed, isNotNull);
      expect(find.byTooltip(AppTexts.noPrevProject), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await _settle(tester);

      expect(find.text('案件C'), findsOneWidget);
      expect(_iconButton(tester, Icons.chevron_left).onPressed, isNotNull);
      expect(_iconButton(tester, Icons.chevron_right).onPressed, isNull);
      expect(find.byTooltip(AppTexts.noNextProject), findsOneWidget);
    });

    testWidgets('← → キーでも移れ、端ではそれ以上進まない', (tester) async {
      _setScreen(tester, const Size(1200, 900));
      await _open(tester, index: 1, onClosed: (_) {});
      expect(find.text('案件B'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _settle(tester);
      expect(find.text('案件C'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // 最後なので変わらない
      await _settle(tester);
      expect(find.text('案件C'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await _settle(tester);
      expect(find.text('案件B'), findsOneWidget);
    });

    testWidgets('閉じると、最後に見ていた案件の位置を返す', (tester) async {
      _setScreen(tester, const Size(1200, 900));
      int? closedAt;
      await _open(tester, index: 0, onClosed: (i) => closedAt = i);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await _settle(tester);
      await tester.tap(find.byTooltip(AppTexts.close));
      await _settle(tester);

      expect(find.text('案件B'), findsNothing); // 閉じた
      expect(closedAt, 1);
    });
  });

  group('タブレット・スマホ幅（全画面、‹ › は下）', () {
    for (final (name, size) in [
      ('タブレット', const Size(820, 1180)),
      ('スマホ', const Size(390, 844)),
    ]) {
      testWidgets('$name：画面いっぱいに開き、文字が一回り大きくなる', (tester) async {
        _setScreen(tester, size);
        await _open(tester, index: 0, onClosed: (_) {});

        // 画面いっぱい（タイトルを含む面の幅が画面幅と同じ）
        final surface = find.ancestor(
          of: find.text('案件A'),
          matching: find.byWidgetPredicate((w) => w is Material && w.color != null),
        ).first;
        expect(tester.getSize(surface).width, size.width);
        expect(tester.getSize(surface).height, size.height);

        // 文字の倍率（端末の設定 1.0 × 全画面の倍率）
        final scaler = MediaQuery.textScalerOf(tester.element(find.text('案件A')));
        expect(scaler.scale(10), closeTo(10 * ProjectsListConfig.fullscreenTextScale, 0.001));

        // ‹ › は下（左右の丸いボタンは出ない）
        expect(find.text(AppTexts.prevShort), findsOneWidget);
        expect(find.text(AppTexts.nextShort), findsOneWidget);
        expect(find.byTooltip(AppTexts.nextProject), findsNothing);
      });
    }

    testWidgets('［前へ］［次へ］で移れ、端では押せない', (tester) async {
      _setScreen(tester, const Size(390, 844));
      await _open(tester, index: 0, onClosed: (_) {});

      expect(_textButton(tester, AppTexts.prevShort).onPressed, isNull);
      expect(_textButton(tester, AppTexts.nextShort).onPressed, isNotNull);

      await tester.tap(find.text(AppTexts.nextShort));
      await _settle(tester);
      expect(find.text('案件B'), findsOneWidget);
      expect(_textButton(tester, AppTexts.prevShort).onPressed, isNotNull);
    });
  });

  testWidgets('案件が 1 件だけなら ‹ › も位置も出さない', (tester) async {
    _setScreen(tester, const Size(1200, 900));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showProjectDetailModal(context, _projects[0]),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await _settle(tester);

    expect(find.text('案件A'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.text(AppTexts.projectPosition(1, 1)), findsNothing);
  });
}
