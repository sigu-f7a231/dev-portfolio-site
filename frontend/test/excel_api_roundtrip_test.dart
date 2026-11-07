// Excel → API（Firestore）→ Excel で、スキルシートの中身が欠けないかのテスト（段階 6：今の Flutter の Excel の処理を流用する）
// 対象：lib/data/api_records.dart と、lib/utils/skill_sheet.dart（読み込み）・skill_sheet_writer.dart（書き出し）のつながり
//
//   テンプレートの Excel ─読む→ YAML の形 ─┬────────────────────────→ 書き出す → 読む … A
//                                         └→ API の形 → JSON → 戻す → 書き出す → 読む … B
//   A と B が同じなら、ログインして API に保存しても、ダウンロードするスキルシートは変わらない
//
// 実行：flutter test test/excel_api_roundtrip_test.dart（frontend/ で）
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/data/api_records.dart';
import 'package:dev_portfolio/data/records.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/utils/skill_sheet_writer.dart';

Uint8List _template() => File(skillSheetTemplateAsset).readAsBytesSync();

List<DataRecord> _list(Object? v) => [for (final p in (v is List ? v : const [])) Map<String, dynamic>.from(p as Map)];

/// Firestore に置いて読み直したのと同じ（JSON にできるものだけが残る）
Object? _json(Object? v) => jsonDecode(jsonEncode(v));
Map<String, dynamic> _jsonMap(Object? v) => _json(v) as Map<String, dynamic>;

/// プロフィールと Work / Private からスキルシートを書き、もう一度読んだ YAML
String _writeAndRead(DataRecord profileRecord, List<DataRecord> work, List<DataRecord> private) {
  final parsed = Profile.parse(yamlOfRecord(profileRecord));
  expect(parsed.errors, isEmpty);
  final profile = parsed.profile!;
  final xlsx = fillSkillSheet(
    _template(),
    SkillSheetData(
      name: profile.name,
      experience: experienceTextOf(profile),
      work: work,
      private: private,
      sheet: profile.sheet,
    ),
    today: DateTime(2026, 11, 6),
  );
  final result = convertSkillSheet(xlsx, fileName: skillSheetTemplateFileName);
  expect(result.errors, isEmpty);
  return result.yamlText!;
}

void main() {
  test('テンプレートの Excel を API に保存して戻しても、書き出すスキルシートは同じ', () {
    final read = convertSkillSheet(_template(), fileName: skillSheetTemplateFileName);
    expect(read.isOk, isTrue);
    final record = recordOfYaml(read.yamlText!);
    final profileRecord = <String, dynamic>{
      for (final key in ['home', 'about', 'sheet']) if (record[key] != null) key: record[key],
    };
    final work = _list(record['work']);
    final private = _list(record['private']);
    expect(work, isNotEmpty, reason: 'テンプレートにはサンプルのプロジェクトがある');

    // A：そのまま
    final direct = _writeAndRead(profileRecord, work, private);

    // B：API の形にして、JSON を通して戻す
    final api = profileToApi(profileRecord);
    final projects = _json([
      ...projectsToApi(work, kind: 'work', previous: const []),
      ...projectsToApi(private, kind: 'private', previous: const []),
    ]) as List;
    final back = profileFromApi(_jsonMap(api.profile), _jsonMap(api.skills));
    List<DataRecord> of(String kind) => [
          for (final p in projects)
            if (p['kind'] == kind) projectFromApi(Map<String, dynamic>.from(p as Map)),
        ];
    final viaApi = _writeAndRead(back, of('work'), of('private'));

    expect(viaApi, direct);
  });

  test('スキルシートだけの項目（ふりがな・生年月日など）も、API を通して残る', () {
    final profile = <String, dynamic>{
      'home': {'name': '往復 太郎', 'role': 'エンジニア', 'tagline': '紹介文'},
      'about': {
        'intro': '自己紹介',
        'recent': '受託開発',
        'recent_tech': {'言語': ['Dart', 'TypeScript'], 'FW': ['Flutter']},
      },
      'sheet': {'furigana': 'おうふく たろう', 'birthday': '1990年04月01日', 'station': '○○駅', 'education': '○○大学'},
    };
    final api = profileToApi(profile);
    expect(api.profile['sheet']['birthday'], '1990-04-01');
    final back = profileFromApi(_jsonMap(api.profile), _jsonMap(api.skills));
    expect(back['sheet'], profile['sheet']);
    expect(back['about']['recent_tech'], profile['about']['recent_tech']);
    expect(_writeAndRead(back, const [], const []), _writeAndRead(profile, const [], const []));
  });
}
