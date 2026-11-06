// スキルシート（Excel）から YAML を作る処理のテスト
// 対象：lib/utils/skill_sheet.dart（convertSkillSheet）・lib/utils/xlsx_reader.dart・lib/utils/yaml_writer.dart
//
// 実行：flutter test test/skill_sheet_test.dart（frontend/ で）
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/utils/profile_bundle.dart';
import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/utils/xlsx_reader.dart';
import 'package:dev_portfolio/utils/yaml_writer.dart';

Uint8List _template() => File(skillSheetTemplateAsset).readAsBytesSync();

/// YAML として読み、JSON 相当（Map / List / 文字列）にする
dynamic _plain(String yaml) => jsonDecode(jsonEncode(loadYaml(yaml)));

/// 比べる項目だけ（details は Excel では「概要：」なども含むので比べない）
Map<String, dynamic> _comparable(Map<String, dynamic> p) => {
      for (final e in p.entries)
        if (e.key != 'details') e.key: e.value is List ? [for (final v in e.value) '$v'] : e.value,
      'link': p['link'] ?? '',
    };

/// テスト用の小さな .xlsx（セルはすべて文字。キーは「A1」などのセル番地）
Uint8List _xlsx(Map<String, String> cells) {
  String esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  final rows = <int, List<String>>{};
  for (final e in cells.entries) {
    final row = int.parse(RegExp(r'\d+').firstMatch(e.key)!.group(0)!);
    (rows[row] ??= []).add(
      '<c r="${e.key}" t="inlineStr"><is><t xml:space="preserve">${esc(e.value)}</t></is></c>',
    );
  }
  final sortedRows = rows.keys.toList()..sort();
  final sheet = '<?xml version="1.0" encoding="UTF-8"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
      '${sortedRows.map((r) => '<row r="$r">${rows[r]!.join()}</row>').join()}'
      '</sheetData></worksheet>';
  const workbook = '<?xml version="1.0" encoding="UTF-8"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>';
  const rels = '<?xml version="1.0" encoding="UTF-8"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
      'Target="worksheets/sheet1.xml"/></Relationships>';

  final archive = Archive();
  for (final (name, text) in [
    ('xl/workbook.xml', workbook),
    ('xl/_rels/workbook.xml.rels', rels),
    ('xl/worksheets/sheet1.xml', sheet),
  ]) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _experience = '直近の開発経験\n'
    '\n'
    'Web開発：社内向けツールの開発を経験。\n'
    'API開発：外部サービスとの連携を経験。\n'
    '\n'
    '主な使用技術・開発環境：\n'
    '言語：Python、Go\n'
    'DB：MySQL\n';

/// 氏名・経験・プロジェクト 2 件（1 件は個人開発）の小さなスキルシート
Map<String, String> _sheet() => {
      'A1': '氏名',
      'C1': '鈴木 一郎',
      'A2': _experience,
      // 見出し（作業工程の小見出しは次の行）
      'A4': 'No.', 'B4': '期間', 'C4': 'プロジェクト名\n業務概要', 'D4': 'サーバ\nOS', 'E4': 'DB',
      'F4': 'FW・MW\nツール等', 'G4': '使用言語', 'H4': '作業工程',
      'H5': '要件定義', 'I5': '実装・単体', 'J5': '保守・運用',
      // 1 件目（Work）
      'A6': '1', 'B6': '2024/4', 'C6': '社内ツール開発', 'D6': 'サーバOS：\nLinux',
      'E6': 'DB：\n- MySQL', 'F6': 'その他ツール・技術：\n- Docker\n- Git / GitHub\n\nAI：GitHub Copilot',
      'G6': '使用言語：\n- Python\n- Django（管理画面）', 'H6': '●', 'I6': '●', 'J6': '-',
      'C7': '概要：\n① 業務効率化のためのツールを開発\n\n担当：設計と実装',
      'B8': '2024/9',
      // 2 件目（Private。期間の終わりがない → 進行中）
      'A9': '2', 'B9': '2025/1', 'C9': '家計簿アプリ【個人開発】', 'D9': 'Windows', 'E9': 'なし',
      'F9': 'VS Code', 'G9': 'Dart\nFlutter（Flutter Web）', 'H9': '●',
      'C10': '個人で使う家計簿アプリ\nURL：\nhttps://example.com/kakeibo',
      // 3 件目：番号だけで名前が空（読み飛ばす）
      'A12': '3',
    };

void main() {
  test('Excel のテンプレートがアセットとして登録されている（pubspec.yaml の書き忘れを見つける）', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final data = await rootBundle.load(skillSheetTemplateAsset);
    expect(data.lengthInBytes, File(skillSheetTemplateAsset).lengthSync());
  });

  group('Excel のテンプレート（assets/data/format_skill_sheet.xlsx）', () {
    late SkillSheetResult result;
    late ProfileBundle bundle;

    setUpAll(() {
      result = convertSkillSheet(_template(), fileName: skillSheetTemplateFileName);
      bundle = readProfileBundle(result.yamlText ?? '', fileName: 'skill_sheet.yaml');
    });

    test('読み込めて、プロフィールとして正しい', () {
      expect(result.errors, isEmpty);
      expect(bundle.errors, isEmpty);
      expect(bundle.isOk, isTrue);
    });

    test('Home / About：氏名と、過去・直近の開発経験と主な技術', () {
      final p = bundle.profile!;
      expect(p.name, '山田 太郎');
      expect(p.role, ExcelTexts.defaultRole);
      expect(p.tagline, contains('Python'));
      expect(p.card.keys, contains('言語'));
      expect(p.recent, contains('Webアプリ開発：'));
      expect(p.past, contains('Webシステム開発：'));
      expect(p.recentTech['言語'], containsAll(['Python', 'Dart']));
      expect(p.pastTech['DB'], ['MySQL', 'PostgreSQL']);
      expect(p.domains.first, 'Webアプリ開発');
    });

    test('Work / Private：中身が Work / Private のテンプレートのサンプルと同じ（details 以外）', () {
      List<Map<String, dynamic>> projects(String? text) => [
            for (final p in (_plain(text!)['projects'] as List).cast<Map<String, dynamic>>())
              _comparable(p),
          ];
      String asset(String name) => File('assets/data/$name').readAsStringSync();

      expect(projects(bundle.workText), projects(asset('format_work.yaml')));
      expect(projects(bundle.privateText), projects(asset('format_private.yaml')));
    });
  });

  group('小さなスキルシート', () {
    late Map<String, dynamic> data;

    setUpAll(() {
      final result = convertSkillSheet(_xlsx(_sheet()), fileName: 'sheet.xlsx');
      expect(result.errors, isEmpty);
      data = _plain(result.yamlText!) as Map<String, dynamic>;
      expect(readProfileBundle(result.yamlText!, fileName: 'sheet.yaml').errors, isEmpty);
    });

    test('名前に「個人開発」が入っているものだけ Private（印はタイトルから外す）', () {
      expect([for (final p in data['work']) p['title']], ['社内ツール開発']);
      expect([for (final p in data['private']) p['title']], ['家計簿アプリ']);
    });

    test('期間：「2024/4」→ 2024-04。終わりがなければ現在', () {
      expect(data['work'][0]['period'], ['2024-04', '2024-09']);
      expect(data['private'][0]['period'], ['2025-01', ExcelTexts.periodOngoing]);
    });

    test('作業工程：● のある列だけ true（「-」は担当なし）。Private には書かない', () {
      expect(data['work'][0]['workflow'], {
        'requirements': true,
        'basic_design': false,
        'detailed_design': false,
        'implementation_unit_test': true,
        'integration_test': false,
        'system_test': false,
        'maintenance_operation': false,
      });
      expect((data['private'][0] as Map).containsKey('workflow'), isFalse);
    });

    test('技術の振り分け（見出し・箇条書き・「 / 」・括弧の補足・AI の見出し・なし）', () {
      final w = data['work'][0] as Map<String, dynamic>;
      expect(w['server_os'], ['Linux']);
      expect(w['db'], ['MySQL']);
      expect(w['container'], ['Docker']);
      expect(w['tools'], ['Git', 'GitHub']);
      expect(w['ai_services'], ['GitHub Copilot']);
      expect(w['skills'], ['Python']);
      expect(w['backend_frameworks'], ['Django']);
      expect(w['frontend_frameworks'], [ExcelTexts.notUsed]);

      final p = data['private'][0] as Map<String, dynamic>;
      expect(p['db'], [ExcelTexts.notUsed]);
      expect(p['frontend_frameworks'], ['Flutter']);
      expect(p['skills'], ['Dart']);
      expect(p['tools'], ['VS Code']);
    });

    test('業務概要：description は「概要：」の 1 行目、details は全体、link は URL', () {
      final w = data['work'][0] as Map<String, dynamic>;
      expect(w['description'], '業務効率化のためのツールを開発');
      expect(w['details'], contains('担当：設計と実装'));
      expect(w['link'], '');
      final p = data['private'][0] as Map<String, dynamic>;
      expect(p['description'], '個人で使う家計簿アプリ');
      expect(p['link'], 'https://example.com/kakeibo');
    });

    test('過去の開発経験がなくても、直近だけで作れる', () {
      expect(data['home']['name'], '鈴木 一郎');
      expect(data['home']['tagline'], ExcelTexts.taglineLanguages(['Python', 'Go']));
      expect(data['about']['domains'], ['Web開発', 'API開発']);
      expect((data['about'] as Map).containsKey('past'), isFalse);
    });
  });

  group('セルの中の見出し・全角の期間', () {
    late Map<String, dynamic> work;

    setUpAll(() {
      final cells = _sheet()
        ..['F6'] = 'その他ツール・技術：\n- Docker\n\nAWS Service; AWS Lambda, S3\nAmazon DynamoDB\n\nGit; GitHub'
        ..['B8'] = '2024/１０';
      final result = convertSkillSheet(_xlsx(cells));
      expect(result.errors, isEmpty);
      work = (_plain(result.yamlText!)['work'] as List).first as Map<String, dynamic>;
    });

    test('「AWS Service;」の下は aws_services（Tools に入れない）。空行のあとは元の読み方に戻る', () {
      expect(work['aws_services'], ['AWS Lambda', 'S3', 'Amazon DynamoDB']);
      expect(work['cloud_platforms'], ['AWS']);
      expect(work['container'], ['Docker']);
      expect(work['tools'], ['Git', 'GitHub']); // 「Git; GitHub」は見出しではなく 2 つの項目
    });

    test('全角の数字の期間も読む（進行中にしない）', () {
      expect(work['period'], ['2024-04', '2024-10']);
    });

    test('1 つのセルに「2020/03～2020/１０」と書いても読む', () {
      final cells = _sheet()
        ..['B6'] = '2020/03～2020/１０'
        ..remove('B8');
      final r = convertSkillSheet(_xlsx(cells));
      expect(_plain(r.yamlText!)['work'][0]['period'], ['2020-03', '2020-10']);
    });
  });

  group('Projects の期間の解釈（Project）', () {
    Project project(Object period) => Project.fromMap({'title': 'x', 'period': period});

    test('「/」や全角の数字でも読み、進行中にしない', () {
      for (final period in [
        ['2020/03', '2020/１０'],
        ['2020-03', '2020-10'],
        '2020/03 から 2020/１０',
        '２０２０年３月～２０２０年１０月',
      ]) {
        final p = project(period);
        expect(p.isOngoing, isFalse, reason: '$period');
        expect(p.hasValidPeriod, isTrue, reason: '$period');
        expect(p.periodStart, DateTime(2020, 3), reason: '$period');
        expect(p.periodEnd, DateTime(2020, 10), reason: '$period');
        expect(p.durationMonths, 8, reason: '$period');
      }
    });

    test('「現在」は進行中', () {
      final p = project(['2020-03', '現在']);
      expect(p.isOngoing, isTrue);
      expect(p.hasValidPeriod, isTrue);
    });
  });

  group('読み込めないとき', () {
    test('.xlsx ではない', () {
      final r = convertSkillSheet(Uint8List.fromList(utf8.encode('name: x')));
      expect(r.isOk, isFalse);
      expect(r.errors, [ExcelTexts.notXlsx]);
    });

    test('氏名が空', () {
      final cells = _sheet()..remove('C1');
      expect(convertSkillSheet(_xlsx(cells)).errors, [ExcelTexts.nameMissing]);
    });

    test('開発経験がない', () {
      final cells = _sheet()..remove('A2');
      expect(convertSkillSheet(_xlsx(cells)).errors, [ExcelTexts.experienceMissing]);
    });
  });

  group('xlsx_reader', () {
    test('列の文字 → 番号', () {
      expect(columnNumber('A'), 1);
      expect(columnNumber('Z'), 26);
      expect(columnNumber('AA'), 27);
      expect(columnNumber('AT'), 46);
    });

    test('テンプレートのセルが読める（共有文字列・結合セルの左上）', () {
      final sheet = readXlsx(_template()).single;
      expect(sheet.name, 'スキルシート');
      expect(sheet.cell(5, 5), '山田 太郎'); // E5
      expect(sheet.cell(11, 5), 'サンプル・ワークプロジェクト'); // E11
    });
  });

  group('yaml_writer', () {
    test('書いた YAML を読み直すと同じ中身', () {
      final data = <String, Object?>{
        'plain': 'Flutter',
        'japanese': '山田 太郎',
        'date': '2023-04',
        'colon': 'a: b',
        'hash': 'x #y',
        'sharp': 'C#',
        'dot': '.NET',
        'bool': 'true',
        'dash': '- item',
        'quote': '"quoted"',
        'multi': '1 行目\n\n3 行目：説明',
        'list': ['利用なし', 'Node.js', '2024'],
        'map': {'言語': ['Python'], 'empty': <String>[]},
        'projects': [
          {'title': 'A', 'workflow': {'requirements': true}},
          {'title': 'B', 'details': '1\n2'},
        ],
      };
      expect(_plain(toYaml(data, header: 'コメント\n2 行目')), jsonDecode(jsonEncode(data)));
    });
  });

  test('作ったプロフィールの新しい項目（recent / past / *_tech）を Profile.parse が読める', () {
    final r = Profile.parse('''
home:
  name: A
  role: B
  tagline: C
about:
  intro: D
  recent: |-
    Web開発：説明
  recent_tech:
    言語:
      - Python
    DB: MySQL
  past_tech: x
''');
    expect(r.errors, [ProfileTexts.errorNotMapField('about.past_tech')]);
    final ok = Profile.parse('''
home: {name: A, role: B, tagline: C}
about:
  intro: D
  recent_tech:
    言語: [Python, Go]
    DB: MySQL
''');
    expect(ok.profile!.recentTech, {'言語': ['Python', 'Go'], 'DB': ['MySQL']});
  });
}
