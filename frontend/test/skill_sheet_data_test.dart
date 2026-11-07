// スキルシートに書く中身の作り方と、見る人向けのスキルシートのコマンドのテスト
// 対象：lib/utils/skill_sheet_data.dart（本人の［ダウンロード］と見る人向けで共通）、lib/utils/skill_sheet_cli.dart（bin/skill_sheet.dart の中身）
//
// 実行：flutter test test/skill_sheet_data_test.dart（frontend/ で）
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/utils/skill_sheet_cli.dart';
import 'package:dev_portfolio/utils/skill_sheet_data.dart';
import 'package:dev_portfolio/utils/skill_sheet_pdf.dart';

/// 公開ページのデータ（API の形。services/api-hono の publicDataOf の結果と同じ。架空の人）
Map<String, dynamic> _public() => {
      'schemaVersion': 1,
      'profile': {
        'home': {'name': '公開 太郎', 'role': 'エンジニア', 'tagline': '紹介文'},
        'about': {'intro': '自己紹介', 'recent': '受託開発', 'domains': ['Web']},
        // 公開ページには入らないが、入っていても使わない
        'sheet': {'furigana': 'こうかい たろう', 'station': '架空駅'},
      },
      'skills': {
        'recentTech': {'言語': ['Dart', 'TypeScript'], '空': []},
      },
      'projects': [
        {'id': 'b', 'kind': 'work', 'order': 1, 'title': '新しい業務', 'period': {'start': '2024-01', 'end': null}},
        {
          'id': 'a',
          'kind': 'work',
          'order': 0,
          'title': '古い業務',
          'period': {'start': '2020-04', 'end': '2021-03'},
          'tech': {'skills': ['Python'], 'db': ['PostgreSQL']},
          'workflow': {'basic_design': true},
        },
        {'id': 'c', 'kind': 'private', 'order': 0, 'title': '個人開発', 'period': {'start': '2023-01', 'end': null}},
        'こわれた項目',
      ],
      'display': {'allowSheetDownload': true},
    };

Uint8List _template() => File(skillSheetTemplateAsset).readAsBytesSync();
Uint8List _font() => File(skillSheetPdfFontAsset).readAsBytesSync();

Uint8List _readFile(String path) => switch (path) {
      'template.xlsx' => _template(),
      'font.ttf' => _font(),
      _ => throw FileSystemException('ありません', path),
    };

List<int> _input(Object? json) => utf8.encode(jsonEncode(json));

void main() {
  group('skillSheetDataOf・publicSkillSheetData', () {
    test('公開ページのデータ → 名前・開発経験・Work / Private（開始の古い順）。スキルシートだけの項目は空', () {
      final data = publicSkillSheetData(_public());
      expect(data.name, '公開 太郎');
      expect(data.experience, contains('受託開発'));
      expect(data.experience, contains('言語：Dart、TypeScript'));
      expect([for (final p in data.work) p['title']], ['古い業務', '新しい業務']);
      expect(data.work.first['db'], ['PostgreSQL']);
      expect(data.work.first['tools'], ['利用なし']);
      expect([for (final p in data.private) p['title']], ['個人開発']);
      expect(data.sheet, isEmpty);
    });

    test('空・形の違うデータでも落ちない（名前がなければ開発経験も空）', () {
      final data = publicSkillSheetData({'profile': 'x', 'projects': 'x'});
      expect(data.name, isEmpty);
      expect(data.experience, isEmpty);
      expect(data.work, isEmpty);
    });

    test('本人の［ダウンロード］と同じ作り方：sheet はそのまま', () {
      const profile = Profile(name: '本人', role: '', tagline: '', intro: '紹介', sheet: {'station': '○○駅'});
      final data = skillSheetDataOf(profile, [
        {'title': 'B', 'period': ['2024-01', '現在']},
        {'title': 'A', 'period': ['2020-01', '2020-06']},
      ], const []);
      expect([for (final p in data.work) p['title']], ['A', 'B']);
      expect(data.sheet, {'station': '○○駅'});
    });

    test('buildSkillSheet：Excel はテンプレートの形（読み直すと同じ中身）、フォントを渡すと PDF', () async {
      final data = publicSkillSheetData(_public());
      final xlsx = await buildSkillSheet(_template(), data, today: DateTime(2026, 11, 8));
      final read = convertSkillSheet(xlsx);
      expect(read.errors, isEmpty);
      expect(read.yamlText, contains('公開 太郎'));
      expect(read.yamlText, contains('古い業務'));
      expect(read.yamlText, isNot(contains('架空駅')));

      final pdf = await buildSkillSheet(_template(), data, font: ByteData.sublistView(_font()));
      expect(ascii.decode(pdf.sublist(0, 4)), '%PDF');
    });
  });

  group('runSkillSheetCli', () {
    test('Excel：テンプレートの形で作る', () async {
      final r = await runSkillSheetCli(
        ['--format', 'xlsx', '--template', 'template.xlsx'],
        _input({'data': _public(), 'today': '2026-11-08'}),
        readFile: _readFile,
      );
      expect(r.exitCode, 0);
      expect(r.error, isEmpty);
      expect(convertSkillSheet(r.output).yamlText, contains('公開 太郎'));
    });

    test('PDF：フォントを使って作る', () async {
      final r = await runSkillSheetCli(
        ['--format', 'pdf', '--template', 'template.xlsx', '--font', 'font.ttf'],
        _input({'data': _public()}),
        readFile: _readFile,
      );
      expect(r.exitCode, 0);
      expect(ascii.decode(r.output.sublist(0, 4)), '%PDF');
    });

    test('異常系：使い方の誤り・入力の誤り・ファイルがないは 2 と理由', () async {
      Future<String> error(List<String> args, Object? input) async {
        final r = await runSkillSheetCli(args, input is List<int> ? input : _input(input), readFile: _readFile);
        expect(r.exitCode, 2);
        expect(r.output, isEmpty);
        return r.error;
      }

      final ok = {'data': _public()};
      expect(await error([], ok), skillSheetCliUsage);
      expect(await error(['--format'], ok), skillSheetCliUsage);
      expect(await error(['format', 'pdf'], ok), skillSheetCliUsage);
      expect(await error(['--format', 'docx', '--template', 'template.xlsx'], ok), skillSheetCliUsage);
      expect(await error(['--format', 'xlsx'], ok), skillSheetCliUsage);
      expect(await error(['--format', 'pdf', '--template', 'template.xlsx'], ok), contains('--font'));
      final xlsx = ['--format', 'xlsx', '--template', 'template.xlsx'];
      expect(await error(xlsx, utf8.encode('{bad')), contains('JSON'));
      expect(await error(xlsx, _input([1])), contains('data')); // JSON の [1]（バイトの [1] ではない）
      expect(await error(xlsx, {'data': 'x'}), contains('data'));
      expect(await error(xlsx, {'data': {}, 'today': 'いつか'}), contains('today'));
      expect(await error(['--format', 'xlsx', '--template', 'none.xlsx'], ok), contains('ファイルを読めません'));
      expect(
        await error(['--format', 'pdf', '--template', 'template.xlsx', '--font', 'none.ttf'], ok),
        contains('ファイルを読めません'),
      );
    });
  });
}
