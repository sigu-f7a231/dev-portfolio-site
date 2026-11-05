// ヘッダーの［データ］：Work / Private のプロジェクトの追加・更新のテスト
// 対象：lib/utils/project_append.dart・lib/sections/header/project_data_dialog.dart・
//       project_form.dart・project_add_confirm.dart・yaml_upload_dialog.dart（append）
//
// 実行：flutter test test/project_data_test.dart（dev_portfolio/ で）
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/header/project_data_dialog.dart';
import 'package:dev_portfolio/sections/header/project_form.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/browser/browser.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/data_format.dart';
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/utils/project_append.dart';
import 'package:dev_portfolio/widgets/tag_input_field.dart';
import 'package:dev_portfolio/widgets/year_month_picker.dart';
import 'package:flutter/services.dart';

import 'test_assets.dart';

List<String> _titles(String? yaml) => [
      for (final p in (loadYaml(yaml!) as YamlMap)['projects'] as YamlList) '${p['title']}',
    ];

const _current = '''
projects:
  - title: 今の業務
    workflow: {requirements: true}
''';

void _setScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _openData(WidgetTester tester, {VoidCallback? onSaved}) async {
  _setScreen(tester);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showProjectDataDialog(context, onSaved: onSaved),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

/// 確認画面の OK → 全画面ローディング（最低 5 秒）が消えるまで
Future<void> _confirmOk(WidgetTester tester) async {
  await tester.tap(find.text(DataTexts.confirmOk));
  await tester.pump(const Duration(milliseconds: 100));
  for (var i = 0; i < 40 && find.text(AppTexts.reloading).evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pump();
}

void main() {
  group('readProjectsInput：テキストから追加するプロジェクトを読む', () {
    test('projects: の下・トップの並び・1 件だけ、のどれでも読む', () {
      for (final text in [
        'projects:\n  - title: A\n    workflow: {requirements: true}\n',
        '- title: A\n  workflow: {requirements: true}\n',
        'title: A\nworkflow: {requirements: true}\n',
      ]) {
        final r = readProjectsInput(text, dataType: 'work');
        expect(r.errors, isEmpty, reason: text);
        expect([for (final p in r.projects) p['title']], ['A'], reason: text);
      }
    });

    test('Markdown（テンプレートと同じ書き方）も読む', () {
      final md = File('assets/data/format_private.md').readAsStringSync();
      final r = readProjectsInput(md, dataType: 'private', fileName: 'x.md');
      expect(r.errors, isEmpty);
      expect(r.projects.single['title'], 'サンプル・プライベートプロジェクト');
    });

    test('足りないもの・書きすぎは何件目かを付けて知らせる', () {
      expect(readProjectsInput('- description: x', dataType: 'private').errors,
          [DataTexts.itemNoTitle(1)]);
      expect(readProjectsInput('- title: A\n- title: B', dataType: 'work').errors,
          [DataTexts.itemNoWorkflow(1), DataTexts.itemNoWorkflow(2)]);
      expect(readProjectsInput('- title: A\n  workflow: {}', dataType: 'private').errors,
          [DataTexts.itemHasWorkflow(1)]);
      expect(readProjectsInput('name: x', dataType: 'private').errors, [DataTexts.noProjectsFound]);
    });
  });

  group('appendProjects：今の一覧の後ろに足す', () {
    final adding = [
      {'title': '新しい業務', 'workflow': {'requirements': false}},
    ];

    test('今の一覧は残る（keepCurrent: false なら外す）', () {
      expect(_titles(appendProjects(_current, adding, dataType: 'work')), ['今の業務', '新しい業務']);
      expect(_titles(appendProjects(_current, adding, dataType: 'work', keepCurrent: false)),
          ['新しい業務']);
    });

    test('足したあとに正しい形でなければ null', () {
      expect(appendProjects(_current, [{'title': 'x'}], dataType: 'work'), isNull);
    });

    test('同じ名前は知らせる', () {
      expect(duplicateTitles(_current, [{'title': '今の業務'}, {'title': '別'}]), ['今の業務']);
    });
  });

  group('複数件のサンプル（assets/data/sample_*_multi）', () {
    // 比べやすい形（details は前後の空白を除く、period・リストは文字列、link は空文字）
    List<Map<String, dynamic>> plain(List<Map<String, dynamic>> projects) => [
          for (final p in projects)
            {
              for (final e in p.entries)
                e.key: e.value is List ? [for (final v in e.value as List) '$v'] : e.value,
              if (p['details'] != null) 'details': '${p['details']}'.trim(),
              'link': p['link'] ?? '',
            },
        ];

    for (final type in ['work', 'private']) {
      test('$type：2 件以上入っていて、YAML と Markdown が同じ中身。1 件目はテンプレートと同じ', () {
        final kind = projectKind(type);
        final yaml = readProjectsInput(
          File(multiSampleAssetPath(kind, DataFormat.yaml)).readAsStringSync(),
          dataType: type,
        );
        final md = readProjectsInput(
          File(multiSampleAssetPath(kind, DataFormat.markdown)).readAsStringSync(),
          dataType: type,
          fileName: 'x.md',
        );
        final template = readProjectsInput(
          File(templateAssetPath(kind, DataFormat.yaml)).readAsStringSync(),
          dataType: type,
        );
        expect(yaml.errors, isEmpty);
        expect(md.errors, isEmpty);
        expect(yaml.projects.length, greaterThanOrEqualTo(2));
        expect(plain(md.projects), plain(yaml.projects));
        expect(plain(yaml.projects).first, plain(template.projects).single);
      });
    }
  });

  test('入力フォームの候補：今の Work / Private の技術を項目ごとにまとめる', () {
    final s = tagSuggestions([
      'projects:\n  - title: A\n    skills: [Python, python, 利用なし]\n    aws_services: [AWS Lambda]\n',
      'projects:\n  - title: B\n    skills: [Go]\n    aws_services: [Lambda, S3]\n',
    ]);
    expect(s['skills'], ['Python', 'Go']);
    expect(s['skills_lang'], ['Python', 'Go']); // グループごとの候補も
    expect(s['aws_services'], ['Lambda', 'S3']);
    expect(s['db'], isEmpty);
  });

  group('タグの入力欄（TagInputField）', () {
    late TagInputController controller;

    Future<void> pump(WidgetTester tester) async {
      controller = TagInputController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TagInputField(
              controller: controller,
              label: 'Skills',
              suggestions: const ['Python', 'PyTorch', 'Django'],
            ),
          ),
        ),
      ));
    }

    Finder field() => find.byType(TextField);

    testWidgets('途中まで打つと候補が出て、選ぶとタグになる', (tester) async {
      await pump(tester);
      await tester.enterText(field(), 'py');
      await tester.pumpAndSettle();
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('PyTorch'), findsOneWidget);
      expect(find.text('Django'), findsNothing);

      await tester.tap(find.text('Python'));
      await tester.pumpAndSettle();
      expect(controller.tags, ['Python']);
      expect(tester.widget<TextField>(field()).controller!.text, isEmpty);

      // すでにタグのものは候補に出ない
      await tester.enterText(field(), 'py');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'Python'), findsNothing);
      expect(find.widgetWithText(ActionChip, 'PyTorch'), findsOneWidget);
    });

    testWidgets('↓ で候補を選び、Enter で決める（選んでいなければ打った文字がタグになる）', (tester) async {
      await pump(tester);
      await tester.enterText(field(), 'dj');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(controller.tags, ['Django']);

      await tester.enterText(field(), 'Rust');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(controller.tags, ['Django', 'Rust']);
    });

    testWidgets('カンマ・読点で区切ると、それより前が 1 つのタグになる', (tester) async {
      await pump(tester);
      await tester.enterText(field(), 'Go, Rust、Dart');
      await tester.pump();
      expect(controller.tags, ['Go', 'Rust']);
      expect(controller.values, ['Go', 'Rust', 'Dart']); // 打ちかけも含める
      expect(tester.widget<TextField>(field()).controller!.text, 'Dart');
    });

    testWidgets('空の欄で Backspace：1 回目は強調、2 回目で消す', (tester) async {
      await pump(tester);
      await tester.enterText(field(), 'Go, Rust,');
      await tester.pump();
      expect(controller.tags, ['Go', 'Rust']);
      expect(tester.widget<TextField>(field()).controller!.text, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.tags, ['Go', 'Rust'], reason: '1 回目はまだ消さない');
      expect(tester.widget<InputChip>(find.widgetWithText(InputChip, 'Rust')).selected, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.tags, ['Go']);
    });

    testWidgets('項目のボタンの画面：すでにある項目を押すと追加、もう一度押すと外す', (tester) async {
      final c = TagInputController();
      addTearDown(c.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TagPickerPanel(
            title: 'Skills',
            controller: c,
            suggestions: const ['Python', 'Go'],
            onDone: () {},
          ),
        ),
      ));
      await tester.tap(find.widgetWithText(FilterChip, 'Go'));
      await tester.pump();
      expect(c.tags, ['Go']);
      expect(find.widgetWithText(InputChip, 'Go'), findsOneWidget); // 入力欄にも入る
      await tester.tap(find.widgetWithText(FilterChip, 'Go'));
      await tester.pump();
      expect(c.tags, isEmpty);
    });

    testWidgets('同じもの（大文字・小文字の違いなど）は 2 つ入らない', (tester) async {
      await pump(tester);
      await tester.enterText(field(), 'git, GIT, Git;,');
      await tester.pump();
      expect(controller.tags, ['git']);
    });
  });

  group('年と月を選ぶ画面（showYearMonthPicker）', () {
    Future<DateTime?> open(WidgetTester tester, {DateTime? initial, DateTime? first}) async {
      DateTime? result;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showYearMonthPicker(
                context,
                title: DataTexts.pickStart,
                initial: initial,
                first: first,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('月を選んで OK で、その年月を返す。‹ › で年を移れる', (tester) async {
      DateTime? result;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showYearMonthPicker(
                context,
                title: DataTexts.pickStart,
                initial: DateTime(2023, 5),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(DataTexts.pickStart), findsOneWidget);
      expect(find.text('2023年5月'), findsOneWidget);

      await tester.tap(find.byTooltip(DataTexts.pickerNextYear));
      await tester.pumpAndSettle();
      expect(find.text(DataTexts.pickerYear(2024)), findsOneWidget);
      await tester.tap(find.text(DataTexts.pickerMonth(2)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(DataTexts.pickerOk));
      await tester.pumpAndSettle();
      expect(result, DateTime(2024, 2));
    });

    testWidgets('first より前の月は選べない・キャンセルは null', (tester) async {
      await open(tester, initial: DateTime(2024, 6), first: DateTime(2024, 6));
      final may = tester.widget<TextButton>(
        find.ancestor(of: find.text(DataTexts.pickerMonth(5)), matching: find.byType(TextButton)),
      );
      expect(may.onPressed, isNull);
      expect(find.byTooltip(DataTexts.pickerPrevYear), findsOneWidget);
      expect(tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(Icons.chevron_left), matching: find.byType(IconButton))).onPressed, isNull);
      await tester.tap(find.text(AppTexts.cancel));
      await tester.pumpAndSettle();
      expect(find.text(DataTexts.pickStart), findsNothing);
    });
  });

  test('入力フォームの期間：「2024/4」「２０２４年４月」も 2024-04 にする', () {
    expect(ProjectFormState.normalizeYearMonth('2024/4'), '2024-04');
    expect(ProjectFormState.normalizeYearMonth('２０２４年４月'), '2024-04');
    expect(ProjectFormState.normalizeYearMonth('2024-13'), isNull);
    expect(ProjectFormState.normalizeYearMonth('今年'), isNull);
  });

  group('［データ］の画面', () {
    setUp(useFileAssets);
    setUp(() {
      stub.SessionStore.clear();
      ProfileStore.instance.value = null;
    });

    testWidgets('追加 → Work → 画面上で入力 → 1 件 → 入力フォーム → 確認画面 → OK で追加（サンプルは外す）',
        (tester) async {
      var saved = 0;
      await _openData(tester, onSaved: () => saved++);
      expect(find.text(DataTexts.stepAction), findsOneWidget);

      await _tapText(tester, DataTexts.add);
      await _tapText(tester, AppTexts.work);
      await _tapText(tester, DataTexts.onScreen);
      await _tapText(tester, DataTexts.single);
      await _tapText(tester, DataTexts.form);
      expect(find.text(DataTexts.stepForm), findsOneWidget);

      // 名前がないと進めない
      await _tapText(tester, DataTexts.next);
      expect(find.text(DataTexts.formTitleRequired), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, DataTexts.formTitle), 'フォームの案件');
      // 期間：欄を押すと年と月を選ぶ画面が開く（年の一覧 → 月 → OK）
      Future<void> pickYearMonth(String field, int year, int month) async {
        await tester.tap(find.widgetWithText(TextFormField, field));
        await tester.pumpAndSettle();
        final yearButton = find.text(DataTexts.pickerYear(year));
        if (yearButton.evaluate().isEmpty) {
          await tester.tap(find.byIcon(Icons.arrow_drop_down)); // 年の一覧（12 年ずつ）を開く
          await tester.pumpAndSettle();
          // 目当ての年が出るまで、前の 12 年へ
          for (var i = 0; i < 10 && find.text(DataTexts.pickerYear(year)).evaluate().isEmpty; i++) {
            await tester.tap(find.byTooltip(DataTexts.pickerPrevYears));
            await tester.pumpAndSettle();
          }
          await tester.tap(find.text(DataTexts.pickerYear(year)).last);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(DataTexts.pickerMonth(month)));
        await tester.pumpAndSettle();
        expect(find.text(AppTexts.yearMonth(DateTime(year, month))), findsWidgets);
        await tester.tap(find.text(DataTexts.pickerOk));
        await tester.pumpAndSettle();
      }

      await pickYearMonth(DataTexts.formPeriodStart, 2024, 4);
      expect(
        tester.widget<TextFormField>(find.widgetWithText(TextFormField, DataTexts.formPeriodStart))
            .controller!
            .text,
        '2024年4月',
      ); // 欄に選んだ年月
      await pickYearMonth(DataTexts.formPeriodEnd, 2024, 9); // 開始の年から開く
      // 技術は項目のボタンを押して開く（入力欄＋すでにある項目の一覧）
      // Skills はグループごとのボタン（プログラミング言語・マークアップ…）
      final skillsButton = find.widgetWithText(
          OutlinedButton, AppTexts.skillCategoryLabels['skills_lang']!.split('：').last);
      await tester.ensureVisible(skillsButton);
      await tester.pumpAndSettle();
      await tester.tap(skillsButton);
      await tester.pumpAndSettle();
      expect(find.text(DataTexts.tagPickerExisting), findsOneWidget);
      await tester.enterText(
          find.descendant(of: find.byType(TagInputField), matching: find.byType(TextField)),
          'Python, Go');
      await tester.pump();
      await _tapText(tester, DataTexts.tagPickerDone);
      expect(find.textContaining('Python, Go'), findsOneWidget); // 入れたものの一覧（Skills：Python, Go）
      await tester.ensureVisible(find.text('要件定義'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('要件定義'));
      await tester.pumpAndSettle();
      await _tapText(tester, DataTexts.next);

      // 確認画面（今はサンプルなので「サンプルを外す」がはじめから付いている）
      expect(find.text(DataTexts.confirmTitle), findsOneWidget);
      expect(find.text(DataTexts.dropSample), findsOneWidget);
      expect(SessionStore.read('work'), isNull, reason: 'OK を押すまでは反映しない');
      await _confirmOk(tester);

      final saved0 = loadYaml(SessionStore.read('work')!) as YamlMap;
      final p = (saved0['projects'] as YamlList).single as YamlMap;
      expect(p['title'], 'フォームの案件');
      expect(p['period'], ['2024-04', '2024-09']);
      expect(p['skills'], ['Python', 'Go']);
      expect(p['db'], [ExcelTexts.notUsed]);
      expect(p['workflow']['requirements'], isTrue);
      expect(p['workflow']['basic_design'], isFalse);
      expect(saved, 1);
      expect(find.text(DataTexts.title), findsNothing);
    });

    testWidgets('追加 → Private → 複数件 → 選んだものだけ → 今の一覧の後ろに足す', (tester) async {
      SessionStore.write('private', 'projects:\n  - title: 今の個人開発\n');
      await _openData(tester);
      await _tapText(tester, DataTexts.add);
      await _tapText(tester, AppTexts.private);
      await _tapText(tester, DataTexts.onScreen);
      await _tapText(tester, DataTexts.multiple);
      expect(find.text(DataTexts.stepText), findsOneWidget);

      await tester.enterText(find.byType(TextField), '- title: 案件1\n- title: 案件2\n- title: 案件3\n');
      await tester.pump();
      await _tapText(tester, DataTexts.next);
      expect(find.text(DataTexts.stepPick), findsOneWidget);

      await _tapText(tester, DataTexts.addSelected);
      await tester.tap(find.widgetWithText(CheckboxListTile, '案件2'));
      await tester.pumpAndSettle();
      await _tapText(tester, DataTexts.next);

      expect(find.text(DataTexts.confirmTitle), findsOneWidget);
      expect(find.text(DataTexts.dropSample), findsNothing, reason: 'サンプルではない');
      await _confirmOk(tester);
      expect(_titles(SessionStore.read('private')), ['今の個人開発', '案件1', '案件3']);
    });

    testWidgets('テキストの画面：テンプレートの保存・コピー・ⓘ・ファイル選択・貼り付けがあり、サンプルを入れて追加できる',
        (tester) async {
      await _openData(tester);
      await _tapText(tester, DataTexts.add);
      await _tapText(tester, AppTexts.work);
      await _tapText(tester, DataTexts.onScreen);
      await _tapText(tester, DataTexts.multiple);
      for (final label in [
        AppTexts.downloadFormat,
        AppTexts.copyTemplate,
        AppTexts.chooseFile,
        AppTexts.pasteText,
        AppTexts.formatYaml,
        AppTexts.formatMarkdown,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byTooltip(AppTexts.formatHelpTooltip), findsOneWidget);

      // 複数件なので、2 件以上入った Markdown のサンプルを入れる → そのまま読める
      await _tapText(tester, AppTexts.formatMarkdown);
      await _tapText(tester, DataTexts.insertSample);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          File('assets/data/sample_work_multi.md').readAsStringSync());
      await _tapText(tester, DataTexts.next);
      expect(find.text(DataTexts.stepPick), findsOneWidget);
      expect(find.textContaining(DataTexts.found(3)), findsOneWidget); // 上の「… › 3 件のプロジェクトが見つかりました」
      expect(find.text('サンプル・ワークプロジェクト'), findsOneWidget);
      expect(find.text('サンプル・社内システムの改修'), findsOneWidget);

      // ［テキストを貼り付け］の画面で書いたものが入力欄に入る
      await _tapText(tester, DataTexts.back);
      await _tapText(tester, AppTexts.pasteText);
      await tester.enterText(find.byType(TextField).last, '- title: 貼り付け\n  workflow: {}\n');
      await tester.pump();
      await _tapText(tester, AppTexts.pasteApply);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '- title: 貼り付け\n  workflow: {}\n');
    });

    testWidgets('1 件を選んだのにテキストに 2 件あると進めない・戻るで前の画面に戻れる', (tester) async {
      await _openData(tester);
      await _tapText(tester, DataTexts.add);
      await _tapText(tester, AppTexts.private);
      await _tapText(tester, DataTexts.onScreen);
      await _tapText(tester, DataTexts.single);
      await _tapText(tester, DataTexts.text);
      await tester.enterText(find.byType(TextField), '- title: A\n- title: B\n');
      await tester.pump();
      await _tapText(tester, DataTexts.next);
      expect(find.textContaining(DataTexts.notSingle(2)), findsOneWidget);

      await _tapText(tester, DataTexts.back);
      expect(find.text(DataTexts.stepSingleInput), findsOneWidget);
    });

    testWidgets('更新 → Work は、これまでのアップロード画面（置き換え）を開く', (tester) async {
      await _openData(tester);
      await _tapText(tester, DataTexts.update);
      await _tapText(tester, AppTexts.work);
      expect(find.text(AppTexts.workUploadTitle), findsOneWidget);
      expect(find.text(DataTexts.title), findsNothing);
    });

    testWidgets('更新：アップロード画面の［戻る］で、Work / Private を選ぶ画面に戻る', (tester) async {
      await _openData(tester);
      await _tapText(tester, DataTexts.update);
      await _tapText(tester, AppTexts.work);
      await _tapText(tester, DataTexts.back);

      expect(find.text(AppTexts.workUploadTitle), findsNothing);
      expect(find.text(DataTexts.stepTarget), findsOneWidget);
      expect(find.text(DataTexts.update), findsOneWidget); // 上の「更新」（選んできたもの）
      // そのまま Private を選び直せる
      await _tapText(tester, AppTexts.private);
      expect(find.text(AppTexts.privateUploadTitle), findsOneWidget);
    });

    testWidgets('追加 → ファイル・貼り付けで追加 は、アップロード画面を「追加」で開く', (tester) async {
      await _openData(tester);
      await _tapText(tester, DataTexts.add);
      await _tapText(tester, AppTexts.work);
      await _tapText(tester, DataTexts.existing);
      expect(find.text(DataTexts.appendTitle(AppTexts.work)), findsOneWidget);
      expect(find.text(DataTexts.appendDescription), findsOneWidget);
    });

    testWidgets('追加（ファイル・貼り付け）：アップロード画面の［戻る］で、追加の方法を選ぶ画面に戻る', (tester) async {
      await _openData(tester);
      await _tapText(tester, DataTexts.add);
      await _tapText(tester, AppTexts.work);
      await _tapText(tester, DataTexts.existing);
      await _tapText(tester, DataTexts.back);

      expect(find.text(DataTexts.stepMethod), findsOneWidget);
      expect(find.text('${DataTexts.add} › ${AppTexts.work}'), findsOneWidget);
      // さらに［戻る］で、その前の画面にも戻れる
      await _tapText(tester, DataTexts.back);
      expect(find.text(DataTexts.stepTarget), findsOneWidget);
    });
  });
}
