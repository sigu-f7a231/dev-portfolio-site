// Work / Private の YAML の検証テスト
// 対象：lib/utils/projects_yaml_validator.dart の isValidProjectsYaml
//
// 実行：flutter test test/projects_yaml_validator_test.dart（frontend/ で）
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/utils/projects_yaml_validator.dart';

String _asset(String name) => File('assets/data/$name').readAsStringSync();

const _workProject = '''
projects:
  - title: 業務プロジェクト
    period: [2024-04, 現在]
    workflow:
      requirements: false
      implementation_unit_test: true
''';

const _privateProject = '''
projects:
  - title: 個人開発
    period: [2023-01, 2023-06]
''';

void main() {
  group('テンプレート（assets/data）', () {
    test('format_work.yaml は Work として正しく、Private としては不可', () {
      final text = _asset('format_work.yaml');
      expect(isValidProjectsYaml(text, 'work'), isTrue);
      expect(isValidProjectsYaml(text, 'private'), isFalse);
    });

    test('format_private.yaml は Private として正しく、Work としては不可', () {
      final text = _asset('format_private.yaml');
      expect(isValidProjectsYaml(text, 'private'), isTrue);
      expect(isValidProjectsYaml(text, 'work'), isFalse);
    });

    test('format_profile.yaml は Work / Private どちらとしても不可', () {
      final text = _asset('format_profile.yaml');
      expect(isValidProjectsYaml(text, 'work'), isFalse);
      expect(isValidProjectsYaml(text, 'private'), isFalse);
    });
  });

  group('Work', () {
    test('workflow のあるプロジェクトは正しい', () {
      expect(isValidProjectsYaml(_workProject, 'work'), isTrue);
    });

    test('1 件でも workflow がなければ不可', () {
      const text = '''
projects:
  - title: A
    workflow:
      requirements: true
  - title: B
''';
      expect(isValidProjectsYaml(text, 'work'), isFalse);
    });
  });

  group('Private', () {
    test('workflow のないプロジェクトは正しい', () {
      expect(isValidProjectsYaml(_privateProject, 'private'), isTrue);
    });

    test('1 件でも workflow があれば不可', () {
      const text = '''
projects:
  - title: A
  - title: B
    workflow:
      requirements: true
''';
      expect(isValidProjectsYaml(text, 'private'), isFalse);
    });
  });

  group('Work / Private 共通で不可', () {
    final cases = <String, String>{
      '空のファイル': '',
      'YAML の書き方の誤り': 'projects:\n  - title: [閉じていない',
      '「キー: 値」の形でない': '- title: A\n',
      'projects がない': 'items:\n  - title: A\n',
      'projects が空': 'projects: []\n',
      'projects が配列でない': 'projects: A\n',
      'プロジェクトが「キー: 値」でない': 'projects:\n  - A\n',
      'title がない': 'projects:\n  - description: 説明だけ\n',
    };

    for (final dataType in ['work', 'private']) {
      cases.forEach((name, text) {
        test('$dataType：$name', () {
          expect(isValidProjectsYaml(text, dataType), isFalse);
        });
      });
    }
  });

  test('想定外の dataType では workflow を見ない（title があれば通る）', () {
    expect(isValidProjectsYaml(_workProject, 'other'), isTrue);
    expect(isValidProjectsYaml(_privateProject, 'other'), isTrue);
  });
}
