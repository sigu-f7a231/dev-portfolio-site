// ヘッダーの［ダウンロード］（スキルシートを Excel / PDF で名前を付けて保存）のテスト
// 対象：lib/sections/header/download_menu.dart・lib/utils/file_saver_stub.dart（テストでは保存した中身を残す）
//
// 実行：flutter test test/download_menu_test.dart（dev_portfolio/ で）
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/sections/header/download_menu.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/asset_text.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/file_saver.dart';
import 'package:dev_portfolio/utils/profile_bundle.dart';
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/utils/skill_sheet.dart';

import 'test_assets.dart';

const _work = '''
projects:
  - title: 新しい案件
    period: [2025-01, 2025-06]
    tools: [React]
    role: [SE]
    scale: 10名
    workflow: {requirements: true}
  - title: 古い案件
    period: [2020-04, 2020-09]
    workflow: {basic_design: true}
''';

const _private = '''
projects:
  - title: 個人アプリ
    period: [2024-01, 現在]
''';

const _profile = Profile(
  name: '鈴木 一郎',
  role: 'エンジニア',
  tagline: '紹介',
  intro: '自己紹介',
  recent: 'Web開発：テスト',
  sheet: {'gender': '男', 'birthday': '1990年04月01日', 'station': '新宿駅'},
);

/// 書き出した Excel を読み直す
ProfileBundle _readBack() {
  final saved = FileSaver.lastSaved!;
  final result = convertSkillSheet(saved.bytes, fileName: saved.fileName);
  expect(result.errors, isEmpty);
  return readProfileBundle(result.yamlText!, fileName: 'x.yaml');
}

List<String> _titles(String? text) => [
      for (final p in (jsonDecode(jsonEncode(loadYaml(text!)))['projects'] as List)) '${p['title']}',
    ];

Future<void> _pump(WidgetTester tester, {bool showLabel = true}) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      appBar: AppBar(actions: [HeaderDownloadButton(showLabel: showLabel)]),
    ),
  ));
}

Future<void> _choose(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip(SkillSheetTexts.buttonTooltip));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  // メニューを閉じてから項目の処理が呼ばれ、そのあとローディングの画面が入る（時間は進めない＝まだ作り始めない）
  for (var i = 0; i < 5 && find.text(SkillSheetTexts.making).evaluate().isEmpty; i++) {
    await tester.pump();
  }
}

