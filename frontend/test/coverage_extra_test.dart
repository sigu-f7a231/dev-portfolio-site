// 網羅しきれていなかった分岐の正常系・異常系
// 対象：
//   lib/sections/projects/pagination/projects_pagination_ui.dart（ページ番号の出し方）
//   lib/utils/app_ready.dart（起動時の読み込み・準備できた知らせ）
//   lib/utils/profile_store.dart（起動時に YAML を指定したとき）
//   lib/sections/projects/views/project_list/project_list_modal_function.dart（詳細：拡大の上限・下限、キー操作、下の ‹ ›、公開ページ、技術のグループ）
//
// 実行：flutter test test/coverage_extra_test.dart（frontend/ で）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/config/projects/projects_views_list_config.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/sections/projects/pagination/projects_pagination_ui.dart';
import 'package:dev_portfolio/sections/projects/views/project_list/project_list_modal_function.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/app_ready.dart';
import 'package:dev_portfolio/utils/asset_text.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/platform_keys.dart';
import 'package:dev_portfolio/utils/private_yaml_loader.dart';
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/utils/tech_catalog.dart';
import 'package:dev_portfolio/utils/work_yaml_loader.dart';

import 'test_assets.dart';

const _profileYaml = '''
home:
  name: 起動 太郎
  role: エンジニア
  tagline: 紹介文
about:
  intro: 自己紹介
''';

