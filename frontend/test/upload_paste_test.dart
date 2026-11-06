// テキストの貼り付け・テンプレートのコピー（ファイルを保存・選択できない人向け）のテスト
// 対象：lib/widgets/upload_parts.dart の showPasteYamlDialog / copyTemplateText / UploadSourcePanel
//
// 実行：flutter test test/upload_paste_test.dart（frontend/ で）
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/widgets/upload_parts.dart';

import 'test_assets.dart';

const _yaml = 'projects:\n  - title: 貼り付けた案件\n    workflow:\n      requirements: true\n';

/// クリップボード（SystemChannels.platform）の代わり
void _mockClipboard(
  WidgetTester tester, {
  String? text,
  void Function(String)? onSet,
}) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.getData') {
        return text == null ? null : <String, dynamic>{'text': text};
      }
      if (call.method == 'Clipboard.setData') {
        onSet?.call((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
}

/// 貼り付け画面を開くボタンだけの画面。閉じたときの結果を [onResult] で受け取る
Future<void> _openPaste(
  WidgetTester tester, {
  String initialText = '',
  required void Function(String?) onResult,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              onResult(await showPasteYamlDialog(context, initialText: initialText)),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

FilledButton _applyButton(WidgetTester tester) => tester.widget<FilledButton>(
      find.ancestor(of: find.text(AppTexts.pasteApply), matching: find.byType(FilledButton)),
    );

void main() {
  // アセット（テンプレート）はファイルから直接読む（テスト中の読み込みで止まらないように。test_assets.dart を参照）
  setUp(useFileAssets);

  group('テキストの貼り付け画面', () {
    testWidgets('空のときは「読み込む」を押せない', (tester) async {
      await _openPaste(tester, onResult: (_) {});
      expect(find.text(AppTexts.pasteTitle), findsOneWidget);
      expect(_applyButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '   \n  ');
      await tester.pump();
      expect(_applyButton(tester).onPressed, isNull, reason: '空白だけも空とみなす');
    });

    testWidgets('入力したテキストを、インデントも含めてそのまま返す', (tester) async {
      String? result;
      await _openPaste(tester, onResult: (r) => result = r);

      await tester.enterText(find.byType(TextField), _yaml);
      await tester.pump();
      expect(_applyButton(tester).onPressed, isNotNull);

      await tester.tap(find.text(AppTexts.pasteApply));
      await tester.pumpAndSettle();
      expect(result, _yaml);
      expect(find.text(AppTexts.pasteTitle), findsNothing); // 閉じた
    });

    testWidgets('キャンセルは null を返す', (tester) async {
      String? result = 'not called';
      await _openPaste(tester, onResult: (r) => result = r);
      await tester.enterText(find.byType(TextField), _yaml);
      await tester.tap(find.text(AppTexts.cancel));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('「クリア」で入力欄を空にでき、空のときは押せない', (tester) async {
      await _openPaste(tester, initialText: _yaml, onResult: (_) {});
      TextButton clear() => tester.widget<TextButton>(find.ancestor(
            of: find.text(AppTexts.pasteClear),
            matching: find.byWidgetPredicate((w) => w is TextButton),
          ));
      expect(clear().onPressed, isNotNull);

      await tester.tap(find.text(AppTexts.pasteClear));
      await tester.pump();
      expect(find.text(_yaml), findsNothing);
      expect(clear().onPressed, isNull);
      expect(_applyButton(tester).onPressed, isNull);
    });

    testWidgets('入力欄の右の × でも空にできる（空のときは × を出さない）', (tester) async {
      await _openPaste(tester, onResult: (_) {});
      expect(find.byTooltip(AppTexts.pasteClear), findsNothing);

      await tester.enterText(find.byType(TextField), _yaml);
      await tester.pump();
      await tester.tap(find.byTooltip(AppTexts.pasteClear));
      await tester.pump();
      expect(find.text(_yaml), findsNothing);
      expect(find.byTooltip(AppTexts.pasteClear), findsNothing);
    });

    testWidgets('前に貼り付けたテキストが入った状態で開く（続きから直せる）', (tester) async {
      await _openPaste(tester, initialText: _yaml, onResult: (_) {});
      expect(find.text(_yaml), findsOneWidget);
      expect(_applyButton(tester).onPressed, isNotNull);
    });

    testWidgets('「クリップボードから貼り付け」で入力欄に入る', (tester) async {
      _mockClipboard(tester, text: _yaml);
      await _openPaste(tester, onResult: (_) {});

      await tester.tap(find.text(AppTexts.pasteFromClipboard));
      await tester.pumpAndSettle();
      expect(find.text(_yaml), findsOneWidget);
      expect(_applyButton(tester).onPressed, isNotNull);
    });

    testWidgets('クリップボードが空なら、その旨を出す', (tester) async {
      _mockClipboard(tester, text: null);
      await _openPaste(tester, onResult: (_) {});

      await tester.tap(find.text(AppTexts.pasteFromClipboard));
      await tester.pumpAndSettle();
      expect(find.text(AppTexts.clipboardEmpty), findsOneWidget);
    });
  });

  testWidgets('テンプレートをコピー：assets の中身がそのままクリップボードに入る', (tester) async {
    String? copied;
    _mockClipboard(tester, onSet: (t) => copied = t);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => copyTemplateText(
              context,
              assetPath: 'assets/data/format_work.yaml',
              fileName: 'format_work.yaml',
            ),
            child: const Text('copy'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('copy'));
    await tester.pumpAndSettle();

    expect(copied, File('assets/data/format_work.yaml').readAsStringSync());
    expect(find.text(AppTexts.templateCopied('format_work.yaml')), findsOneWidget);
  });

  group('UploadSourcePanel', () {
    Future<Map<String, int>> pumpPanel(WidgetTester tester, {bool busy = false, bool hasSource = false}) async {
      final calls = <String, int>{};
      void count(String k) => calls[k] = (calls[k] ?? 0) + 1;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UploadSourcePanel(
            onTemplateFormatChanged: (f) => count('format:${f.name}'),
            onSaveTemplate: () => count('save'),
            onCopyTemplate: () => count('copy'),
            onPickFile: busy ? null : () => count('pick'),
            onPasteText: busy ? null : () => count('paste'),
            hasSource: hasSource,
          ),
        ),
      ));
      return calls;
    }

    testWidgets('4 つのボタンがそれぞれの処理を呼ぶ', (tester) async {
      final calls = await pumpPanel(tester);
      for (final label in [
        AppTexts.downloadFormat,
        AppTexts.copyTemplate,
        AppTexts.chooseFile,
        AppTexts.pasteText,
      ]) {
        await tester.tap(find.text(label));
      }
      expect(calls, {'save': 1, 'copy': 1, 'pick': 1, 'paste': 1});
    });

    testWidgets('読み込み中はファイル選択・貼り付けを押せない', (tester) async {
      final calls = await pumpPanel(tester, busy: true);
      await tester.tap(find.text(AppTexts.chooseFile));
      await tester.tap(find.text(AppTexts.pasteText));
      expect(calls, isEmpty);
    });

    testWidgets('テンプレートの形式（YAML / Markdown）を切り替えられる', (tester) async {
      final calls = await pumpPanel(tester);
      expect(find.text(AppTexts.formatYaml), findsOneWidget);
      await tester.tap(find.text(AppTexts.formatMarkdown));
      expect(calls, {'format:markdown': 1});
    });

    testWidgets('読み込んだ後は「別のファイルを選択」になる', (tester) async {
      await pumpPanel(tester, hasSource: true);
      expect(find.text(AppTexts.chooseAnotherFile), findsOneWidget);
      expect(find.text(AppTexts.chooseFile), findsNothing);
    });
  });
}
