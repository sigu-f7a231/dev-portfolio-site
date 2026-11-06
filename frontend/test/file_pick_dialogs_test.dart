// ファイルを選ぶ流れのテスト（最初の入力画面・Work / Private のアップロード画面）
// 対象：lib/widgets/profile_setup_dialog.dart、lib/sections/header/yaml_upload_dialog.dart
// ファイル選択のダイアログは lib/utils/file_pick.dart の pickFile を差し替えて、選んだファイルを渡す
// - 正常系：YAML・Markdown・Excel を選ぶ → 読み込める → アップロード
// - 異常系：キャンセル・中身なし・拡張子が違う・選ぶ途中のエラー・文字コードが違う・壊れた Excel・保存の失敗
//
// 実行：flutter test test/file_pick_dialogs_test.dart（frontend/ で）
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/header/yaml_upload_dialog.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/asset_text.dart';
import 'package:dev_portfolio/utils/browser/browser.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/file_pick.dart';
import 'package:dev_portfolio/utils/file_saver.dart';
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/widgets/profile_setup_dialog.dart';

import 'test_assets.dart';

const _profileYaml = '''
home:
  name: 選んだ 太郎
  role: エンジニア
  tagline: 紹介文
about:
  intro: 自己紹介
''';

const _profileMd = '# home\n- name: Markdown 花子\n- role: エンジニア\n## tagline\n紹介文\n# about\n## intro\n自己紹介\n';

const _workYaml = '''
projects:
  - title: 選んだ業務
    workflow:
      requirements: true
''';

/// 次に選ぶファイル（null ならキャンセル）。選ぶときに渡された拡張子も残す
PickedFile? _next;
Object? _throw;
List<String>? _askedExtensions;

void _willPick(String name, List<int>? bytes) {
  _next = (name: name, bytes: bytes == null ? null : Uint8List.fromList(bytes));
  _throw = null;
}

Future<void> _pumpOpener(WidgetTester tester, void Function(BuildContext) open, {bool dark = false}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(onPressed: () => open(context), child: const Text('open')),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

ButtonStyleButton _uploadButton(WidgetTester tester) => tester.widget<ButtonStyleButton>(
      find.ancestor(of: find.text(AppTexts.upload), matching: find.byWidgetPredicate((w) => w is FilledButton)),
    );

Future<void> _confirmAndWait(WidgetTester tester) async {
  await tester.tap(find.text(AppTexts.upload));
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppTexts.confirmOk));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  if (find.text(OverwriteTexts.overwrite).evaluate().isNotEmpty) {
    await tester.tap(find.text(OverwriteTexts.overwrite));
    await tester.pump(const Duration(milliseconds: 100));
  }
  for (var i = 0; i < 40 && find.text(AppTexts.reloading).evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pump();
}