void _screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUpAll(loadAppFont);

  // ------------------------------------------------------------
  group('ページ番号の出し方', () {
    /// 表示中のページ番号と「…」を左から順に（「…」は null）
    List<int?> visible(WidgetTester tester) {
      final items = <(double, int?)>[];
      for (final e in find.byType(Text).evaluate()) {
        final t = (e.widget as Text).data;
        final x = tester.getTopLeft(find.byWidget(e.widget)).dx;
        if (t == AppTexts.paginationEllipsis) items.add((x, null));
        if (t != null && int.tryParse(t) != null) items.add((x, int.parse(t)));
      }
      items.sort((a, b) => a.$1.compareTo(b.$1));
      return [for (final i in items) i.$2];
    }

    Future<List<int>> pump(WidgetTester tester, {required int current, required int total, double width = 600}) async {
      _screen(tester, Size(width, 400));
      final changed = <int>[];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProjectsPaginationUI(currentPage: current, totalPages: total, onPageChanged: changed.add),
        ),
      ));
      return changed;
    }

    testWidgets('1 ページだけなら何も出さない', (tester) async {
      await pump(tester, current: 1, total: 1);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('収まるならすべての番号', (tester) async {
      await pump(tester, current: 2, total: 5);
      expect(visible(tester), [1, 2, 3, 4, 5]);
    });

    // 幅 600：番号は 10 枠（両端・「…」を含む）
    for (final (current, expected) in [
      (1, [1, 2, 3, 4, 5, 6, 7, 8, null, 20]), // 先頭寄り：「…」は右だけ
      (10, [1, null, 7, 8, 9, 10, 11, 12, null, 20]), // 真ん中：「…」は両側
      (20, [1, null, 13, 14, 15, 16, 17, 18, 19, 20]), // 末尾寄り：「…」は左だけ
    ]) {
      testWidgets('20 ページの $current ページ目 → $expected', (tester) async {
        await pump(tester, current: current, total: 20);
        expect(visible(tester), expected);
      });
    }

    testWidgets('かなり狭いと「‹ 3 / 20 ›」の形', (tester) async {
      await pump(tester, current: 3, total: 20, width: 300);
      expect(find.text(AppTexts.paginationCompact(3, 20)), findsOneWidget);
      expect(find.text(AppTexts.paginationEllipsis), findsNothing);
    });

    testWidgets('番号・‹ › を押すとそのページへ。端の ‹ › は押せない', (tester) async {
      var changed = await pump(tester, current: 10, total: 20);
      // 1 回押すごとに確かめる（どれが届かないかを分かるように）
      Future<void> tapAndExpect(Finder f, List<int> expected, String what) async {
        expect(f, findsOneWidget, reason: what);
        await tester.tap(f);
        await tester.pump(const Duration(milliseconds: 500));
        expect(changed, expected, reason: what);
      }

      await tapAndExpect(find.text('11'), [11], '番号 11');
      await tapAndExpect(find.byIcon(Icons.chevron_left), [11, 9], '‹（前のページ）');
      await tapAndExpect(find.byIcon(Icons.chevron_right), [11, 9, 11], '›（次のページ）');
      await tapAndExpect(find.text('10'), [11, 9, 11], '今のページ（押しても変わらない）');

      changed = await pump(tester, current: 1, total: 20);
      await tester.tap(find.byTooltip(AppTexts.paginationPrev));
      expect(changed, isEmpty);
      changed = await pump(tester, current: 20, total: 20, width: 300);
      await tester.tap(find.byTooltip(AppTexts.paginationNext));
      expect(changed, isEmpty);
    });

    // スマホでは Material のボタンが当たり判定を広げるので、番号の数の計算とずれてはみ出していた（直した不具合）
    testWidgets('スマホ（Android / iOS）でも、どの幅・どの位置ではみ出さず › が画面内にある', variant: TargetPlatformVariant.mobile(), (tester) async {
      for (final width in [320.0, 360.0, 414.0, 600.0, 800.0, 1280.0]) {
        for (final current in [1, 2, 5, 10, 16, 19, 20]) {
          await pump(tester, current: current, total: 20, width: width);
          expect(tester.takeException(), isNull, reason: '幅 $width・$current ページ目');
          final next = tester.getRect(find.byIcon(Icons.chevron_right));
          expect(next.right, lessThanOrEqualTo(width), reason: '幅 $width・$current ページ目');
        }
      }
    });

    testWidgets('ダークでも描ける', (tester) async {
      _screen(tester, const Size(600, 400));
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: ProjectsPaginationUI(currentPage: 5, totalPages: 9, onPageChanged: (_) {})),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  // ------------------------------------------------------------
  group('起動時の読み込み（AppReady）・起動時に YAML を指定したとき（ProfileStore）', () {
    setUp(() {
      useFileAssets();
      stub.SessionStore.clear();
      stub.dispatchedEvents.clear();
      WorkYamlLoader.clearCustomYaml();
      PrivateYamlLoader.clearCustomYaml();
      ProfileStore.instance.value = null;
      ProfileStore.instance.startupErrors = const [];
    });
    tearDown(() {
      ProfileStore.fromArg = false;
      ProfileStore.instance.value = null;
      ProfileStore.instance.startupErrors = const [];
    });

    test('正常系：preload でセッションのプロフィールを読み込む', () async {
      stub.SessionStore.write(ProfileStore.sessionKey, _profileYaml);
      await AppReady.preload();
      expect(ProfileStore.instance.value?.name, '起動 太郎');
    });

    test('異常系：読み込みに失敗しても preload はエラーにしない', () async {
      loadAssetText = (_) => Future.error(Exception('読めない'));
      await expectLater(AppReady.preload(), completes);
      expect(ProfileStore.instance.value, isNull);
    });

    testWidgets('描画が落ち着いたら、準備できたことをブラウザに知らせる', (tester) async {
      await tester.pumpWidget(const SizedBox());
      AppReady.notifyWhenSettled();
      expect(stub.dispatchedEvents, isEmpty, reason: 'すぐには送らない');
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(stub.dispatchedEvents, [AppReady.eventName]);
    });

    test('起動時に指定：正しいプロフィールなら、それを使う（セッションより優先）', () async {
      ProfileStore.fromArg = true;
      stub.SessionStore.write(ProfileStore.sessionKey, _profileYaml.replaceFirst('起動 太郎', 'セッション 花子'));
      loadAssetText = (path) async => path == ProfileStore.assetPath ? _profileYaml : '';
      await ProfileStore.instance.load();
      expect(ProfileStore.instance.value?.name, '起動 太郎');
      expect(ProfileStore.instance.startupErrors, isEmpty);
    });

    test('起動時に指定：中身が正しくなければ理由を残し、セッションのものを使う', () async {
      ProfileStore.fromArg = true;
      stub.SessionStore.write(ProfileStore.sessionKey, _profileYaml);
      loadAssetText = (_) async => 'home:\n  name: 名前だけ\n';
      await ProfileStore.instance.load();
      expect(ProfileStore.instance.startupErrors, isNotEmpty);
      expect(ProfileStore.instance.value?.name, '起動 太郎');
    });

    test('起動時に指定：ファイルがなければ、その理由を残す', () async {
      ProfileStore.fromArg = true;
      loadAssetText = (_) => Future.error(Exception('ファイルがありません'));
      await ProfileStore.instance.load();
      expect(ProfileStore.instance.startupErrors.single, contains('ファイルがありません'));
      expect(ProfileStore.instance.value, isNull);
    });

    test('起動時に指定：一緒に指定した Work / Private を読む。なければ null', () async {
      ProfileStore.fromArg = true;
      loadAssetText = (path) async {
        if (path == ProfileStore.workAssetPath) return 'projects:\n  - title: 起動の業務\n';
        throw Exception('ない');
      };
      expect(await ProfileStore.startupProjects('work'), contains('起動の業務'));
      expect(await ProfileStore.startupProjects('private'), isNull);
      expect(await WorkYamlLoader.loadYamlString(), contains('起動の業務'));
    });

    test('異常系：セッションのプロフィールが壊れていれば使わない', () async {
      stub.SessionStore.write(ProfileStore.sessionKey, 'home: [');
      await ProfileStore.instance.load();
      expect(ProfileStore.instance.value, isNull);
    });
  });

  // ------------------------------------------------------------
  group('案件の詳細', () {
    tearDown(ProjectDetailView.reset);

    final projects = [
      for (final t in ['案件A', '案件B', '案件C'])
        Project.fromMap({
          'title': t,
          'description': '$t の説明',
          'period': ['2024-01', '2024-03'],
          'link': t == '案件A' ? 'https://example.com/a' : '',
          'skills': ['Python', 'HTML', '利用なし'],
          'tools': ['Git', 'VS Code'],
        }),
    ];

    Future<void> open(WidgetTester tester, {int index = 0, Size size = const Size(1600, 1200)}) async {
      _screen(tester, size);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showProjectDetailModal(context, projects[index], projects: projects),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await _settle(tester);
    }

    IconButton iconButton(WidgetTester tester, String tooltip) => tester.widget<IconButton>(
          find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)).first,
        );

    testWidgets('いちばん大きくすると［A＋］、いちばん小さくすると［A−］を押せない', (tester) async {
      await open(tester);
      final zoomIn = AppTexts.zoomIn(shortcutModifierLabel);
      final zoomOut = AppTexts.zoomOut(shortcutModifierLabel);
      expect(iconButton(tester, zoomOut).onPressed, isNull, reason: 'はじめは 100% でいちばん小さい');

      for (var i = 0; i < ProjectsListConfig.modalZoomLevels.length; i++) {
        if (iconButton(tester, zoomIn).onPressed == null) break;
        await tester.tap(find.byTooltip(zoomIn));
        await _settle(tester);
      }
      expect(ProjectDetailView.zoom, ProjectsListConfig.modalZoomLevels.last);
      expect(iconButton(tester, zoomIn).onPressed, isNull);

      while (iconButton(tester, zoomOut).onPressed != null) {
        await tester.tap(find.byTooltip(zoomOut));
        await _settle(tester);
      }
      expect(ProjectDetailView.zoom, ProjectsListConfig.modalZoomLevels.first);
    });

    testWidgets('キー操作：修飾キー ＋ テンキー・＋・；（JIS の＋）・−、0 だけで文字の大きさを戻す、F で大きく表示', (tester) async {
      await open(tester);
      final mod = isApplePlatform ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft;
      Future<void> withMod(LogicalKeyboardKey key, {bool shift = false}) async {
        await tester.sendKeyDownEvent(mod);
        if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(key);
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(mod);
        await _settle(tester);
      }

      final levels = ProjectsListConfig.modalZoomLevels;
      var expected = 0;
      for (final (key, shift) in [
        (LogicalKeyboardKey.numpadAdd, false),
        (LogicalKeyboardKey.semicolon, false),
        (LogicalKeyboardKey.semicolon, true),
        (LogicalKeyboardKey.equal, true),
      ]) {
        await withMod(key, shift: shift);
        expected++;
        expect(ProjectDetailView.zoom, levels[expected], reason: '$key shift=$shift');
      }
      await withMod(LogicalKeyboardKey.numpadSubtract);
      expect(ProjectDetailView.zoom, levels[expected - 1]);
      await withMod(LogicalKeyboardKey.numpad0);
      expect(ProjectDetailView.zoom, isNull);

      // 修飾キーなしの 0 は文字の大きさだけ戻す（大きく表示はそのまま）
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await _settle(tester);
      expect(ProjectDetailView.large, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
      await _settle(tester);
      expect(ProjectDetailView.zoom, isNull);
      expect(ProjectDetailView.large, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await _settle(tester);
      expect(ProjectDetailView.large, isFalse);
    });

    testWidgets('大きく表示では ‹ › を下に出す。最初の案件は［前へ］、最後の案件は［次へ］を押せない', (tester) async {
      await open(tester, size: const Size(1400, 900));
      await tester.tap(find.byTooltip(AppTexts.largeView));
      await _settle(tester);

      ButtonStyleButton bottom(String label) => tester.widget<ButtonStyleButton>(
            find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)).first,
          );
      expect(bottom(AppTexts.prevShort).onPressed, isNull);
      await tester.tap(find.text(AppTexts.nextShort).first);
      await _settle(tester);
      await tester.tap(find.text(AppTexts.nextShort).first);
      await _settle(tester);
      expect(find.text('案件C'), findsWidgets);
      expect(bottom(AppTexts.nextShort).onPressed, isNull);
      await tester.tap(find.text(AppTexts.prevShort).first);
      await _settle(tester);
      expect(find.text('案件B'), findsWidgets);
    });

    group('公開ページのボタン', () {
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final launched = <String>[];
      var canLaunch = true;

      setUp(() {
        launched.clear();
        canLaunch = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'canLaunch') return canLaunch;
          if (call.method == 'launch') {
            launched.add((call.arguments as Map)['url'] as String);
            return true;
          }
          return null;
        });
      });
      tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));

      testWidgets('正常系：リンクがあれば出し、押すと開く', (tester) async {
        await open(tester);
        await tester.tap(find.text(AppTexts.openPublicPage));
        await _settle(tester);
        expect(launched, ['https://example.com/a']);
      });

      testWidgets('異常系：開けないリンクなら何もしない', (tester) async {
        canLaunch = false;
        await open(tester);
        await tester.tap(find.text(AppTexts.openPublicPage));
        await _settle(tester);
        expect(launched, isEmpty);
      });

      testWidgets('リンクがなければボタンを出さない', (tester) async {
        await open(tester, index: 1);
        expect(find.text(AppTexts.openPublicPage), findsNothing);
      });
    });

    testWidgets('Skills・Tools はグループごとの見出しに分け、「利用なし」は出さない', (tester) async {
      await open(tester);
      for (final label in {
        AppTexts.skillCategoryLabels[skillGroupOf('Python').key] ?? AppTexts.fieldSkills,
        AppTexts.skillCategoryLabels[skillGroupOf('HTML').key] ?? AppTexts.fieldSkills,
        AppTexts.skillCategoryLabels[toolGroupOf('Git').key] ?? AppTexts.fieldTools,
      }) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      expect(find.text(Project.notUsed), findsNothing);
    });
  });
}
