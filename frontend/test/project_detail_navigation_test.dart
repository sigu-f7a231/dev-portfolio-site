// 案件の詳細ダイアログ：‹ › で前後の案件に移るテスト
// 対象：lib/sections/projects/views/project_list/project_list_modal_function.dart
//
// 実行：flutter test test/project_detail_navigation_test.dart（frontend/ で）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/config/projects/projects_views_list_config.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/sections/projects/views/project_list/project_list_modal_function.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/platform_keys.dart';

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
  // 表示の大きさは次に開いたときも引き継ぐので、テストごとに元に戻す
  tearDown(ProjectDetailView.reset);

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

  group('画面共有向けの表示の大きさ', () {
    double scale(WidgetTester tester) =>
        MediaQuery.textScalerOf(tester.element(find.text('案件A'))).scale(10) / 10;

    testWidgets('PC：A＋ で文字とダイアログが大きくなり、100% を押すと戻る', (tester) async {
      _setScreen(tester, const Size(1600, 1200));
      await _open(tester, index: 0, onClosed: (_) {});
      expect(find.text(AppTexts.zoomPercent(100)), findsOneWidget);
      expect(_iconButton(tester, Icons.text_decrease).onPressed, isNull); // いちばん小さい

      await tester.tap(find.byTooltip(AppTexts.zoomIn(shortcutModifierLabel)));
      await _settle(tester);
      final zoom = ProjectsListConfig.modalZoomLevels[1];
      expect(scale(tester), closeTo(zoom, 0.001));
      expect(find.text(AppTexts.zoomPercent((zoom * 100).round())), findsOneWidget);
      final surface = find.ancestor(of: find.text('案件A'), matching: find.byType(Material)).first;
      expect(tester.getSize(surface).width, closeTo(ProjectsListConfig.modalMaxWidth * zoom, 0.5));

      await tester.tap(find.text(AppTexts.zoomPercent((zoom * 100).round())));
      await _settle(tester);
      expect(scale(tester), 1);
    });

    testWidgets('PC：キーボードの ＋ − でも変えられる', (tester) async {
      _setScreen(tester, const Size(1600, 1200));
      await _open(tester, index: 0, onClosed: (_) {});
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await _settle(tester);
      expect(scale(tester), closeTo(ProjectsListConfig.modalZoomLevels[1], 0.001));
      await tester.sendKeyEvent(LogicalKeyboardKey.minus);
      await _settle(tester);
      expect(scale(tester), 1);
    });

    testWidgets('PC：「大きく表示」で画面いっぱいになり、次に開いたときも引き継ぐ', (tester) async {
      const size = Size(1400, 900);
      _setScreen(tester, size);
      await _open(tester, index: 0, onClosed: (_) {});
      await tester.tap(find.byTooltip(AppTexts.largeView));
      await _settle(tester);

      final surface = find.ancestor(of: find.text('案件A'), matching: find.byType(Material)).first;
      expect(tester.getSize(surface), size);
      expect(scale(tester), closeTo(ProjectsListConfig.fullscreenTextScale, 0.001));
      expect(find.byTooltip(AppTexts.normalView(shortcutModifierLabel)), findsOneWidget);

      await tester.tap(find.byTooltip(AppTexts.close));
      await _settle(tester);
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(find.byTooltip(AppTexts.normalView(shortcutModifierLabel)), findsOneWidget, reason: '次に開いたときも大きく表示');
    });

    testWidgets('スマホ：「大きく表示」は出さない（いつも全画面）が、文字の大きさは変えられる', (tester) async {
      _setScreen(tester, const Size(390, 844));
      await _open(tester, index: 0, onClosed: (_) {});
      expect(find.byTooltip(AppTexts.largeView), findsNothing);
      await tester.tap(find.byTooltip(AppTexts.zoomIn(shortcutModifierLabel)));
      await _settle(tester);
      expect(scale(tester), closeTo(ProjectsListConfig.modalZoomLevels[2], 0.001)); // 1.15 の次
    });
  
    // Mac は ⌘、Windows などは Ctrl
    for (final (name, platform, key) in [
      ('Mac', TargetPlatform.macOS, LogicalKeyboardKey.metaLeft),
      ('Windows', TargetPlatform.windows, LogicalKeyboardKey.controlLeft),
    ]) {
      testWidgets('$name：${name == 'Mac' ? '⌘' : 'Ctrl'} ＋ 0 で文字の大きさも大きく表示も元に戻す', variant: TargetPlatformVariant.only(platform), (tester) async {
        expect(shortcutModifierLabel, name == 'Mac' ? '⌘' : 'Ctrl');
        _setScreen(tester, const Size(1400, 900));
        await _open(tester, index: 0, onClosed: (_) {});

        await tester.tap(find.byTooltip(AppTexts.largeView));
        await _settle(tester);
        await tester.tap(find.byTooltip(AppTexts.zoomIn(shortcutModifierLabel)));
        await _settle(tester);
        expect(ProjectDetailView.large, isTrue);
        expect(ProjectDetailView.zoom, isNotNull);

        // 修飾キー ＋ ＋（=）でも大きくなる
        final before = ProjectDetailView.zoom!;
        await tester.sendKeyDownEvent(key);
        await tester.sendKeyEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(key);
        await _settle(tester);
        expect(ProjectDetailView.zoom, greaterThan(before));

        await tester.sendKeyDownEvent(key);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
        await tester.sendKeyUpEvent(key);
        await _settle(tester);
        expect(ProjectDetailView.large, isFalse);
        expect(ProjectDetailView.zoom, isNull);
        expect(scale(tester), 1);
      });
    }
  });
}
