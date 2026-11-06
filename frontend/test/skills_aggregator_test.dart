// Skills の集計（割合）のテスト
// 対象：lib/sections/skills/data/skills_aggregator.dart
//
// 実行：flutter test test/skills_aggregator_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/sections/skills/data/skills_aggregator.dart';

double _sum(Map<String, double> m) => m.values.fold(0, (a, b) => a + b);

void main() {
  group('aggregateCategory（分類ごとの出現割合 %）', () {
    test('案件ごとに数え、全体に対する割合にする', () {
      final r = aggregateCategory([
        {'skills': ['Dart', 'Python']},
        {'skills': ['Dart']},
      ], 'skills');
      expect(r.keys, ['Dart', 'Python']);
      expect(r['Dart'], closeTo(200 / 3, 1e-9));
      expect(r['Python'], closeTo(100 / 3, 1e-9));
    });

    test('合計は 100%', () {
      final r = aggregateCategory([
        {'db': ['MySQL', 'Redis', 'Oracle']},
        {'db': ['MySQL']},
        {'db': ['PostgreSQL', 'Redis']},
      ], 'db');
      expect(_sum(r), closeTo(100, 1e-9));
    });

    test('表記ゆれは 1 つにまとめ、よく知られた名前は正式な書き方で表示', () {
      final r = aggregateCategory([
        {'skills': ['python']},
        {'skills': ['PYTHON']},
        {'skills': ['Ｐｙｔｈｏｎ']},
      ], 'skills');
      expect(r, {'Python': 100});
    });

    test('1 つの案件の中で同じものが重なっても 1 回と数える', () {
      final r = aggregateCategory([
        {'skills': ['Dart', 'dart', 'DART']},
        {'skills': ['Go']},
      ], 'skills');
      expect(r, {'Dart': 50, 'Go': 50});
    });

    test('クラウドのサービスは先頭の AWS などを外してまとめる', () {
      final r = aggregateCategory([
        {'aws_services': ['AWS Lambda']},
        {'aws_services': ['Lambda', 'Amazon S3']},
      ], 'aws_services');
      expect(r.keys, unorderedEquals(['Lambda', 'S3']));
      expect(r['Lambda'], closeTo(200 / 3, 1e-9));
    });

    test('「利用なし」・空の項目は数えない', () {
      final r = aggregateCategory([
        {'db': ['利用なし']},
        {'db': ['MySQL', '']},
        {'db': ['  利用なし  ']},
      ], 'db');
      expect(r, {'MySQL': 100});
    });

    test('数えるものがなければ空（0 で割らない）', () {
      expect(aggregateCategory([], 'skills'), isEmpty);
      expect(aggregateCategory([{'skills': ['利用なし']}], 'skills'), isEmpty);
      expect(aggregateCategory([{'db': ['MySQL']}], 'skills'), isEmpty); // その分類の項目がない
    });

    test('値がカンマ区切りの文字でも数える', () {
      final r = aggregateCategory([
        {'skills': 'Dart, Python'},
        {'skills': ['Dart']},
      ], 'skills');
      expect(r.keys, ['Dart', 'Python']);
    });

    test('YAML から読んだ並び（YamlList / YamlMap）をそのまま渡せる', () {
      final projects = loadYaml('''
projects:
  - skills: [Dart, Python]
  - skills:
      - Dart
''')['projects'] as YamlList;
      final r = aggregateCategory(projects, 'skills');
      expect(r['Dart'], closeTo(200 / 3, 1e-9));
    });
  });

  group('aggregateWorkflow（工程ごとの担当率 %）', () {
    test('工程ごとに、true の案件の割合', () {
      final r = aggregateWorkflow([
        {'workflow': {'requirements': true, 'basic_design': false}},
        {'workflow': {'requirements': true, 'basic_design': true}},
      ]);
      expect(r, {'requirements': 100, 'basic_design': 50});
    });

    test('工程の書かれていない案件は数に入れない', () {
      final r = aggregateWorkflow([
        {'workflow': {'requirements': true}},
        {'title': '工程なし'},
      ]);
      expect(r, {'requirements': 100});
    });

    test('true 以外（文字の "true"・1・null）は担当していない扱い', () {
      final r = aggregateWorkflow([
        {'workflow': {'requirements': 'true'}},
        {'workflow': {'requirements': 1}},
        {'workflow': {'requirements': null}},
        {'workflow': {'requirements': true}},
      ]);
      expect(r, {'requirements': 25});
    });

    test('一度も true がない工程は 0%', () {
      final r = aggregateWorkflow([
        {'workflow': {'system_test': false}},
      ]);
      expect(r, {'system_test': 0});
    });

    test('案件がなければ空', () {
      expect(aggregateWorkflow([]), isEmpty);
    });

    test('YAML から読んだ値（YamlMap）でも数える', () {
      final projects = loadYaml('''
- workflow:
    requirements: true
    basic_design: false
''') as YamlList;
      expect(aggregateWorkflow(projects), {'requirements': 100, 'basic_design': 0});
    });
  });
}