void main() {
  setUpAll(loadAppFont);

  setUp(() {
    useFileAssets();
    stub.SessionStore.clear();
    ProfileStore.instance.value = null;
    ProfileStore.instance.startupErrors = const [];
    FileSaver.lastSaved = null;
    _next = null;
    _throw = null;
    _askedExtensions = null;
    pickFile = (extensions) async {
      _askedExtensions = extensions;
      if (_throw != null) throw _throw!;
      return _next;
    };
    addTearDown(resetFilePicker);
  });
  tearDown(() {
    ProfileStore.instance.value = null;
    ProfileStore.instance.startupErrors = const [];
  });

  group('最初の入力画面：YAML / Markdown のファイル', () {
    testWidgets('正常系：YAML を選ぶ → 読み込める → アップロードで反映', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      _willPick('me.yaml', utf8.encode(_profileYaml));
      await _tapText(tester, AppTexts.chooseFile);

      expect(_askedExtensions, containsAll(['yaml', 'yml', 'md', 'markdown']));
      expect(find.text(AppTexts.fileReady('me.yaml')), findsOneWidget);
      expect(find.text(AppTexts.chooseAnotherFile), findsOneWidget); // 2 回目は「別のファイル」

      await _confirmAndWait(tester);
      expect(ProfileStore.instance.value?.name, '選んだ 太郎');
    });

    testWidgets('正常系：Markdown を選ぶ', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      _willPick('me.md', utf8.encode(_profileMd));
      await _tapText(tester, AppTexts.chooseFile);
      expect(find.text(AppTexts.fileReady('me.md')), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNotNull);
    });

    testWidgets('異常系：キャンセル・中身なしは、前の選択のまま', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      _willPick('me.yaml', utf8.encode(_profileYaml));
      await _tapText(tester, AppTexts.chooseFile);

      _next = null; // キャンセル
      await _tapText(tester, AppTexts.chooseAnotherFile);
      expect(find.text(AppTexts.fileReady('me.yaml')), findsOneWidget);

      _willPick('empty.yaml', null); // 中身が読めない
      await _tapText(tester, AppTexts.chooseAnotherFile);
      expect(find.text(AppTexts.fileReady('me.yaml')), findsOneWidget);
    });

    testWidgets('異常系：拡張子が違う', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      _willPick('me.txt', utf8.encode(_profileYaml));
      await _tapText(tester, AppTexts.chooseFile);
      expect(find.text('${AppTexts.bullet}${ProfileTexts.extensionOnly}'), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);
    });

    testWidgets('異常系：選ぶ途中のエラー・UTF-8 でない中身', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      _throw = Exception('選べません');
      await _tapText(tester, AppTexts.chooseFile);
      expect(find.textContaining('選べません'), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);

      _willPick('broken.yaml', [0xff, 0xfe, 0xfd]);
      await _tapText(tester, AppTexts.chooseFile);
      expect(find.textContaining(AppTexts.fileReadFailed('').trim()), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);
    });

    testWidgets('起動時に指定した YAML が読めなかった理由は、ファイルを選ぶまで出す', (tester) async {
      ProfileStore.instance.startupErrors = ['壊れていました'];
      await _pumpOpener(tester, showProfileSetupDialog);
      expect(find.text(ProfileTexts.startupFailedTitle), findsOneWidget);
      expect(find.text('${AppTexts.bullet}壊れていました'), findsOneWidget);

      _willPick('me.yaml', utf8.encode(_profileYaml));
      await _tapText(tester, AppTexts.chooseFile);
      expect(find.text(ProfileTexts.startupFailedTitle), findsNothing);
    });

    testWidgets('ⓘ で書き方の説明を開いて閉じる', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await tester.tap(find.byTooltip(ProfileTexts.helpTooltip));
      await tester.pumpAndSettle();
      expect(find.text(AppTexts.close), findsOneWidget);
      await tester.tap(find.text(AppTexts.close));
      await tester.pumpAndSettle();
      expect(find.text(ProfileTexts.setupTitle), findsOneWidget);
    });
  });

  group('最初の入力画面：Excel（スキルシート）', () {
    Future<void> toExcel(WidgetTester tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await _tapText(tester, ExcelTexts.methodExcel);
    }

    final template = File('assets/data/format_skill_sheet.xlsx').readAsBytesSync();

    testWidgets('正常系：Excel を選ぶ → 読み込める → 作った YAML を保存できる → アップロード', (tester) async {
      await toExcel(tester);
      _willPick('sheet.xlsx', template);
      await _tapText(tester, ExcelTexts.chooseExcel);

      expect(_askedExtensions, containsAll(['xlsx', 'xlsm']));
      expect(find.text(AppTexts.fileReady('sheet.xlsx')), findsOneWidget);
      expect(find.text(ExcelTexts.chooseAnotherExcel), findsOneWidget);

      await _tapText(tester, ExcelTexts.saveYaml);
      expect(FileSaver.lastSaved?.fileName, endsWith('.yaml'));
      expect(utf8.decode(FileSaver.lastSaved!.bytes), contains('home:'));

      await _confirmAndWait(tester);
      expect(ProfileStore.instance.value, isNotNull);
    });

    testWidgets('正常系：Excel のテンプレートを保存する', (tester) async {
      await toExcel(tester);
      await _tapText(tester, ExcelTexts.saveTemplate);
      expect(FileSaver.lastSaved?.fileName, skillSheetTemplateFileName);
      expect(FileSaver.lastSaved!.bytes, template);
    });

    testWidgets('異常系：テンプレートを読めなければ、保存に失敗したと出す', (tester) async {
      await toExcel(tester);
      loadAssetBytes = (_) => Future.error(const FileSystemException('ない'));
      await _tapText(tester, ExcelTexts.saveTemplate);
      expect(find.textContaining(AppTexts.downloadFailed('').trim()), findsOneWidget);
      expect(FileSaver.lastSaved, isNull);
    });

    testWidgets('異常系：拡張子が違う（.xls）・壊れた Excel・キャンセル', (tester) async {
      await toExcel(tester);
      _willPick('old.xls', template);
      await _tapText(tester, ExcelTexts.chooseExcel);
      expect(find.text('${AppTexts.bullet}${ExcelTexts.extensionOnly}'), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);

      _willPick('broken.xlsx', [1, 2, 3, 4]);
      await _tapText(tester, ExcelTexts.chooseAnotherExcel);
      expect(_uploadButton(tester).onPressed, isNull);
      expect(find.text(ExcelTexts.saveYaml), findsNothing);

      _next = null;
      await _tapText(tester, ExcelTexts.chooseAnotherExcel);
      expect(_uploadButton(tester).onPressed, isNull);
    });

    testWidgets('異常系：選ぶ途中のエラー', (tester) async {
      await toExcel(tester);
      _throw = Exception('Excel を選べません');
      await _tapText(tester, ExcelTexts.chooseExcel);
      expect(find.textContaining('Excel を選べません'), findsOneWidget);
    });

    testWidgets('入力方法を切り替えると、選んでいたファイルは取り消す（同じ方法を押しても何もしない）', (tester) async {
      await toExcel(tester);
      _willPick('sheet.xlsx', template);
      await _tapText(tester, ExcelTexts.chooseExcel);
      await _tapText(tester, ExcelTexts.methodExcel); // 同じ方法
      expect(find.text(AppTexts.fileReady('sheet.xlsx')), findsOneWidget);

      await _tapText(tester, ExcelTexts.methodText);
      expect(find.text(AppTexts.fileReady('sheet.xlsx')), findsNothing);
      expect(_uploadButton(tester).onPressed, isNull);
    });

    for (final method in [ExcelTexts.methodExcel, ExcelTexts.methodText]) {
      testWidgets('ダークでも描ける（$method）', (tester) async {
        await _pumpOpener(tester, showProfileSetupDialog, dark: true);
        await _tapText(tester, method);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Work / Private のアップロード画面：ファイル', () {
    for (final type in ['work', 'private']) {
      testWidgets('$type：異常系（キャンセル・エラー・文字コード）', (tester) async {
        await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: type));

        _next = null;
        await _tapText(tester, AppTexts.chooseFile);
        expect(find.text(AppTexts.noFileChosen), findsOneWidget);

        // 拡張子はファイル選択のダイアログ側で絞る（.yaml / .yml / .md / .markdown だけ）
        expect(_askedExtensions, containsAll(['yaml', 'yml', 'md', 'markdown']));

        _throw = Exception('選べません');
        await _tapText(tester, AppTexts.chooseFile);
        expect(find.textContaining('選べません'), findsWidgets);

        _willPick('broken.yaml', [0xff, 0xfe]);
        await _tapText(tester, AppTexts.chooseFile);
        expect(_uploadButton(tester).onPressed, isNull);
      });
    }

    testWidgets('work：正常系：YAML を選んでアップロードすると、セッションに保存', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'work'));
      _willPick('work.yaml', utf8.encode(_workYaml));
      await _tapText(tester, AppTexts.chooseFile);
      expect(find.text(AppTexts.fileReady('work.yaml')), findsOneWidget);
      await _confirmAndWait(tester);
      expect(SessionStore.read('work'), contains('選んだ業務'));
    });

    testWidgets('private：異常系：Work の YAML（workflow あり）は弾く', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'private'));
      _willPick('work.yaml', utf8.encode(_workYaml));
      await _tapText(tester, AppTexts.chooseFile);
      expect(find.text(AppTexts.fileRejected('work.yaml')), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);
    });
  });
}