/// 作り終わるまで進める（ローディングの円は止まらないので pumpAndSettle は終わってから）
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  setUp(useFileAssets);
  setUp(() {
    stub.SessionStore.clear();
    ProfileStore.instance.value = null;
    FileSaver.lastSaved = null;
  });

  group('今のデータ（currentSkillSheetData）', () {
    test('プロフィール・Work・Private。案件は開始の古い順、技術は本来の分類に移してから', () async {
      ProfileStore.instance.value = _profile;
      stub.SessionStore.write('work', _work);
      stub.SessionStore.write('private', _private);
      final data = await currentSkillSheetData();
      expect(data.name, '鈴木 一郎');
      expect(data.experience, contains('Web開発：テスト'));
      expect(data.sheet, _profile.sheet);
      expect([for (final p in data.work) p['title']], ['古い案件', '新しい案件']);
      expect(data.private.single['title'], '個人アプリ');
      final moved = data.work.last;
      expect(moved['frontend_frameworks'], contains('React'));
    });

    test('まだ読み込んでいなければ、テンプレートのサンプル（Work / Private）。氏名・経験は空', () async {
      final data = await currentSkillSheetData();
      expect(data.name, '');
      expect(data.experience, '');
      expect(data.work, isNotEmpty);
      expect(data.private, isNotEmpty);
    });
  });

  group('作る中身（buildSkillSheetBytes）', () {
    test('Excel：読み直すと同じ（氏名・個人の項目・案件の順・役割 / 規模）', () async {
      ProfileStore.instance.value = _profile;
      stub.SessionStore.write('work', _work);
      stub.SessionStore.write('private', _private);
      final bytes = await buildSkillSheetBytes(pdf: false, today: DateTime(2026, 11, 5));
      final back = readProfileBundle(convertSkillSheet(bytes).yamlText!, fileName: 'x.yaml');
      expect(back.profile!.name, '鈴木 一郎');
      expect(back.profile!.sheet, _profile.sheet);
      expect(_titles(back.workText), ['古い案件', '新しい案件']);
      expect(_titles(back.privateText), ['個人アプリ']);
      final w = (loadYaml(back.workText!)['projects'] as YamlList).last as YamlMap;
      expect(w['role'], ['SE']);
      expect(w['scale'], '10名');
    });

    test('PDF：%PDF で始まる', () async {
      final bytes = await buildSkillSheetBytes(pdf: true);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('［ダウンロード］のボタン', () {
    testWidgets('押すと Excel / PDF を選ぶメニュー（スマホはアイコンだけ）', (tester) async {
      await _pump(tester);
      expect(find.text(SkillSheetTexts.button), findsOneWidget);
      await tester.tap(find.text(SkillSheetTexts.button));
      await tester.pumpAndSettle();
      expect(find.text(SkillSheetTexts.excel), findsOneWidget);
      expect(find.text(SkillSheetTexts.pdf), findsOneWidget);

      await _pump(tester, showLabel: false);
      await tester.pumpAndSettle();
      expect(find.text(SkillSheetTexts.button), findsNothing);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('Excel：名前を付けて保存（.xlsx）→ 作っている間はローディング → 画面の下に知らせる', (tester) async {
      ProfileStore.instance.value = _profile;
      stub.SessionStore.write('work', _work);
      await _pump(tester);
      await _choose(tester, SkillSheetTexts.excel);
      expect(find.text(SkillSheetTexts.making), findsOneWidget);
      await _finish(tester);

      expect(find.text(SkillSheetTexts.making), findsNothing);
      final saved = FileSaver.lastSaved!;
      expect(saved.fileName, matches(RegExp(r'^skill_sheet_\d{8}\.xlsx$')));
      expect(saved.mimeType, skillSheetMimeType);
      expect(saved.extensions, ['.xlsx']);
      // テストの保存は「ダウンロード」扱い（Web の保存ダイアログが使えないブラウザと同じ）
      expect(find.text(SkillSheetTexts.downloaded(SkillSheetTexts.excelShort, saved.fileName)),
          findsOneWidget);
      expect(_titles(_readBack().workText), ['古い案件', '新しい案件']);
    });

    testWidgets('PDF：名前を付けて保存（.pdf）→ 画面の下に知らせる', (tester) async {
      await _pump(tester);
      await _choose(tester, SkillSheetTexts.pdf);
      expect(find.text(SkillSheetTexts.making), findsOneWidget);
      await _finish(tester);
      final saved = FileSaver.lastSaved!;
      expect(saved.fileName, endsWith('.pdf'));
      expect(saved.mimeType, SkillSheetTexts.pdfMimeType);
      expect(saved.extensions, ['.pdf']);
      expect(ascii.decode(saved.bytes.sublist(0, 5)), '%PDF-');
      expect(find.text(SkillSheetTexts.downloaded(SkillSheetTexts.pdfShort, saved.fileName)),
          findsOneWidget);
    });

    testWidgets('作れなかったら、ローディングを閉じて理由を知らせる（保存しない）', (tester) async {
      loadAssetBytes = (path) => Future.error(StateError('読めません'));
      await _pump(tester);
      await _choose(tester, SkillSheetTexts.excel);
      await _finish(tester);
      expect(find.text(SkillSheetTexts.making), findsNothing);
      expect(find.textContaining(SkillSheetTexts.failed(SkillSheetTexts.excelShort, '')), findsOneWidget);
      expect(find.textContaining('読めません'), findsOneWidget);
      expect(FileSaver.lastSaved, isNull);
    });
  });

  test('PC・スマホのヘッダーに［ダウンロード］がある（スマホはアイコンだけ）', () {
    final desktop = File('lib/sections/header/desktop_header.dart').readAsStringSync();
    final mobile = File('lib/sections/header/mobile_header.dart').readAsStringSync();
    expect(desktop, contains('HeaderDownloadButton(showLabel: showUploadLabel)'));
    expect(mobile, contains('HeaderDownloadButton(showLabel: false)'));
  });

  group('ファイル名・文言', () {
    test('skill_sheet_YYYYMMDD（月日は 2 桁）', () {
      expect(SkillSheetTexts.fileName(DateTime(2026, 1, 2), 'xlsx'), 'skill_sheet_20260102.xlsx');
      expect(SkillSheetTexts.fileName(DateTime(2026, 12, 31), 'pdf'), 'skill_sheet_20261231.pdf');
    });

    test('結果の知らせ', () {
      expect(SkillSheetTexts.saved('A', 'b.pdf'), contains('b.pdf'));
      expect(SkillSheetTexts.cancelled('A'), contains('やめました'));
      expect(SkillSheetTexts.failed('A', 'x'), endsWith('x'));
    });
  });

  group('FileSaver（テスト用の実装）', () {
    test('saveGeneratedBytesAs は make で作ったものを保存する', () async {
      var made = 0;
      final r = await FileSaver.saveGeneratedBytesAs(
        fileName: 'a.bin',
        description: 'd',
        mimeType: 'application/octet-stream',
        extensions: const ['.bin'],
        make: () async {
          made++;
          return Uint8List.fromList([1, 2, 3]);
        },
      );
      expect(r, FileSaveResult.downloaded);
      expect(made, 1);
      expect(FileSaver.lastSaved!.bytes, [1, 2, 3]);
    });

    test('make が失敗したら、そのまま失敗する（保存しない）', () async {
      await expectLater(
        FileSaver.saveGeneratedBytesAs(
          fileName: 'a.bin',
          description: 'd',
          mimeType: 'x',
          extensions: const ['.bin'],
          make: () async => throw StateError('x'),
        ),
        throwsStateError,
      );
      expect(FileSaver.lastSaved, isNull);
    });

    test('saveTextAs は文字を UTF-8 で残す', () async {
      await FileSaver.saveTextAs(
          fileName: 't.yaml', text: 'あ', description: 'd', mimeType: 'text/yaml', extensions: const ['.yaml']);
      expect(utf8.decode(FileSaver.lastSaved!.bytes), 'あ');
    });
  });
}
