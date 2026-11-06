// 書き方の説明ダイアログ（ⓘ）のテスト
// 対象：lib/sections/header/yaml_format_help.dart
// - Work / Private で中身が変わる（workflow の扱い）
// - サンプルの読み込み：読めた・読み込み中・読めなかった
//
// 実行：flutter test test/yaml_format_help_test.dart（frontend/ で）
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/header/yaml_format_help.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/asset_text.dart';
import 'package:dev_portfolio/widgets/app_loading_indicator.dart';

import 'test_assets.dart';

Future<void> _open(WidgetTester tester, String dataType, {bool dark = false, bool settle = true}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showYamlFormatHelp(context, dataType),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

String _bullet(String text) => '${AppTexts.bullet}$text';

List<String> _samples(WidgetTester tester) =>
    [for (final w in tester.widgetList<SelectableText>(find.byType(SelectableText))) w.data!];

void main() {
  setUpAll(loadAppFont);

  test('yamlFormatFileName：work 以外は Private のファイル', () {
    expect(yamlFormatFileName('work'), 'format_work.yaml');
    expect(yamlFormatFileName('private'), 'format_private.yaml');
    expect(yamlFormatFileName('other'), 'format_private.yaml');
  });

  group('正常系', () {
    setUp(useFileAssets);

    testWidgets('Work：workflow は必須。工程の一覧とサンプル（YAML・Markdown）', (tester) async {
      await _open(tester, 'work');
      expect(find.text(AppTexts.formatHelpTitle(true)), findsOneWidget);
      expect(find.text(_bullet(AppTexts.helpRuleWorkflowWork)), findsOneWidget);
      expect(find.text(_bullet(AppTexts.helpRuleWorkflowPrivate)), findsNothing);
      expect(find.text('workflow'), findsOneWidget);
      expect(find.textContaining('requirements: 要件定義'), findsOneWidget);
      expect(find.text(_bullet(AppTexts.helpMarkdownWorkflow)), findsOneWidget);
      expect(_samples(tester), [
        File('assets/data/format_work.yaml').readAsStringSync(),
        File('assets/data/format_work.md').readAsStringSync(),
      ]);
    });

    testWidgets('Private：workflow は書かない。工程の一覧は出さない', (tester) async {
      await _open(tester, 'private');
      expect(find.text(AppTexts.formatHelpTitle(false)), findsOneWidget);
      expect(find.text(_bullet(AppTexts.helpRuleWorkflowPrivate)), findsOneWidget);
      expect(find.text(_bullet(AppTexts.helpRuleWorkflowWork)), findsNothing);
      expect(find.text('workflow'), findsNothing);
      expect(find.textContaining('requirements: 要件定義'), findsNothing);
      expect(find.text(_bullet(AppTexts.helpMarkdownPrivate)), findsOneWidget);
      expect(_samples(tester), [
        File('assets/data/format_private.yaml').readAsStringSync(),
        File('assets/data/format_private.md').readAsStringSync(),
      ]);
    });

    testWidgets('［閉じる］で閉じる', (tester) async {
      await _open(tester, 'work');
      await tester.tap(find.text(AppTexts.close));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    for (final type in ['work', 'private']) {
      testWidgets('ダークでも描ける（$type）', (tester) async {
        await _open(tester, type, dark: true);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('異常系：サンプルの読み込み', () {
    testWidgets('読み込み中は、くるくるを出す', (tester) async {
      final never = Completer<String>();
      loadAssetText = (_) => never.future;
      addTearDown(resetAssetTextLoader);
      await _open(tester, 'work', settle: false);
      expect(find.byType(AppLoadingIndicator), findsNWidgets(2));
      expect(find.byType(SelectableText), findsNothing);
    });

    testWidgets('読めなければ、読めなかったと出す（説明はそのまま見られる）', (tester) async {
      loadAssetText = (_) => Future.error(const FileSystemException('ない'));
      addTearDown(resetAssetTextLoader);
      await _open(tester, 'private');
      expect(find.text(AppTexts.helpSampleLoadFailed), findsNWidgets(2));
      expect(find.text(AppTexts.formatHelpTitle(false)), findsOneWidget);
    });
  });
}
